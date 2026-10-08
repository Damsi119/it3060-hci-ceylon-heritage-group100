package com.ceylonheritage.backend.controller;

import com.ceylonheritage.backend.Dtos.HistoricalPlaceDto;
import com.ceylonheritage.backend.service.HistoricalPlaceService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/places")
public class HistoricalPlaceController {

    private final HistoricalPlaceService historicalPlaceService;

    public HistoricalPlaceController(
            HistoricalPlaceService historicalPlaceService
    ) {
        this.historicalPlaceService = historicalPlaceService;
    }

    @GetMapping
    public ResponseEntity<List<HistoricalPlaceDto>> getAllPlaces() {
        return ResponseEntity.ok(
                historicalPlaceService.getAllPlaces()
        );
    }

    @GetMapping("/featured")
    public ResponseEntity<List<HistoricalPlaceDto>> getFeaturedPlaces() {
        return ResponseEntity.ok(
                historicalPlaceService.getFeaturedPlaces()
        );
    }

    @GetMapping("/popular")
    public ResponseEntity<List<HistoricalPlaceDto>> getPopularPlaces() {
        return ResponseEntity.ok(
                historicalPlaceService.getPopularPlaces()
        );
    }

    @GetMapping("/recommended")
    public ResponseEntity<List<HistoricalPlaceDto>> getRecommendedPlaces() {
        return ResponseEntity.ok(
                historicalPlaceService.getRecommendedPlaces()
        );
    }

    @GetMapping("/{id}")
    public ResponseEntity<HistoricalPlaceDto> getPlaceById(
            @PathVariable("id") Long id
    ) {
        return ResponseEntity.ok(
                historicalPlaceService.getPlaceById(id)
        );
    }

    @GetMapping("/search")
    public ResponseEntity<List<HistoricalPlaceDto>> searchPlaces(
            @RequestParam(name = "keyword", defaultValue = "")
            String keyword,

            @RequestParam(name = "category", defaultValue = "ALL")
            String category
    ) {
        return ResponseEntity.ok(
                historicalPlaceService.searchPlaces(
                        keyword,
                        category
                )
        );
    }

    @GetMapping("/nearby")
    public ResponseEntity<List<HistoricalPlaceDto>> getNearbyPlaces(
            @RequestParam("latitude") double latitude,

            @RequestParam("longitude") double longitude,

            @RequestParam(name = "radiusKm", defaultValue = "10")
            double radiusKm
    ) {
        return ResponseEntity.ok(
                historicalPlaceService.getNearbyPlaces(
                        latitude,
                        longitude,
                        radiusKm
                )
        );
    }
}