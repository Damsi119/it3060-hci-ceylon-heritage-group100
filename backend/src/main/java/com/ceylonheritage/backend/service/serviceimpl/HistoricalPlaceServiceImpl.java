package com.ceylonheritage.backend.service.serviceimpl;

import com.ceylonheritage.backend.Dtos.HistoricalPlaceDto;
import com.ceylonheritage.backend.entities.HistoricalPlace;
import com.ceylonheritage.backend.repository.HistoricalPlaceRepository;
import com.ceylonheritage.backend.service.HistoricalPlaceService;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@Transactional(readOnly = true)
public class HistoricalPlaceServiceImpl
        implements HistoricalPlaceService {

    private static final Set<String> VALID_CATEGORIES = Set.of(
            "ANCIENT_CITY",
            "TEMPLE",
            "FORT",
            "MUSEUM",
            "ARCHAEOLOGICAL_SITE"
    );

    // Curated selections for the current local test database.
    // Update these IDs when your team selects the final places.
    private static final List<Long> POPULAR_PLACE_IDS =
            List.of(4L, 5L, 6L, 7L);

    private static final List<Long> RECOMMENDED_PLACE_IDS =
            List.of(1L, 2L, 3L);

    private final HistoricalPlaceRepository historicalPlaceRepository;

    public HistoricalPlaceServiceImpl(
            HistoricalPlaceRepository historicalPlaceRepository
    ) {
        this.historicalPlaceRepository = historicalPlaceRepository;
    }

    @Override
    public List<HistoricalPlaceDto> getAllPlaces() {
        return historicalPlaceRepository
                .findByActiveTrueOrderByNameAsc()
                .stream()
                .map(this::toDto)
                .toList();
    }

    @Override
    public List<HistoricalPlaceDto> getFeaturedPlaces() {
        return historicalPlaceRepository
                .findByFeaturedTrueAndActiveTrueOrderByNameAsc()
                .stream()
                .map(this::toDto)
                .toList();
    }

    @Override
    public List<HistoricalPlaceDto> getPopularPlaces() {
        return getCuratedPlaces(POPULAR_PLACE_IDS);
    }

    @Override
    public List<HistoricalPlaceDto> getRecommendedPlaces() {
        return getCuratedPlaces(RECOMMENDED_PLACE_IDS);
    }

    private List<HistoricalPlaceDto> getCuratedPlaces(
            List<Long> selectedIds
    ) {
        if (selectedIds.isEmpty()) {
            return List.of();
        }

        Map<Long, HistoricalPlace> placesById =
                historicalPlaceRepository
                        .findByActiveTrueAndIdIn(selectedIds)
                        .stream()
                        .collect(Collectors.toMap(
                                HistoricalPlace::getId,
                                Function.identity()
                        ));

        // Preserve the selected display order.
        // Missing or inactive places are omitted.
        return selectedIds.stream()
                .map(placesById::get)
                .filter(Objects::nonNull)
                .map(this::toDto)
                .toList();
    }

    @Override
    public HistoricalPlaceDto getPlaceById(Long id) {
        if (id == null || id <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Place ID must be a positive number"
            );
        }

        HistoricalPlace place = historicalPlaceRepository
                .findByIdAndActiveTrue(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Historical place not found"
                ));

        return toDto(place);
    }

    @Override
    public List<HistoricalPlaceDto> searchPlaces(String keyword) {
        return searchPlaces(keyword, null);
    }

    @Override
    public List<HistoricalPlaceDto> searchPlaces(
            String keyword,
            String category
    ) {
        String searchTerm = keyword == null ? "" : keyword.trim();
        String selectedCategory = normalizeCategory(category);

        List<HistoricalPlace> places;

        if (selectedCategory == null) {
            if (searchTerm.isEmpty()) {
                return getAllPlaces();
            }

            places = historicalPlaceRepository
                    .findByActiveTrueAndNameContainingIgnoreCaseOrActiveTrueAndCityContainingIgnoreCaseOrderByNameAsc(
                            searchTerm,
                            searchTerm
                    );
        } else if (searchTerm.isEmpty()) {
            places = historicalPlaceRepository
                    .findByActiveTrueAndCategoryIgnoreCaseOrderByNameAsc(
                            selectedCategory
                    );
        } else {
            places = historicalPlaceRepository
                    .searchByKeywordAndCategory(
                            searchTerm,
                            selectedCategory
                    );
        }

        return places.stream()
                .map(this::toDto)
                .toList();
    }

    @Override
    public List<HistoricalPlaceDto> getNearbyPlaces(
            double latitude,
            double longitude,
            double radiusKm
    ) {
        validateLocation(latitude, longitude, radiusKm);

        return historicalPlaceRepository
                .findByActiveTrueOrderByNameAsc()
                .stream()
                .map(place -> {
                    HistoricalPlaceDto dto = toDto(place);

                    double distance = calculateDistanceKm(
                            latitude,
                            longitude,
                            place.getLatitude(),
                            place.getLongitude()
                    );

                    dto.setDistanceKm(distance);
                    return dto;
                })
                .filter(dto -> dto.getDistanceKm() <= radiusKm)
                .sorted(Comparator.comparing(
                        HistoricalPlaceDto::getDistanceKm
                ))
                .toList();
    }

    private String normalizeCategory(String category) {
        if (category == null || category.isBlank()) {
            return null;
        }

        String normalized = category.trim()
                .toUpperCase(Locale.ROOT);

        if ("ALL".equals(normalized)) {
            return null;
        }

        if (!VALID_CATEGORIES.contains(normalized)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Invalid category. Use ALL, ANCIENT_CITY, TEMPLE, "
                            + "FORT, MUSEUM, or ARCHAEOLOGICAL_SITE"
            );
        }

        return normalized;
    }

    private HistoricalPlaceDto toDto(HistoricalPlace place) {
        HistoricalPlaceDto dto = new HistoricalPlaceDto();

        dto.setId(place.getId());
        dto.setName(place.getName());
        dto.setCity(place.getCity());
        dto.setCategory(place.getCategory());
        dto.setClimateType(place.getClimateType());
        dto.setTravelTags(place.getTravelTags());
        dto.setDescription(place.getDescription());
        dto.setImageUrl(place.getImageUrl());
        dto.setGalleryImages(
                new ArrayList<>(place.getGalleryImages())
        );
        dto.setLatitude(place.getLatitude());
        dto.setLongitude(place.getLongitude());
        dto.setRating(place.getRating());
        dto.setReviewCount(place.getReviewCount());
        dto.setOpeningHours(place.getOpeningHours());
        dto.setVisitDuration(place.getVisitDuration());
        dto.setVisitDurationMinutes(place.getVisitDurationMinutes());
        dto.setBestTimeToVisit(place.getBestTimeToVisit());
        dto.setEntryFee(place.getEntryFee());
        dto.setAccessibility(place.getAccessibility());
        dto.setFeatured(place.isFeatured());

        return dto;
    }

    private void validateLocation(
            double latitude,
            double longitude,
            double radiusKm
    ) {
        if (!Double.isFinite(latitude)
                || latitude < -90
                || latitude > 90) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Latitude must be between -90 and 90"
            );
        }

        if (!Double.isFinite(longitude)
                || longitude < -180
                || longitude > 180) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Longitude must be between -180 and 180"
            );
        }

        if (!Double.isFinite(radiusKm)
                || radiusKm <= 0
                || radiusKm > 200) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Radius must be greater than 0 and at most 200 km"
            );
        }
    }

    private double calculateDistanceKm(
            double userLatitude,
            double userLongitude,
            double placeLatitude,
            double placeLongitude
    ) {
        double earthRadiusKm = 6371.0;

        double latitudeDifference = Math.toRadians(
                placeLatitude - userLatitude
        );

        double longitudeDifference = Math.toRadians(
                placeLongitude - userLongitude
        );

        double userLatitudeRadians = Math.toRadians(userLatitude);
        double placeLatitudeRadians = Math.toRadians(placeLatitude);

        double a =
                Math.sin(latitudeDifference / 2)
                        * Math.sin(latitudeDifference / 2)
                        + Math.cos(userLatitudeRadians)
                        * Math.cos(placeLatitudeRadians)
                        * Math.sin(longitudeDifference / 2)
                        * Math.sin(longitudeDifference / 2);

        a = Math.max(0.0, Math.min(1.0, a));

        double c = 2 * Math.atan2(
                Math.sqrt(a),
                Math.sqrt(1 - a)
        );

        return earthRadiusKm * c;
    }
}
