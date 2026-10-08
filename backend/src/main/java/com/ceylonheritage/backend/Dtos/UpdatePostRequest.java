package com.ceylonheritage.backend.Dtos;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
public class UpdatePostRequest {

    @NotBlank(message = "Caption is required")
    @Size(
            max = 500,
            message = "Caption must not exceed 500 characters"
    )
    private String caption;

    @Size(
            max = 10,
            message = "You can add a maximum of 10 tags"
    )
    private List<
            @NotBlank(message = "Tag must not be blank")
            @Size(
                    max = 50,
                    message = "Each tag must not exceed 50 characters"
            )
                    String
            > tags = new ArrayList<>();
}