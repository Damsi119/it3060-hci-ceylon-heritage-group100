package com.ceylonheritage.backend.Dtos;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;

import java.time.LocalDateTime;
import java.util.List;

public final class TourismDto {
    private TourismDto() {}

    public record PlaceResponse(
            Long id,
            String slug,
            String name,
            String category,
            String description,
            String address,
            String city,
            String province,
            double rating,
            int reviewCount,
            int distanceMeters,
            boolean open,
            String openingHours,
            String priceRange,
            Double latitude,
            Double longitude,
            String imageUrl
    ) {}

    public record ReviewRequest(
            @Min(value = 1, message = "Rating must be between 1 and 5")
            @Max(value = 5, message = "Rating must be between 1 and 5")
            int rating,
            @NotBlank(message = "Review text is required")
            String comment
    ) {}

    public record ReviewResponse(
            Long id,
            String authorName,
            String authorLabel,
            int rating,
            String comment,
            LocalDateTime createdAt
    ) {}

    public record RatingSummaryResponse(
            double averageRating,
            long reviewCount,
            long fiveStars,
            long fourStars,
            long threeStars,
            long twoStars,
            long oneStar
    ) {}

    public record WeatherResponse(
            String location,
            String province,
            int temperatureCelsius,
            String condition,
            int humidityPercent,
            int windKmh,
            String uvIndex,
            List<HourlyForecast> hourly,
            List<DailyForecast> fiveDay,
            boolean demoData
    ) {}

    public record HourlyForecast(String time, int temperatureCelsius, String condition) {}
    public record DailyForecast(String day, int highCelsius, int lowCelsius, String condition) {}
}
