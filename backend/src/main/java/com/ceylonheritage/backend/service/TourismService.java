package com.ceylonheritage.backend.service;

import com.ceylonheritage.backend.Dtos.TourismDto;
import com.ceylonheritage.backend.entities.FavoritePlace;
import com.ceylonheritage.backend.entities.Place;
import com.ceylonheritage.backend.entities.PlaceReview;
import com.ceylonheritage.backend.entities.User;
import com.ceylonheritage.backend.repository.FavoritePlaceRepository;
import com.ceylonheritage.backend.repository.PlaceRepository;
import com.ceylonheritage.backend.repository.PlaceReviewRepository;
import com.ceylonheritage.backend.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.Comparator;
import java.util.List;
import java.util.Locale;

@Service
public class TourismService {

    private final PlaceRepository placeRepository;
    private final PlaceReviewRepository reviewRepository;
    private final FavoritePlaceRepository favoriteRepository;
    private final UserRepository userRepository;
    private final OpenStreetMapPlacesService openStreetMapPlacesService;

    public TourismService(PlaceRepository placeRepository,
                          PlaceReviewRepository reviewRepository,
                          FavoritePlaceRepository favoriteRepository,
                          UserRepository userRepository,
                          OpenStreetMapPlacesService openStreetMapPlacesService) {
        this.placeRepository = placeRepository;
        this.reviewRepository = reviewRepository;
        this.favoriteRepository = favoriteRepository;
        this.userRepository = userRepository;
        this.openStreetMapPlacesService = openStreetMapPlacesService;
    }

    @Transactional(readOnly = true)
    public List<TourismDto.PlaceResponse> getPlaces(String category, String search) {
        return getPlaces(category, search, null, null, 5000);
    }

    @Transactional
    public List<TourismDto.PlaceResponse> getPlaces(
            String category, String search, Double latitude, Double longitude, int radiusMeters) {
        if ((latitude == null) != (longitude == null)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Latitude and longitude must be provided together");
        }
        String normalizedCategory = normalizeCategory(category);
        String term = search == null ? "" : search.trim().toLowerCase(Locale.ROOT);
        List<Place> candidates = latitude == null
                ? placeRepository.findAll()
                : openStreetMapPlacesService.findNearby(latitude, longitude, radiusMeters);
        return candidates.stream()
                .filter(place -> normalizedCategory == null || place.getCategory().equalsIgnoreCase(normalizedCategory))
                .filter(place -> term.isBlank() || place.getName().toLowerCase(Locale.ROOT).contains(term)
                        || place.getDescription().toLowerCase(Locale.ROOT).contains(term)
                        || place.getAddress().toLowerCase(Locale.ROOT).contains(term))
                .sorted(Comparator.comparingDouble(place -> distanceFor(place, latitude, longitude)))
                .map(place -> toPlaceResponse(place, latitude, longitude))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<TourismDto.PlaceResponse> getRecommendations(String sort) {
        Comparator<Place> comparator = switch (sort == null ? "nearby" : sort.toLowerCase(Locale.ROOT)) {
            case "popular" -> Comparator.comparingInt(Place::getReviewCount).reversed()
                    .thenComparing(Comparator.comparingDouble(Place::getRating).reversed());
            case "trending" -> Comparator.comparingDouble(Place::getRating).reversed()
                    .thenComparing(Comparator.comparingInt(Place::getReviewCount).reversed());
            default -> Comparator.comparingInt(Place::getDistanceMeters);
        };
        return placeRepository.findAll().stream().sorted(comparator).map(this::toPlaceResponse).toList();
    }

    @Transactional(readOnly = true)
    public TourismDto.PlaceResponse getPlace(Long placeId) {
        return toPlaceResponse(requirePlace(placeId));
    }

    @Transactional(readOnly = true)
    public List<TourismDto.ReviewResponse> getReviews(Long placeId, String sort) {
        requirePlace(placeId);
        var reviews = reviewRepository.findByPlace_IdOrderByCreatedAtDesc(placeId);
        if ("highest-rated".equalsIgnoreCase(sort)) {
            reviews = reviews.stream().sorted(Comparator.comparingInt(PlaceReview::getRating).reversed()
                    .thenComparing(PlaceReview::getCreatedAt, Comparator.reverseOrder())).toList();
        }
        return reviews.stream().map(this::toReviewResponse).toList();
    }

    @Transactional(readOnly = true)
    public TourismDto.RatingSummaryResponse getRatingSummary(Long placeId) {
        Place place = requirePlace(placeId);
        List<PlaceReview> reviews = reviewRepository.findByPlace_Id(placeId);
        if (reviews.isEmpty()) {
            return new TourismDto.RatingSummaryResponse(place.getRating(), place.getReviewCount(), 0, 0, 0, 0, 0);
        }
        double average = reviews.stream().mapToInt(PlaceReview::getRating).average().orElse(0);
        return new TourismDto.RatingSummaryResponse(average, reviews.size(),
                countRating(reviews, 5), countRating(reviews, 4), countRating(reviews, 3),
                countRating(reviews, 2), countRating(reviews, 1));
    }

    @Transactional
    public TourismDto.ReviewResponse addReview(Long placeId, String username, TourismDto.ReviewRequest request) {
        Place place = requirePlace(placeId);
        User author = userRepository.findByUsernameIgnoreCaseAndDeletedFalse(username)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User account was not found"));
        String displayName = ((author.getFirstName() == null ? "" : author.getFirstName().trim()) + " "
                + (author.getLastName() == null ? "" : author.getLastName().trim())).trim();
        if (displayName.isBlank()) displayName = author.getUsername();

        PlaceReview review = PlaceReview.builder()
                .place(place).author(author).authorName(displayName).authorLabel("Verified Visitor")
                .rating(request.rating()).comment(request.comment().trim()).build();
        review = reviewRepository.save(review);

        List<PlaceReview> allReviews = reviewRepository.findByPlace_Id(placeId);
        place.setRating(allReviews.stream().mapToInt(PlaceReview::getRating).average().orElse(place.getRating()));
        place.setReviewCount(allReviews.size());
        placeRepository.save(place);
        return toReviewResponse(review);
    }

    @Transactional(readOnly = true)
    public List<TourismDto.PlaceResponse> getFavorites(String username) {
        User user = requireUser(username);
        return favoriteRepository.findByUser_IdOrderByCreatedAtDesc(user.getId()).stream()
                .map(FavoritePlace::getPlace).map(this::toPlaceResponse).toList();
    }

    @Transactional
    public TourismDto.PlaceResponse addFavorite(String username, Long placeId) {
        User user = requireUser(username);
        Place place = requirePlace(placeId);
        if (favoriteRepository.findByUser_IdAndPlace_Id(user.getId(), placeId).isEmpty()) {
            favoriteRepository.save(FavoritePlace.builder().user(user).place(place).build());
        }
        return toPlaceResponse(place);
    }

    @Transactional
    public void removeFavorite(String username, Long placeId) {
        User user = requireUser(username);
        favoriteRepository.findByUser_IdAndPlace_Id(user.getId(), placeId)
                .ifPresent(favoriteRepository::delete);
    }

    @Transactional(readOnly = true)
    public TourismDto.WeatherResponse getWeather(String location) {
        String place = location == null || location.isBlank() ? "Galle" : location.trim();
        return new TourismDto.WeatherResponse(place, "Southern Province", 28, "Partly Cloudy",
                78, 12, "Moderate",
                List.of(new TourismDto.HourlyForecast("Now", 28, "Partly Cloudy"),
                        new TourismDto.HourlyForecast("10 AM", 27, "Sunny"),
                        new TourismDto.HourlyForecast("11 AM", 28, "Sunny"),
                        new TourismDto.HourlyForecast("12 PM", 27, "Partly Cloudy"),
                        new TourismDto.HourlyForecast("1 PM", 28, "Partly Cloudy")),
                List.of(new TourismDto.DailyForecast("Today", 28, 24, "Partly Cloudy"),
                        new TourismDto.DailyForecast("Tomorrow", 29, 25, "Sunny Intervals"),
                        new TourismDto.DailyForecast("Wed", 26, 23, "Heavy Rain"),
                        new TourismDto.DailyForecast("Thu", 27, 24, "Light Showers"),
                        new TourismDto.DailyForecast("Fri", 28, 24, "Partly Cloudy")), true);
    }

    private User requireUser(String username) {
        return userRepository.findByUsernameIgnoreCaseAndDeletedFalse(username)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User account was not found"));
    }

    private Place requirePlace(Long placeId) {
        return placeRepository.findById(placeId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Place was not found"));
    }

    private TourismDto.PlaceResponse toPlaceResponse(Place place) {
        return toPlaceResponse(place, null, null);
    }

    private TourismDto.PlaceResponse toPlaceResponse(Place place, Double originLat, Double originLon) {
        return new TourismDto.PlaceResponse(place.getId(), place.getSlug(), place.getName(), place.getCategory(),
                place.getDescription(), place.getAddress(), place.getCity(), place.getProvince(), place.getRating(),
                place.getReviewCount(), (int) Math.round(distanceFor(place, originLat, originLon)), place.isOpen(), place.getOpeningHours(),
                place.getPriceRange(), place.getLatitude(), place.getLongitude(), place.getImageUrl());
    }

    private double distanceFor(Place place, Double originLat, Double originLon) {
        if (originLat == null || originLon == null || place.getLatitude() == null || place.getLongitude() == null) {
            return place.getDistanceMeters();
        }
        double earthRadius = 6_371_000;
        double dLat = Math.toRadians(place.getLatitude() - originLat);
        double dLon = Math.toRadians(place.getLongitude() - originLon);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(originLat)) * Math.cos(Math.toRadians(place.getLatitude()))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return earthRadius * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }

    private TourismDto.ReviewResponse toReviewResponse(PlaceReview review) {
        return new TourismDto.ReviewResponse(review.getId(), review.getAuthorName(), review.getAuthorLabel(),
                review.getRating(), review.getComment(), review.getCreatedAt());
    }

    private long countRating(List<PlaceReview> reviews, int rating) {
        return reviews.stream().filter(review -> review.getRating() == rating).count();
    }

    private String normalizeCategory(String category) {
        if (category == null || category.isBlank() || "all".equalsIgnoreCase(category)) return null;
        String normalized = category.trim().toUpperCase(Locale.ROOT);
        if (normalized.equals("RESTAURANT")) return "RESTAURANTS";
        if (normalized.equals("HOTEL")) return "HOTELS";
        if (normalized.equals("SHOP")) return "SHOPS";
        if (normalized.equals("HISTORICAL")) return "HERITAGE";
        return normalized;
    }
}
