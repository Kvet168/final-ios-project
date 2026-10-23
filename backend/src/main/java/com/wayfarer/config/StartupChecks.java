package com.wayfarer.config;

import jakarta.annotation.PostConstruct;
import org.springframework.stereotype.Component;

/** Refuses to boot in production with development defaults. */
@Component
public class StartupChecks {
    private final AppProperties props;

    public StartupChecks(AppProperties props) { this.props = props; }

    @PostConstruct
    void check() {
        if (props.jwt().accessSecret().getBytes().length < 32) {
            throw new IllegalStateException("wayfarer.jwt.access-secret must be at least 32 bytes");
        }
        if (props.prod()) {
            if (props.jwt().accessSecret().startsWith("dev-only")) throw new IllegalStateException("JWT_ACCESS_SECRET must be set in production");
            if (props.payment().webhookSecret().startsWith("dev-")) throw new IllegalStateException("PAYMENT_WEBHOOK_SECRET must be set in production");
        }
    }
}
