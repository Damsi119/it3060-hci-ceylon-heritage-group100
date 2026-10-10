package com.ceylonheritage.backend.service;

import com.ceylonheritage.backend.Dtos.WeatherForecastDto;
import com.ceylonheritage.backend.Dtos.WeatherForecastDto.DailyForecast;
import com.ceylonheritage.backend.Dtos.WeatherForecastDto.HourlyForecast;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpStatus;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.server.ResponseStatusException;

import java.net.http.HttpClient;

@Service
public class WeatherService {

    private static final String FORECAST_HOST = "api.open-meteo.com";
    private static final String GEOCODING_HOST = "geocoding-api.open-meteo.com";
    private static final DateTimeFormatter HOUR_LABEL =
            DateTimeFormatter.ofPattern("h a", Locale.ENGLISH);
    private static final DateTimeFormatter DAY_LABEL =
            DateTimeFormatter.ofPattern("EEE", Locale.ENGLISH);

    private final RestClient restClient;

    public WeatherService() {
        var httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .build();
        var requestFactory = new JdkClientHttpRequestFactory(httpClient);
        requestFactory.setReadTimeout(Duration.ofSeconds(10));
        this.restClient = RestClient.builder()
                .requestFactory(requestFactory)
                .build();
    }

    public WeatherForecastDto getForecast(String requestedLocation) {
        String locationName = requestedLocation == null
                ? "Galle"
                : requestedLocation.trim();
        if (locationName.isBlank()) {
            locationName = "Galle";
        }

        Map<String, Object> geocoding = getJson(
                GEOCODING_HOST,
                "/v1/search",
                Map.of(
                        "name", locationName,
                        "count", 1,
                        "language", "en",
                        "countryCode", "LK"
                )
        );
        List<?> matches = list(geocoding, "results");
        if (matches.isEmpty() || !(matches.get(0) instanceof Map<?, ?>)) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "No Sri Lankan location matched: " + locationName
            );
        }

        Map<String, Object> place = map(matches.get(0));
        double latitude = number(place, "latitude");
        double longitude = number(place, "longitude");
        String canonicalName = string(place, "name", locationName);
        String province = string(place, "admin1", "Sri Lanka");

        Map<String, Object> forecast = getJson(
                FORECAST_HOST,
                "/v1/forecast",
                Map.of(
                        "latitude", latitude,
                        "longitude", longitude,
                        "current", "temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code,uv_index",
                        "hourly", "temperature_2m,weather_code",
                        "daily", "weather_code,temperature_2m_max,temperature_2m_min",
                        "timezone", "Asia/Colombo",
                        "forecast_days", 5
                )
        );

        Map<String, Object> current = object(forecast, "current");
        Map<String, Object> hourly = object(forecast, "hourly");
        Map<String, Object> daily = object(forecast, "daily");

        return new WeatherForecastDto(
                canonicalName,
                province,
                (int) Math.round(number(current, "temperature_2m")),
                condition(number(current, "weather_code")),
                (int) Math.round(number(current, "relative_humidity_2m")),
                (int) Math.round(number(current, "wind_speed_10m")),
                uvLabel(number(current, "uv_index")),
                buildHourly(current, hourly),
                buildDaily(daily),
                false
        );
    }

    private Map<String, Object> getJson(
            String host,
            String path,
            Map<String, ?> query
    ) {
        try {
            Map<String, Object> body = restClient.get()
                    .uri(builder -> {
                        var uri = builder.scheme("https")
                                .host(host)
                                .path(path);
                        query.forEach((name, value) -> uri.queryParam(name, value));
                        return uri.build();
                    })
                    .retrieve()
                    .body(new ParameterizedTypeReference<>() {});
            if (body == null) {
                throw new IllegalStateException("Weather provider returned an empty response");
            }
            return body;
        } catch (ResponseStatusException exception) {
            throw exception;
        } catch (RuntimeException exception) {
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "Weather provider is temporarily unavailable",
                    exception
            );
        }
    }

    private List<HourlyForecast> buildHourly(
            Map<String, Object> current,
            Map<String, Object> hourly
    ) {
        List<?> times = list(hourly, "time");
        List<?> temperatures = list(hourly, "temperature_2m");
        List<?> codes = list(hourly, "weather_code");
        if (times.isEmpty() || temperatures.isEmpty() || codes.isEmpty()) {
            return List.of();
        }

        LocalDateTime currentTime = parseTime(string(current, "time", ""));
        int start = 0;
        if (currentTime != null) {
            long nearestMinutes = Long.MAX_VALUE;
            for (int i = 0; i < times.size(); i++) {
                LocalDateTime time = parseTime(times.get(i).toString());
                if (time == null) continue;
                long difference = Math.abs(Duration.between(currentTime, time).toMinutes());
                if (difference < nearestMinutes) {
                    start = i;
                    nearestMinutes = difference;
                }
            }
        }

        List<HourlyForecast> result = new ArrayList<>();
        for (int i = start; i < times.size() && result.size() < 5; i++) {
            LocalDateTime time = parseTime(times.get(i).toString());
            if (time == null || i >= temperatures.size() || i >= codes.size()) continue;
            String label = result.isEmpty() ? "Now" : HOUR_LABEL.format(time);
            result.add(new HourlyForecast(
                    label,
                    (int) Math.round(asNumber(temperatures.get(i))),
                    condition(asNumber(codes.get(i)))
            ));
        }
        return result;
    }

    private List<DailyForecast> buildDaily(Map<String, Object> daily) {
        List<?> dates = list(daily, "time");
        List<?> highs = list(daily, "temperature_2m_max");
        List<?> lows = list(daily, "temperature_2m_min");
        List<?> codes = list(daily, "weather_code");
        List<DailyForecast> result = new ArrayList<>();
        for (int i = 0; i < dates.size() && i < 5; i++) {
            if (i >= highs.size() || i >= lows.size() || i >= codes.size()) break;
            LocalDate date = LocalDate.parse(dates.get(i).toString());
            String day = switch (i) {
                case 0 -> "Today";
                case 1 -> "Tomorrow";
                default -> DAY_LABEL.format(date);
            };
            result.add(new DailyForecast(
                    day,
                    (int) Math.round(asNumber(highs.get(i))),
                    (int) Math.round(asNumber(lows.get(i))),
                    condition(asNumber(codes.get(i)))
            ));
        }
        return result;
    }

    private String condition(double weatherCode) {
        int code = (int) Math.round(weatherCode);
        if (code == 0) return "Clear Sky";
        if (code == 1) return "Mainly Clear";
        if (code == 2) return "Partly Cloudy";
        if (code == 3) return "Overcast";
        if (code == 45 || code == 48) return "Fog";
        if (code >= 51 && code <= 57) return "Drizzle";
        if (code >= 61 && code <= 67) return "Rain";
        if (code >= 71 && code <= 77) return "Snow";
        if (code >= 80 && code <= 82) return "Rain Showers";
        if (code == 85 || code == 86) return "Snow Showers";
        if (code >= 95) return "Thunderstorm";
        return "Cloudy";
    }

    private String uvLabel(double uv) {
        if (uv < 3) return "Low";
        if (uv < 6) return "Moderate";
        if (uv < 8) return "High";
        if (uv < 11) return "Very High";
        return "Extreme";
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> object(Map<String, Object> source, String key) {
        Object value = source.get(key);
        return value instanceof Map<?, ?> ? (Map<String, Object>) value : Map.of();
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> map(Object value) {
        return value instanceof Map<?, ?> ? (Map<String, Object>) value : Map.of();
    }

    private List<?> list(Map<String, Object> source, String key) {
        Object value = source.get(key);
        return value instanceof List<?> values ? values : List.of();
    }

    private String string(Map<String, Object> source, String key, String fallback) {
        Object value = source.get(key);
        return value == null ? fallback : value.toString();
    }

    private double number(Map<String, Object> source, String key) {
        return asNumber(source.get(key));
    }

    private double asNumber(Object value) {
        return value instanceof Number number ? number.doubleValue() : 0;
    }

    private LocalDateTime parseTime(String value) {
        if (value == null || value.isBlank()) return null;
        try {
            return LocalDateTime.parse(value);
        } catch (RuntimeException ignored) {
            return null;
        }
    }
}
