package com.ceylonheritage.backend.repository;

import com.ceylonheritage.backend.entities.GuideProfile;
import com.ceylonheritage.backend.entities.User;
import com.ceylonheritage.backend.enums.GuideApplicationStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface GuideProfileRepository
        extends JpaRepository<GuideProfile, Long> {

    Optional<GuideProfile> findByUser(User user);

    Optional<GuideProfile> findByUserId(Long userId);

    Optional<GuideProfile> findByIdAndUserDeletedFalse(Long id);

    Optional<GuideProfile> findByUserIdAndUserDeletedFalse(Long userId);

    Optional<GuideProfile> findTopByEmailIgnoreCaseAndStatusIn(
            String email,
            Collection<GuideApplicationStatus> statuses
    );

    boolean existsByUser(User user);

    boolean existsByEmailIgnoreCaseAndStatusIn(
            String email,
            Collection<GuideApplicationStatus> statuses
    );

    List<GuideProfile> findByStatus(
            GuideApplicationStatus status
    );

    List<GuideProfile> findByStatusAndUserDeletedFalse(
            GuideApplicationStatus status
    );

    List<GuideProfile> findByPrimaryServiceAreaIgnoreCase(
            String primaryServiceArea
    );

    List<GuideProfile> findByPrimaryServiceAreaIgnoreCaseAndUserDeletedFalse(
            String primaryServiceArea
    );
}

