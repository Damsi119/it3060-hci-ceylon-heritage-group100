package com.ceylonheritage.backend.service.serviceimpl;

import com.ceylonheritage.backend.Dtos.PostLikeDto;
import com.ceylonheritage.backend.entities.Post;
import com.ceylonheritage.backend.entities.PostLike;
import com.ceylonheritage.backend.entities.User;
import com.ceylonheritage.backend.repository.PostLikeRepository;
import com.ceylonheritage.backend.repository.UserRepository;
import com.ceylonheritage.backend.service.NotificationService;
import com.ceylonheritage.backend.service.PostLikeService;
import jakarta.persistence.EntityManager;
import jakarta.persistence.LockModeType;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.Objects;

@Service
@Transactional(readOnly = true)
public class PostLikeServiceImpl implements PostLikeService {

    private final PostLikeRepository postLikeRepository;
    private final UserRepository userRepository;
    private final EntityManager entityManager;
    private final NotificationService notificationService;

    public PostLikeServiceImpl(
            PostLikeRepository postLikeRepository,
            UserRepository userRepository,
            EntityManager entityManager,
            NotificationService notificationService
    ) {
        this.postLikeRepository = postLikeRepository;
        this.userRepository = userRepository;
        this.entityManager = entityManager;
        this.notificationService = notificationService;
    }

    @Override
    @Transactional
    public PostLikeDto likePost(
            Long authenticatedUserId,
            Long postId
    ) {
        User user = requireUser(authenticatedUserId);
        Post post = requirePost(postId, true);

        // Repeated requests keep a single like.
        boolean created = false;
        if (!postLikeRepository.existsByPost_IdAndUser_Id(
                postId,
                user.getId()
        )) {
            PostLike like = new PostLike();
            like.setPost(post);
            like.setUser(user);

            postLikeRepository.saveAndFlush(like);
            created = true;
        }

        if (created
                && !Objects.equals(post.getAuthor().getId(), user.getId())) {
            notificationService.createForUser(
                    post.getAuthor(),
                    "New like on your post",
                    getUserName(user)
                            + " liked your "
                            + post.getHistoricalPlace().getName()
                            + " post."
            );
        }

        return buildStatus(postId, user.getId());
    }

    @Override
    @Transactional
    public PostLikeDto unlikePost(
            Long authenticatedUserId,
            Long postId
    ) {
        User user = requireUser(authenticatedUserId);
        requirePost(postId, true);

        // Removing an already absent like is also successful.
        postLikeRepository.findByPost_IdAndUser_Id(
                postId,
                user.getId()
        ).ifPresent(postLikeRepository::delete);

        postLikeRepository.flush();

        return buildStatus(postId, user.getId());
    }

    @Override
    public PostLikeDto getLikeStatus(
            Long authenticatedUserId,
            Long postId
    ) {
        if (authenticatedUserId != null) {
            requireUser(authenticatedUserId);
        }

        requirePost(postId, false);

        return buildStatus(postId, authenticatedUserId);
    }

    private PostLikeDto buildStatus(
            Long postId,
            Long userId
    ) {
        long likeCount = postLikeRepository.countByPost_Id(postId);

        boolean likedByCurrentUser = userId != null
                && postLikeRepository.existsByPost_IdAndUser_Id(
                postId,
                userId
        );

        return new PostLikeDto(
                postId,
                likeCount,
                likedByCurrentUser
        );
    }

    private User requireUser(Long userId) {
        if (userId == null || userId <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Please log in"
            );
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "Please log in"
                ));

        if (!user.isEnabled()) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Your account is not active"
            );
        }

        return user;
    }

    private Post requirePost(
            Long postId,
            boolean lockForUpdate
    ) {
        if (postId == null || postId <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Post ID must be a positive number"
            );
        }

        // Serialize like/unlike changes for the same post,
        // preventing concurrent requests from inserting duplicate likes.
        Post post = lockForUpdate
                ? entityManager.find(
                Post.class,
                postId,
                LockModeType.PESSIMISTIC_WRITE
        )
                : entityManager.find(Post.class, postId);

        if (post == null) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "Post not found"
            );
        }

        return post;
    }


    private String getUserName(User user) {
        String firstName = user.getFirstName() == null
                ? ""
                : user.getFirstName().trim();

        String lastName = user.getLastName() == null
                ? ""
                : user.getLastName().trim();

        String fullName = (firstName + " " + lastName).trim();

        return fullName.isBlank()
                ? user.getUsername()
                : fullName;
    }
}
