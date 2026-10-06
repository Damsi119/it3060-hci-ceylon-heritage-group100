package com.ceylonheritage.backend.service.serviceimpl;

import com.ceylonheritage.backend.Dtos.CreateTourRequest;
import com.ceylonheritage.backend.Dtos.TourDto;
import com.ceylonheritage.backend.Dtos.UpdateTourRequest;
import com.ceylonheritage.backend.entities.HistoricalPlace;
import com.ceylonheritage.backend.entities.Tour;
import com.ceylonheritage.backend.entities.TourStop;
import com.ceylonheritage.backend.entities.User;
import com.ceylonheritage.backend.repository.HistoricalPlaceRepository;
import com.ceylonheritage.backend.repository.TourRepository;
import com.ceylonheritage.backend.repository.TourStopRepository;
import com.ceylonheritage.backend.repository.UserRepository;
import com.ceylonheritage.backend.service.TourService;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@Transactional(readOnly = true)
public class TourServiceImpl implements TourService {

    private final TourRepository tourRepository;
    private final TourStopRepository tourStopRepository;
    private final HistoricalPlaceRepository historicalPlaceRepository;
    private final UserRepository userRepository;

    public TourServiceImpl(
            TourRepository tourRepository,
            TourStopRepository tourStopRepository,
            HistoricalPlaceRepository historicalPlaceRepository,
            UserRepository userRepository
    ) {
        this.tourRepository = tourRepository;
        this.tourStopRepository = tourStopRepository;
        this.historicalPlaceRepository = historicalPlaceRepository;
        this.userRepository = userRepository;
    }

    @Override
    @Transactional
    public TourDto createTour(
            Long authenticatedUserId,
            CreateTourRequest request
    ) {
        User owner = requireUser(authenticatedUserId);
        String name = validateName(request.name());
        List<HistoricalPlace> places = validatePlaces(request.placeIds());

        Tour tour = new Tour();
        tour.setOwner(owner);
        tour.setName(name);

        tourRepository.saveAndFlush(tour);
        saveStops(tour, places);

        return toDto(tour);
    }

    @Override
    public List<TourDto> getMyTours(Long authenticatedUserId) {
        requireUser(authenticatedUserId);

        return tourRepository
                .findByOwner_IdOrderByUpdatedAtDescIdDesc(
                        authenticatedUserId
                )
                .stream()
                .map(this::toDto)
                .toList();
    }

    @Override
    public TourDto getTourById(
            Long authenticatedUserId,
            Long tourId
    ) {
        requireUser(authenticatedUserId);

        return toDto(requireOwnedTour(
                authenticatedUserId,
                tourId
        ));
    }

    @Override
    @Transactional
    public TourDto updateTour(
            Long authenticatedUserId,
            Long tourId,
            UpdateTourRequest request
    ) {
        requireUser(authenticatedUserId);

        Tour tour = requireOwnedTour(authenticatedUserId, tourId);

        if (!Objects.equals(tour.getVersion(), request.version())) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Tour was updated. Reload it before editing."
            );
        }

        String name = validateName(request.name());
        List<HistoricalPlace> places = validatePlaces(request.placeIds());

        tour.setName(name);

        // Make stop-only edits update the parent and its version too.
        tour.setUpdatedAt(LocalDateTime.now());
        tourRepository.saveAndFlush(tour);

        // Flush deletions before inserting replacement stops.
        tourStopRepository.deleteByTour_Id(tourId);
        tourStopRepository.flush();

        saveStops(tour, places);

        return toDto(tour);
    }

    private User requireUser(Long userId) {
        if (userId == null) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Authentication required"
            );
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "Authentication required"
                ));

        if (!user.isEnabled()) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Account is disabled or deleted"
            );
        }

        return user;
    }

    private Tour requireOwnedTour(Long userId, Long tourId) {
        if (tourId == null || tourId <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Tour ID must be a positive number"
            );
        }

        return tourRepository.findByIdAndOwner_Id(tourId, userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Tour not found"
                ));
    }

    private String validateName(String name) {
        if (name == null || name.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Tour name is required"
            );
        }

        String trimmedName = name.trim();

        if (trimmedName.length() > 150) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Tour name must not exceed 150 characters"
            );
        }

        return trimmedName;
    }

    private List<HistoricalPlace> validatePlaces(List<Long> placeIds) {
        if (placeIds == null
                || placeIds.isEmpty()
                || placeIds.size() > 20) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Select between 1 and 20 historical places"
            );
        }

        if (placeIds.stream().anyMatch(id -> id == null || id <= 0)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Place IDs must be positive numbers"
            );
        }

        if (new HashSet<>(placeIds).size() != placeIds.size()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "A place cannot be added twice to the same tour"
            );
        }

        Map<Long, HistoricalPlace> placesById =
                historicalPlaceRepository
                        .findByActiveTrueAndIdIn(placeIds)
                        .stream()
                        .collect(Collectors.toMap(
                                HistoricalPlace::getId,
                                Function.identity()
                        ));

        List<HistoricalPlace> orderedPlaces = new ArrayList<>();

        for (Long placeId : placeIds) {
            HistoricalPlace place = placesById.get(placeId);

            if (place == null) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Historical place is missing or inactive: " + placeId
                );
            }

            orderedPlaces.add(place);
        }

        return orderedPlaces;
    }

    private void saveStops(
            Tour tour,
            List<HistoricalPlace> places
    ) {
        List<TourStop> stops = new ArrayList<>();

        for (int index = 0; index < places.size(); index++) {
            TourStop stop = new TourStop();
            stop.setTour(tour);
            stop.setHistoricalPlace(places.get(index));
            stop.setStopOrder(index + 1);
            stops.add(stop);
        }

        tourStopRepository.saveAllAndFlush(stops);
    }

    private TourDto toDto(Tour tour) {
        List<TourStop> stops = tourStopRepository
                .findByTour_IdOrderByStopOrderAscIdAsc(tour.getId());

        List<TourDto.StopDto> stopDtos = stops.stream()
                .map(stop -> {
                    HistoricalPlace place = stop.getHistoricalPlace();

                    return new TourDto.StopDto(
                            stop.getId(),
                            stop.getStopOrder(),
                            place.getId(),
                            place.getName(),
                            place.getCity(),
                            place.getImageUrl(),
                            place.getLatitude(),
                            place.getLongitude(),
                            place.getVisitDuration(),
                            place.getVisitDurationMinutes(),
                            place.getRating(),
                            place.getReviewCount()
                    );
                })
                .toList();

        Double distanceKm = calculateTotalDistance(stops);

        // Current travel estimate: straight-line distance at 4 km/h.
        Integer travelMinutes = distanceKm == null
                ? null
                : (int) Math.ceil(distanceKm / 4.0 * 60);

        Integer visitMinutes = calculateVisitMinutes(stops);

        // Only provide a total when both components are available.
        Integer totalMinutes = travelMinutes == null || visitMinutes == null
                ? null
                : Math.addExact(travelMinutes, visitMinutes);

        return new TourDto(
                tour.getId(),
                tour.getOwner().getId(),
                tour.getName(),
                tour.getVersion(),
                stops.size(),
                distanceKm,
                totalMinutes,
                travelMinutes,
                visitMinutes,
                distanceKm == null
                        ? "UNAVAILABLE"
                        : "STRAIGHT_LINE_BETWEEN_STOPS",
                totalMinutes == null
                        ? "UNAVAILABLE"
                        : "STRAIGHT_LINE_TRAVEL_AT_4_KMH_PLUS_PLANNED_VISITS",
                stopDtos,
                tour.getCreatedAt(),
                tour.getUpdatedAt()
        );
    }

    private Integer calculateVisitMinutes(List<TourStop> stops) {
        int total = 0;

        for (TourStop stop : stops) {
            Integer minutes = stop.getHistoricalPlace()
                    .getVisitDurationMinutes();

            // Missing or invalid visit times make the total unavailable.
            if (minutes == null || minutes < 0 || minutes > 1440) {
                return null;
            }

            total = Math.addExact(total, minutes);
        }

        return total;
    }

    private Double calculateTotalDistance(List<TourStop> stops) {
        for (TourStop stop : stops) {
            HistoricalPlace place = stop.getHistoricalPlace();

            if (!validCoordinates(
                    place.getLatitude(),
                    place.getLongitude()
            )) {
                return null;
            }
        }

        double total = 0;

        for (int index = 1; index < stops.size(); index++) {
            HistoricalPlace previous =
                    stops.get(index - 1).getHistoricalPlace();

            HistoricalPlace current =
                    stops.get(index).getHistoricalPlace();

            total += distanceKm(
                    previous.getLatitude(),
                    previous.getLongitude(),
                    current.getLatitude(),
                    current.getLongitude()
            );
        }

        return total;
    }

    private boolean validCoordinates(Double latitude, Double longitude) {
        return latitude != null
                && longitude != null
                && Double.isFinite(latitude)
                && Double.isFinite(longitude)
                && latitude >= -90
                && latitude <= 90
                && longitude >= -180
                && longitude <= 180;
    }

    private double distanceKm(
            double latitude1,
            double longitude1,
            double latitude2,
            double longitude2
    ) {
        double latitudeDifference =
                Math.toRadians(latitude2 - latitude1);

        double longitudeDifference =
                Math.toRadians(longitude2 - longitude1);

        double a =
                Math.pow(Math.sin(latitudeDifference / 2), 2)
                        + Math.cos(Math.toRadians(latitude1))
                        * Math.cos(Math.toRadians(latitude2))
                        * Math.pow(Math.sin(longitudeDifference / 2), 2);

        a = Math.max(0, Math.min(1, a));

        return 6371.0 * 2 * Math.atan2(
                Math.sqrt(a),
                Math.sqrt(1 - a)
        );
    }
}