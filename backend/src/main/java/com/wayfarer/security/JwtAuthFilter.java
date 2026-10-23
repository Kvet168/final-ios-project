package com.wayfarer.security;

import com.wayfarer.user.repository.UserRepository;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class JwtAuthFilter extends OncePerRequestFilter {
    public static final String ERROR_ATTR = "wayfarer.auth.error";

    private final JwtService jwt;
    private final TokenDenylist denylist;
    private final UserRepository users;

    public JwtAuthFilter(JwtService jwt, TokenDenylist denylist, UserRepository users) {
        this.jwt = jwt;
        this.denylist = denylist;
        this.users = users;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain) throws ServletException, IOException {
        String header = req.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            try {
                Claims c = jwt.parse(header.substring(7));
                if (denylist.isDenied(c.getId())) {
                    req.setAttribute(ERROR_ATTR, "INVALID_TOKEN");
                } else {
                    UUID userId = UUID.fromString(c.getSubject());
                    Optional<Map<String, Object>> row = users.findAuthInfo(userId);
                    if (row.isEmpty()) {
                        req.setAttribute(ERROR_ATTR, "INVALID_TOKEN");
                    } else {
                        String role = row.get().get("role").toString();
                        AuthUser user = new AuthUser(userId, row.get().get("email").toString(), role, c.getId(), c.getExpiration().toInstant());
                        var auth = new UsernamePasswordAuthenticationToken(user, null, List.of(new SimpleGrantedAuthority("ROLE_" + role.toUpperCase())));
                        SecurityContextHolder.getContext().setAuthentication(auth);
                    }
                }
            } catch (ExpiredJwtException e) {
                req.setAttribute(ERROR_ATTR, "TOKEN_EXPIRED");
            } catch (JwtException | IllegalArgumentException e) {
                req.setAttribute(ERROR_ATTR, "INVALID_TOKEN");
            }
        }
        chain.doFilter(req, res);
    }
}
