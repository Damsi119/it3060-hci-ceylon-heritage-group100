package com.ceylonheritage.backend.service;

public interface EmailService {

    void sendVerificationCode(String email, String code);

    void sendPasswordResetCode(String email, String code);

    void sendGuideRequestRejected(String email, String name, String reason);

    void sendGuideApprovedCredentials(
            String email,
            String name,
            String username,
            String temporaryPassword
    );
}
