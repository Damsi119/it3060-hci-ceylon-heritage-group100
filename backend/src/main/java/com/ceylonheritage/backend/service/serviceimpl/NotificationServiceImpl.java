package com.ceylonheritage.backend.service.serviceimpl;

import com.ceylonheritage.backend.Dtos.NotificationDto;
import com.ceylonheritage.backend.Dtos.UserDto;
import com.ceylonheritage.backend.entities.Notification;
import com.ceylonheritage.backend.entities.User;
import com.ceylonheritage.backend.enums.Role;
import com.ceylonheritage.backend.exception.UserException;
import com.ceylonheritage.backend.repository.NotificationRepository;
import com.ceylonheritage.backend.repository.UserRepository;
import com.ceylonheritage.backend.service.NotificationService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
public class NotificationServiceImpl implements NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;

    public NotificationServiceImpl(
            NotificationRepository notificationRepository,
            UserRepository userRepository
    ) {
        this.notificationRepository = notificationRepository;
        this.userRepository = userRepository;
    }


    @Override
    public NotificationDto.NotificationListResponse getNotifications(
            String username
    ) {

        User user = getUser(username);

        return new NotificationDto.NotificationListResponse(
                notificationRepository.findByUserOrderByCreatedAtDesc(user)
                        .stream()
                        .map(this::toResponse)
                        .toList()
        );
    }


    @Override
    public NotificationDto.UnreadCountResponse getUnreadCount(
            String username
    ) {

        User user = getUser(username);

        return new NotificationDto.UnreadCountResponse(
                notificationRepository.countByUserAndReadFalse(user)
        );
    }


    @Override
    @Transactional
    public NotificationDto.NotificationResponse markRead(
            String username,
            Long notificationId
    ) {

        User user = getUser(username);
        Notification notification = getNotification(notificationId, user);

        if (!notification.isRead()) {
            notification.setRead(true);
            notification.setReadAt(LocalDateTime.now());
            notificationRepository.save(notification);
        }

        return toResponse(notification);
    }


    @Override
    @Transactional
    public UserDto.MessageResponse markAllRead(String username) {

        User user = getUser(username);

        notificationRepository.findByUserOrderByCreatedAtDesc(user)
                .forEach(notification -> {
                    if (!notification.isRead()) {
                        notification.setRead(true);
                        notification.setReadAt(LocalDateTime.now());
                        notificationRepository.save(notification);
                    }
                });

        return new UserDto.MessageResponse(
                true,
                "Notifications marked as read"
        );
    }


    @Override
    @Transactional
    public UserDto.MessageResponse deleteNotification(
            String username,
            Long notificationId
    ) {

        User user = getUser(username);
        Notification notification = getNotification(notificationId, user);

        notificationRepository.delete(notification);

        return new UserDto.MessageResponse(
                true,
                "Notification deleted"
        );
    }


    @Override
    @Transactional
    public NotificationDto.NotificationResponse createForUser(
            User user,
            String title,
            String message
    ) {

        if (user == null || user.isDeleted()) {
            throw new UserException("Notification user not found");
        }

        Notification notification = notificationRepository.save(
                Notification.builder()
                        .user(user)
                        .title(clean(title, "Notification"))
                        .message(clean(message, "You have a new update."))
                        .build()
        );

        return toResponse(notification);
    }


    @Override
    @Transactional
    public void createForRole(
            Role role,
            String title,
            String message
    ) {

        if (role == null) {
            return;
        }

        userRepository.findByRoleAndDeletedFalse(role)
                .stream()
                .filter(User::isEnabled)
                .forEach(user -> createForUser(user, title, message));
    }


    private User getUser(String username) {

        return userRepository
                .findByUsernameIgnoreCaseAndDeletedFalse(username)
                .orElseThrow(() ->
                        new UserException("User not found")
                );
    }


    private Notification getNotification(Long id, User user) {

        return notificationRepository
                .findByIdAndUser(id, user)
                .orElseThrow(() ->
                        new UserException("Notification not found")
                );
    }


    private String clean(String value, String fallback) {

        if (value == null || value.trim().isBlank()) {
            return fallback;
        }

        return value.trim();
    }


    private NotificationDto.NotificationResponse toResponse(
            Notification notification
    ) {

        return new NotificationDto.NotificationResponse(
                notification.getId(),
                notification.getTitle(),
                notification.getMessage(),
                notification.isRead(),
                notification.getReadAt(),
                notification.getCreatedAt()
        );
    }
}
