package com.ceylonheritage.backend.entities;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
        name = "tour_stops",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_tour_stop_place",
                        columnNames = {"tour_id", "place_id"}
                )
        },
        indexes = {
                @Index(
                        name = "idx_tour_stop_order",
                        columnList = "tour_id, stop_order"
                )
        }
)
@Getter
@Setter
@NoArgsConstructor
public class TourStop {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "tour_id", nullable = false)
    private Tour tour;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "place_id", nullable = false)
    private HistoricalPlace historicalPlace;

    @Column(name = "stop_order", nullable = false)
    private Integer stopOrder;
}