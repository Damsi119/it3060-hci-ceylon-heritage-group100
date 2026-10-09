package com.ceylonheritage.backend.controller;

import com.ceylonheritage.backend.Dtos.TourismDto;
import com.ceylonheritage.backend.service.TourismService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/users/me/favourites")
public class FavoritePlaceController {

    private final TourismService tourismService;

    public FavoritePlaceController(TourismService tourismService) {
        this.tourismService = tourismService;
    }

    @GetMapping
    public ResponseEntity<List<TourismDto.PlaceResponse>> getFavorites(Authentication authentication) {
        return ResponseEntity.ok(tourismService.getFavorites(authentication.getName()));
    }

    @PutMapping("/{placeId}")
    public ResponseEntity<TourismDto.PlaceResponse> addFavorite(Authentication authentication,
                                                                 @PathVariable Long placeId) {
        return ResponseEntity.ok(tourismService.addFavorite(authentication.getName(), placeId));
    }

    @DeleteMapping("/{placeId}")
    public ResponseEntity<Void> removeFavorite(Authentication authentication, @PathVariable Long placeId) {
        tourismService.removeFavorite(authentication.getName(), placeId);
        return ResponseEntity.noContent().build();
    }
}
