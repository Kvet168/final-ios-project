package com.wayfarer.review.service;

import com.wayfarer.audit.service.AuditService;
import com.wayfarer.booking.repository.BookingRepository;
import com.wayfarer.catalog.repository.AccommodationRepository;
import com.wayfarer.common.ApiException;
import com.wayfarer.common.Pages;
import com.wayfarer.common.Rows;
import com.wayfarer.review.dto.ReviewDtos.CreateReviewRequest;
import com.wayfarer.review.repository.ReviewRepository;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ReviewService {
    private final ReviewRepository reviews;
    private final AccommodationRepository accommodations;
    private final BookingRepository bookings;
    private final AuditService audit;

    public ReviewService(ReviewRepository reviews, AccommodationRepository accommodations, BookingRepository bookings, AuditService audit) {
        this.reviews = reviews;
        this.accommodations = accommodations;
        this.bookings = bookings;
        this.audit = audit;
    }

    private UUID accommodationId(String idOrSlug) {
        return Rows.uuid(accommodations.findLightByIdOrSlug(idOrSlug).orElseThrow(() -> ApiException.notFound("Accommodation")), "id");
    }

    /** Public list: only the author's first name is exposed. */
    public Map<String, Object> list(String idOrSlug, int page, int pageSize) {
        int size = Pages.clampSize(pageSize, 50), p = Pages.clampPage(page);
        List<Map<String, Object>> rows = reviews.published(accommodationId(idOrSlug), size, Pages.offset(p, size)).stream().map(r -> {
            Map<String, Object> m = new LinkedHashMap<>(r);
            m.put("author", String.valueOf(r.get("author")).split(" ")[0]);
            return m;
        }).toList();
        return Pages.of(rows, p, size);
    }

    @Transactional
    public Map<String, Object> create(UUID userId, String idOrSlug, CreateReviewRequest r) {
        UUID accId = accommodationId(idOrSlug);
        Map<String, Object> stay = bookings.stayFor(userId, accId)
            .orElseThrow(() -> ApiException.forbidden("STAY_REQUIRED", "Only guests with a confirmed booking at this property can leave a review."));
        if (reviews.exists(accId, userId)) throw ApiException.conflict("REVIEW_EXISTS", "You have already reviewed this property.");
        Map<String, Object> created = reviews.insert(accId, userId, Rows.uuid(stay, "id"), r.rating(), r.title().trim(), r.body().trim());
        accommodations.refreshRating(accId);
        return created;
    }

    public Map<String, Object> mine(UUID userId) { return Map.of("items", reviews.forUser(userId)); }

    public Map<String, Object> moderationList(String status, int page, int pageSize) {
        int size = Pages.clampSize(pageSize, 100), p = Pages.clampPage(page);
        return Pages.of(reviews.moderationList(status, size, Pages.offset(p, size)), p, size);
    }

    @Transactional
    public void moderate(UUID actorId, UUID reviewId, String status) {
        UUID accId = reviews.setStatus(reviewId, status).orElseThrow(() -> ApiException.notFound("Review"));
        accommodations.refreshRating(accId);
        audit.record(actorId, "review.moderate", "review", reviewId, Map.of("status", status));
    }
}
