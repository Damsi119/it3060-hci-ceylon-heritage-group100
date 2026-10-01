package com.ceylonheritage.backend.service.serviceimpl;

import com.ceylonheritage.backend.Dtos.UserDto;
import com.ceylonheritage.backend.entities.ForgotPassword;
import com.ceylonheritage.backend.entities.User;
import com.ceylonheritage.backend.exception.UserException;
import com.ceylonheritage.backend.repository.ForgotPasswordRepository;
import com.ceylonheritage.backend.repository.UserRepository;
import com.ceylonheritage.backend.service.EmailService;
import com.ceylonheritage.backend.service.ForgotPasswordService;
import com.ceylonheritage.backend.utils.OtpUtil;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
public class ForgotPasswordServiceImpl implements ForgotPasswordService {

    private final ForgotPasswordRepository forgotPasswordRepository;
    private final UserRepository userRepository;
    private final EmailService emailService;
    private final PasswordEncoder passwordEncoder;

    public ForgotPasswordServiceImpl(
            ForgotPasswordRepository forgotPasswordRepository,
            UserRepository userRepository,
            EmailService emailService,
            PasswordEncoder passwordEncoder
    ) {
        this.forgotPasswordRepository = forgotPasswordRepository;
        this.userRepository = userRepository;
        this.emailService = emailService;
        this.passwordEncoder = passwordEncoder;
    }


    @Override
    public UserDto.MessageResponse requestReset(
            UserDto.ForgotPasswordRequest request
    ) {

        int provided = countProvided(
                request.username(),
                request.email(),
                request.phone()
        );

        if (provided < 2) {
            throw new UserException(
                    "Please provide at least two account details"
            );
        }

        User user = findMatchingUser(request);

        if (!user.isEnabled()) {
            throw new UserException(
                    "Account is not active"
            );
        }

        ForgotPassword reset = forgotPasswordRepository
                .findByUser(user)
                .orElse(null);

        LocalDateTime now = LocalDateTime.now();

        if (reset != null) {

            checkBlock(reset, now);

            if (reset.getLastOtpSentAt() != null &&
                    now.isBefore(
                            reset.getLastOtpSentAt().plusMinutes(1)
                    )) {

                throw new UserException(
                        "Please wait one minute before requesting another code"
                );
            }
        }

        String otp = OtpUtil.generateOtp();

        if (reset == null) {

            reset = ForgotPassword.builder()
                    .user(user)
                    .otp(otp)
                    .otpExpiry(now.plusMinutes(5))
                    .verified(false)
                    .lastOtpSentAt(now)
                    .resendCount(0)
                    .build();

        } else {

            reset.setOtp(otp);
            reset.setOtpExpiry(now.plusMinutes(5));
            reset.setVerified(false);
            reset.setLastOtpSentAt(now);
        }

        forgotPasswordRepository.save(reset);

        emailService.sendPasswordResetCode(
                user.getEmail(),
                otp
        );

        return new UserDto.MessageResponse(
                true,
                "Password reset code has been sent to your email"
        );
    }


    @Override
    public UserDto.MessageResponse verifyOtp(
            UserDto.ForgotPasswordVerifyRequest request
    ) {

        User user = userRepository
                .findByEmailIgnoreCaseAndDeletedFalse(
                        request.email().trim()
                )
                .orElseThrow(() ->
                        new UserException("User not found")
                );

        ForgotPassword reset = forgotPasswordRepository
                .findByUser(user)
                .orElseThrow(() ->
                        new UserException(
                                "Password reset request not found"
                        )
                );

        if (!reset.getOtp().equals(request.code().trim())) {
            throw new UserException(
                    "Invalid verification code"
            );
        }

        if (reset.getOtpExpiry() == null ||
                LocalDateTime.now().isAfter(reset.getOtpExpiry())) {

            throw new UserException(
                    "Verification code has expired"
            );
        }

        reset.setVerified(true);

        forgotPasswordRepository.save(reset);

        return new UserDto.MessageResponse(
                true,
                "Verification successful"
        );
    }


    @Override
    public UserDto.MessageResponse resendOtp(
            UserDto.ForgotPasswordResendRequest request
    ) {

        User user = userRepository
                .findByEmailIgnoreCaseAndDeletedFalse(
                        request.email().trim()
                )
                .orElseThrow(() ->
                        new UserException("User not found")
                );

        ForgotPassword reset = forgotPasswordRepository
                .findByUser(user)
                .orElseThrow(() ->
                        new UserException(
                                "Password reset request not found"
                        )
                );

        LocalDateTime now = LocalDateTime.now();

        checkBlock(reset, now);

        if (reset.getLastOtpSentAt() != null &&
                now.isBefore(
                        reset.getLastOtpSentAt().plusMinutes(1)
                )) {

            throw new UserException(
                    "Please wait one minute before requesting another code"
            );
        }

        if (reset.getFirstResendAt() == null ||
                now.isAfter(
                        reset.getFirstResendAt().plusMinutes(30)
                )) {

            reset.setFirstResendAt(now);
            reset.setResendCount(0);
        }

        int resendCount = reset.getResendCount() == null
                ? 0
                : reset.getResendCount();

        if (resendCount >= 3) {

            reset.setBlockUntil(
                    now.plusMinutes(30)
            );

            forgotPasswordRepository.save(reset);

            throw new UserException(
                    "OTP resend limit reached. Please try again in 30 minutes"
            );
        }

        String otp = OtpUtil.generateOtp();

        reset.setOtp(otp);
        reset.setOtpExpiry(now.plusMinutes(5));
        reset.setVerified(false);
        reset.setLastOtpSentAt(now);
        reset.setResendCount(resendCount + 1);

        forgotPasswordRepository.save(reset);

        emailService.sendPasswordResetCode(
                user.getEmail(),
                otp
        );

        return new UserDto.MessageResponse(
                true,
                "A new password reset code has been sent"
        );
    }


    @Override
    @Transactional
    public UserDto.MessageResponse resetPassword(
            UserDto.ResetPasswordRequest request
    ) {

        if (!request.newPassword()
                .equals(request.confirmPassword())) {

            throw new UserException(
                    "Passwords do not match"
            );
        }

        User user = userRepository
                .findByEmailIgnoreCaseAndDeletedFalse(
                        request.email().trim()
                )
                .orElseThrow(() ->
                        new UserException("User not found")
                );

        ForgotPassword reset = forgotPasswordRepository
                .findByUser(user)
                .orElseThrow(() ->
                        new UserException(
                                "Password reset request not found"
                        )
                );

        if (!reset.isVerified()) {
            throw new UserException(
                    "Please verify the reset code first"
            );
        }

        if (reset.getOtpExpiry() == null ||
                LocalDateTime.now().isAfter(reset.getOtpExpiry())) {

            throw new UserException(
                    "Password reset session has expired"
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

        user.setRefreshTokenHash(null);

        userRepository.save(user);

        forgotPasswordRepository.delete(reset);

        return new UserDto.MessageResponse(
                true,
                "Password reset successfully"
        );
    }


    private User findMatchingUser(
            UserDto.ForgotPasswordRequest request
    ) {

        User user;

        if (hasText(request.email())) {

            user = userRepository
                    .findByEmailIgnoreCaseAndDeletedFalse(
                            request.email().trim()
                    )
                    .orElseThrow(() ->
                            new UserException(
                                    "Account details do not match"
                            )
                    );

        } else if (hasText(request.username())) {

            user = userRepository
                    .findByUsernameIgnoreCaseAndDeletedFalse(
                            request.username().trim()
                    )
                    .orElseThrow(() ->
                            new UserException(
                                    "Account details do not match"
                            )
                    );

        } else {

            user = userRepository
                    .findByPhoneAndDeletedFalse(
                            request.phone().trim()
                    )
                    .orElseThrow(() ->
                            new UserException(
                                    "Account details do not match"
                            )
                    );
        }

        if (hasText(request.email()) &&
                !user.getEmail().equalsIgnoreCase(
                        request.email().trim()
                )) {

            throw new UserException(
                    "Account details do not match"
            );
        }

        if (hasText(request.username()) &&
                !user.getUsername().equalsIgnoreCase(
                        request.username().trim()
                )) {

            throw new UserException(
                    "Account details do not match"
            );
        }

        if (hasText(request.phone()) &&
                (user.getPhone() == null ||
                        !user.getPhone().equals(
                        request.phone().trim()
                ))) {

            throw new UserException(
                    "Account details do not match"
            );
        }

        return user;
    }


    private void checkBlock(
            ForgotPassword reset,
            LocalDateTime now
    ) {

        if (reset.getBlockUntil() == null) {
            return;
        }

        if (now.isBefore(reset.getBlockUntil())) {
            throw new UserException(
                    "Too many attempts. Please try again later"
            );
        }

        reset.setBlockUntil(null);
        reset.setResendCount(0);
        reset.setFirstResendAt(null);

        forgotPasswordRepository.save(reset);
    }


    private int countProvided(
            String username,
            String email,
            String phone
    ) {

        int count = 0;

        if (hasText(username)) {
            count++;
        }

        if (hasText(email)) {
            count++;
        }

        if (hasText(phone)) {
            count++;
        }

        return count;
    }


    private boolean hasText(String value) {
        return value != null && !value.trim().isEmpty();
    }
}

