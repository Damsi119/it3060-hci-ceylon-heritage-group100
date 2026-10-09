package com.ceylonheritage.backend.Dtos;

import java.time.LocalDateTime;
import java.util.List;

public class NotificationDto {

    public record NotificationResponse(

            Long id,

            String title,

            String message,

            boolean read,

            LocalDateTime readAt,

            LocalDateTime createdAt

    ) {}


    public record NotificationListResponse(

            List<NotificationResponse> notifications

    ) {}


    public record UnreadCountResponse(

            long unreadCount

    ) {}
}
