package com.ceylonheritage.backend.Dtos;

public record PostLikeDto(
        Long postId,
        long likeCount,
        boolean likedByCurrentUser
) {
}