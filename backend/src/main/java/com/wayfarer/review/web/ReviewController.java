package com.wayfarer.review.web;

import com.wayfarer.review.dto.ReviewDtos.CreateReviewRequest;
import com.wayfarer.review.service.ReviewService;
import com.wayfarer.security.CurrentUser;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
@Tag(name = "Reviews")
public class ReviewController {
    private final ReviewService reviews;

    public ReviewController(ReviewService reviews) { this.reviews = reviews; }

    @GetMapping("/accommodations/{idOrSlug}/reviews")
    public Map<String, Object> list(@PathVariable String idOrSlug, @RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "12") int pageSize) {
        return reviews.list(idOrSlug, page, pageSize);
    }

    @PostMapping("/accommodations/{idOrSlug}/reviews")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> create(@PathVariable String idOrSlug, @Valid @RequestBody CreateReviewRequest r) {
        return reviews.create(CurrentUser.require().id(), idOrSlug, r);
    }

    @GetMapping("/users/me/reviews")
    public Map<String, Object> mine() { return reviews.mine(CurrentUser.require().id()); }
}
