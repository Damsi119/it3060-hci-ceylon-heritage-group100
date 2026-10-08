package com.ceylonheritage.backend.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.UUID;

@Service
public class ProfileImageStorageService {

    private static final long MAX_IMAGE_SIZE = 5L * 1024 * 1024;
    private static final String URL_PREFIX = "/uploads/profile-images/";

    private final Path uploadDirectory;

    public ProfileImageStorageService(
            @Value("${app.upload.profile-directory:uploads/profile-images}")
            String directory
    ) {
        this.uploadDirectory = Path.of(directory)
                .toAbsolutePath()
                .normalize();
    }

    public String saveImage(MultipartFile image, String prefix) {
        String extension = validateImage(image);
        String safePrefix = prefix == null || prefix.isBlank()
                ? "image"
                : prefix.replaceAll("[^a-zA-Z0-9_-]", "");

        try {
            Files.createDirectories(uploadDirectory);

            String filename = safePrefix + "-" + UUID.randomUUID() + extension;
            Path destination = uploadDirectory.resolve(filename);

            try (InputStream input = image.getInputStream()) {
                Files.copy(input, destination);
            } catch (IOException exception) {
                Files.deleteIfExists(destination);
                throw exception;
            }

            return URL_PREFIX + filename;
        } catch (IOException exception) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "Could not save profile image",
                    exception
            );
        }
    }

    public void deleteImage(String imageUrl) {
        if (imageUrl == null || !imageUrl.startsWith(URL_PREFIX)) {
            return;
        }

        Path file = uploadDirectory
                .resolve(imageUrl.substring(URL_PREFIX.length()))
                .normalize();

        if (!uploadDirectory.equals(file.getParent())) {
            return;
        }

        try {
            Files.deleteIfExists(file);
        } catch (IOException exception) {
            org.slf4j.LoggerFactory
                    .getLogger(ProfileImageStorageService.class)
                    .warn("Could not delete profile image: {}", file, exception);
        }
    }

    private String validateImage(MultipartFile image) {
        if (image == null || image.isEmpty()) {
            throw badRequest("Photo must not be empty");
        }

        if (image.getSize() > MAX_IMAGE_SIZE) {
            throw badRequest("Photo must be 5 MB or smaller");
        }

        try (InputStream input = image.getInputStream()) {
            byte[] header = input.readNBytes(8);

            boolean jpeg = header.length >= 3
                    && (header[0] & 0xff) == 0xff
                    && (header[1] & 0xff) == 0xd8
                    && (header[2] & 0xff) == 0xff;

            boolean png = header.length == 8
                    && (header[0] & 0xff) == 0x89
                    && header[1] == 0x50
                    && header[2] == 0x4e
                    && header[3] == 0x47
                    && header[4] == 0x0d
                    && header[5] == 0x0a
                    && header[6] == 0x1a
                    && header[7] == 0x0a;

            if (jpeg) {
                return ".jpg";
            }

            if (png) {
                return ".png";
            }

            throw badRequest("Only JPG and PNG photos are allowed");
        } catch (IOException exception) {
            throw badRequest("Could not read the uploaded photo");
        }
    }

    private ResponseStatusException badRequest(String message) {
        return new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                message
        );
    }
}
