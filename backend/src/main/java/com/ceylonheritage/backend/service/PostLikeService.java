package com.ceylonheritage.backend.service;

import com.ceylonheritage.backend.Dtos.PostLikeDto;

public interface PostLikeService {

    PostLikeDto likePost(
            Long authenticatedUserId,
            Long postId
    );

    PostLikeDto unlikePost(
            Long authenticatedUserId,
            Long postId
    );

    PostLikeDto getLikeStatus(
            Long authenticatedUserId,
            Long postId
    );
}