package com.ceylonheritage.backend.Dtos;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
public class HistoricalPlaceDto {

    private Long id;
    private String name;
    private String city;
    private String category;
    private String climateType;
    private String travelTags;
    private String description;
    private String imageUrl;

    private List<String> galleryImages = new ArrayList<>();

    private Double latitude;
    private Double longitude;

    private Double rating;
    private Integer reviewCount;
    private String openingHours;

    // Display text, for example: "1–2 hours".
    private String visitDuration;

    // Planned visit time in minutes; null means not configured.
    private Integer visitDurationMinutes;

    private String bestTimeToVisit;
    private String entryFee;
    private String accessibility;

    private boolean featured;

    // Calculated when the user's location is provided.
    private Double distanceKm;
}
