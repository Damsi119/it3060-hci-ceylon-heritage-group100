package com.ceylonheritage.backend.service.serviceimpl;

import com.ceylonheritage.backend.Dtos.UserDto;
import com.ceylonheritage.backend.entities.User;
import com.ceylonheritage.backend.enums.Role;
import com.ceylonheritage.backend.exception.UserException;
import com.ceylonheritage.backend.repository.ForgotPasswordRepository;
import com.ceylonheritage.backend.repository.UserRepository;
import com.ceylonheritage.backend.service.ProfileImageStorageService;
import com.ceylonheritage.backend.service.UserService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final ForgotPasswordRepository forgotPasswordRepository;
    private final PasswordEncoder passwordEncoder;
    private final ProfileImageStorageService profileImageStorageService;

    public UserServiceImpl(
            UserRepository userRepository,
            ForgotPasswordRepository forgotPasswordRepository,
            PasswordEncoder passwordEncoder,
            ProfileImageStorageService profileImageStorageService
    ) {
        this.userRepository = userRepository;
        this.forgotPasswordRepository = forgotPasswordRepository;
        this.passwordEncoder = passwordEncoder;
        this.profileImageStorageService = profileImageStorageService;
    }


    @Override
    public UserDto.UserProfileResponse getProfile(String username) {

        User user = getUser(username);

        return toProfileResponse(user);
    }


    @Override
    @Transactional
    public UserDto.UserProfileResponse updateProfile(
            String username,
            UserDto.UpdateProfileRequest request
    ) {

        User user = getUser(username);

        if (request.firstName() != null) {
            user.setFirstName(request.firstName().trim());
        }

        if (request.lastName() != null) {
            user.setLastName(request.lastName().trim());
        }

        if (request.address() != null) {
            user.setAddress(request.address().trim());
        }

        if (request.phone() != null) {

            String phone = request.phone().trim();

            if (phone.isBlank()) {
                throw new UserException(
                        "Phone number cannot be empty"
                );
            }

            if (!phone.equals(user.getPhone()) &&
                    userRepository.existsByPhoneAndDeletedFalse(phone)) {

                throw new UserException(
                        "Phone number already exists"
                );
            }

            user.setPhone(phone);
        }

        userRepository.save(user);

        return toProfileResponse(user);
    }


    @Override
    @Transactional
    public UserDto.UserProfileResponse updateProfilePhoto(
            String username,
            MultipartFile photo
    ) {

        User user = getUser(username);
        String previousImageUrl = user.getProfileImageUrl();
        String imageUrl = profileImageStorageService.saveImage(
                photo,
                "profile"
        );

        user.setProfileImageUrl(imageUrl);
        userRepository.save(user);
        profileImageStorageService.deleteImage(previousImageUrl);

        return toProfileResponse(user);
    }


    @Override
    @Transactional
    public UserDto.UserProfileResponse updateCoverPhoto(
            String username,
            MultipartFile photo
    ) {

        User user = getUser(username);
        String previousImageUrl = user.getCoverImageUrl();
        String imageUrl = profileImageStorageService.saveImage(
                photo,
                "cover"
        );

        user.setCoverImageUrl(imageUrl);
        userRepository.save(user);
        profileImageStorageService.deleteImage(previousImageUrl);

        return toProfileResponse(user);
    }


    @Override
    @Transactional
    public UserDto.MessageResponse changePassword(
            String username,
            UserDto.ChangePasswordRequest request
    ) {

        User user = getUser(username);

        if (!passwordEncoder.matches(
                request.currentPassword(),
                user.getPassword()
        )) {

            throw new UserException(
                    "Current password is incorrect"
            );
        }

        if (!request.newPassword()
                .equals(request.confirmPassword())) {

            throw new UserException(
                    "Passwords do not match"
            );
        }

        if (passwordEncoder.matches(
                request.newPassword(),
                user.getPassword()
        )) {

            throw new UserException(
                    "New password must be different from the current password"
            );
        }

        user.setPassword(
                passwordEncoder.encode(
                        request.newPassword()
                )
        );

        user.setPasswordChangeRequired(false);
        user.setRefreshTokenHash(null);

        userRepository.save(user);

        return new UserDto.MessageResponse(
                true,
                "Password changed successfully"
        );
    }


    @Override
    @Transactional
    public UserDto.MessageResponse logout(String username) {

        User user = getUser(username);

        user.setRefreshTokenHash(null);

        userRepository.save(user);

        return new UserDto.MessageResponse(
                true,
                "Logged out successfully"
        );
    }


    @Override
    @Transactional
    public UserDto.MessageResponse deleteAccount(
            String username,
            UserDto.DeleteAccountRequest request
    ) {

        User user = getUser(username);

        if (!passwordEncoder.matches(
                request.currentPassword(),
                user.getPassword()
        )) {

            throw new UserException(
                    "Current password is incorrect"
            );
        }

        Long userId = user.getId();

        forgotPasswordRepository.deleteByUserId(userId);

        String previousProfileImageUrl = user.getProfileImageUrl();
        String previousCoverImageUrl = user.getCoverImageUrl();

        user.setFirstName(null);
        user.setLastName(null);
        user.setAddress(null);
        user.setProfileImageUrl(null);
        user.setCoverImageUrl(null);

        user.setUsername(
                "deleted_" + userId
        );

        user.setEmail(
                "deleted_" + userId + "@historia.local"
        );

        user.setPhone(
                "deleted_" + userId
        );

        user.setProviderId(null);

        user.setPassword(
                passwordEncoder.encode(
                        UUID.randomUUID().toString()
                )
        );

        user.setRefreshTokenHash(null);

        user.setVerifyCode(null);
        user.setVerifyCodeExpiry(null);
        user.setLastOtpSentAt(null);
        user.setOtpResendCount(0);
        user.setOtpFirstResendTime(null);
        user.setOtpBlockUntil(null);

        user.setEmailVerified(false);
        user.setEnabled(false);
        user.setDeleted(true);
        user.setDeletedAt(LocalDateTime.now());
        user.setPasswordChangeRequired(false);

        userRepository.save(user);
        profileImageStorageService.deleteImage(previousProfileImageUrl);
        profileImageStorageService.deleteImage(previousCoverImageUrl);

        return new UserDto.MessageResponse(
                true,
                "Account deleted successfully"
        );
    }


    @Override
    public List<UserDto.UserProfileResponse> getUsers(Role role) {

        List<User> users = role == null
                ? userRepository.findByDeletedFalse()
                : userRepository.findByRoleAndDeletedFalse(role);

        return users.stream()
                .map(this::toProfileResponse)
                .toList();
    }


    @Override
    @Transactional
    public UserDto.UserProfileResponse updateUserStatus(
            String adminUsername,
            Long userId,
            UserDto.AdminUserStatusRequest request
    ) {

        User admin = getUser(adminUsername);
        User user = getUserById(userId);

        if (admin.getId().equals(user.getId())) {
            throw new UserException(
                    "Admin cannot disable their own account"
            );
        }

        user.setEnabled(request.enabled());

        userRepository.save(user);

        return toProfileResponse(user);
    }


    @Override
    @Transactional
    public UserDto.MessageResponse deleteUser(
            String adminUsername,
            Long userId
    ) {

        User admin = getUser(adminUsername);
        User user = getUserById(userId);

        if (admin.getId().equals(user.getId())) {
            throw new UserException(
                    "Admin cannot delete their own account"
            );
        }

        softDelete(user);

        return new UserDto.MessageResponse(
                true,
                "User deleted successfully"
        );
    }


    private User getUser(String username) {

        return userRepository
                .findByUsernameIgnoreCaseAndDeletedFalse(username)
                .orElseThrow(() ->
                        new UserException("User not found")
                );
    }


    private UserDto.UserProfileResponse toProfileResponse(
            User user
    ) {

        return new UserDto.UserProfileResponse(
                user.getId(),
                user.getUsername(),
                user.getEmail(),
                user.getPhone(),
                user.getFirstName(),
                user.getLastName(),
                user.getAddress(),
                user.getProfileImageUrl(),
                user.getCoverImageUrl(),
                user.getRole(),
                user.getProvider(),
                user.isEmailVerified(),
                user.isPasswordChangeRequired()
        );
    }


    private User getUserById(Long userId) {

        return userRepository
                .findByIdAndDeletedFalse(userId)
                .orElseThrow(() ->
                        new UserException("User not found")
                );
    }


    private void softDelete(User user) {

        Long userId = user.getId();

        forgotPasswordRepository.deleteByUserId(userId);

        String previousProfileImageUrl = user.getProfileImageUrl();
        String previousCoverImageUrl = user.getCoverImageUrl();

        user.setFirstName(null);
        user.setLastName(null);
        user.setAddress(null);
        user.setProfileImageUrl(null);
        user.setCoverImageUrl(null);
        user.setUsername("deleted_" + userId);
        user.setEmail("deleted_" + userId + "@historia.local");
        user.setPhone("deleted_" + userId);
        user.setProviderId(null);
        user.setPassword(
                passwordEncoder.encode(
                        UUID.randomUUID().toString()
                )
        );
        user.setRefreshTokenHash(null);
        user.setVerifyCode(null);
        user.setVerifyCodeExpiry(null);
        user.setLastOtpSentAt(null);
        user.setOtpResendCount(0);
        user.setOtpFirstResendTime(null);
        user.setOtpBlockUntil(null);
        user.setEmailVerified(false);
        user.setEnabled(false);
        user.setDeleted(true);
        user.setDeletedAt(LocalDateTime.now());
        user.setPasswordChangeRequired(false);

        userRepository.save(user);
        profileImageStorageService.deleteImage(previousProfileImageUrl);
        profileImageStorageService.deleteImage(previousCoverImageUrl);
    }
}

