package com.ceylonheritage.backend.service.serviceimpl;

import com.ceylonheritage.backend.service.EmailService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailServiceImpl implements EmailService {

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username:}")
    private String fromEmail;

    public EmailServiceImpl(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    @Override
    public void sendVerificationCode(String email, String code) {

        SimpleMailMessage message = new SimpleMailMessage();

        message.setFrom(fromEmail);
        message.setTo(email);
        message.setSubject("HISTORIA - Verify Your Email");
        message.setText(
                "Your HISTORIA verification code is: " + code +
                        "\n\nThis code will expire in 5 minutes."
        );

        mailSender.send(message);
    }

    @Override
    public void sendPasswordResetCode(String email, String code) {

        SimpleMailMessage message = new SimpleMailMessage();

        message.setFrom(fromEmail);
        message.setTo(email);
        message.setSubject("HISTORIA - Password Reset");
        message.setText(
                "Your HISTORIA password reset code is: " + code +
                        "\n\nThis code will expire in 5 minutes."
        );

        mailSender.send(message);
    }

    @Override
    public void sendGuideRequestRejected(
            String email,
            String name,
            String reason
    ) {

        SimpleMailMessage message = new SimpleMailMessage();

        message.setFrom(fromEmail);
        message.setTo(email);
        message.setSubject("HISTORIA - Guide Request Update");
        message.setText(
                "Hello " + name + ",\n\n" +
                        "Your guide request has been rejected." +
                        formatReason(reason) +
                        "\n\nThank you,\nHISTORIA Team"
        );

        mailSender.send(message);
    }

    @Override
    public void sendGuideApprovedCredentials(
            String email,
            String name,
            String username,
            String temporaryPassword
    ) {

        SimpleMailMessage message = new SimpleMailMessage();

        message.setFrom(fromEmail);
        message.setTo(email);
        message.setSubject("HISTORIA - Guide Account Approved");
        message.setText(
                "Hello " + name + ",\n\n" +
                        "Your guide request has been approved. Use these credentials to login:\n\n" +
                        "Username: " + username + "\n" +
                        "Email: " + email + "\n" +
                        "Temporary password: " + temporaryPassword + "\n\n" +
                        "You must change this temporary password after your first login." +
                        "\n\nThank you,\nHISTORIA Team"
        );

        mailSender.send(message);
    }

    private String formatReason(String reason) {

        if (reason == null || reason.trim().isBlank()) {
            return "";
        }

        return "\n\nReason: " + reason.trim();
    }
}
