package com.ceylonheritage.backend.repository;

import com.ceylonheritage.backend.entities.Tour;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TourRepository extends JpaRepository<Tour, Long> {

    List<Tour> findByOwner_IdOrderByUpdatedAtDescIdDesc(Long ownerId);

    Optional<Tour> findByIdAndOwner_Id(Long id, Long ownerId);
}