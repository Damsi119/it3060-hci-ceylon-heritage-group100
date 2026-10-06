package com.ceylonheritage.backend.repository;

import com.ceylonheritage.backend.entities.Post;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;

public interface PostRepository extends JpaRepository<Post, Long> {

    // All posts: newest first.
    List<Post> findAllByOrderByCreatedAtDescIdDesc();

    // My Posts: posts belonging to the selected author.
    List<Post> findByAuthor_IdOrderByCreatedAtDescIdDesc(
            Long authorId
    );

    // Recent posts: posts created since the supplied time.
    List<Post> findByCreatedAtGreaterThanEqualOrderByCreatedAtDescIdDesc(
            LocalDateTime since
    );
}