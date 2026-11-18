package com.wayfarer.media.repository;

import com.wayfarer.common.Db;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;

@Repository
public class MediaRepository {
    private final Db db;

    public MediaRepository(Db db) { this.db = db; }

    public UUID insert(UUID ownerId, String contentType, byte[] data) {
        return (UUID) db.one("INSERT INTO media(owner_id, content_type, byte_size, data) VALUES (:o, :t, :s, :d) RETURNING id",
            Db.params().addValue("o", ownerId).addValue("t", contentType).addValue("s", data.length).addValue("d", data)).orElseThrow().get("id");
    }

    public Optional<Map<String, Object>> find(UUID id) { return db.one("SELECT content_type, data FROM media WHERE id = :id", Map.of("id", id)); }

    public void deleteOwned(UUID id, UUID ownerId) { db.update("DELETE FROM media WHERE id = :id AND owner_id = :o", Map.of("id", id, "o", ownerId)); }

    public boolean ownedBy(UUID id, UUID ownerId) { return db.exists("SELECT 1 FROM media WHERE id = :id AND owner_id = :o", Map.of("id", id, "o", ownerId)); }
}
