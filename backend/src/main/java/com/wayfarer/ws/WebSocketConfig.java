package com.wayfarer.ws;

import com.wayfarer.user.repository.UserRepository;
import com.wayfarer.config.AppProperties;
import com.wayfarer.security.JwtService;
import com.wayfarer.security.TokenDenylist;
import io.jsonwebtoken.Claims;
import java.util.Arrays;
import java.util.Map;
import java.util.UUID;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;
import org.springframework.web.socket.server.HandshakeInterceptor;

@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {
    public static final String USER_ATTR = "userId";

    private final UserSocketRegistry registry;
    private final JwtService jwt;
    private final TokenDenylist denylist;
    private final UserRepository users;
    private final AppProperties props;

    public WebSocketConfig(UserSocketRegistry registry, JwtService jwt, TokenDenylist denylist, UserRepository users, AppProperties props) {
        this.registry = registry;
        this.jwt = jwt;
        this.denylist = denylist;
        this.users = users;
        this.props = props;
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry r) {
        String[] origins = Arrays.stream(props.corsOrigins().split(",")).map(String::trim).toArray(String[]::new);
        r.addHandler(registry, "/ws").addInterceptors(new AuthHandshake()).setAllowedOriginPatterns(origins);
    }

    /** Requires `Authorization: Bearer <access token>` on the upgrade request. */
    private class AuthHandshake implements HandshakeInterceptor {
        @Override
        public boolean beforeHandshake(ServerHttpRequest req, ServerHttpResponse res, WebSocketHandler h, Map<String, Object> attrs) {
            String header = req.getHeaders().getFirst("Authorization");
            if (header == null || !header.startsWith("Bearer ")) return reject(res);
            try {
                Claims c = jwt.parse(header.substring(7));
                UUID userId = UUID.fromString(c.getSubject());
                if (denylist.isDenied(c.getId()) || users.findAuthInfo(userId).isEmpty()) return reject(res);
                attrs.put(USER_ATTR, userId);
                return true;
            } catch (Exception e) {
                return reject(res);
            }
        }

        private boolean reject(ServerHttpResponse res) {
            res.setStatusCode(HttpStatus.UNAUTHORIZED);
            return false;
        }

        @Override
        public void afterHandshake(ServerHttpRequest req, ServerHttpResponse res, WebSocketHandler h, Exception ex) {}
    }
}
