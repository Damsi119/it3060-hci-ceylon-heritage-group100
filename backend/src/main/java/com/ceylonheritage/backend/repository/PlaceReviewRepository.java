package com.ceylonheritage.backend.repository;

import com.ceylonheritage.backend.entities.PlaceReview;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PlaceReviewRepository extends JpaRepository<PlaceReview, Long> {
    List<PlaceReview> findByPlace_IdOrderByCreatedAtDesc(Long placeId);
    long countByPlace_Id(Long placeId);
    List<PlaceReview> findByPlace_Id(Long placeId);
    Optional<PlaceReview> findByIdAndPlace_Id(Long id, Long placeId);
}
