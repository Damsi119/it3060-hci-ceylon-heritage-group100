package com.ceylonheritage.backend.service;

import com.ceylonheritage.backend.Dtos.CreateTourRequest;
import com.ceylonheritage.backend.Dtos.TourDto;
import com.ceylonheritage.backend.Dtos.UpdateTourRequest;

import java.util.List;

public interface TourService {

    TourDto createTour(
            Long authenticatedUserId,
            CreateTourRequest request
    );

    List<TourDto> getMyTours(
            Long authenticatedUserId
    );

    TourDto getTourById(
            Long authenticatedUserId,
            Long tourId
    );

    TourDto updateTour(
            Long authenticatedUserId,
            Long tourId,
            UpdateTourRequest request
    );
}