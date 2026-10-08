package com.ceylonheritage.backend.controller;


import com.ceylonheritage.backend.Dtos.UserDto;
import com.ceylonheritage.backend.service.UserService;
import jakarta.validation.Valid;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }


    @GetMapping("/me")
    public ResponseEntity<UserDto.UserProfileResponse> getProfile(
            Authentication authentication
    ) {

        return ResponseEntity.ok(
                userService.getProfile(
                        authentication.getName()
                )
        );
    }


    @PutMapping("/me")
    public ResponseEntity<UserDto.UserProfileResponse> updateProfile(
            Authentication authentication,
            @Valid @RequestBody UserDto.UpdateProfileRequest request
    ) {

        return ResponseEntity.ok(
                userService.updateProfile(
                        authentication.getName(),
                        request
                )
        );
    }


    @PutMapping(
            value = "/me/profile-photo",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE
    )
    public ResponseEntity<UserDto.UserProfileResponse> updateProfilePhoto(
            Authentication authentication,
            @RequestPart("photo") MultipartFile photo
    ) {

        return ResponseEntity.ok(
                userService.updateProfilePhoto(
                        authentication.getName(),
                        photo
                )
        );
    }


    @PutMapping(
            value = "/me/cover-photo",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE
    )
    public ResponseEntity<UserDto.UserProfileResponse> updateCoverPhoto(
            Authentication authentication,
            @RequestPart("photo") MultipartFile photo
    ) {

        return ResponseEntity.ok(
                userService.updateCoverPhoto(
                        authentication.getName(),
                        photo
                )
        );
    }


    @PutMapping("/me/password")
    public ResponseEntity<UserDto.MessageResponse> changePassword(
            Authentication authentication,
            @Valid @RequestBody UserDto.ChangePasswordRequest request
    ) {

        return ResponseEntity.ok(
                userService.changePassword(
                        authentication.getName(),
                        request
                )
        );
    }


    @PostMapping("/logout")
    public ResponseEntity<UserDto.MessageResponse> logout(
            Authentication authentication
    ) {

        return ResponseEntity.ok(
                userService.logout(
                        authentication.getName()
                )
        );
    }


    @DeleteMapping("/me")
    public ResponseEntity<UserDto.MessageResponse> deleteAccount(
            Authentication authentication,
            @Valid @RequestBody UserDto.DeleteAccountRequest request
    ) {

        return ResponseEntity.ok(
                userService.deleteAccount(
                        authentication.getName(),
                        request
                )
        );
    }
}
