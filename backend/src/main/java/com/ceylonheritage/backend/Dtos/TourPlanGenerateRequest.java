package com.ceylonheritage.backend.Dtos;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record TourPlanGenerateRequest(

        @NotBlank(message = "Tell us what kind of trip you want")
        @Size(max = 600, message = "Trip request must not exceed 600 characters")
        String prompt

) {}
