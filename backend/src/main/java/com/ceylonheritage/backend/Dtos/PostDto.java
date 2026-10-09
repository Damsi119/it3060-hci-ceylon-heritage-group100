package com.ceylonheritage.backend.Dtos;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
public class PostDto {

    private Long id;

    private Long authorId;
    private String authorName;

    private Long placeId;
    private String placeName;
    private String placeCity;

    private String caption;

    private List<String> imageUrls = new ArrayList<>();
    private List<String> tags = new ArrayList<>();

    private long likeCount;
    private long commentCount;
    private boolean likedByCurrentUser;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}