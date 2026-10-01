package com.ceylonheritage.backend.security;

import com.ceylonheritage.backend.exception.UserException;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.Collections;

@Service
public class GoogleTokenService {

    private final GoogleIdTokenVerifier verifier;

    public GoogleTokenService(
            @Value("${google.oauth.client-id:${spring.security.oauth2.client.registration.google.client-id:}}")
            String clientId
    ) {

        if (clientId == null || clientId.isBlank()) {
            this.verifier = null;
            return;
        }

        try {
            this.verifier = new GoogleIdTokenVerifier.Builder(
                    GoogleNetHttpTransport.newTrustedTransport(),
                    GsonFactory.getDefaultInstance()
            )
                    .setAudience(
                            Collections.singletonList(clientId.trim())
                    )
                    .build();

        } catch (GeneralSecurityException | IOException exception) {
            throw new IllegalStateException(
                    "Could not initialize Google login",
                    exception
            );
        }
    }


    public GoogleUserInfo verify(String token) {

        if (verifier == null) {
            throw new UserException(
                    "Google login is not configured"
            );
        }

        try {
            GoogleIdToken idToken = verifier.verify(token);

            if (idToken == null) {
                throw new UserException(
                        "Invalid Google account"
                );
            }

            GoogleIdToken.Payload payload =
                    idToken.getPayload();

            if (!Boolean.TRUE.equals(
                    payload.getEmailVerified()
            )) {
                throw new UserException(
                        "Google email is not verified"
                );
            }

            String firstName =
                    payload.get("given_name") == null
                            ? null
                            : payload.get("given_name").toString();

            String lastName =
                    payload.get("family_name") == null
                            ? null
                            : payload.get("family_name").toString();

            return new GoogleUserInfo(
                    payload.getSubject(),
                    payload.getEmail(),
                    firstName,
                    lastName
            );

        } catch (GeneralSecurityException | IOException | IllegalArgumentException exception) {

            throw new UserException(
                    "Invalid Google account"
            );
        }
    }


    public record GoogleUserInfo(
            String providerId,
            String email,
            String firstName,
            String lastName
    ) {}
}

