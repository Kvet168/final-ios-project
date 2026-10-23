package com.wayfarer.catalog.repository;

import com.wayfarer.common.Db;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Repository;

/** Small lookup tables: currencies, amenities, guides. */
@Repository
public class ReferenceDataRepository {
    private final Db db;

    public ReferenceDataRepository(Db db) { this.db = db; }

    public List<Map<String, Object>> currencies() { return db.list("SELECT code, name, symbol, per_usd, rate_source, updated_at FROM currencies ORDER BY code"); }

    public List<Map<String, Object>> amenities() { return db.list("SELECT code, label FROM amenities ORDER BY label"); }

    public boolean currencyExists(String code) { return db.exists("SELECT 1 FROM currencies WHERE code = :c", Map.of("c", code)); }

    public List<Map<String, Object>> documents() { return db.list("SELECT slug, title, category, source_label, is_demo FROM travel_documents ORDER BY category, title"); }
}
