package com.ceylonheritage.backend.service;

import com.ceylonheritage.backend.Dtos.HistoricalPlaceDto;

import java.util.List;

public interface HistoricalPlaceService {

    List<HistoricalPlaceDto> getAllPlaces();

    List<HistoricalPlaceDto> getFeaturedPlaces();

    List<HistoricalPlaceDto> getPopularPlaces();

    List<HistoricalPlaceDto> getRecommendedPlaces();

    HistoricalPlaceDto getPlaceById(Long id);

    List<HistoricalPlaceDto> searchPlaces(String keyword);

    List<HistoricalPlaceDto> searchPlaces(
            String keyword,
            String category
    );

    List<HistoricalPlaceDto> getNearbyPlaces(
            double latitude,
            double longitude,
            double radiusKm
    );
}