package com.ceylonheritage.backend.entities;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "places")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Place {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 120)
    private String slug;

    @Column(nullable = false, length = 160)
    private String name;

    @Column(nullable = false, length = 30)
    private String category;

    @Column(nullable = false, length = 1200)
    private String description;

    @Column(nullable = false, length = 160)
    private String address;

    @Column(nullable = false, length = 80)
    private String city;

    @Column(nullable = false, length = 80)
    private String province;

    @Builder.Default
    @Column(nullable = false)
    private double rating = 0;

    @Builder.Default
    @Column(nullable = false)
    private int reviewCount = 0;

    @Builder.Default
    @Column(nullable = false)
    private int distanceMeters = 0;

    @Builder.Default
    @Column(name = "is_open", nullable = false)
    private boolean open = true;

    @Column(length = 80)
    private String openingHours;

    @Column(length = 80)
    private String priceRange;

    private Double latitude;
    private Double longitude;

    @Column(length = 500)
    private String imageUrl;
}
