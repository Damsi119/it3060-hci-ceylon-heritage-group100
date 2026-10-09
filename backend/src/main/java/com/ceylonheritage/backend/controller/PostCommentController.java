package com.ceylonheritage.backend.controller;

import com.ceylonheritage.backend.Dtos.CreatePostCommentRequest;
import com.ceylonheritage.backend.Dtos.PostCommentDto;
import com.ceylonheritage.backend.entities.User;
import com.ceylonheritage.backend.service.PostCommentService;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/posts")
public class PostCommentController {

    private final PostCommentService postCommentService;

    public PostCommentController(
            PostCommentService postCommentService
    ) {
        this.postCommentService = postCommentService;
    }

    @PostMapping("/{postId}/comments")
    public ResponseEntity<PostCommentDto> createComment(
            @PathVariable("postId") Long postId,
            @AuthenticationPrincipal User authenticatedUser,
            @Valid @RequestBody CreatePostCommentRequest request
    ) {
        PostCommentDto comment = postCommentService.createComment(
                getUserId(authenticatedUser),
                postId,
                request
        );

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(comment);
    }

    @GetMapping("/{postId}/comments")
    public ResponseEntity<Page<PostCommentDto>> getComments(
            @PathVariable("postId") Long postId,
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "20") int size
    ) {
        return ResponseEntity.ok(
                postCommentService.getComments(postId, page, size)
        );
    }

    @DeleteMapping("/{postId}/comments/{commentId}")
    public ResponseEntity<Void> deleteComment(
            @PathVariable("postId") Long postId,
            @PathVariable("commentId") Long commentId,
            @AuthenticationPrincipal User authenticatedUser
    ) {
        postCommentService.deleteComment(
                getUserId(authenticatedUser),
                postId,
                commentId
        );

        return ResponseEntity.noContent().build();
    }

    private Long getUserId(User authenticatedUser) {
        return authenticatedUser == null
                ? null
                : authenticatedUser.getId();
    }
}