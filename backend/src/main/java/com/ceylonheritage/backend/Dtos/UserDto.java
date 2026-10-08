package com.ceylonheritage.backend.Dtos;

import com.ceylonheritage.backend.enums.AuthProvider;
import com.ceylonheritage.backend.enums.Role;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;

public class UserDto {

    public record RegisterRequest(

            @NotBlank(message = "Username is required")
            String username,

            @NotBlank(message = "Email is required")
            @Email(message = "Please provide a valid email")
            String email,

            @NotBlank(message = "Phone number is required")
            String phone,

            @NotBlank(message = "Password is required")
            @Size(min = 8, message = "Password must be at least 8 characters")
            String password,

            @NotBlank(message = "Confirm password is required")
            String confirmPassword,

            String firstName,

            String lastName,

            String address,

            @NotNull(message = "Role is required")
            Role role

    ) {}


    public record LoginRequest(

            @NotBlank(message = "Email, username or phone is required")
            String identifier,

            @NotBlank(message = "Password is required")
            String password

    ) {}


    public record AuthResponse(

            String accessToken,

            String refreshToken,

            UserProfileResponse user

    ) {}


    public record RefreshTokenRequest(

            @NotBlank(message = "Refresh token is required")
            String refreshToken

    ) {}


    public record VerifyOtpRequest(

            @NotBlank(message = "Email is required")
            @Email(message = "Please provide a valid email")
            String email,

            @NotBlank(message = "Verification code is required")
            String code

    ) {}


    public record ResendOtpRequest(

            @NotBlank(message = "Email is required")
            @Email(message = "Please provide a valid email")
            String email

    ) {}


    public record UpdateProfileRequest(

            String firstName,

            String lastName,

            String phone,

            String address

    ) {}


    public record ChangePasswordRequest(

            @NotBlank(message = "Current password is required")
            String currentPassword,

            @NotBlank(message = "New password is required")
            @Size(min = 8, message = "Password must be at least 8 characters")
            String newPassword,

            @NotBlank(message = "Confirm password is required")
            String confirmPassword

    ) {}


    public record ForgotPasswordRequest(

            String username,

            @Email(message = "Please provide a valid email")
            String email,

            String phone

    ) {}


    public record ForgotPasswordVerifyRequest(

            @NotBlank(message = "Email is required")
            @Email(message = "Please provide a valid email")
            String email,

            @NotBlank(message = "Verification code is required")
            String code

    ) {}

    public record ForgotPasswordResendRequest(

            @NotBlank(message = "Email is required")
            @Email(message = "Please provide a valid email")
            String email

    ) {}


    public record ResetPasswordRequest(

            @NotBlank(message = "Email is required")
            @Email(message = "Please provide a valid email")
            String email,

            @NotBlank(message = "New password is required")
            @Size(min = 8, message = "Password must be at least 8 characters")
            String newPassword,

            @NotBlank(message = "Confirm password is required")
            String confirmPassword

    ) {}


    public record DeleteAccountRequest(

            @NotBlank(message = "Current password is required")
            String currentPassword

    ) {}


    public record UserProfileResponse(

            Long id,

            String username,

            String email,

            String phone,

            String firstName,

            String lastName,

            String address,

            String profileImageUrl,

            String coverImageUrl,

            Role role,

            AuthProvider provider,

            boolean emailVerified,

            boolean passwordChangeRequired

    ) {}


    public record MessageResponse(

            boolean success,

            String message,

            Boolean verificationRequired

    ) {
        public MessageResponse(boolean success, String message) {
            this(success, message, null);
        }
    }

    public record GoogleLoginRequest(

            @NotBlank(message = "Google ID token is required")
            String idToken,

            Role role

    ) {}


    public record AdminUserStatusRequest(

            @NotNull(message = "Enabled status is required")
            Boolean enabled

    ) {}


    public record UserListResponse(

            List<UserProfileResponse> users

    ) {}
}
