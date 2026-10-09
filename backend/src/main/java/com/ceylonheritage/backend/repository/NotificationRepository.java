package com.ceylonheritage.backend.repository;

import com.ceylonheritage.backend.entities.Notification;
import com.ceylonheritage.backend.entities.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface NotificationRepository extends JpaRepository<Notification, Long> {

    List<Notification> findByUserOrderByCreatedAtDesc(User user);

    Optional<Notification> findByIdAndUser(Long id, User user);

    long countByUserAndReadFalse(User user);
}
