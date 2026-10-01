package com.ceylonheritage.backend.service.serviceimpl;

import com.ceylonheritage.backend.Dtos.UserDto;
import com.ceylonheritage.backend.entities.User;
import com.ceylonheritage.backend.enums.AuthProvider;
import com.ceylonheritage.backend.enums.Role;
import com.ceylonheritage.backend.exception.UserException;
import com.ceylonheritage.backend.repository.UserRepository;
import com.ceylonheritage.backend.security.GoogleTokenService;
import com.ceylonheritage.backend.security.JwtService;
import com.ceylonheritage.backend.service.AuthService;
import com.ceylonheritage.backend.service.EmailService;
import com.ceylonheritage.backend.utils.OtpUtil;
import com.ceylonheritage.backend.utils.TokenHashUtil;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;
    private final JwtService jwtService;
    private final GoogleTokenService googleTokenService;

    public AuthServiceImpl(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            EmailService emailService,
            JwtService jwtService,
            GoogleTokenService googleTokenService
    ) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.emailService = emailService;
        this.jwtService = jwtService;
        this.googleTokenService = googleTokenService;
    }


    @Override
    @Transactional
    public UserDto.MessageResponse register(
            UserDto.RegisterRequest request
    ) {

        String username = request.username().trim();
        String email = request.email().trim().toLowerCase();
        String phone = request.phone().trim();

        if (!request.password()
                .equals(request.confirmPassword())) {

            throw new UserException(
                    "Passwords do not match"
            );
        }

        if (request.role() != Role.TOURIST) {
            throw new UserException(
                    "Please use guide registration for guide accounts"
            );
        }

        if (userRepository
                .existsByUsernameIgnoreCaseAndDeletedFalse(username)) {

            throw new UserException(
                    "Username already exists"
            );
        }

        if (userRepository
                .existsByEmailIgnoreCaseAndDeletedFalse(email)) {

            throw new UserException(
                    "Email already exists"
            );
        }

        if (userRepository
                .existsByPhoneAndDeletedFalse(phone)) {

            throw new UserException(
                    "Phone number already exists"
            );
        }

        String otp = OtpUtil.generateOtp();
        LocalDateTime now = LocalDateTime.now();

        User user = User.builder()
                .username(username)
                .email(email)
                .phone(phone)
                .password(
                        passwordEncoder.encode(
                                request.password()
                        )
                )
                .firstName(request.firstName())
                .lastName(request.lastName())
                .address(request.address())
                .role(Role.TOURIST)
                .provider(AuthProvider.LOCAL)
                .emailVerified(false)
                .enabled(true)
                .deleted(false)
                .verifyCode(otp)
                .verifyCodeExpiry(
                        now.plusMinutes(5)
                )
                .lastOtpSentAt(now)
                .otpResendCount(0)
                .build();

        userRepository.save(user);

        emailService.sendVerificationCode(
                user.getEmail(),
                otp
        );

        return new UserDto.MessageResponse(
                true,
                "Registration successful. Check your email for the verification code."
        );
    }


    @Override
    @Transactional
    public UserDto.MessageResponse verifyEmail(
            UserDto.VerifyOtpRequest request
    ) {

        User user = userRepository
                .findByEmailIgnoreCaseAndDeletedFalse(
                        request.email().trim()
                )
                .orElseThrow(() ->
                        new UserException(
                                "User not found"
                        )
                );

        if (user.isEmailVerified()) {
            throw new UserException(
                    "Email is already verified"
            );
        }

        if (user.getVerifyCode() == null ||
                !user.getVerifyCode()
                        .equals(request.code().trim())) {

            throw new UserException(
                    "Invalid verification code"
            );
        }

        if (user.getVerifyCodeExpiry() == null ||
                LocalDateTime.now()
                        .isAfter(user.getVerifyCodeExpiry())) {

            throw new UserException(
                    "Verification code has expired"
            );
        }

        user.setEmailVerified(true);

        user.setVerifyCode(null);
        user.setVerifyCodeExpiry(null);
        user.setLastOtpSentAt(null);
        user.setOtpResendCount(0);
        user.setOtpFirstResendTime(null);
        user.setOtpBlockUntil(null);

        userRepository.save(user);

        return new UserDto.MessageResponse(
                true,
                "Email verified successfully"
        );
    }


    @Override
    @Transactional
    public UserDto.MessageResponse resendOtp(
            UserDto.ResendOtpRequest request
    ) {

        User user = userRepository
                .findByEmailIgnoreCaseAndDeletedFalse(
                        request.email().trim()
                )
                .orElseThrow(() ->
                        new UserException(
                                "User not found"
                        )
                );

        if (user.isEmailVerified()) {
            throw new UserException(
                    "Email is already verified"
            );
        }

        LocalDateTime now = LocalDateTime.now();

        if (user.getOtpBlockUntil() != null) {

            if (now.isBefore(
                    user.getOtpBlockUntil()
            )) {

                throw new UserException(
                        "Too many attempts. Please try again later."
                );
            }

            user.setOtpBlockUntil(null);
            user.setOtpResendCount(0);
            user.setOtpFirstResendTime(null);
        }

        if (user.getLastOtpSentAt() != null &&
                now.isBefore(
                        user.getLastOtpSentAt()
                                .plusMinutes(1)
                )) {

            throw new UserException(
                    "Please wait one minute before requesting another code."
            );
        }

        if (user.getOtpFirstResendTime() == null ||
                now.isAfter(
                        user.getOtpFirstResendTime()
                                .plusMinutes(30)
                )) {

            user.setOtpFirstResendTime(now);
            user.setOtpResendCount(0);
        }

        int resendCount =
                user.getOtpResendCount() == null
                        ? 0
                        : user.getOtpResendCount();

        if (resendCount >= 3) {

            user.setOtpBlockUntil(
                    now.plusMinutes(30)
            );

            userRepository.save(user);

            throw new UserException(
                    "OTP resend limit reached. Please try again in 30 minutes."
            );
        }

        String otp = OtpUtil.generateOtp();

        user.setVerifyCode(otp);
        user.setVerifyCodeExpiry(
                now.plusMinutes(5)
        );
        user.setLastOtpSentAt(now);
        user.setOtpResendCount(
                resendCount + 1
        );

        userRepository.save(user);

        emailService.sendVerificationCode(
                user.getEmail(),
                otp
        );

        return new UserDto.MessageResponse(
                true,
                "A new verification code has been sent to your email."
        );
    }


    @Override
    @Transactional
    public UserDto.AuthResponse login(
            UserDto.LoginRequest request
    ) {

        String identifier =
                request.identifier().trim();

        User user = findUser(identifier);

        if (!user.isEmailVerified()) {
            throw new UserException(
                    "Please verify your email first"
            );
        }

        if (!user.isEnabled()) {
            throw new UserException(
                    "Account is not active"
            );
        }

        if (!passwordEncoder.matches(
                request.password(),
                user.getPassword()
        )) {

            throw new UserException(
                    "Invalid login details"
            );
        }

        String accessToken =
                jwtService.generateAccessToken(user);

        String refreshToken =
                jwtService.generateRefreshToken(user);

        user.setRefreshTokenHash(
                TokenHashUtil.hash(refreshToken)
        );

        userRepository.save(user);

        return new UserDto.AuthResponse(
                accessToken,
                refreshToken,
                toProfileResponse(user)
        );
    }


    @Override
    @Transactional
    public UserDto.AuthResponse refreshToken(
            UserDto.RefreshTokenRequest request
    ) {

        String refreshToken =
                request.refreshToken().trim();

        String username;

        try {
            username =
                    jwtService.extractUsername(
                            refreshToken
                    );

        } catch (Exception exception) {

            throw new UserException(
                    "Invalid refresh token"
            );
        }

        User user = userRepository
                .findByUsernameIgnoreCaseAndDeletedFalse(
                        username
                )
                .orElseThrow(() ->
                        new UserException(
                                "User not found"
                        )
                );

        if (!jwtService.isRefreshTokenValid(
                refreshToken,
                user
        )) {

            throw new UserException(
                    "Invalid or expired refresh token"
            );
        }

        String tokenHash =
                TokenHashUtil.hash(refreshToken);

        if (user.getRefreshTokenHash() == null ||
                !user.getRefreshTokenHash()
                        .equals(tokenHash)) {

            throw new UserException(
                    "Refresh token is no longer valid"
            );
        }

        String newAccessToken =
                jwtService.generateAccessToken(user);

        String newRefreshToken =
                jwtService.generateRefreshToken(user);

        user.setRefreshTokenHash(
                TokenHashUtil.hash(
                        newRefreshToken
                )
        );

        userRepository.save(user);

        return new UserDto.AuthResponse(
                newAccessToken,
                newRefreshToken,
                toProfileResponse(user)
        );
    }


    @Override
    @Transactional
    public UserDto.AuthResponse googleLogin(
            UserDto.GoogleLoginRequest request
    ) {

        GoogleTokenService.GoogleUserInfo googleUser =
                googleTokenService.verify(
                        request.idToken()
                );

        String email =
                googleUser.email()
                        .trim()
                        .toLowerCase();

        User user = userRepository
                .findByEmailIgnoreCaseAndDeletedFalse(email)
                .orElse(null);

        if (user == null) {

            Role requestedRole = request.role() == null
                    ? Role.TOURIST
                    : request.role();

            if (requestedRole == Role.ADMIN) {
                throw new UserException(
                        "Admin registration is not allowed"
                );
            }

            if (requestedRole == Role.GUIDE) {
                throw new UserException(
                        "Please complete the guide registration form to create a guide account"
                );
            }

            if (requestedRole != Role.TOURIST) {
                throw new UserException(
                        "Invalid account type"
                );
            }

            String username =
                    createGoogleUsername(email);

            user = User.builder()
                    .username(username)
                    .email(email)
                    .phone(null)
                    .password(
                            passwordEncoder.encode(
                                    UUID.randomUUID()
                                            .toString()
                            )
                    )
                    .firstName(
                            googleUser.firstName()
                    )
                    .lastName(
                            googleUser.lastName()
                    )
                    .role(Role.TOURIST)
                    .provider(AuthProvider.GOOGLE)
                    .providerId(
                            googleUser.providerId()
                    )
                    .emailVerified(true)
                    .enabled(true)
                    .deleted(false)
                    .otpResendCount(0)
                    .build();

            userRepository.save(user);

        } else {

            if (user.getRole() == Role.ADMIN) {
                throw new UserException(
                        "Google login is not allowed for admin accounts"
                );
            }

            if (user.getProvider() == null ||
                    user.getProvider() == AuthProvider.LOCAL) {

                if (user.getProviderId() != null &&
                        !user.getProviderId()
                                .equals(
                                        googleUser.providerId()
                                )) {

                    throw new UserException(
                            "Google account does not match"
                    );
                }

                user.setProviderId(googleUser.providerId());
                user.setEmailVerified(true);
                user.setVerifyCode(null);
                user.setVerifyCodeExpiry(null);

            } else if (user.getProvider() == AuthProvider.GOOGLE) {

                if (user.getProviderId() == null ||
                        !user.getProviderId()
                                .equals(
                                        googleUser.providerId()
                                )) {

                    throw new UserException(
                            "Google account does not match"
                    );
                }
            }

            if (!user.isEnabled()) {
                if (user.getRole() == Role.GUIDE) {
                    throw new UserException(
                            "Guide account is not approved yet"
                    );
                }

                throw new UserException(
                        "Account is not active"
                );
            }
        }

        String accessToken =
                jwtService.generateAccessToken(user);

        String refreshToken =
                jwtService.generateRefreshToken(user);

        user.setRefreshTokenHash(
                TokenHashUtil.hash(refreshToken)
        );

        userRepository.save(user);

        return new UserDto.AuthResponse(
                accessToken,
                refreshToken,
                toProfileResponse(user)
        );
    }


    private User findUser(String identifier) {

        return userRepository
                .findByEmailIgnoreCaseAndDeletedFalse(
                        identifier
                )

                .or(() ->
                        userRepository
                                .findByUsernameIgnoreCaseAndDeletedFalse(
                                        identifier
                                )
                )

                .or(() ->
                        userRepository
                                .findByPhoneAndDeletedFalse(
                                        identifier
                                )
                )

                .orElseThrow(() ->
                        new UserException(
                                "Invalid login details"
                        )
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
                user.getRole(),
                user.getProvider(),
                user.isEmailVerified(),
                user.isPasswordChangeRequired()
        );
    }


    private String createGoogleUsername(
            String email
    ) {

        String base = email
                .substring(
                        0,
                        email.indexOf("@")
                )
                .replaceAll(
                        "[^a-zA-Z0-9_]",
                        ""
                )
                .toLowerCase();

        if (base.isBlank()) {
            base = "user";
        }

        String username = base;
        int number = 1;

        while (userRepository
                .existsByUsernameIgnoreCaseAndDeletedFalse(
                        username
                )) {

            username = base + number;
            number++;
        }

        return username;
    }
}

