package com.wayfarer.ai.web;

import com.wayfarer.ai.dto.AssistantDtos.Answer;
import com.wayfarer.ai.dto.PlanDtos.AssistantRequest;
import com.wayfarer.ai.dto.PlanDtos.RecommendationRequest;
import com.wayfarer.ai.dto.PlanDtos.TravelPlanRequest;
import com.wayfarer.ai.service.AiService;
import com.wayfarer.security.CurrentUser;
import io.swagger.v3.oas.annotations.security.SecurityRequirements;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Planner and assistant. Open to anonymous callers; signing in additionally saves trips and conversation history. */
@RestController
@RequestMapping("/api/ai")
@Tag(name = "AI")
@SecurityRequirements
public class AiController {
    private final AiService ai;

    public AiController(AiService ai) { this.ai = ai; }

    @GetMapping("/status")
    public Map<String, Object> status() { return ai.status(); }

    @PostMapping("/travel-plan")
    public Map<String, Object> travelPlan(@Valid @RequestBody TravelPlanRequest r) { return ai.travelPlan(r, CurrentUser.optional()); }

    @PostMapping("/assistant")
    public Answer assistant(@Valid @RequestBody AssistantRequest r) { return ai.ask(r, CurrentUser.optional()); }

    @PostMapping("/recommendations")
    public Map<String, Object> recommendations(@Valid @RequestBody RecommendationRequest r) { return ai.recommend(r); }

    @GetMapping("/sources")
    public Map<String, Object> sources() { return ai.sources(); }
}
