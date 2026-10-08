package com.ceylonheritage.backend.repository;

import com.ceylonheritage.backend.entities.Place;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface PlaceRepository extends JpaRepository<Place, Long> {
    Optional<Place> findBySlug(String slug);
}
