package com.ceylonheritage.backend.repository;

import com.ceylonheritage.backend.entities.HistoricalPlace;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface HistoricalPlaceRepository
        extends JpaRepository<HistoricalPlace, Long> {

    List<HistoricalPlace> findByActiveTrueOrderByNameAsc();

    List<HistoricalPlace>
    findByFeaturedTrueAndActiveTrueOrderByNameAsc();

    Optional<HistoricalPlace> findByIdAndActiveTrue(Long id);

    List<HistoricalPlace>
    findByActiveTrueAndNameContainingIgnoreCaseOrActiveTrueAndCityContainingIgnoreCaseOrderByNameAsc(
            String name,
            String city
    );

    List<HistoricalPlace>
    findByActiveTrueAndCategoryIgnoreCaseOrderByNameAsc(
            String category
    );

    @Query("""
            SELECT p
            FROM HistoricalPlace p
            WHERE p.active = true
              AND LOWER(p.category) = LOWER(:category)
              AND (
                  LOWER(p.name) LIKE LOWER(CONCAT('%', :keyword, '%'))
                  OR LOWER(p.city) LIKE LOWER(CONCAT('%', :keyword, '%'))
              )
            ORDER BY p.name ASC
            """)
    List<HistoricalPlace> searchByKeywordAndCategory(
            @Param("keyword") String keyword,
            @Param("category") String category
    );

    // Fetch active places selected for curated discovery sections.
    List<HistoricalPlace> findByActiveTrueAndIdIn(
            Collection<Long> ids
    );
}