package com.wayfarer.notification.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.wayfarer.common.ApiException;
import com.wayfarer.notification.dto.UserPush;
import com.wayfarer.notification.repository.NotificationRepository;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class NotificationService {
    private final NotificationRepository repository;
    private final ObjectMapper json;
    private final ApplicationEventPublisher events;

    public NotificationService(NotificationRepository repository, ObjectMapper json, ApplicationEventPublisher events) {
        this.repository = repository;
        this.json = json;
        this.events = events;
    }

    /** Stores an in-app notification and pushes it over WebSocket once the surrounding transaction commits. */
    public void notify(UUID userId, String type, String title, String body, Map<String, ?> data) {
        String dataJson;
        try {
            dataJson = json.writeValueAsString(data == null ? Map.of() : data);
        } catch (JsonProcessingException e) {
            dataJson = "{}";
        }
        repository.insert(userId, type, title, body, dataJson);
        Map<String, Object> push = new LinkedHashMap<>();
        push.put("type", type);
        push.put("title", title);
        push.put("body", body);
        push.put("data", data == null ? Map.of() : data);
        events.publishEvent(new UserPush(userId, "notification", push));
    }

    public Map<String, Object> list(UUID userId) {
        List<Map<String, Object>> rows = repository.latest(userId, 100);
        long unread = rows.stream().filter(r -> r.get("read_at") == null).count();
        return Map.of("items", rows, "unread", unread, "push", "In-app and WebSocket. Mobile push delivery requires platform credentials and is not configured.");
    }

    @Transactional
    public void markRead(UUID userId, UUID id) {
        if (!repository.markRead(id, userId)) throw ApiException.notFound("Notification");
    }

    @Transactional
    public void markAllRead(UUID userId) { repository.markAllRead(userId); }
}
