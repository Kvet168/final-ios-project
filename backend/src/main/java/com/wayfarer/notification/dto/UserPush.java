package com.wayfarer.notification.dto;

import java.util.UUID;

/** Event published when something should be pushed live to a user's open WebSocket sessions. */
public record UserPush(UUID userId, String type, Object data) {}
