package com.ceylonheritage.backend.controller;

import com.ceylonheritage.backend.Dtos.CreateTourRequest;
import com.ceylonheritage.backend.Dtos.TourDto;
import com.ceylonheritage.backend.Dtos.UpdateTourRequest;
import com.ceylonheritage.backend.entities.User;
import com.ceylonheritage.backend.service.TourService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.net.URI;
import java.util.List;

@RestController
@RequestMapping("/api/tours")
public class TourController {

    private final TourService tourService;

    public TourController(TourService tourService) {
        this.tourService = tourService;
    }

    @PostMapping
    @PreAuthorize("hasRole('TOURIST')")
    public ResponseEntity<TourDto> createTour(
            @AuthenticationPrincipal User user,
            @Valid @RequestBody CreateTourRequest request
    ) {
        TourDto tour = tourService.createTour(
                authenticatedUserId(user),
                request
        );

        return ResponseEntity
                .created(URI.create("/api/tours/" + tour.id()))
                .body(tour);
    }

    @GetMapping("/my")
    public ResponseEntity<List<TourDto>> getMyTours(
            @AuthenticationPrincipal User user
    ) {
        return ResponseEntity.ok(
                tourService.getMyTours(authenticatedUserId(user))
        );
    }

    @GetMapping("/{tourId}")
    public ResponseEntity<TourDto> getTourById(
            @AuthenticationPrincipal User user,
            @PathVariable("tourId") Long tourId
    ) {
        return ResponseEntity.ok(
                tourService.getTourById(
                        authenticatedUserId(user),
                        tourId
                )
        );
    }

    @PutMapping("/{tourId}")
    @PreAuthorize("hasRole('TOURIST')")
    public ResponseEntity<TourDto> updateTour(
            @AuthenticationPrincipal User user,
            @PathVariable("tourId") Long tourId,
            @Valid @RequestBody UpdateTourRequest request
    ) {
        return ResponseEntity.ok(
                tourService.updateTour(
                        authenticatedUserId(user),
                        tourId,
                        request
                )
        );
    }

    private Long authenticatedUserId(User user) {
        if (user == null || user.getId() == null) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Authentication required"
            );
        }

        return user.getId();
    }
}
