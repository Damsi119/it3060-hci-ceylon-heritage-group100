package com.ceylonheritage.backend.config;

import com.ceylonheritage.backend.entities.HistoricalPlace;
import com.ceylonheritage.backend.repository.HistoricalPlaceRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class HistoricalPlaceInitializer implements CommandLineRunner {

    private static final Logger LOGGER =
            LoggerFactory.getLogger(HistoricalPlaceInitializer.class);

    private final HistoricalPlaceRepository historicalPlaceRepository;

    public HistoricalPlaceInitializer(
            HistoricalPlaceRepository historicalPlaceRepository
    ) {
        this.historicalPlaceRepository = historicalPlaceRepository;
    }

    @Override
    public void run(String... args) {
        if (historicalPlaceRepository.count() > 0) {
            return;
        }

        historicalPlaceRepository.saveAll(List.of(
                place(
                        "Galle Fort",
                        "Galle",
                        "FORT",
                        "A fortified coastal heritage city with colonial streets, ramparts and ocean views.",
                        "assets/images/galle_fort.png",
                        6.0259,
                        80.2168,
                        true,
                        4.8,
                        520,
                        "Open all day",
                        "2-3 hours",
                        150,
                        "Morning or evening",
                        "Free",
                        "Moderate walking",
                        "BEACH",
                        "BEACH,COASTAL,HISTORICAL,FORT,FAMILY"
                ),
                place(
                        "Sigiriya Rock Fortress",
                        "Sigiriya",
                        "ARCHAEOLOGICAL_SITE",
                        "Ancient rock fortress known for royal gardens, frescoes and wide landscape views.",
                        "assets/images/sigiriya.png",
                        7.9570,
                        80.7603,
                        true,
                        4.9,
                        860,
                        "7:00 AM - 5:30 PM",
                        "3-4 hours",
                        210,
                        "Early morning",
                        "Ticket required",
                        "Stairs and climbing",
                        "WARM",
                        "HISTORICAL,NATURE,SCENIC,ANCIENT"
                ),
                place(
                        "Temple of the Tooth",
                        "Kandy",
                        "TEMPLE",
                        "Sacred Buddhist temple in Kandy that preserves one of Sri Lanka's most important relics.",
                        "assets/images/temple_of_the_tooth.png",
                        7.2936,
                        80.6413,
                        true,
                        4.8,
                        740,
                        "5:30 AM - 8:00 PM",
                        "1-2 hours",
                        90,
                        "Morning rituals",
                        "Ticket required",
                        "Easy access",
                        "HILL_COUNTRY",
                        "HISTORICAL,CULTURE,TEMPLE,FAMILY"
                ),
                place(
                        "Polonnaruwa Ancient City",
                        "Polonnaruwa",
                        "ANCIENT_CITY",
                        "Ruins of a medieval capital with palaces, temples and stone monuments.",
                        "assets/images/polonnaruwa.png",
                        7.9403,
                        81.0188,
                        true,
                        4.7,
                        610,
                        "7:00 AM - 6:00 PM",
                        "4-5 hours",
                        270,
                        "Morning",
                        "Ticket required",
                        "Cycling or walking",
                        "DRY",
                        "HISTORICAL,ANCIENT,CULTURE,FAMILY"
                ),
                place(
                        "Ruwanwelisaya",
                        "Anuradhapura",
                        "TEMPLE",
                        "Large ancient stupa and one of Anuradhapura's most revered Buddhist monuments.",
                        "assets/images/ruwanwelisaya.png",
                        8.3500,
                        80.3964,
                        true,
                        4.9,
                        690,
                        "Open all day",
                        "1-2 hours",
                        90,
                        "Evening",
                        "Free",
                        "Easy access",
                        "DRY",
                        "HISTORICAL,TEMPLE,CULTURE,ANCIENT"
                ),
                place(
                        "Gal Vihara",
                        "Polonnaruwa",
                        "ARCHAEOLOGICAL_SITE",
                        "Famous rock-cut Buddha statues carved during the Polonnaruwa period.",
                        "assets/images/gal_vihara.png",
                        7.9667,
                        81.0042,
                        true,
                        4.8,
                        480,
                        "7:00 AM - 6:00 PM",
                        "1 hour",
                        60,
                        "Morning",
                        "Ticket required",
                        "Short walk",
                        "DRY",
                        "HISTORICAL,CULTURE,ANCIENT,TEMPLE"
                ),
                place(
                        "Jaffna Fort",
                        "Jaffna",
                        "FORT",
                        "Northern coastal fort with colonial walls, open lawns and lagoon views.",
                        "assets/images/jaffna_fort.png",
                        9.6625,
                        80.0100,
                        true,
                        4.4,
                        320,
                        "8:00 AM - 6:00 PM",
                        "1-2 hours",
                        90,
                        "Evening",
                        "Free",
                        "Moderate walking",
                        "WARM",
                        "HISTORICAL,FORT,COASTAL,FAMILY"
                ),
                place(
                        "Lankathilaka Temple",
                        "Polonnaruwa",
                        "TEMPLE",
                        "Tall brick temple ruins that show the scale of Polonnaruwa architecture.",
                        "assets/images/lankathilaka_temple.png",
                        7.9588,
                        81.0047,
                        true,
                        4.6,
                        260,
                        "7:00 AM - 6:00 PM",
                        "45 minutes",
                        45,
                        "Morning",
                        "Ticket required",
                        "Short walk",
                        "DRY",
                        "HISTORICAL,TEMPLE,ANCIENT,CULTURE"
                )
        ));

        LOGGER.info("Default historical places were added to the database.");
    }

    private HistoricalPlace place(
            String name,
            String city,
            String category,
            String description,
            String imageUrl,
            Double latitude,
            Double longitude,
            boolean featured,
            Double rating,
            Integer reviewCount,
            String openingHours,
            String visitDuration,
            Integer visitDurationMinutes,
            String bestTimeToVisit,
            String entryFee,
            String accessibility,
            String climateType,
            String travelTags
    ) {
        HistoricalPlace place = new HistoricalPlace();

        place.setName(name);
        place.setCity(city);
        place.setCategory(category);
        place.setDescription(description);
        place.setImageUrl(imageUrl);
        place.setLatitude(latitude);
        place.setLongitude(longitude);
        place.setFeatured(featured);
        place.setActive(true);
        place.setRating(rating);
        place.setReviewCount(reviewCount);
        place.setOpeningHours(openingHours);
        place.setVisitDuration(visitDuration);
        place.setVisitDurationMinutes(visitDurationMinutes);
        place.setBestTimeToVisit(bestTimeToVisit);
        place.setEntryFee(entryFee);
        place.setAccessibility(accessibility);
        place.setClimateType(climateType);
        place.setTravelTags(travelTags);

        return place;
    }
}
