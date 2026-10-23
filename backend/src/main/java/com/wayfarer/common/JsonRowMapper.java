package com.wayfarer.common;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Arrays;
import org.postgresql.util.PGobject;
import org.springframework.jdbc.core.ColumnMapRowMapper;

/** Maps rows to JSON-friendly maps: arrays become lists, jsonb becomes a tree, dates/timestamps become java.time. */
public class JsonRowMapper extends ColumnMapRowMapper {
    private static final ObjectMapper JSON = new ObjectMapper();

    @Override
    protected Object getColumnValue(ResultSet rs, int index) throws SQLException {
        Object v = super.getColumnValue(rs, index);
        if (v instanceof java.sql.Array a) {
            Object arr = a.getArray();
            return arr instanceof Object[] o ? Arrays.asList(o) : arr;
        }
        if (v instanceof PGobject p && ("jsonb".equals(p.getType()) || "json".equals(p.getType()))) {
            try {
                JsonNode n = JSON.readTree(p.getValue());
                return n;
            } catch (Exception e) {
                return p.getValue();
            }
        }
        if (v instanceof java.sql.Timestamp t) return t.toInstant();
        if (v instanceof java.sql.Date d) return d.toLocalDate();
        return v;
    }
}
