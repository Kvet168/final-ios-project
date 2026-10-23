package com.wayfarer.system.web;

import com.wayfarer.common.Db;
import com.wayfarer.config.AppProperties;
import io.swagger.v3.oas.annotations.security.SecurityRequirements;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Lightweight liveness/readiness for clients and load balancers (the actuator endpoints stay available for operations). */
@RestController
@RequestMapping("/api/health")
@Tag(name = "System")
@SecurityRequirements
public class HealthController {
    private final Db db;
    private final AppProperties props;

    public HealthController(Db db, AppProperties props) {
        this.db = db;
        this.props = props;
    }

    @GetMapping
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> body = new LinkedHashMap<>();
        try {
            db.list("SELECT 1");
            body.put("status", "ok");
            body.put("database", "postgresql");
            body.put("paymentMode", props.payment().mode());
            body.put("time", Instant.now().toString());
            return ResponseEntity.ok(body);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(Map.of("status", "degraded", "database", "unreachable"));
        }
    }
}
