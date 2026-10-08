package com.ceylonheritage.backend.repository;

import com.ceylonheritage.backend.entities.PostComment;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface PostCommentRepository
        extends JpaRepository<PostComment, Long> {

    Page<PostComment> findByPost_IdOrderByCreatedAtDescIdDesc(
            Long postId,
            Pageable pageable
    );

    long countByPost_Id(Long postId);

    Optional<PostComment> findByIdAndPost_IdAndAuthor_Id(
            Long commentId,
            Long postId,
            Long authorId
    );
}