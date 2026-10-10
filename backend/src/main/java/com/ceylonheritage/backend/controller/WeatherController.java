package com.ceylonheritage.backend.controller;

import com.ceylonheritage.backend.Dtos.WeatherForecastDto;
import com.ceylonheritage.backend.service.WeatherService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/weather")
public class WeatherController {

    private final WeatherService weatherService;

    public WeatherController(WeatherService weatherService) {
        this.weatherService = weatherService;
    }

    @GetMapping
    public WeatherForecastDto getForecast(
            @RequestParam(defaultValue = "Galle") String location
    ) {
        return weatherService.getForecast(location);
    }
}
