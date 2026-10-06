package com.ceylonheritage.backend.service;

import com.ceylonheritage.backend.Dtos.CreatePostRequest;
import com.ceylonheritage.backend.Dtos.PostDto;
import com.ceylonheritage.backend.Dtos.UpdatePostRequest;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

public interface PostService {

    List<PostDto> getAllPosts();

    List<PostDto> getRecentPosts();

    List<PostDto> getMyPosts(Long authenticatedUserId);

    PostDto getPostById(Long postId);

    PostDto createPost(
            Long authenticatedUserId,
            CreatePostRequest request,
            List<MultipartFile> photos
    );

    PostDto updatePost(
            Long authenticatedUserId,
            Long postId,
            UpdatePostRequest request
    );

    void deletePost(
            Long authenticatedUserId,
            Long postId
    );
}