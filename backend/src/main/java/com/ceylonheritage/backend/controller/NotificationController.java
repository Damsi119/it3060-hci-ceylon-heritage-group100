package com.ceylonheritage.backend.controller;

import com.ceylonheritage.backend.Dtos.NotificationDto;
import com.ceylonheritage.backend.Dtos.UserDto;
import com.ceylonheritage.backend.service.NotificationService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }


    @GetMapping
    public ResponseEntity<NotificationDto.NotificationListResponse> getNotifications(
            Authentication authentication
    ) {

        return ResponseEntity.ok(
                notificationService.getNotifications(
                        authentication.getName()
                )
        );
    }


    @GetMapping("/unread-count")
    public ResponseEntity<NotificationDto.UnreadCountResponse> getUnreadCount(
            Authentication authentication
    ) {

        return ResponseEntity.ok(
                notificationService.getUnreadCount(
                        authentication.getName()
                )
        );
    }


    @PutMapping("/{notificationId}/read")
    public ResponseEntity<NotificationDto.NotificationResponse> markRead(
            Authentication authentication,
            @PathVariable Long notificationId
    ) {

        return ResponseEntity.ok(
                notificationService.markRead(
                        authentication.getName(),
                        notificationId
                )
        );
    }


    @PutMapping("/read-all")
    public ResponseEntity<UserDto.MessageResponse> markAllRead(
            Authentication authentication
    ) {

        return ResponseEntity.ok(
                notificationService.markAllRead(
                        authentication.getName()
                )
        );
    }


    @DeleteMapping("/{notificationId}")
    public ResponseEntity<UserDto.MessageResponse> deleteNotification(
            Authentication authentication,
            @PathVariable Long notificationId
    ) {

        return ResponseEntity.ok(
                notificationService.deleteNotification(
                        authentication.getName(),
                        notificationId
                )
        );
    }
}
