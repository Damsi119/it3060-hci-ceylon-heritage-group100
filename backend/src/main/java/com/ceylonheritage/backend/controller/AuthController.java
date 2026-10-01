package com.ceylonheritage.backend.controller;

import com.ceylonheritage.backend.Dtos.UserDto;
import com.ceylonheritage.backend.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }


    @PostMapping("/register")
    public ResponseEntity<UserDto.MessageResponse> register(
            @Valid @RequestBody UserDto.RegisterRequest request
    ) {

        return ResponseEntity.ok(
                authService.register(request)
        );
    }


    @PostMapping("/verify-email")
    public ResponseEntity<UserDto.MessageResponse> verifyEmail(
            @Valid @RequestBody UserDto.VerifyOtpRequest request
    ) {

        return ResponseEntity.ok(
                authService.verifyEmail(request)
        );
    }


    @PostMapping("/resend-otp")
    public ResponseEntity<UserDto.MessageResponse> resendOtp(
            @Valid @RequestBody UserDto.ResendOtpRequest request
    ) {

        return ResponseEntity.ok(
                authService.resendOtp(request)
        );
    }


    @PostMapping("/login")
    public ResponseEntity<UserDto.AuthResponse> login(
            @Valid @RequestBody UserDto.LoginRequest request
    ) {

        return ResponseEntity.ok(
                authService.login(request)
        );
    }


    @PostMapping("/refresh")
    public ResponseEntity<UserDto.AuthResponse> refreshToken(
            @Valid @RequestBody UserDto.RefreshTokenRequest request
    ) {

        return ResponseEntity.ok(
                authService.refreshToken(request)
        );
    }


    @PostMapping("/google")
    public ResponseEntity<UserDto.AuthResponse> googleLogin(
            @Valid @RequestBody UserDto.GoogleLoginRequest request
    ) {

        return ResponseEntity.ok(
                authService.googleLogin(request)
        );
    }
}

