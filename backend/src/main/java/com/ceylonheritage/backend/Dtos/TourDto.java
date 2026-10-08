package com.ceylonheritage.backend.Dtos;

import java.time.LocalDateTime;
import java.util.List;

public record TourDto(

        Long id,
        Long ownerId,
        String name,
        Long version,

        int totalPlaces,

        Double totalDistanceKm,

        // Total travel time + planned visit time.
        // Null when either component is unavailable.
        Integer estimatedDurationMinutes,

        Integer travelDurationMinutes,
        Integer totalVisitDurationMinutes,

        // Identifies how distance and duration were calculated.
        String distanceCalculationMethod,
        String durationCalculationMethod,

        List<StopDto> stops,

        LocalDateTime createdAt,
        LocalDateTime updatedAt

) {

    public record StopDto(

            Long id,
            int stopOrder,

            Long placeId,
            String placeName,
            String placeCity,
            String imageUrl,

            Double latitude,
            Double longitude,

            // Display text, for example: "1–2 hours".
            String visitDuration,

            // Planned visit time in minutes; null means not configured.
            Integer visitDurationMinutes,

            Double rating,
            Integer reviewCount

    ) {
    }
}