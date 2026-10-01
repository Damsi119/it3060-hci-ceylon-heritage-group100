package com.ceylonheritage.backend.service.serviceimpl;

import com.ceylonheritage.backend.Dtos.GuideDto;
import com.ceylonheritage.backend.entities.GuideProfile;
import com.ceylonheritage.backend.entities.Notification;
import com.ceylonheritage.backend.entities.User;
import com.ceylonheritage.backend.enums.AuthProvider;
import com.ceylonheritage.backend.enums.GuideApplicationStatus;
import com.ceylonheritage.backend.enums.Role;
import com.ceylonheritage.backend.exception.UserException;
import com.ceylonheritage.backend.repository.GuideProfileRepository;
import com.ceylonheritage.backend.repository.NotificationRepository;
import com.ceylonheritage.backend.repository.UserRepository;
import com.ceylonheritage.backend.service.EmailService;
import com.ceylonheritage.backend.service.GuideService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class GuideServiceImpl implements GuideService {

    private static final List<GuideApplicationStatus> ACTIVE_REQUEST_STATUSES =
            List.of(
                    GuideApplicationStatus.PENDING,
                    GuideApplicationStatus.APPROVED
            );

    private static final char[] TEMP_PASSWORD_CHARS =
            "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789@$#".toCharArray();

    private final SecureRandom secureRandom = new SecureRandom();

    private final GuideProfileRepository guideProfileRepository;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;
    private final NotificationRepository notificationRepository;

    public GuideServiceImpl(
            GuideProfileRepository guideProfileRepository,
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            EmailService emailService,
            NotificationRepository notificationRepository
    ) {
        this.guideProfileRepository = guideProfileRepository;
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.emailService = emailService;
        this.notificationRepository = notificationRepository;
    }


    @Override
    @Transactional
    public GuideDto.GuideProfileResponse submitGuideRequest(
            GuideDto.GuideApplicationRequest request
    ) {

        String email = cleanEmail(request.email());
        String phone = cleanRequired(request.phone(), "Phone number is required");

        if (userRepository.existsByEmailIgnoreCaseAndDeletedFalse(email)) {
            throw new UserException(
                    "A user account already exists with this email"
            );
        }

        if (userRepository.existsByPhoneAndDeletedFalse(phone)) {
            throw new UserException(
                    "A user account already exists with this phone number"
            );
        }

        if (guideProfileRepository.existsByEmailIgnoreCaseAndStatusIn(
                email,
                ACTIVE_REQUEST_STATUSES
        )) {
            throw new UserException(
                    "A guide request already exists for this email"
            );
        }

        GuideProfile profile = GuideProfile.builder()
                .name(cleanRequired(request.name(), "Name is required"))
                .email(email)
                .phone(phone)
                .primaryServiceArea(cleanRequired(
                        request.primaryServiceArea(),
                        "Service area is required"
                ))
                .languages(cleanRequired(
                        request.languages(),
                        "Languages are required"
                ))
                .experience(cleanRequired(
                        request.experience(),
                        "Experience is required"
                ))
                .status(GuideApplicationStatus.PENDING)
                .build();

        guideProfileRepository.save(profile);

        return toResponse(profile);
    }


    @Override
    public List<GuideDto.GuideProfileResponse> getGuidesByStatus(
            GuideApplicationStatus status
    ) {

        return guideProfileRepository.findByStatus(status)
                .stream()
                .map(this::toResponse)
                .toList();
    }


    @Override
    public List<GuideDto.GuideProfileResponse> getApprovedGuides() {

        return guideProfileRepository
                .findByStatusAndUserDeletedFalse(
                        GuideApplicationStatus.APPROVED
                )
                .stream()
                .map(this::toResponse)
                .toList();
    }


    @Override
    @Transactional
    public GuideDto.GuideProfileResponse reviewGuide(
            String adminUsername,
            Long guideProfileId,
            GuideDto.GuideReviewRequest request
    ) {

        User admin = userRepository
                .findByUsernameIgnoreCaseAndDeletedFalse(adminUsername)
                .orElseThrow(() -> new UserException("Admin not found"));

        GuideProfile profile = guideProfileRepository
                .findById(guideProfileId)
                .orElseThrow(() ->
                        new UserException("Guide request not found")
                );

        if (profile.getStatus() != GuideApplicationStatus.PENDING) {
            throw new UserException(
                    "Only pending guide requests can be reviewed"
            );
        }

        if (request.status() == GuideApplicationStatus.REJECTED) {
            reject(profile, admin, request.reviewNote());
            return toResponse(profile);
        }

        if (request.status() == GuideApplicationStatus.APPROVED) {
            approve(profile, admin, request.reviewNote());
            return toResponse(profile);
        }

        throw new UserException(
                "Guide requests can only be approved or rejected"
        );
    }


    private void reject(
            GuideProfile profile,
            User admin,
            String reviewNote
    ) {

        profile.setStatus(GuideApplicationStatus.REJECTED);
        profile.setReviewNote(cleanOptional(reviewNote));
        profile.setReviewedBy(admin);
        profile.setReviewedAt(LocalDateTime.now());

        guideProfileRepository.save(profile);

        emailService.sendGuideRequestRejected(
                profile.getEmail(),
                profile.getName(),
                profile.getReviewNote()
        );
    }


    private void approve(
            GuideProfile profile,
            User admin,
            String reviewNote
    ) {

        String email = profile.getEmail().trim().toLowerCase();
        String phone = profile.getPhone().trim();

        if (userRepository.existsByEmailIgnoreCaseAndDeletedFalse(email)) {
            throw new UserException(
                    "A user account already exists with this email"
            );
        }

        if (userRepository.existsByPhoneAndDeletedFalse(phone)) {
            throw new UserException(
                    "A user account already exists with this phone number"
            );
        }

        String username = createUsername(email);
        String temporaryPassword = generateTemporaryPassword();
        String[] nameParts = splitName(profile.getName());

        User guide = User.builder()
                .username(username)
                .email(email)
                .phone(phone)
                .password(passwordEncoder.encode(temporaryPassword))
                .firstName(nameParts[0])
                .lastName(nameParts[1])
                .role(Role.GUIDE)
                .provider(AuthProvider.LOCAL)
                .emailVerified(true)
                .enabled(true)
                .deleted(false)
                .passwordChangeRequired(true)
                .otpResendCount(0)
                .build();

        userRepository.save(guide);

        profile.setUser(guide);
        profile.setStatus(GuideApplicationStatus.APPROVED);
        profile.setReviewNote(cleanOptional(reviewNote));
        profile.setReviewedBy(admin);
        profile.setReviewedAt(LocalDateTime.now());

        guideProfileRepository.save(profile);

        notificationRepository.save(Notification.builder()
                .user(guide)
                .title("Guide account approved")
                .message("Your guide account has been approved. Please change your temporary password after login.")
                .build());

        emailService.sendGuideApprovedCredentials(
                guide.getEmail(),
                profile.getName(),
                guide.getUsername(),
                temporaryPassword
        );
    }


    private GuideDto.GuideProfileResponse toResponse(
            GuideProfile profile
    ) {

        Long userId = profile.getUser() == null
                ? null
                : profile.getUser().getId();

        return new GuideDto.GuideProfileResponse(
                profile.getId(),
                userId,
                profile.getName(),
                profile.getEmail(),
                profile.getPhone(),
                profile.getPrimaryServiceArea(),
                profile.getLanguages(),
                profile.getExperience(),
                profile.getStatus(),
                profile.getReviewNote(),
                profile.getCreatedAt(),
                profile.getReviewedAt()
        );
    }


    private String createUsername(String email) {

        String base = email
                .substring(0, email.indexOf("@"))
                .replaceAll("[^a-zA-Z0-9_]", "")
                .toLowerCase();

        if (base.isBlank()) {
            base = "guide";
        }

        String username = base;
        int number = 1;

        while (userRepository.existsByUsernameIgnoreCaseAndDeletedFalse(username)) {
            username = base + number;
            number++;
        }

        return username;
    }


    private String generateTemporaryPassword() {

        StringBuilder password = new StringBuilder();

        for (int index = 0; index < 14; index++) {
            password.append(TEMP_PASSWORD_CHARS[
                    secureRandom.nextInt(TEMP_PASSWORD_CHARS.length)
            ]);
        }

        return password.toString();
    }


    private String[] splitName(String name) {

        String cleaned = name == null ? "" : name.trim();

        if (cleaned.isBlank()) {
            return new String[] {"Guide", null};
        }

        int firstSpace = cleaned.indexOf(" ");

        if (firstSpace < 0) {
            return new String[] {cleaned, null};
        }

        return new String[] {
                cleaned.substring(0, firstSpace).trim(),
                cleaned.substring(firstSpace + 1).trim()
        };
    }


    private String cleanEmail(String email) {

        return cleanRequired(email, "Email is required").toLowerCase();
    }


    private String cleanRequired(String value, String message) {

        if (value == null || value.trim().isBlank()) {
            throw new UserException(message);
        }

        return value.trim();
    }


    private String cleanOptional(String value) {

        if (value == null || value.trim().isBlank()) {
            return null;
        }

        return value.trim();
    }
}
