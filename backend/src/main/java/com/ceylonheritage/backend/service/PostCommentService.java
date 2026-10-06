package com.ceylonheritage.backend.service;

import com.ceylonheritage.backend.Dtos.CreatePostCommentRequest;
import com.ceylonheritage.backend.Dtos.PostCommentDto;
import org.springframework.data.domain.Page;

public interface PostCommentService {

    PostCommentDto createComment(
            Long authenticatedUserId,
            Long postId,
            CreatePostCommentRequest request
    );

    Page<PostCommentDto> getComments(
            Long postId,
            int page,
            int size
    );

    void deleteComment(
            Long authenticatedUserId,
            Long postId,
            Long commentId
    );
}