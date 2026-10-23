package com.wayfarer.common;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.regex.Pattern;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Component;

/** Thin wrapper over NamedParameterJdbcTemplate returning JSON-friendly maps. Joins the caller's @Transactional context. */
@Component
public class Db {
    private static final Pattern UUID = Pattern.compile("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", Pattern.CASE_INSENSITIVE);
    private static final JsonRowMapper MAPPER = new JsonRowMapper();

    private final NamedParameterJdbcTemplate jdbc;

    public Db(NamedParameterJdbcTemplate jdbc) { this.jdbc = jdbc; }

    public static boolean isUuid(String s) { return s != null && UUID.matcher(s).matches(); }

    public static MapSqlParameterSource params() { return new MapSqlParameterSource(); }

    public List<Map<String, Object>> list(String sql, Map<String, ?> p) { return jdbc.query(sql, p, MAPPER); }

    public List<Map<String, Object>> list(String sql, MapSqlParameterSource p) { return jdbc.query(sql, p, MAPPER); }

    public List<Map<String, Object>> list(String sql) { return jdbc.query(sql, Map.of(), MAPPER); }

    public Optional<Map<String, Object>> one(String sql, Map<String, ?> p) { return list(sql, p).stream().findFirst(); }

    public Optional<Map<String, Object>> one(String sql, MapSqlParameterSource p) { return list(sql, p).stream().findFirst(); }

    public int update(String sql, Map<String, ?> p) { return jdbc.update(sql, p); }

    public int update(String sql, MapSqlParameterSource p) { return jdbc.update(sql, p); }

    public boolean exists(String sql, Map<String, ?> p) { return !list(sql, p).isEmpty(); }
}
