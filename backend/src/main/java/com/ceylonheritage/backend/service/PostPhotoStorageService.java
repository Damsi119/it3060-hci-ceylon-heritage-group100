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
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
public class PostPhotoStorageService {

    private static final long MAX_PHOTO_SIZE = 5L * 1024 * 1024;

    // Initial project limit: maximum 5 photos per post.
    private static final int MAX_PHOTOS = 5;

    private final Path uploadDirectory;

    public PostPhotoStorageService(
            @Value("${app.upload.post-directory:uploads/community-posts}")
            String directory
    ) {
        this.uploadDirectory = Path.of(directory)
                .toAbsolutePath()
                .normalize();
    }

    public List<String> savePhotos(List<MultipartFile> photos) {
        if (photos == null || photos.isEmpty()) {
            throw badRequest("Please add at least one photo");
        }

        if (photos.size() > MAX_PHOTOS) {
            throw badRequest("You can upload a maximum of 5 photos");
        }

        // Validate every photo before saving any files.
        List<String> extensions = photos.stream()
                .map(this::validatePhoto)
                .toList();

        List<String> savedUrls = new ArrayList<>();

        try {
            Files.createDirectories(uploadDirectory);

            for (int i = 0; i < photos.size(); i++) {
                String filename = UUID.randomUUID()
                        + extensions.get(i);

                Path destination = uploadDirectory.resolve(filename);

                try (InputStream input = photos.get(i).getInputStream()) {
                    Files.copy(input, destination);
                } catch (IOException exception) {
                    Files.deleteIfExists(destination);
                    throw exception;
                }

                savedUrls.add("/uploads/community-posts/" + filename);
            }

            return savedUrls;
        } catch (IOException exception) {
            deletePhotos(savedUrls);

            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "Could not save post photos",
                    exception
            );
        }
    }

    private String validatePhoto(MultipartFile photo) {
        if (photo == null || photo.isEmpty()) {
            throw badRequest("Photo must not be empty");
        }

        if (photo.getSize() > MAX_PHOTO_SIZE) {
            throw badRequest("Each photo must be 5 MB or smaller");
        }

        // Check file signatures rather than trusting the filename.
        try (InputStream input = photo.getInputStream()) {
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

    public void deletePhotos(List<String> photoUrls) {
        if (photoUrls == null) {
            return;
        }

        for (String url : photoUrls) {
            String prefix = "/uploads/community-posts/";

            if (url == null || !url.startsWith(prefix)) {
                continue;
            }

            Path file = uploadDirectory
                    .resolve(url.substring(prefix.length()))
                    .normalize();

            if (!uploadDirectory.equals(file.getParent())) {
                continue;
            }

            try {
                Files.deleteIfExists(file);
            } catch (IOException exception) {
                // Cleanup failure must not hide the original error.
                org.slf4j.LoggerFactory
                        .getLogger(PostPhotoStorageService.class)
                        .warn("Could not delete post photo: {}", file, exception);
            }
        }
    }

    private ResponseStatusException badRequest(String message) {
        return new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                message
        );
    }
}