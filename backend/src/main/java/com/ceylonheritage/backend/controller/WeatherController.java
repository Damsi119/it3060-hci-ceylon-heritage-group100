package com.ceylonheritage.backend.controller;

import com.ceylonheritage.backend.Dtos.TourismDto;
import com.ceylonheritage.backend.service.TourismService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/weather")
public class WeatherController {

    private final TourismService tourismService;

    public WeatherController(TourismService tourismService) {
        this.tourismService = tourismService;
    }

    @GetMapping
    public ResponseEntity<TourismDto.WeatherResponse> getWeather(
            @RequestParam(defaultValue = "Galle") String location) {
        return ResponseEntity.ok(tourismService.getWeather(location));
    }
}
