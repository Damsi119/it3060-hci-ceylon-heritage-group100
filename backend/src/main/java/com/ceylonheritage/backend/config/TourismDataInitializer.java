package com.ceylonheritage.backend.config;

import com.ceylonheritage.backend.entities.Place;
import com.ceylonheritage.backend.entities.PlaceReview;
import com.ceylonheritage.backend.repository.PlaceRepository;
import com.ceylonheritage.backend.repository.PlaceReviewRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class TourismDataInitializer {

    @Bean
    CommandLineRunner seedTourismData(PlaceRepository places, PlaceReviewRepository reviews) {
        return args -> {
            List<Place> samplePlaces = List.of(
                    place("fort-paradise-restaurant", "Fort Paradise Restaurant", "RESTAURANTS", "Authentic Sri Lankan cuisine with a panoramic sea view. Try fresh lagoon prawns, devilled crab, and traditional coconut roti.", "Galle Fort, Galle", "Galle", "Southern Province", 5.0, 1, 250, true, "8:00 AM – 10:00 PM", "LKR 1,500 – 3,000", 6.0260, 80.2170),
                    place("heritage-hotel", "The Heritage Hotel", "HOTELS", "A comfortable heritage stay close to the historic streets and ramparts of Galle Fort.", "Church Street, Galle Fort", "Galle", "Southern Province", 4.4, 86, 400, true, "Check-in from 2:00 PM", "LKR 15,000 – 35,000", 6.0272, 80.2162),
                    place("galle-heritage-cafe", "Galle Heritage Cafe", "RESTAURANTS", "A relaxed cafe serving coffee, local desserts, and light meals inside the old fort.", "Pedlar Street, Galle Fort", "Galle", "Southern Province", 4.5, 53, 550, false, "8:00 AM – 8:00 PM", "LKR 700 – 2,000", 6.0268, 80.2191),
                    place("amangalla-hotel", "Amangalla Hotel", "HOTELS", "A historic hotel in a restored colonial building, with a courtyard and heritage interiors.", "Church Street, Galle Fort", "Galle", "Southern Province", 4.7, 91, 700, true, "Open daily", "LKR 30,000+", 6.0277, 80.2173),
                    place("laksala-shop", "Laksala Souvenir Shop", "SHOPS", "Browse Sri Lankan crafts, textiles, wooden carvings, and locally made souvenirs.", "Galle Fort, Galle", "Galle", "Southern Province", 4.8, 42, 850, true, "9:00 AM – 6:00 PM", "LKR 500 – 10,000", 6.0251, 80.2194),
                    place("galle-fort", "Galle Fort", "HERITAGE", "A UNESCO World Heritage Site built by the Portuguese and fortified by the Dutch. Its ramparts, streets, and buildings form a living heritage neighbourhood.", "Galle Fort, Galle", "Galle", "Southern Province", 4.8, 4, 350, true, "Open daily", "Free entry", 6.0260, 80.2170),
                    place("dutch-reformed-church", "Dutch Reformed Church", "HERITAGE", "A historic church within Galle Fort, known for its colonial architecture and long history.", "Church Street, Galle Fort", "Galle", "Southern Province", 4.7, 118, 470, true, "9:00 AM – 5:00 PM", "Free entry", 6.0271, 80.2177),
                    place("maritime-museum", "Maritime Museum", "MUSEUM", "Explore exhibits about Sri Lanka’s maritime history, trade, and coastal life.", "Queen Street, Galle Fort", "Galle", "Southern Province", 4.6, 75, 590, true, "9:00 AM – 5:00 PM", "LKR 500 – 1,000", 6.0254, 80.2185),
                    place("national-museum", "National Museum", "MUSEUM", "Discover artefacts and exhibits documenting the history and culture of the southern region.", "Leyn Baan Street, Galle Fort", "Galle", "Southern Province", 4.3, 61, 800, true, "9:00 AM – 5:00 PM", "LKR 500 – 1,000", 6.0268, 80.2188)
            );

            for (Place sample : samplePlaces) {
                places.findBySlug(sample.getSlug()).orElseGet(() -> places.save(sample));
            }

            Place fort = places.findBySlug("galle-fort").orElseThrow();
            if (reviews.countByPlace_Id(fort.getId()) == 0) {
                reviews.saveAll(List.of(
                        review(fort, "Sarah M.", 5, "A useful and interesting place to visit. There are plenty of historical details, museums and cozy cafes here."),
                        review(fort, "Kavindu P.", 5, "Stunning heritage views. Visit near sunset to catch gorgeous photographs."),
                        review(fort, "Sandhya R.", 5, "Loved the quiet colonial pathways and museum relics. A local walking tour made the visit even better."),
                        review(fort, "Nimal J.", 4, "Beautiful ramparts and a lovely walk beside the ocean.")));
            }

            Place restaurant = places.findBySlug("fort-paradise-restaurant").orElseThrow();
            if (reviews.countByPlace_Id(restaurant.getId()) == 0) {
                reviews.save(review(restaurant, "Maya T.", 5, "Fresh seafood, friendly service, and a beautiful view over the ocean."));
            }
        };
    }

    private Place place(String slug, String name, String category, String description, String address,
                        String city, String province, double rating, int reviewCount, int distance,
                        boolean open, String hours, String price, double latitude, double longitude) {
        return Place.builder().slug(slug).name(name).category(category).description(description)
                .address(address).city(city).province(province).rating(rating).reviewCount(reviewCount)
                .distanceMeters(distance).open(open).openingHours(hours).priceRange(price)
                .latitude(latitude).longitude(longitude).build();
    }

    private PlaceReview review(Place place, String author, int rating, String comment) {
        return PlaceReview.builder().place(place).authorName(author).authorLabel("Verified Local Guide")
                .rating(rating).comment(comment).build();
    }
}
