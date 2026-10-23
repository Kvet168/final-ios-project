package com.wayfarer.ai.dto;

import java.util.List;
import java.util.UUID;

public final class AssistantDtos {
    private AssistantDtos() {}

    public record Source(UUID documentId, String slug, String title, String source, String category, String snippet, double score, boolean isDemo) {
        public Source withScore(double s) { return new Source(documentId, slug, title, source, category, snippet, s, isDemo); }
    }

    public record Card(String type, String title, String subtitle, String image, String route) {}

    public record DestinationRef(String slug, String name) {}

    public record Answer(String answer, String mode, List<Source> sources, boolean grounded, String disclaimer, String intent, DestinationRef destination,
                         List<Card> cards, List<String> followUps) {}
}
