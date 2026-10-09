package com.ceylonheritage.backend.service;

import com.ceylonheritage.backend.Dtos.NotificationDto;
import com.ceylonheritage.backend.Dtos.UserDto;
import com.ceylonheritage.backend.entities.User;
import com.ceylonheritage.backend.enums.Role;

public interface NotificationService {

    NotificationDto.NotificationListResponse getNotifications(String username);

    NotificationDto.UnreadCountResponse getUnreadCount(String username);

    NotificationDto.NotificationResponse markRead(String username, Long notificationId);

    UserDto.MessageResponse markAllRead(String username);

    UserDto.MessageResponse deleteNotification(String username, Long notificationId);

    NotificationDto.NotificationResponse createForUser(
            User user,
            String title,
            String message
    );

    void createForRole(
            Role role,
            String title,
            String message
    );
}
