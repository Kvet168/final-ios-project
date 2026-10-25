package com.wayfarer.ai.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.wayfarer.config.AppProperties;
import java.net.http.HttpClient;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.springframework.http.MediaType;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

/**
 * Provider abstraction over the Anthropic Messages API and the Google Gemini generateContent API. When no key is configured
 * {@link #configured()} is false and every caller must use its deterministic fallback and report mode "rules" / "retrieval-only"
 * to the user.
 */
@Component
public class LlmClient {
    /** One chat message. {@code role} is "user" or "assistant". */
    public record Turn(String role, String text) {}

    private final AppProperties.Ai cfg;
    private final HttpClient http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();

    public LlmClient(AppProperties props) { this.cfg = props.ai(); }

    public boolean configured() { return cfg.configured(); }

    public String complete(String system, String user, int maxTokens, Duration timeout) {
        return chat(system, List.of(new Turn("user", user)), maxTokens, timeout);
    }

    /** Multi-turn chat. The last turn should be the user's current message. */
    public String chat(String system, List<Turn> turns, int maxTokens, Duration timeout) {
        if (!configured()) throw new IllegalStateException("LLM not configured");
        List<Turn> conversation = normalize(turns);
        if (conversation.isEmpty()) throw new IllegalArgumentException("No messages to send");
        JdkClientHttpRequestFactory factory = new JdkClientHttpRequestFactory(http);
        factory.setReadTimeout(timeout);
        String provider = cfg.isGemini() ? "gemini" : "anthropic";
        try {
            String text = cfg.isGemini() ? chatGemini(factory, system, conversation, maxTokens) : chatAnthropic(factory, system, conversation, maxTokens);
            if (text.isBlank()) throw new IllegalStateException("empty response (model " + cfg.modelName() + ")");
            return text;
        } catch (org.springframework.web.client.RestClientResponseException e) {
            String detail = e.getResponseBodyAsString();
            throw new IllegalStateException(provider + " HTTP " + e.getStatusCode().value() + " (model " + cfg.modelName() + "): "
                + (detail.length() > 300 ? detail.substring(0, 300) : detail), e);
        }
    }

    /** Both providers want alternating roles that start with the user: drop blanks, merge neighbours with the same role, skip a leading assistant turn. */
    static List<Turn> normalize(List<Turn> turns) {
        List<Turn> out = new ArrayList<>();
        for (Turn t : turns) {
            if (t == null || t.text() == null || t.text().isBlank()) continue;
            String role = "assistant".equals(t.role()) || "model".equals(t.role()) ? "assistant" : "user";
            if (out.isEmpty() && role.equals("assistant")) continue;
            if (!out.isEmpty() && out.get(out.size() - 1).role().equals(role)) {
                Turn last = out.remove(out.size() - 1);
                out.add(new Turn(role, last.text() + "\n\n" + t.text().trim()));
            } else {
                out.add(new Turn(role, t.text().trim()));
            }
        }
        return out;
    }

    private String chatAnthropic(JdkClientHttpRequestFactory factory, String system, List<Turn> turns, int maxTokens) {
        List<Map<String, String>> messages = turns.stream().map(t -> Map.of("role", t.role(), "content", t.text())).toList();
        JsonNode body = RestClient.builder().requestFactory(factory).baseUrl("https://api.anthropic.com").build().post().uri("/v1/messages")
            .contentType(MediaType.APPLICATION_JSON)
            .header("x-api-key", cfg.key()).header("anthropic-version", "2023-06-01")
            .body(Map.of("model", cfg.modelName(), "max_tokens", maxTokens, "system", system, "messages", messages))
            .retrieve().body(JsonNode.class);
        StringBuilder out = new StringBuilder();
        if (body != null && body.has("content")) {
            for (JsonNode part : body.get("content")) if ("text".equals(part.path("type").asText())) out.append(part.path("text").asText()).append('\n');
        }
        return out.toString().trim();
    }

    /** Gemini 2.5 models "think" before answering and count that against maxOutputTokens, which can leave the answer empty. */
    private Map<String, Object> generationConfig(int maxTokens) {
        Map<String, Object> g = new java.util.HashMap<>();
        g.put("maxOutputTokens", maxTokens);
        String m = cfg.modelName();
        if (m.startsWith("gemini-2.5") && !m.contains("pro")) g.put("thinkingConfig", Map.of("thinkingBudget", 0));
        return g;
    }

    private String chatGemini(JdkClientHttpRequestFactory factory, String system, List<Turn> turns, int maxTokens) {
        List<Map<String, Object>> contents = turns.stream()
            .map(t -> Map.<String, Object>of("role", "assistant".equals(t.role()) ? "model" : "user", "parts", List.of(Map.of("text", t.text())))).toList();
        JsonNode body = RestClient.builder().requestFactory(factory).baseUrl("https://generativelanguage.googleapis.com").build().post()
            .uri("/v1beta/models/{model}:generateContent", cfg.modelName())
            .contentType(MediaType.APPLICATION_JSON)
            .header("x-goog-api-key", cfg.key())
            .body(Map.of(
                "systemInstruction", Map.of("parts", List.of(Map.of("text", system))),
                "contents", contents,
                "generationConfig", generationConfig(maxTokens)))
            .retrieve().body(JsonNode.class);
        StringBuilder out = new StringBuilder();
        if (body != null) {
            for (JsonNode part : body.path("candidates").path(0).path("content").path("parts")) {
                if (part.has("text")) out.append(part.path("text").asText()).append('\n');
            }
        }
        return out.toString().trim();
    }

    /** Extracts the first JSON object from model text (models sometimes wrap JSON in prose or fences). */
    public static String extractJson(String text) {
        int start = text.indexOf('{'), end = text.lastIndexOf('}');
        if (start < 0 || end <= start) throw new IllegalArgumentException("No JSON object in model output");
        return text.substring(start, end + 1);
    }
}
