package com.wayfarer.ai.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.wayfarer.config.AppProperties;
import java.net.http.HttpClient;
import java.time.Duration;
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
    private final AppProperties.Ai cfg;
    private final HttpClient http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();

    public LlmClient(AppProperties props) { this.cfg = props.ai(); }

    public boolean configured() { return cfg.configured(); }

    public String complete(String system, String user, int maxTokens, Duration timeout) {
        if (!configured()) throw new IllegalStateException("LLM not configured");
        JdkClientHttpRequestFactory factory = new JdkClientHttpRequestFactory(http);
        factory.setReadTimeout(timeout);
        return cfg.isGemini() ? completeGemini(factory, system, user, maxTokens) : completeAnthropic(factory, system, user, maxTokens);
    }

    private String completeAnthropic(JdkClientHttpRequestFactory factory, String system, String user, int maxTokens) {
        JsonNode body = RestClient.builder().requestFactory(factory).baseUrl("https://api.anthropic.com").build().post().uri("/v1/messages")
            .contentType(MediaType.APPLICATION_JSON)
            .header("x-api-key", cfg.apiKey()).header("anthropic-version", "2023-06-01")
            .body(Map.of("model", cfg.modelName(), "max_tokens", maxTokens, "system", system, "messages", List.of(Map.of("role", "user", "content", user))))
            .retrieve().body(JsonNode.class);
        StringBuilder out = new StringBuilder();
        if (body != null && body.has("content")) {
            for (JsonNode part : body.get("content")) if ("text".equals(part.path("type").asText())) out.append(part.path("text").asText()).append('\n');
        }
        return out.toString().trim();
    }

    private String completeGemini(JdkClientHttpRequestFactory factory, String system, String user, int maxTokens) {
        JsonNode body = RestClient.builder().requestFactory(factory).baseUrl("https://generativelanguage.googleapis.com").build().post()
            .uri("/v1beta/models/{model}:generateContent", cfg.modelName())
            .contentType(MediaType.APPLICATION_JSON)
            .header("x-goog-api-key", cfg.apiKey())
            .body(Map.of(
                "systemInstruction", Map.of("parts", List.of(Map.of("text", system))),
                "contents", List.of(Map.of("role", "user", "parts", List.of(Map.of("text", user)))),
                "generationConfig", Map.of("maxOutputTokens", maxTokens)))
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
