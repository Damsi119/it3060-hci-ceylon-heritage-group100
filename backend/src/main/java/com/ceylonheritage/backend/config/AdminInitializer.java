package com.ceylonheritage.backend.config;

import com.ceylonheritage.backend.entities.User;
import com.ceylonheritage.backend.enums.AuthProvider;
import com.ceylonheritage.backend.enums.Role;
import com.ceylonheritage.backend.repository.UserRepository;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class AdminInitializer implements CommandLineRunner {

    private static final Logger LOGGER =
            LoggerFactory.getLogger(AdminInitializer.class);

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${admin.username:}")
    private String adminUsername;

    @Value("${admin.email:}")
    private String adminEmail;

    @Value("${admin.phone:}")
    private String adminPhone;

    @Value("${admin.password:}")
    private String adminPassword;

    public AdminInitializer(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder
    ) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) {

        if (userRepository.existsByRoleAndDeletedFalse(Role.ADMIN)) {
            return;
        }

        if (isBlank(adminUsername) ||
                isBlank(adminEmail) ||
                isBlank(adminPassword)) {

            LOGGER.warn(
                    "Default admin account was not created because admin credentials are not configured."
            );
            return;
        }

        User admin = User.builder()
                .username(adminUsername.trim())
                .email(adminEmail.trim().toLowerCase())
                .phone(clean(adminPhone))
                .password(
                        passwordEncoder.encode(adminPassword)
                )
                .firstName("Ceylon Heritage")
                .lastName("Admin")
                .role(Role.ADMIN)
                .provider(AuthProvider.LOCAL)
                .emailVerified(true)
                .enabled(true)
                .deleted(false)
                .otpResendCount(0)
                .build();

        userRepository.save(admin);

        LOGGER.info(
                "Ceylon Heritage admin account created successfully."
        );
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isBlank();
    }

    private String clean(String value) {

        if (isBlank(value)) {
            return null;
        }

        return value.trim();
    }
}
