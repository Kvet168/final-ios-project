package com.wayfarer.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.wayfarer.common.GlobalExceptionHandler;
import com.wayfarer.config.AppProperties;
import java.util.Arrays;
import java.util.List;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.header.writers.DelegatingRequestMatcherHeaderWriter;
import org.springframework.security.web.header.writers.StaticHeadersWriter;
import org.springframework.security.web.util.matcher.AntPathRequestMatcher;
import org.springframework.security.web.util.matcher.OrRequestMatcher;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

@Configuration
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    PasswordEncoder passwordEncoder() { return new BCryptPasswordEncoder(10); }

    /** Authentication is JWT-only, so there are no in-memory users (this also stops Boot generating a random default password). */
    @Bean
    UserDetailsService noUsers() { return new InMemoryUserDetailsManager(); }

    @Bean
    SecurityFilterChain filterChain(HttpSecurity http, JwtAuthFilter jwtFilter, RateLimitFilter rateLimit, ObjectMapper json) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable)           // stateless bearer-token API, no cookies
            .cors(c -> {})
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(a -> a
                .requestMatchers("/api/auth/**", "/api/payments/webhook", "/api/health", "/api/docs/**", "/api/openapi/**", "/swagger-ui/**", "/api/swagger-ui/**",
                    "/v3/api-docs/**", "/actuator/health/**", "/ws/**").permitAll()
                // anonymous reads: catalogue, reviews, templates, AI (works signed in or out; signing in adds saving and history)
                .requestMatchers(HttpMethod.GET, "/api/meta", "/api/home", "/api/documents", "/api/destinations/**", "/api/accommodations/**", "/api/room-types/**",
                    "/api/attractions/**", "/api/locations/**", "/api/ai/status", "/api/ai/sources", "/api/itineraries/*", "/api/ads", "/api/ads/*/article").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/business/register", "/api/ads/events").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/routes/estimate", "/api/ai/travel-plan", "/api/ai/assistant", "/api/ai/recommendations").permitAll()
                // the dashboards are public static files; every API call they make is authorised server-side
                .requestMatchers(HttpMethod.GET, "/admin", "/admin/**", "/partner", "/partner/**", "/business", "/business/**", "/dashboard/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/media/*").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/media").hasAnyRole("PARTNER", "BUSINESS", "STAFF", "ADMIN")
                .requestMatchers("/api/admin/**").hasAnyRole("STAFF", "ADMIN")
                .requestMatchers("/api/partner/**").hasRole("PARTNER")      // hotel owners only; administrators have read-only views under /api/admin
                .requestMatchers("/api/business/**").hasAnyRole("BUSINESS", "PARTNER")   // advertisers: business owners and hotel partners
                .anyRequest().authenticated())
            .exceptionHandling(e -> e
                .authenticationEntryPoint((req, res, ex) -> {
                    Object code = req.getAttribute(JwtAuthFilter.ERROR_ATTR);
                    boolean expired = "TOKEN_EXPIRED".equals(code);
                    String c = code != null ? code.toString() : "UNAUTHENTICATED";
                    String m = expired ? "Access token expired" : code != null ? "Invalid access token" : "Authentication required";
                    res.setStatus(401);
                    res.setContentType("application/json");
                    json.writeValue(res.getOutputStream(), GlobalExceptionHandler.body(c, m, null));
                })
                .accessDeniedHandler((req, res, ex) -> {
                    res.setStatus(403);
                    res.setContentType("application/json");
                    json.writeValue(res.getOutputStream(), GlobalExceptionHandler.body("FORBIDDEN", "You do not have permission to perform this action", null));
                }))
            .headers(h -> h.addHeaderWriter(new DelegatingRequestMatcherHeaderWriter(
                new OrRequestMatcher(new AntPathRequestMatcher("/admin/**"), new AntPathRequestMatcher("/partner/**"), new AntPathRequestMatcher("/business/**"), new AntPathRequestMatcher("/dashboard/**")),
                new StaticHeadersWriter("Content-Security-Policy",
                    "default-src 'self'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self'; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'"))))
            .addFilterBefore(rateLimit, UsernamePasswordAuthenticationFilter.class)
            .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    @Bean
    CorsConfigurationSource corsConfigurationSource(AppProperties props) {
        CorsConfiguration cfg = new CorsConfiguration();
        List<String> origins = Arrays.stream(props.corsOrigins().split(",")).map(String::trim).toList();
        cfg.setAllowedOriginPatterns(origins);
        cfg.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        cfg.setAllowedHeaders(List.of("Authorization", "Content-Type", "Idempotency-Key"));
        cfg.setMaxAge(3600L);
        UrlBasedCorsConfigurationSource src = new UrlBasedCorsConfigurationSource();
        src.registerCorsConfiguration("/api/**", cfg);
        return src;
    }
}
