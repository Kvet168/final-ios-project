package com.wayfarer.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "wayfarer")
public record AppProperties(boolean prod, int holdMinutes, Jwt jwt, Payment payment, RateLimit rateLimit,
                            String corsOrigins, int cacheTtlSec, Ai ai) {

    /** Optional language model. With no key the planner and assistant run on deterministic rules and stored guides. */
    public record Ai(String apiKey, String model, int requestsPerMinute) {
        public boolean configured() { return apiKey != null && !apiKey.isBlank(); }
    }

    public record Jwt(String accessSecret, long accessTtlSec, long refreshTtlSec, String issuer) {}

    public record Payment(String mode, String webhookSecret) {
        public boolean isMock() { return "mock".equals(mode); }
    }

    public record RateLimit(int authMax, int windowSec) {}
}
