package com.ceylonheritage.backend.service;

import com.ceylonheritage.backend.entities.Place;
import com.ceylonheritage.backend.repository.PlaceRepository;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.ConcurrentHashMap;

/** Fetches nearby named places from OpenStreetMap's Overpass API and stores
 *  them in the local places table so detail, review, and favourite APIs work. */
@Service
public class OpenStreetMapPlacesService {
    private static final String OVERPASS_URL = "https://overpass-api.de/api/interpreter";
    private static final int RESULT_LIMIT = 100;
    private static final Duration CACHE_TTL = Duration.ofMinutes(5);

    private final PlaceRepository placeRepository;
    private final JsonMapper objectMapper;
    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(12))
            .build();
    private final ConcurrentHashMap<String, CacheEntry> cache = new ConcurrentHashMap<>();

    public OpenStreetMapPlacesService(PlaceRepository placeRepository, JsonMapper objectMapper) {
        this.placeRepository = placeRepository;
        this.objectMapper = objectMapper;
    }

    public synchronized List<Place> findNearby(double latitude, double longitude, int requestedRadius) {
        int radius = Math.max(500, Math.min(requestedRadius, 10_000));
        String cacheKey = String.format(Locale.ROOT, "%.3f:%.3f:%d", latitude, longitude, radius);
        CacheEntry cached = cache.get(cacheKey);
        if (cached != null && cached.expiresAt().isAfter(Instant.now())) {
            return cached.places();
        }

        try {
            String query = buildQuery(latitude, longitude, radius);
            HttpRequest request = HttpRequest.newBuilder(URI.create(OVERPASS_URL))
                    .timeout(Duration.ofSeconds(40))
                    .header("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8")
                    .header("User-Agent", "CeylonHeritageStudentApp/1.0")
                    .POST(HttpRequest.BodyPublishers.ofString(
                            "data=" + URLEncoder.encode(query, StandardCharsets.UTF_8)))
                    .build();
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                throw new IOException("Overpass returned HTTP " + response.statusCode());
            }

            JsonNode elements = objectMapper.readTree(response.body()).path("elements");
            List<Place> nearby = new ArrayList<>();
            int count = 0;
            for (JsonNode element : elements) {
                Place place = toPlace(element, latitude, longitude);
                if (place == null) continue;
                nearby.add(placeRepository.findBySlug(place.getSlug()).map(existing -> {
                    existing.setName(place.getName());
                    existing.setCategory(place.getCategory());
                    existing.setDescription(place.getDescription());
                    existing.setAddress(place.getAddress());
                    existing.setCity(place.getCity());
                    existing.setProvince(place.getProvince());
                    existing.setDistanceMeters(place.getDistanceMeters());
                    existing.setOpeningHours(place.getOpeningHours());
                    existing.setLatitude(place.getLatitude());
                    existing.setLongitude(place.getLongitude());
                    return existing;
                }).orElse(place));
                if (++count >= RESULT_LIMIT) break;
            }

            List<Place> saved = placeRepository.saveAll(nearby);
            if (cache.size() > 32) cache.clear();
            List<Place> immutable = List.copyOf(saved);
            cache.put(cacheKey, new CacheEntry(Instant.now().plus(CACHE_TTL), immutable));
            return immutable;
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw unavailable(exception);
        } catch (IOException | RuntimeException exception) {
            if (exception instanceof ResponseStatusException statusException) throw statusException;
            throw unavailable(exception);
        }
    }

    private Place toPlace(JsonNode element, double originLat, double originLon) {
        JsonNode tags = element.path("tags");
        String name = tag(tags, "name", tag(tags, "name:en", "")).trim();
        if (name.isBlank()) return null;

        JsonNode point = element.has("center") ? element.path("center") : element;
        if (!point.has("lat") || !point.has("lon")) return null;
        double latitude = point.path("lat").asDouble();
        double longitude = point.path("lon").asDouble();
        String amenity = tag(tags, "amenity", "").toLowerCase(Locale.ROOT);
        String tourism = tag(tags, "tourism", "").toLowerCase(Locale.ROOT);
        String historic = tag(tags, "historic", "");
        String shop = tag(tags, "shop", "");
        String category = category(amenity, tourism, historic, shop);
        if (category == null) return null;

        String type = tag(element, "type", "node");
        String osmId = element.path("id").asText();
        String slug = "osm-" + type + "-" + osmId;
        String street = tag(tags, "addr:street", "");
        String houseNumber = tag(tags, "addr:housenumber", "");
        String city = firstTag(tags, "addr:city", "addr:town", "addr:village", "addr:suburb");
        String address = String.join(", ", List.of(houseNumber, street, city).stream()
                .filter(value -> !value.isBlank()).toList());
        if (address.isBlank()) address = city.isBlank() ? "Nearby area" : city;
        String description = tag(tags, "description", "OpenStreetMap place in the "
                + category.toLowerCase(Locale.ROOT) + " category.");
        if (description.length() > 1200) description = description.substring(0, 1200);

        return Place.builder()
                .slug(slug)
                .name(name.length() > 160 ? name.substring(0, 160) : name)
                .category(category)
                .description(description)
                .address(address.length() > 160 ? address.substring(0, 160) : address)
                .city(city.isBlank() ? "Nearby" : city)
                .province(tag(tags, "addr:province", tag(tags, "addr:state", "Sri Lanka")))
                .rating(0)
                .reviewCount(0)
                .distanceMeters((int) Math.round(distanceMeters(originLat, originLon, latitude, longitude)))
                .open(true)
                .openingHours(emptyToNull(tag(tags, "opening_hours", "")))
                .latitude(latitude)
                .longitude(longitude)
                .build();
    }

    private String buildQuery(double latitude, double longitude, int radius) {
        String around = "(around:" + radius + "," + latitude + "," + longitude + ")";
        return "[out:json][timeout:25];(" +
                "nwr" + around + "[\"name\"][\"amenity\"~\"^(restaurant|cafe|fast_food|food_court|bar|pub)$\"];" +
                "nwr" + around + "[\"name\"][\"tourism\"~\"^(attraction|museum|hotel|guest_house|motel|hostel|viewpoint|gallery)$\"];" +
                "nwr" + around + "[\"name\"][\"historic\"];" +
                "nwr" + around + "[\"name\"][\"shop\"];" +
                ");out center;";
    }

    private String category(String amenity, String tourism, String historic, String shop) {
        if (List.of("restaurant", "cafe", "fast_food", "food_court", "bar", "pub").contains(amenity)) {
            return "RESTAURANTS";
        }
        if (List.of("hotel", "guest_house", "motel", "hostel").contains(tourism)) return "HOTELS";
        if (!shop.isBlank()) return "SHOPS";
        if ("museum".equals(tourism)) return "MUSEUM";
        if (!historic.isBlank() || List.of("attraction", "viewpoint", "gallery").contains(tourism)) {
            return "HERITAGE";
        }
        return null;
    }

    private String firstTag(JsonNode tags, String... keys) {
        for (String key : keys) {
            String value = tag(tags, key, "");
            if (!value.isBlank()) return value;
        }
        return "";
    }

    private String tag(JsonNode tags, String key, String fallback) {
        JsonNode value = tags.get(key);
        return value == null || value.isNull() ? fallback : value.asText(fallback);
    }

    private String emptyToNull(String value) {
        return value.isBlank() ? null : value;
    }

    private double distanceMeters(double lat1, double lon1, double lat2, double lon2) {
        double earthRadius = 6_371_000;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return earthRadius * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }

    private ResponseStatusException unavailable(Exception cause) {
        return new ResponseStatusException(
                HttpStatus.SERVICE_UNAVAILABLE,
                "Live nearby places are temporarily unavailable. Please try again.",
                cause);
    }

    private record CacheEntry(Instant expiresAt, List<Place> places) {}
}
