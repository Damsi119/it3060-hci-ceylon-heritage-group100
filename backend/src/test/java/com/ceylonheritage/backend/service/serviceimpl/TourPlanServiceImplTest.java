package com.ceylonheritage.backend.service.serviceimpl;

import com.ceylonheritage.backend.Dtos.TourPlanGenerateRequest;
import com.ceylonheritage.backend.Dtos.TourPlanResponse;
import com.ceylonheritage.backend.entities.HistoricalPlace;
import com.ceylonheritage.backend.repository.HistoricalPlaceRepository;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class TourPlanServiceImplTest {

    private final HistoricalPlaceRepository repository =
            mock(HistoricalPlaceRepository.class);
    private final TourPlanServiceImpl service =
            new TourPlanServiceImpl(repository);

    @Test
    void generatesHotWeatherPlanForRequestedDuration() {
        when(repository.findByActiveTrueOrderByNameAsc())
                .thenReturn(samplePlaces());

        TourPlanResponse response = service.generatePlan(
                new TourPlanGenerateRequest(
                        "I want a hot weather tour for 3days. "
                                + "I'm starting from Colombo."
                )
        );

        assertEquals(3, response.durationDays());
        assertEquals("Colombo", response.startingLocation());
        assertTrue(response.preference().contains("Hot weather"));
        assertNotEquals("Galle", response.destination());
        assertTrue(response.confidenceLabel().endsWith("% Match"));
        assertTrue(response.places().stream().anyMatch(place ->
                "Sigiriya".equals(place.city())
                        || "Polonnaruwa".equals(place.city())));
    }

    @Test
    void stillMatchesBeachRequestsToCoastalPlans() {
        when(repository.findByActiveTrueOrderByNameAsc())
                .thenReturn(samplePlaces());

        TourPlanResponse response = service.generatePlan(
                new TourPlanGenerateRequest(
                        "I have Rs. 15,000. I want a beach trip for 2 days. "
                                + "I'm starting from Colombo."
                )
        );

        assertEquals(2, response.durationDays());
        assertEquals("Galle", response.destination());
        assertTrue(response.preference().contains("Beach"));
    }

    @Test
    void keepsExplicitDestinationSuggestionsInsideThatCity() {
        when(repository.findByActiveTrueOrderByNameAsc())
                .thenReturn(samplePlaces());

        TourPlanResponse response = service.generatePlan(
                new TourPlanGenerateRequest(
                        "I want historical places in anuradha pura for 2 days."
                )
        );

        assertEquals("Anuradhapura", response.destination());
        assertEquals(2, response.durationDays());
        assertFalse(response.places().isEmpty());
        assertTrue(response.places().stream().allMatch(place ->
                "Anuradhapura".equals(place.city())));
    }

    private List<HistoricalPlace> samplePlaces() {
        return List.of(
                place(
                        1L,
                        "Galle Fort",
                        "Galle",
                        "FORT",
                        "BEACH",
                        "BEACH,COASTAL,HISTORICAL,FORT,FAMILY"
                ),
                place(
                        2L,
                        "Sigiriya Rock Fortress",
                        "Sigiriya",
                        "ARCHAEOLOGICAL_SITE",
                        "WARM",
                        "HISTORICAL,NATURE,SCENIC,ANCIENT"
                ),
                place(
                        3L,
                        "Polonnaruwa Ancient City",
                        "Polonnaruwa",
                        "ANCIENT_CITY",
                        "DRY",
                        "HISTORICAL,ANCIENT,CULTURE,FAMILY"
                ),
                place(
                        4L,
                        "Gal Vihara",
                        "Polonnaruwa",
                        "ARCHAEOLOGICAL_SITE",
                        "DRY",
                        "HISTORICAL,CULTURE,ANCIENT,TEMPLE"
                ),
                place(
                        5L,
                        "Temple of the Tooth",
                        "Kandy",
                        "TEMPLE",
                        "HILL_COUNTRY",
                        "HISTORICAL,CULTURE,TEMPLE,FAMILY"
                ),
                place(
                        6L,
                        "Ruwanwelisaya",
                        "Anuradhapura",
                        "TEMPLE",
                        "DRY",
                        "HISTORICAL,TEMPLE,CULTURE,ANCIENT"
                )
        );
    }

    private HistoricalPlace place(
            Long id,
            String name,
            String city,
            String category,
            String climateType,
            String travelTags
    ) {
        HistoricalPlace place = new HistoricalPlace();

        place.setId(id);
        place.setName(name);
        place.setCity(city);
        place.setCategory(category);
        place.setClimateType(climateType);
        place.setTravelTags(travelTags);
        place.setDescription(name + " in " + city);
        place.setImageUrl("assets/images/test.png");
        place.setLatitude(7.0);
        place.setLongitude(80.0);
        place.setFeatured(true);
        place.setRating(4.8);

        return place;
    }
}
