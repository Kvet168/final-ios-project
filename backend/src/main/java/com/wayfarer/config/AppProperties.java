package com.wayfarer.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "wayfarer")
public record AppProperties(boolean prod, int holdMinutes, Jwt jwt, Payment payment, RateLimit rateLimit,
                            String corsOrigins, int cacheTtlSec, Ai ai) {

    /**
     * Optional language model. With no key the planner and assistant run on deterministic rules and stored guides.
     * {@code provider} is "anthropic", "gemini" or "auto" (an Anthropic key always starts with "sk-ant-"; any other key is treated as Gemini).
     */
    public record Ai(String apiKey, String model, int requestsPerMinute, String provider) {
        public boolean configured() { return apiKey != null && !apiKey.isBlank(); }

        /** The key without stray whitespace or quotes from copy and paste. */
        public String key() { return apiKey == null ? "" : apiKey.strip().replaceAll("^[\"']|[\"']$", ""); }

        public boolean isGemini() {
            if ("gemini".equalsIgnoreCase(provider)) return true;
            if ("anthropic".equalsIgnoreCase(provider)) return false;
            return configured() && !key().startsWith("sk-ant-");
        }

        /** The configured model, or the provider's default when AI_MODEL is unset or belongs to the other provider. */
        public String modelName() {
            boolean gemini = isGemini();
            if (model == null || model.isBlank()) return gemini ? "gemini-3.8-flash" : "claude-sonnet-5-5";
            if (gemini && !model.startsWith("gemini")) return "gemini-3.8-flash";
            return model;
        }
    }

    public record Jwt(String accessSecret, long accessTtlSec, long refreshTtlSec, String issuer) {}

    public record Payment(String mode, String webhookSecret) {
        public boolean isMock() { return "mock".equals(mode); }
    }

    public record RateLimit(int authMax, int windowSec) {}
}
