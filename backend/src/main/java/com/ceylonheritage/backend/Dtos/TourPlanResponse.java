package com.ceylonheritage.backend.Dtos;

import java.util.List;

public record TourPlanResponse(
        String title,
        String destination,
        String preference,
        String startingLocation,
        Integer durationDays,
        Integer totalBudget,
        Integer totalEstimatedCost,
        String mapsUrl,
        String confidenceLabel,
        List<String> detectedKeywords,
        List<String> notes,
        List<ExpenseItem> expenses,
        List<ItineraryDay> itinerary,
        List<PlaceSuggestion> places
) {

    public record ExpenseItem(
            String name,
            Integer estimatedCost
    ) {}

    public record ItineraryDay(
            Integer day,
            List<String> activities
    ) {}

    public record PlaceSuggestion(
            Long id,
            String name,
            String city,
            String category,
            String imageUrl,
            Double latitude,
            Double longitude,
            String climateType,
            List<String> travelTags,
            String mapsUrl
    ) {}
}
