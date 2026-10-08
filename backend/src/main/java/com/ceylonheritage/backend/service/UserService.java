package com.ceylonheritage.backend.service;

import com.ceylonheritage.backend.Dtos.UserDto;
import com.ceylonheritage.backend.enums.Role;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

public interface UserService {

    UserDto.UserProfileResponse getProfile(String username);

    UserDto.UserProfileResponse updateProfile(
            String username,
            UserDto.UpdateProfileRequest request
    );

    UserDto.UserProfileResponse updateProfilePhoto(
            String username,
            MultipartFile photo
    );

    UserDto.UserProfileResponse updateCoverPhoto(
            String username,
            MultipartFile photo
    );

    UserDto.MessageResponse changePassword(
            String username,
            UserDto.ChangePasswordRequest request
    );

    UserDto.MessageResponse logout(String username);

    UserDto.MessageResponse deleteAccount(
            String username,
            UserDto.DeleteAccountRequest request
    );

    List<UserDto.UserProfileResponse> getUsers(Role role);

    UserDto.UserProfileResponse updateUserStatus(
            String adminUsername,
            Long userId,
            UserDto.AdminUserStatusRequest request
    );

    UserDto.MessageResponse deleteUser(
            String adminUsername,
            Long userId
    );
}
