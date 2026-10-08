package com.ceylonheritage.backend.controller;

import com.ceylonheritage.backend.Dtos.TourismDto;
import com.ceylonheritage.backend.service.TourismService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/tourism/places")
public class PlaceController {

    private final TourismService tourismService;

    public PlaceController(TourismService tourismService) {
        this.tourismService = tourismService;
    }

    @GetMapping
    public ResponseEntity<List<TourismDto.PlaceResponse>> getPlaces(
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Double latitude,
            @RequestParam(required = false) Double longitude,
            @RequestParam(defaultValue = "5000") int radiusMeters) {
        return ResponseEntity.ok(tourismService.getPlaces(category, search, latitude, longitude, radiusMeters));
    }

    @GetMapping("/recommended")
    public ResponseEntity<List<TourismDto.PlaceResponse>> getRecommendations(
            @RequestParam(defaultValue = "nearby") String sort) {
        return ResponseEntity.ok(tourismService.getRecommendations(sort));
    }

    @GetMapping("/{placeId}")
    public ResponseEntity<TourismDto.PlaceResponse> getPlace(@PathVariable Long placeId) {
        return ResponseEntity.ok(tourismService.getPlace(placeId));
    }

    @GetMapping("/{placeId}/reviews")
    public ResponseEntity<List<TourismDto.ReviewResponse>> getReviews(
            @PathVariable Long placeId,
            @RequestParam(defaultValue = "latest") String sort) {
        return ResponseEntity.ok(tourismService.getReviews(placeId, sort));
    }

    @GetMapping("/{placeId}/ratings")
    public ResponseEntity<TourismDto.RatingSummaryResponse> getRatingSummary(@PathVariable Long placeId) {
        return ResponseEntity.ok(tourismService.getRatingSummary(placeId));
    }

    @PostMapping("/{placeId}/reviews")
    public ResponseEntity<TourismDto.ReviewResponse> addReview(
            Authentication authentication,
            @PathVariable Long placeId,
            @Valid @RequestBody TourismDto.ReviewRequest request) {
        return ResponseEntity.ok(tourismService.addReview(placeId, authentication.getName(), request));
    }
}
