package com.ceylonheritage.backend.Dtos;

import com.ceylonheritage.backend.enums.GuideApplicationStatus;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDateTime;

public class GuideDto {

    public record GuideApplicationRequest(

            @NotBlank(message = "Name is required")
            String name,

            @NotBlank(message = "Email is required")
            @Email(message = "Please provide a valid email")
            String email,

            @NotBlank(message = "Phone number is required")
            String phone,

            @NotBlank(message = "Service area is required")
            String primaryServiceArea,

            @NotBlank(message = "Languages are required")
            String languages,

            @NotBlank(message = "Experience is required")
            String experience

    ) {}


    public record GuideReviewRequest(

            @NotNull(message = "Review status is required")
            GuideApplicationStatus status,

            String reviewNote

    ) {}


    public record GuideProfileResponse(

            Long id,

            Long userId,

            String name,

            String email,

            String phone,

            String primaryServiceArea,

            String languages,

            String experience,

            GuideApplicationStatus status,

            String reviewNote,

            LocalDateTime createdAt,

            LocalDateTime reviewedAt

    ) {}
}
