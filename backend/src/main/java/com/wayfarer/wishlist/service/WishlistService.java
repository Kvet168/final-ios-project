package com.wayfarer.wishlist.service;

import com.wayfarer.common.ApiException;
import com.wayfarer.wishlist.repository.WishlistRepository;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class WishlistService {
    private final WishlistRepository wishlist;

    public WishlistService(WishlistRepository wishlist) { this.wishlist = wishlist; }

    private static void requireKind(String kind) {
        if (!WishlistRepository.isKind(kind)) throw ApiException.unprocessable("VALIDATION_ERROR", "kind must be destination, accommodation or attraction");
    }

    public Map<String, Object> list(UUID userId) { return Map.of("items", wishlist.list(userId)); }

    @Transactional
    public void add(UUID userId, String kind, UUID refId) {
        requireKind(kind);
        if (!wishlist.targetExists(kind, refId)) throw ApiException.notFound(kind);
        wishlist.add(userId, kind, refId);
    }

    @Transactional
    public void remove(UUID userId, String kind, UUID refId) {
        requireKind(kind);
        wishlist.remove(userId, kind, refId);
    }

    public Map<String, Object> searchHistory(UUID userId) { return Map.of("items", wishlist.searchHistory(userId)); }

    public void recordSearch(UUID userId, String term) {
        if (term != null && !term.isBlank()) wishlist.recordSearch(userId, term.trim());
    }
}
