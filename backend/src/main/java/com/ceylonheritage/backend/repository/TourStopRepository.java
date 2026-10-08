package com.ceylonheritage.backend.repository;

import com.ceylonheritage.backend.entities.TourStop;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TourStopRepository
        extends JpaRepository<TourStop, Long> {

    @EntityGraph(attributePaths = "historicalPlace")
    List<TourStop> findByTour_IdOrderByStopOrderAscIdAsc(Long tourId);

    void deleteByTour_Id(Long tourId);
}