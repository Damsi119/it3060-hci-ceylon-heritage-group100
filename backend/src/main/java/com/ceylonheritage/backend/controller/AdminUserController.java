package com.ceylonheritage.backend.controller;

import com.ceylonheritage.backend.Dtos.UserDto;
import com.ceylonheritage.backend.enums.Role;
import com.ceylonheritage.backend.service.UserService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/admin/users")
@PreAuthorize("hasRole('ADMIN')")
public class AdminUserController {

    private final UserService userService;

    public AdminUserController(UserService userService) {
        this.userService = userService;
    }


    @GetMapping
    public ResponseEntity<List<UserDto.UserProfileResponse>> getUsers(
            @RequestParam(required = false) Role role
    ) {

        return ResponseEntity.ok(
                userService.getUsers(role)
        );
    }


    @PutMapping("/{userId}/status")
    public ResponseEntity<UserDto.UserProfileResponse> updateUserStatus(
            Authentication authentication,
            @PathVariable Long userId,
            @Valid @RequestBody UserDto.AdminUserStatusRequest request
    ) {

        return ResponseEntity.ok(
                userService.updateUserStatus(
                        authentication.getName(),
                        userId,
                        request
                )
        );
    }


    @DeleteMapping("/{userId}")
    public ResponseEntity<UserDto.MessageResponse> deleteUser(
            Authentication authentication,
            @PathVariable Long userId
    ) {

        return ResponseEntity.ok(
                userService.deleteUser(
                        authentication.getName(),
                        userId
                )
        );
    }
}
