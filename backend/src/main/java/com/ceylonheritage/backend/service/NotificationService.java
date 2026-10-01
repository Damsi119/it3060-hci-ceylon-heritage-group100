package com.ceylonheritage.backend.service;

import com.ceylonheritage.backend.Dtos.NotificationDto;
import com.ceylonheritage.backend.Dtos.UserDto;

public interface NotificationService {

    NotificationDto.NotificationListResponse getNotifications(String username);

    NotificationDto.NotificationResponse markRead(String username, Long notificationId);

    UserDto.MessageResponse markAllRead(String username);

    UserDto.MessageResponse deleteNotification(String username, Long notificationId);
}
