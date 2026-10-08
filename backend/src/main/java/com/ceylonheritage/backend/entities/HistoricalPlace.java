package com.ceylonheritage.backend.entities;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "historical_places")
@Getter
@Setter
@NoArgsConstructor
public class HistoricalPlace {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 150)
    private String name;

    @Column(nullable = false, length = 100)
    private String city;

    @Column(length = 50)
    private String category;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false, length = 1000)
    private String imageUrl;

    @ElementCollection
    @CollectionTable(
            name = "historical_place_images",
            joinColumns = @JoinColumn(name = "place_id")
    )
    @OrderColumn(name = "image_order")
    @Column(name = "image_url", nullable = false, length = 1000)
    private List<String> galleryImages = new ArrayList<>();

    @Column(nullable = false)
    private Double latitude;

    @Column(nullable = false)
    private Double longitude;

    @Column(nullable = false)
    private boolean featured = false;

    @Column(nullable = false)
    private boolean active = true;

    @Column(nullable = false)
    private Double rating = 0.0;

    @Column(nullable = false)
    private Integer reviewCount = 0;

    @Column(length = 150)
    private String openingHours;

    // Display text, for example: "1–2 hours".
    @Column(length = 100)
    private String visitDuration;

    // Planned visit time used for calculations.
    // Null means the visit time has not been configured.
    @Column(name = "visit_duration_minutes")
    private Integer visitDurationMinutes;

    @Column(length = 100)
    private String bestTimeToVisit;

    @Column(length = 150)
    private String entryFee;

    @Column(length = 150)
    private String accessibility;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}