package com.ceylonheritage.backend.repository;

import com.ceylonheritage.backend.entities.FavoritePlace;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface FavoritePlaceRepository extends JpaRepository<FavoritePlace, Long> {
    List<FavoritePlace> findByUser_IdOrderByCreatedAtDesc(Long userId);
    Optional<FavoritePlace> findByUser_IdAndPlace_Id(Long userId, Long placeId);
}
