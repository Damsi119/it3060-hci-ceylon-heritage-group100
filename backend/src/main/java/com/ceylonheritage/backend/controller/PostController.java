package com.ceylonheritage.backend.controller;

import com.ceylonheritage.backend.Dtos.CreatePostRequest;
import com.ceylonheritage.backend.Dtos.PostDto;
import com.ceylonheritage.backend.Dtos.UpdatePostRequest;
import com.ceylonheritage.backend.entities.User;
import com.ceylonheritage.backend.service.PostService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/api/posts")
public class PostController {

    private final PostService postService;

    public PostController(PostService postService) {
        this.postService = postService;
    }

    @GetMapping
    public ResponseEntity<List<PostDto>> getAllPosts() {
        return ResponseEntity.ok(postService.getAllPosts());
    }

    @GetMapping("/recent")
    public ResponseEntity<List<PostDto>> getRecentPosts() {
        return ResponseEntity.ok(postService.getRecentPosts());
    }

    @GetMapping("/my")
    public ResponseEntity<List<PostDto>> getMyPosts(
            @AuthenticationPrincipal User authenticatedUser
    ) {
        Long userId = requireUserId(authenticatedUser);

        return ResponseEntity.ok(
                postService.getMyPosts(userId)
        );
    }

    @GetMapping("/{id}")
    public ResponseEntity<PostDto> getPostById(
            @PathVariable("id") Long postId
    ) {
        return ResponseEntity.ok(
                postService.getPostById(postId)
        );
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<PostDto> createPost(
            @AuthenticationPrincipal User authenticatedUser,

            @Valid
            @RequestPart("post")
            CreatePostRequest request,

            @RequestPart("photos")
            List<MultipartFile> photos
    ) {
        Long userId = requireUserId(authenticatedUser);

        PostDto createdPost = postService.createPost(
                userId,
                request,
                photos
        );

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(createdPost);
    }

    @PutMapping(
            value = "/{id}",
            consumes = MediaType.APPLICATION_JSON_VALUE
    )
    public ResponseEntity<PostDto> updatePost(
            @AuthenticationPrincipal User authenticatedUser,
            @PathVariable("id") Long postId,
            @Valid @RequestBody UpdatePostRequest request
    ) {
        Long userId = requireUserId(authenticatedUser);

        return ResponseEntity.ok(
                postService.updatePost(
                        userId,
                        postId,
                        request
                )
        );
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePost(
            @AuthenticationPrincipal User authenticatedUser,
            @PathVariable("id") Long postId
    ) {
        Long userId = requireUserId(authenticatedUser);

        postService.deletePost(userId, postId);

        return ResponseEntity.noContent().build();
    }

    private Long requireUserId(User authenticatedUser) {
        if (authenticatedUser == null
                || authenticatedUser.getId() == null) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Please log in"
            );
        }

        if (!authenticatedUser.isEnabled()) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Your account is not active"
            );
        }

        return authenticatedUser.getId();
    }
}