package com.ceylonheritage.backend.Dtos;

import java.time.LocalDateTime;

public record PostCommentDto(

        Long id,
        Long postId,
        Long authorId,
        String authorName,
        String content,
        LocalDateTime createdAt

) {
}