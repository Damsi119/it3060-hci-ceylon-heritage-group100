package com.ceylonheritage.backend.service.serviceimpl;

import com.ceylonheritage.backend.Dtos.CreatePostCommentRequest;
import com.ceylonheritage.backend.Dtos.PostCommentDto;
import com.ceylonheritage.backend.entities.Post;
import com.ceylonheritage.backend.entities.PostComment;
import com.ceylonheritage.backend.entities.User;
import com.ceylonheritage.backend.repository.PostCommentRepository;
import com.ceylonheritage.backend.repository.UserRepository;
import com.ceylonheritage.backend.service.PostCommentService;
import jakarta.persistence.EntityManager;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
@Transactional(readOnly = true)
public class PostCommentServiceImpl implements PostCommentService {

    private final PostCommentRepository postCommentRepository;
    private final UserRepository userRepository;
    private final EntityManager entityManager;

    public PostCommentServiceImpl(
            PostCommentRepository postCommentRepository,
            UserRepository userRepository,
            EntityManager entityManager
    ) {
        this.postCommentRepository = postCommentRepository;
        this.userRepository = userRepository;
        this.entityManager = entityManager;
    }

    @Override
    @Transactional
    public PostCommentDto createComment(
            Long authenticatedUserId,
            Long postId,
            CreatePostCommentRequest request
    ) {
        User author = requireUser(authenticatedUserId);
        Post post = requirePost(postId);

        if (request == null
                || request.content() == null
                || request.content().isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Comment is required"
            );
        }

        if (request.content().length() > 1000) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Comment must not exceed 1000 characters"
            );
        }

        PostComment comment = new PostComment();
        comment.setPost(post);
        comment.setAuthor(author);
        comment.setContent(request.content().strip());

        postCommentRepository.saveAndFlush(comment);

        return toDto(comment);
    }

    @Override
    public Page<PostCommentDto> getComments(
            Long postId,
            int page,
            int size
    ) {
        requirePost(postId);

        if (page < 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Page must be zero or greater"
            );
        }

        if (size < 1 || size > 50) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Page size must be between 1 and 50"
            );
        }

        return postCommentRepository
                .findByPost_IdOrderByCreatedAtDescIdDesc(
                        postId,
                        PageRequest.of(page, size)
                )
                .map(this::toDto);
    }

    @Override
    @Transactional
    public void deleteComment(
            Long authenticatedUserId,
            Long postId,
            Long commentId
    ) {
        User author = requireUser(authenticatedUserId);
        requirePost(postId);

        if (commentId == null || commentId <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Comment ID must be a positive number"
            );
        }

        // Only the comment's author can delete it.
        PostComment comment = postCommentRepository
                .findByIdAndPost_IdAndAuthor_Id(
                        commentId,
                        postId,
                        author.getId()
                )
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Comment not found"
                ));

        postCommentRepository.delete(comment);
        postCommentRepository.flush();
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

    private Post requirePost(Long postId) {
        if (postId == null || postId <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Post ID must be a positive number"
            );
        }

        Post post = entityManager.find(Post.class, postId);

        if (post == null) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "Post not found"
            );
        }

        return post;
    }

    private PostCommentDto toDto(PostComment comment) {
        User author = comment.getAuthor();

        return new PostCommentDto(
                comment.getId(),
                comment.getPost().getId(),
                author.getId(),
                getAuthorName(author),
                comment.getContent(),
                comment.getCreatedAt()
        );
    }

    private String getAuthorName(User author) {
        String firstName = author.getFirstName() == null
                ? ""
                : author.getFirstName().trim();

        String lastName = author.getLastName() == null
                ? ""
                : author.getLastName().trim();

        String fullName = (firstName + " " + lastName).trim();

        return fullName.isBlank()
                ? author.getUsername()
                : fullName;
    }
}