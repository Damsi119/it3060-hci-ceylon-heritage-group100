package com.ceylonheritage.backend.Dtos;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.util.List;

public record CreateTourRequest(

        @NotBlank(message = "Tour name is required")
        @Size(max = 150, message = "Tour name must not exceed 150 characters")
        String name,

        @NotEmpty(message = "Select at least one historical place")
        @Size(max = 20, message = "A tour can contain at most 20 places")
        List<
                @NotNull(message = "Place ID is required")
                @Positive(message = "Place ID must be a positive number")
                        Long
                > placeIds

) {
}