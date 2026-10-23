package com.wayfarer.ws;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.wayfarer.notification.dto.UserPush;
import java.io.IOException;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.ConcurrentWebSocketSessionDecorator;
import org.springframework.web.socket.handler.TextWebSocketHandler;

/**
 * Raw WebSocket endpoint at /ws. The handshake is authenticated with the same JWT as the REST API (see WebSocketConfig).
 * Each user receives only their own events, delivered after the database transaction that caused them has committed.
 * Message shape: {"type":"booking.status"|"notification","data":{...}}.
 */
@Component
public class UserSocketRegistry extends TextWebSocketHandler {
    private static final Logger log = LoggerFactory.getLogger(UserSocketRegistry.class);

    private final Map<UUID, Set<WebSocketSession>> sessions = new ConcurrentHashMap<>();
    private final ObjectMapper json;

    public UserSocketRegistry(ObjectMapper json) { this.json = json; }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        UUID userId = (UUID) session.getAttributes().get(WebSocketConfig.USER_ATTR);
        WebSocketSession safe = new ConcurrentWebSocketSessionDecorator(session, 5_000, 64 * 1024);
        session.getAttributes().put("safe", safe);
        sessions.computeIfAbsent(userId, k -> ConcurrentHashMap.newKeySet()).add(safe);
        send(safe, Map.of("type", "connected", "data", Map.of("userId", userId)));
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        if ("ping".equalsIgnoreCase(message.getPayload().trim())) send((WebSocketSession) session.getAttributes().get("safe"), Map.of("type", "pong"));
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        UUID userId = (UUID) session.getAttributes().get(WebSocketConfig.USER_ATTR);
        Object safe = session.getAttributes().get("safe");
        Set<WebSocketSession> set = sessions.get(userId);
        if (set != null && safe != null) {
            set.remove((WebSocketSession) safe);
            if (set.isEmpty()) sessions.remove(userId);
        }
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void onPush(UserPush push) {
        Set<WebSocketSession> set = sessions.get(push.userId());
        if (set == null) return;
        Map<String, Object> msg = Map.of("type", push.type(), "data", push.data());
        for (WebSocketSession s : set) send(s, msg);
    }

    public int connectionCount() { return sessions.values().stream().mapToInt(Set::size).sum(); }

    private void send(WebSocketSession s, Object payload) {
        try {
            if (s != null && s.isOpen()) s.sendMessage(new TextMessage(json.writeValueAsString(payload)));
        } catch (IOException | IllegalStateException e) {
            log.debug("websocket send failed: {}", e.getMessage());
        }
    }
}
