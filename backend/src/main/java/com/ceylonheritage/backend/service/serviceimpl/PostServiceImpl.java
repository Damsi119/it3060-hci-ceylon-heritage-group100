package com.ceylonheritage.backend.service.serviceimpl;

import com.ceylonheritage.backend.Dtos.CreatePostRequest;
import com.ceylonheritage.backend.Dtos.PostDto;
import com.ceylonheritage.backend.Dtos.UpdatePostRequest;
import com.ceylonheritage.backend.entities.HistoricalPlace;
import com.ceylonheritage.backend.entities.Post;
import com.ceylonheritage.backend.entities.User;
import com.ceylonheritage.backend.repository.HistoricalPlaceRepository;
import com.ceylonheritage.backend.repository.PostCommentRepository;
import com.ceylonheritage.backend.repository.PostLikeRepository;
import com.ceylonheritage.backend.repository.PostRepository;
import com.ceylonheritage.backend.repository.UserRepository;
import com.ceylonheritage.backend.service.PostPhotoStorageService;
import com.ceylonheritage.backend.service.PostService;
import jakarta.persistence.EntityManager;
import jakarta.persistence.LockModeType;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validator;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@Transactional(readOnly = true)
public class PostServiceImpl implements PostService {

    private final PostRepository postRepository;
    private final UserRepository userRepository;
    private final HistoricalPlaceRepository historicalPlaceRepository;
    private final PostPhotoStorageService postPhotoStorageService;
    private final PostLikeRepository postLikeRepository;
    private final PostCommentRepository postCommentRepository;
    private final Validator validator;
    private final EntityManager entityManager;

    public PostServiceImpl(
            PostRepository postRepository,
            UserRepository userRepository,
            HistoricalPlaceRepository historicalPlaceRepository,
            PostPhotoStorageService postPhotoStorageService,
            PostLikeRepository postLikeRepository,
            PostCommentRepository postCommentRepository,
            Validator validator,
            EntityManager entityManager
    ) {
        this.postRepository = postRepository;
        this.userRepository = userRepository;
        this.historicalPlaceRepository = historicalPlaceRepository;
        this.postPhotoStorageService = postPhotoStorageService;
        this.postLikeRepository = postLikeRepository;
        this.postCommentRepository = postCommentRepository;
        this.validator = validator;
        this.entityManager = entityManager;
    }

    @Override
    public List<PostDto> getAllPosts() {
        Long currentUserId = getCurrentUserId();

        return postRepository
                .findAllByOrderByCreatedAtDescIdDesc()
                .stream()
                .map(post -> toDto(post, currentUserId))
                .toList();
    }

    @Override
    public List<PostDto> getRecentPosts() {
        LocalDateTime since = LocalDateTime.now().minusDays(7);
        Long currentUserId = getCurrentUserId();

        return postRepository
                .findByCreatedAtGreaterThanEqualOrderByCreatedAtDescIdDesc(
                        since
                )
                .stream()
                .map(post -> toDto(post, currentUserId))
                .toList();
    }

    @Override
    public List<PostDto> getMyPosts(Long authenticatedUserId) {
        User author = getAuthenticatedUser(authenticatedUserId);

        return postRepository
                .findByAuthor_IdOrderByCreatedAtDescIdDesc(author.getId())
                .stream()
                .map(post -> toDto(post, author.getId()))
                .toList();
    }

    @Override
    public PostDto getPostById(Long postId) {
        validatePostId(postId);

        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Post not found"
                ));

        return toDto(post, getCurrentUserId());
    }

    @Override
    @Transactional
    public PostDto createPost(
            Long authenticatedUserId,
            CreatePostRequest request,
            List<MultipartFile> photos
    ) {
        User author = getAuthenticatedUser(authenticatedUserId);
        validateRequest(request, "Post details are required");

        HistoricalPlace place = historicalPlaceRepository
                .findByIdAndActiveTrue(request.getPlaceId())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Historical place not found"
                ));

        List<String> tags = normalizeTags(request.getTags());

        Post post = new Post();
        post.setAuthor(author);
        post.setHistoricalPlace(place);
        post.setCaption(request.getCaption().trim());
        post.setTags(tags);

        requireTransactionSynchronization();

        List<String> imageUrls =
                postPhotoStorageService.savePhotos(photos);

        try {
            TransactionSynchronizationManager.registerSynchronization(
                    new TransactionSynchronization() {
                        @Override
                        public void afterCompletion(int status) {
                            if (status != STATUS_COMMITTED) {
                                postPhotoStorageService
                                        .deletePhotos(imageUrls);
                            }
                        }
                    }
            );
        } catch (RuntimeException exception) {
            postPhotoStorageService.deletePhotos(imageUrls);
            throw exception;
        }

        post.setImageUrls(new ArrayList<>(imageUrls));

        Post savedPost = postRepository.saveAndFlush(post);
        return toDto(savedPost, author.getId());
    }

    @Override
    @Transactional
    public PostDto updatePost(
            Long authenticatedUserId,
            Long postId,
            UpdatePostRequest request
    ) {
        User author = getAuthenticatedUser(authenticatedUserId);
        Post post = requireOwnedPost(author.getId(), postId);

        validateRequest(request, "Updated post details are required");

        post.setCaption(request.getCaption().trim());
        post.setTags(normalizeTags(request.getTags()));

        Post savedPost = postRepository.saveAndFlush(post);

        return toDto(savedPost, author.getId());
    }

    @Override
    @Transactional
    public void deletePost(
            Long authenticatedUserId,
            Long postId
    ) {
        User author = getAuthenticatedUser(authenticatedUserId);
        Post post = requireOwnedPost(author.getId(), postId);

        requireTransactionSynchronization();

        // Copy the photo URLs before deleting the post.
        List<String> photoUrls =
                new ArrayList<>(post.getImageUrls());

        // Remove dependent records before deleting their parent post.
        entityManager.createQuery(
                        "delete from PostComment comment "
                                + "where comment.post.id = :postId"
                )
                .setParameter("postId", postId)
                .executeUpdate();

        entityManager.createQuery(
                        "delete from PostLike postLike "
                                + "where postLike.post.id = :postId"
                )
                .setParameter("postId", postId)
                .executeUpdate();

        // JPA also removes the post's image URL and tag collections.
        postRepository.delete(post);
        postRepository.flush();

        // Keep photos if the database transaction rolls back.
        TransactionSynchronizationManager.registerSynchronization(
                new TransactionSynchronization() {
                    @Override
                    public void afterCommit() {
                        postPhotoStorageService.deletePhotos(photoUrls);
                    }
                }
        );
    }

    private Post requireOwnedPost(Long userId, Long postId) {
        validatePostId(postId);

        // Serialize mutations of this post, including like/unlike.
        Post post = entityManager.find(
                Post.class,
                postId,
                LockModeType.PESSIMISTIC_WRITE
        );

        if (post == null) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "Post not found"
            );
        }

        if (!Objects.equals(post.getAuthor().getId(), userId)) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "You can only edit or delete your own posts"
            );
        }

        return post;
    }

    private void validatePostId(Long postId) {
        if (postId == null || postId <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Post ID must be a positive number"
            );
        }
    }

    private void requireTransactionSynchronization() {
        if (!TransactionSynchronizationManager
                .isSynchronizationActive()) {
            throw new IllegalStateException(
                    "Post changes require an active transaction"
            );
        }
    }

    private User getAuthenticatedUser(Long authenticatedUserId) {
        if (authenticatedUserId == null || authenticatedUserId <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Please log in"
            );
        }

        User user = userRepository.findById(authenticatedUserId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "Authenticated user not found"
                ));

        if (!user.isEnabled()) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Your account is not active"
            );
        }

        return user;
    }

    private Long getCurrentUserId() {
        Authentication authentication = SecurityContextHolder
                .getContext()
                .getAuthentication();

        if (authentication == null || !authentication.isAuthenticated()) {
            return null;
        }

        if (authentication.getPrincipal() instanceof User user
                && user.isEnabled()) {
            return user.getId();
        }

        return null;
    }

    private <T> void validateRequest(T request, String missingMessage) {
        if (request == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    missingMessage
            );
        }

        Set<ConstraintViolation<T>> violations =
                validator.validate(request);

        if (!violations.isEmpty()) {
            String message = violations.stream()
                    .map(ConstraintViolation::getMessage)
                    .sorted()
                    .collect(Collectors.joining("; "));

            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    message
            );
        }
    }

    private List<String> normalizeTags(List<String> tags) {
        if (tags == null || tags.isEmpty()) {
            return new ArrayList<>();
        }

        List<String> normalizedTags = new ArrayList<>();

        for (String tag : tags) {
            if (tag == null) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Tag must contain text"
                );
            }

            String normalized = tag.trim();

            if (normalized.startsWith("#")) {
                normalized = normalized.substring(1).trim();
            }

            if (normalized.isBlank()) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Tag must contain text"
                );
            }

            if (!normalizedTags.contains(normalized)) {
                normalizedTags.add(normalized);
            }
        }

        return normalizedTags;
    }

    private PostDto toDto(Post post, Long currentUserId) {
        PostDto dto = new PostDto();

        User author = post.getAuthor();
        HistoricalPlace place = post.getHistoricalPlace();

        dto.setId(post.getId());
        dto.setAuthorId(author.getId());
        dto.setAuthorName(getAuthorName(author));

        dto.setPlaceId(place.getId());
        dto.setPlaceName(place.getName());
        dto.setPlaceCity(place.getCity());

        dto.setCaption(post.getCaption());
        dto.setImageUrls(new ArrayList<>(post.getImageUrls()));
        dto.setTags(new ArrayList<>(post.getTags()));

        dto.setLikeCount(
                postLikeRepository.countByPost_Id(post.getId())
        );

        dto.setCommentCount(
                postCommentRepository.countByPost_Id(post.getId())
        );

        dto.setLikedByCurrentUser(
                currentUserId != null
                        && postLikeRepository.existsByPost_IdAndUser_Id(
                        post.getId(),
                        currentUserId
                )
        );

        dto.setCreatedAt(post.getCreatedAt());
        dto.setUpdatedAt(post.getUpdatedAt());

        return dto;
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