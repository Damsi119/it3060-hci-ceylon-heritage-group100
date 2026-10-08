package com.ceylonheritage.backend.repository;

import com.ceylonheritage.backend.entities.PostLike;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface PostLikeRepository
        extends JpaRepository<PostLike, Long> {

    long countByPost_Id(Long postId);

    boolean existsByPost_IdAndUser_Id(
            Long postId,
            Long userId
    );

    Optional<PostLike> findByPost_IdAndUser_Id(
            Long postId,
            Long userId
    );
}