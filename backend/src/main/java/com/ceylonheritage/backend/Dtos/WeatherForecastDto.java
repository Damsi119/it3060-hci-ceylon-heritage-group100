package com.ceylonheritage.backend.Dtos;

import java.util.List;

public record WeatherForecastDto(
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
) {
    public record HourlyForecast(
            String time,
            int temperatureCelsius,
            String condition
    ) {}

    public record DailyForecast(
            String day,
            int highCelsius,
            int lowCelsius,
            String condition
    ) {}
}
