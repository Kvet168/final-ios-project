package com.wayfarer.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.wayfarer.common.GlobalExceptionHandler;
import com.wayfarer.config.AppProperties;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/** Per-client-IP limits: credential endpoints (brute force) and the AI endpoints (cost). Limits come from configuration. */
@Component
public class RateLimitFilter extends OncePerRequestFilter {
    private final RateLimiter limiter;
    private final AppProperties props;
    private final ObjectMapper json;

    public RateLimitFilter(RateLimiter limiter, AppProperties props, ObjectMapper json) {
        this.limiter = limiter;
        this.props = props;
        this.json = json;
    }

    private enum Bucket { AUTH, AI, NONE }

    private static Bucket bucket(HttpServletRequest req) {
        String p = req.getRequestURI();
        if (!"POST".equals(req.getMethod())) return Bucket.NONE;
        if (p.startsWith("/api/auth/") && !p.endsWith("/logout")) return Bucket.AUTH;
        if (p.startsWith("/api/ai/") || (p.startsWith("/api/itineraries/") && p.endsWith("/generate"))) return Bucket.AI;
        return Bucket.NONE;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest req) { return bucket(req) == Bucket.NONE; }

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain) throws ServletException, IOException {
        Bucket b = bucket(req);
        boolean ok = b == Bucket.AUTH
            ? limiter.allow("rl:auth:" + req.getRemoteAddr(), props.rateLimit().authMax(), props.rateLimit().windowSec())
            : limiter.allow("rl:ai:" + req.getRemoteAddr(), props.ai().requestsPerMinute(), 60);
        if (!ok) {
            res.setStatus(429);
            res.setContentType("application/json");
            String msg = b == Bucket.AUTH ? "Too many attempts. Please try again later." : "You are asking too quickly. Please wait a moment.";
            json.writeValue(res.getOutputStream(), GlobalExceptionHandler.body("RATE_LIMITED", msg, null));
            return;
        }
        chain.doFilter(req, res);
    }
}
