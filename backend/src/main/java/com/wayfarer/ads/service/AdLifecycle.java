package com.wayfarer.ads.service;

import com.wayfarer.ads.repository.AdRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Switches campaigns on and off by date. Serving also checks the dates itself, so an ad never shows outside its dates even if this
 * job is late; the job keeps the status shown in the dashboards correct and frees slots of unpaid or finished campaigns.
 * Every statement is idempotent, so several API instances can run it safely.
 */
@Component
public class AdLifecycle {
    private static final Logger LOG = LoggerFactory.getLogger(AdLifecycle.class);
    static final int UNPAID_HOLD_DAYS = 3;

    private final AdRepository ads;

    public AdLifecycle(AdRepository ads) { this.ads = ads; }

    @Scheduled(fixedDelay = 300_000, initialDelay = 20_000)
    @Transactional
    public void tick() {
        try {
            int on = ads.activateDue(), off = ads.expireDue(), stale = ads.cancelStaleUnpaid(UNPAID_HOLD_DAYS).size();
            if (on + off + stale > 0) LOG.info("ads lifecycle: activated {}, expired {}, released {} unpaid", on, off, stale);
        } catch (RuntimeException e) {
            LOG.warn("ads lifecycle failed: {}", e.getMessage());
        }
    }
}
