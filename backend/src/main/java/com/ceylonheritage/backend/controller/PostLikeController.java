package com.ceylonheritage.backend.controller;

import com.ceylonheritage.backend.Dtos.PostLikeDto;
import com.ceylonheritage.backend.entities.User;
import com.ceylonheritage.backend.service.PostLikeService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;

@RestController
@RequestMapping("/api/posts")
public class PostLikeController {

    private final PostLikeService postLikeService;

    public PostLikeController(PostLikeService postLikeService) {
        this.postLikeService = postLikeService;
    }

    @PostMapping("/{postId}/like")
    public ResponseEntity<PostLikeDto> likePost(
            @PathVariable("postId") Long postId,
            @AuthenticationPrincipal User authenticatedUser
    ) {
        return ResponseEntity.ok(
                postLikeService.likePost(
                        getUserId(authenticatedUser),
                        postId
                )
        );
    }

    @DeleteMapping("/{postId}/like")
    public ResponseEntity<PostLikeDto> unlikePost(
            @PathVariable("postId") Long postId,
            @AuthenticationPrincipal User authenticatedUser
    ) {
        return ResponseEntity.ok(
                postLikeService.unlikePost(
                        getUserId(authenticatedUser),
                        postId
                )
        );
    }

    @GetMapping("/{postId}/likes")
    public ResponseEntity<PostLikeDto> getLikeStatus(
            @PathVariable("postId") Long postId,
            @AuthenticationPrincipal User authenticatedUser
    ) {
        return ResponseEntity.ok(
                postLikeService.getLikeStatus(
                        getUserId(authenticatedUser),
                        postId
                )
        );
    }

    private Long getUserId(User authenticatedUser) {
        return authenticatedUser == null
                ? null
                : authenticatedUser.getId();
    }
}