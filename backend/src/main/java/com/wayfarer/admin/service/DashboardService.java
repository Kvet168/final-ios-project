package com.wayfarer.admin.service;

import com.wayfarer.admin.repository.AdminRepository;
import com.wayfarer.ai.repository.AiLogRepository;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.stereotype.Service;

@Service
public class DashboardService {
    private final AdminRepository admin;
    private final AiLogRepository aiLog;

    public DashboardService(AdminRepository admin, AiLogRepository aiLog) {
        this.admin = admin;
        this.aiLog = aiLog;
    }

    public Map<String, Object> overview() {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("counts", admin.counts());
        m.put("bookingsByStatus", admin.bookingsByStatus());
        m.put("revenueSimulatedUsd", admin.revenue());
        m.put("bookingsLast30Days", admin.bookingsPerDay(30));
        m.put("aiUsage", aiLog.usageByKind());
        m.put("note", "Revenue figures include simulated demo payments only.");
        return m;
    }

    public Map<String, Object> aiUsage() { return Map.of("items", aiLog.recentUsage(100)); }
}
