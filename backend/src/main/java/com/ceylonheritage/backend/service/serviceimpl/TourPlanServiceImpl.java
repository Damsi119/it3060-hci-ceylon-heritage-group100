package com.ceylonheritage.backend.service.serviceimpl;

import com.ceylonheritage.backend.Dtos.TourPlanGenerateRequest;
import com.ceylonheritage.backend.Dtos.TourPlanResponse;
import com.ceylonheritage.backend.entities.HistoricalPlace;
import com.ceylonheritage.backend.repository.HistoricalPlaceRepository;
import com.ceylonheritage.backend.service.TourPlanService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
@Transactional(readOnly = true)
public class TourPlanServiceImpl implements TourPlanService {

    private static final int DEFAULT_BUDGET = 15_000;
    private static final int MAX_PLACES = 4;

    private static final Pattern MONEY_PATTERN = Pattern.compile(
            "(?:rs\\.?|lkr|rupees?|රු)\\s*([0-9][0-9,]*(?:\\.\\d+)?)"
                    + "|\\b([0-9]+(?:\\.\\d+)?)\\s*k\\b",
            Pattern.CASE_INSENSITIVE
    );

    private static final Pattern LARGE_NUMBER_PATTERN = Pattern.compile(
            "\\b([0-9][0-9,]{3,})(?:\\.\\d+)?\\b"
    );

    private static final Pattern FROM_PATTERN = Pattern.compile(
            "\\b(?:starting\\s+from|start\\s+from|leaving\\s+from|"
                    + "departing\\s+from|from)\\s+([a-zA-Z ]{2,35})",
            Pattern.CASE_INSENSITIVE
    );

    private static final List<String> KNOWN_CITIES = List.of(
            "Colombo",
            "Galle",
            "Kandy",
            "Nuwara Eliya",
            "Ella",
            "Haputale",
            "Badulla",
            "Anuradhapura",
            "Polonnaruwa",
            "Sigiriya",
            "Dambulla",
            "Matara",
            "Mirissa",
            "Unawatuna",
            "Hikkaduwa",
            "Trincomalee",
            "Jaffna",
            "Negombo",
            "Ratnapura",
            "Kurunegala"
    );

    private static final List<PreferenceProfile> PREFERENCES = List.of(
            new PreferenceProfile(
                    "COLD",
                    "Cold weather",
                    List.of("cold", "cool", "chill", "mist", "misty",
                            "hill", "mountain", "tea", "nuwara", "ella"),
                    List.of("COLD", "HILL_COUNTRY"),
                    List.of("COLD", "NATURE", "HILL_COUNTRY"),
                    List.of("Nuwara Eliya", "Ella", "Haputale", "Kandy"),
                    "Nuwara Eliya"
            ),
            new PreferenceProfile(
                    "BEACH",
                    "Beach and coastal",
                    List.of("beach", "sea", "coast", "coastal", "ocean",
                            "surf", "sunset"),
                    List.of("BEACH", "COASTAL", "WARM"),
                    List.of("BEACH", "COASTAL", "RELAX"),
                    List.of("Galle", "Mirissa", "Unawatuna", "Hikkaduwa",
                            "Trincomalee", "Negombo"),
                    "Galle"
            ),
            new PreferenceProfile(
                    "NATURE",
                    "Nature and scenery",
                    List.of("nature", "hike", "hiking", "waterfall",
                            "forest", "lake", "view", "scenery", "green"),
                    List.of("ANY", "COLD", "HILL_COUNTRY"),
                    List.of("NATURE", "HIKING", "SCENIC"),
                    List.of("Ella", "Sigiriya", "Kandy", "Nuwara Eliya",
                            "Polonnaruwa"),
                    "Ella"
            ),
            new PreferenceProfile(
                    "HISTORICAL",
                    "Historical and cultural",
                    List.of("history", "historical", "ancient", "temple",
                            "heritage", "culture", "museum", "fort",
                            "archaeological"),
                    List.of("ANY", "DRY", "WARM"),
                    List.of("HISTORICAL", "CULTURE", "ANCIENT"),
                    List.of("Anuradhapura", "Polonnaruwa", "Kandy", "Galle",
                            "Dambulla"),
                    "Anuradhapura"
            ),
            new PreferenceProfile(
                    "FAMILY",
                    "Family friendly",
                    List.of("family", "kids", "children", "safe", "relax"),
                    List.of("ANY"),
                    List.of("FAMILY", "RELAX", "CULTURE"),
                    List.of("Kandy", "Galle", "Colombo", "Polonnaruwa"),
                    "Kandy"
            )
    );

    private final HistoricalPlaceRepository historicalPlaceRepository;

    public TourPlanServiceImpl(
            HistoricalPlaceRepository historicalPlaceRepository
    ) {
        this.historicalPlaceRepository = historicalPlaceRepository;
    }

    @Override
    public TourPlanResponse generatePlan(TourPlanGenerateRequest request) {
        String prompt = request.prompt().trim();
        String normalizedPrompt = normalize(prompt);

        Integer detectedBudget = extractBudget(prompt);
        int budget = detectedBudget == null ? DEFAULT_BUDGET : detectedBudget;

        PreferenceProfile preference = detectPreference(normalizedPrompt);
        String startingLocation = detectStartingLocation(prompt)
                .orElse("Your location");

        List<HistoricalPlace> allPlaces = historicalPlaceRepository
                .findByActiveTrueOrderByNameAsc();
        boolean usedInactiveFallback = false;

        if (allPlaces.isEmpty()) {
            allPlaces = historicalPlaceRepository.findAll();
            usedInactiveFallback = !allPlaces.isEmpty();
        }

        List<ScoredPlace> scoredPlaces = scorePlaces(allPlaces, preference);
        Optional<String> matchedDestination =
                chooseDestination(scoredPlaces, preference);

        String destination = matchedDestination
                .orElse(preference.defaultDestination());

        List<ScoredPlace> selectedPlaces = selectPlaces(
                scoredPlaces,
                destination
        );

        boolean exactPlaceMatch = selectedPlaces.stream()
                .anyMatch(place -> place.score() > 0
                        && equalsIgnoreCase(place.place().getCity(), destination));

        List<String> notes = buildNotes(
                detectedBudget,
                startingLocation,
                exactPlaceMatch,
                usedInactiveFallback,
                allPlaces.isEmpty()
        );

        List<TourPlanResponse.ExpenseItem> expenses =
                buildExpenses(budget, durationDays(budget));

        int totalEstimatedCost = expenses.stream()
                .mapToInt(TourPlanResponse.ExpenseItem::estimatedCost)
                .sum();

        List<TourPlanResponse.ItineraryDay> itinerary = buildItinerary(
                durationDays(budget),
                startingLocation,
                destination,
                selectedPlaces
        );

        List<TourPlanResponse.PlaceSuggestion> placeSuggestions =
                selectedPlaces.stream()
                        .map(scored -> toPlaceSuggestion(scored.place()))
                        .toList();

        return new TourPlanResponse(
                "Recommended Tour - " + destination,
                destination,
                preference.label(),
                startingLocation,
                durationDays(budget),
                budget,
                totalEstimatedCost,
                mapsUrl(destination + " Sri Lanka"),
                confidenceLabel(
                        detectedBudget != null,
                        !"Your location".equals(startingLocation),
                        exactPlaceMatch
                ),
                detectedKeywords(preference, normalizedPrompt),
                notes,
                expenses,
                itinerary,
                placeSuggestions
        );
    }

    private Integer extractBudget(String prompt) {
        Matcher moneyMatcher = MONEY_PATTERN.matcher(prompt);

        if (moneyMatcher.find()) {
            String exactAmount = moneyMatcher.group(1);
            String shortAmount = moneyMatcher.group(2);

            if (exactAmount != null) {
                return parseMoney(exactAmount);
            }

            if (shortAmount != null) {
                return (int) Math.round(
                        Double.parseDouble(shortAmount) * 1000
                );
            }
        }

        Matcher numberMatcher = LARGE_NUMBER_PATTERN.matcher(prompt);

        if (numberMatcher.find()) {
            return parseMoney(numberMatcher.group(1));
        }

        return null;
    }

    private int parseMoney(String amount) {
        String cleanAmount = amount.replace(",", "");
        return (int) Math.round(Double.parseDouble(cleanAmount));
    }

    private PreferenceProfile detectPreference(String normalizedPrompt) {
        return PREFERENCES.stream()
                .filter(preference -> preference.keywords().stream()
                        .anyMatch(normalizedPrompt::contains))
                .findFirst()
                .orElse(PREFERENCES.stream()
                        .filter(item -> "HISTORICAL".equals(item.code()))
                        .findFirst()
                        .orElseThrow());
    }

    private Optional<String> detectStartingLocation(String prompt) {
        Matcher fromMatcher = FROM_PATTERN.matcher(prompt);

        if (fromMatcher.find()) {
            String phrase = fromMatcher.group(1);
            Optional<String> city = findKnownCity(phrase);

            if (city.isPresent()) {
                return city;
            }
        }

        return findKnownCity(prompt);
    }

    private Optional<String> findKnownCity(String text) {
        String normalizedText = normalize(text);

        return KNOWN_CITIES.stream()
                .filter(city -> normalizedText.contains(normalize(city)))
                .findFirst();
    }

    private List<ScoredPlace> scorePlaces(
            List<HistoricalPlace> places,
            PreferenceProfile preference
    ) {
        return places.stream()
                .map(place -> new ScoredPlace(
                        place,
                        scorePlace(place, preference)
                ))
                .sorted(Comparator
                        .comparingInt(ScoredPlace::score)
                        .reversed()
                        .thenComparing(
                                scored -> safeRating(scored.place()),
                                Comparator.reverseOrder()
                        )
                        .thenComparing(scored -> scored.place().getName()))
                .toList();
    }

    private int scorePlace(
            HistoricalPlace place,
            PreferenceProfile preference
    ) {
        Set<String> metadata = placeMetadata(place);
        int score = 0;

        if (metadata.contains(preference.code())) {
            score += 6;
        }

        for (String climateType : preference.climateTypes()) {
            if (metadata.contains(climateType)) {
                score += 3;
            }
        }

        for (String tag : preference.tags()) {
            if (metadata.contains(tag)) {
                score += 4;
            }
        }

        for (String cityHint : preference.cityHints()) {
            if (equalsIgnoreCase(place.getCity(), cityHint)) {
                score += 5;
            }
        }

        if (Boolean.TRUE.equals(place.isFeatured())) {
            score += 1;
        }

        return score;
    }

    private Optional<String> chooseDestination(
            List<ScoredPlace> scoredPlaces,
            PreferenceProfile preference
    ) {
        Map<String, Integer> scoreByCity = new LinkedHashMap<>();

        for (ScoredPlace scoredPlace : scoredPlaces) {
            String city = safeText(scoredPlace.place().getCity());

            if (city.isBlank()) {
                continue;
            }

            scoreByCity.merge(city, scoredPlace.score(), Integer::sum);
        }

        return scoreByCity.entrySet()
                .stream()
                .filter(entry -> entry.getValue() > 0)
                .sorted(Map.Entry.<String, Integer>comparingByValue()
                        .reversed()
                        .thenComparing(entry -> cityHintRank(
                                entry.getKey(),
                                preference
                        )))
                .map(Map.Entry::getKey)
                .findFirst();
    }

    private int cityHintRank(
            String city,
            PreferenceProfile preference
    ) {
        for (int index = 0; index < preference.cityHints().size(); index++) {
            if (equalsIgnoreCase(city, preference.cityHints().get(index))) {
                return index;
            }
        }

        return preference.cityHints().size();
    }

    private List<ScoredPlace> selectPlaces(
            List<ScoredPlace> scoredPlaces,
            String destination
    ) {
        List<ScoredPlace> destinationPlaces = scoredPlaces.stream()
                .filter(place -> equalsIgnoreCase(
                        place.place().getCity(),
                        destination
                ))
                .limit(MAX_PLACES)
                .toList();

        if (!destinationPlaces.isEmpty()) {
            return destinationPlaces;
        }

        return scoredPlaces.stream()
                .limit(MAX_PLACES)
                .toList();
    }

    private List<TourPlanResponse.ExpenseItem> buildExpenses(
            int budget,
            int durationDays
    ) {
        Map<String, Integer> percentages = new LinkedHashMap<>();

        if (durationDays == 1) {
            percentages.put("Transport", 35);
            percentages.put("Food", 25);
            percentages.put("Attractions", 20);
            percentages.put("Emergency Budget", 20);
        } else {
            percentages.put("Transport", 30);
            percentages.put("Accommodation", 30);
            percentages.put("Food", 20);
            percentages.put("Attractions", 10);
            percentages.put("Emergency Budget", 10);
        }

        List<TourPlanResponse.ExpenseItem> items = new ArrayList<>();
        int used = 0;
        int index = 0;

        for (Map.Entry<String, Integer> entry : percentages.entrySet()) {
            index++;
            int amount = index == percentages.size()
                    ? budget - used
                    : roundToNearestHundred(budget * entry.getValue() / 100.0);

            used += amount;
            items.add(new TourPlanResponse.ExpenseItem(
                    entry.getKey(),
                    amount
            ));
        }

        return items;
    }

    private int durationDays(int budget) {
        if (budget < 8_000) {
            return 1;
        }

        if (budget < 22_000) {
            return 2;
        }

        if (budget < 40_000) {
            return 3;
        }

        return 4;
    }

    private int roundToNearestHundred(double value) {
        return (int) Math.round(value / 100.0) * 100;
    }

    private List<TourPlanResponse.ItineraryDay> buildItinerary(
            int durationDays,
            String start,
            String destination,
            List<ScoredPlace> selectedPlaces
    ) {
        List<TourPlanResponse.ItineraryDay> days = new ArrayList<>();
        List<String> placeNames = selectedPlaces.stream()
                .map(scored -> scored.place().getName())
                .filter(name -> name != null && !name.isBlank())
                .toList();

        String firstStop = placeNames.isEmpty()
                ? "the main attraction area"
                : placeNames.get(0);

        days.add(new TourPlanResponse.ItineraryDay(
                1,
                List.of(
                        "Morning: Travel from " + start + " to "
                                + destination + ".",
                        "Afternoon: Visit " + firstStop + ".",
                        "Evening: Explore nearby viewpoints, markets or "
                                + "local food spots."
                )
        ));

        if (durationDays == 1) {
            return days;
        }

        if (durationDays == 2) {
            days.add(new TourPlanResponse.ItineraryDay(
                    2,
                    List.of(
                            "Morning: Visit " + joinPlaces(placeNames, 1, 3)
                                    + ".",
                            "Afternoon: Keep time for lunch and the return "
                                    + "journey.",
                            "Evening: Travel back to " + start + "."
                    )
            ));
            return days;
        }

        days.add(new TourPlanResponse.ItineraryDay(
                2,
                List.of(
                        "Morning: Visit " + joinPlaces(placeNames, 1, 3)
                                + ".",
                        "Afternoon: Add a relaxed stop for photos and local "
                                + "food.",
                        "Evening: Rest near " + destination + "."
                )
        ));

        days.add(new TourPlanResponse.ItineraryDay(
                3,
                List.of(
                        "Morning: Visit " + joinPlaces(placeNames, 3, 4)
                                + " or choose a nearby cultural stop.",
                        "Afternoon: Buy souvenirs and start the return "
                                + "journey.",
                        "Evening: Travel back to " + start + "."
                )
        ));

        if (durationDays == 4) {
            days.add(new TourPlanResponse.ItineraryDay(
                    4,
                    List.of(
                            "Morning: Use this as a flexible rest or backup "
                                    + "travel day.",
                            "Afternoon: Visit one extra nearby attraction if "
                                    + "budget and time allow.",
                            "Evening: Complete the journey safely."
                    )
            ));
        }

        return days;
    }

    private String joinPlaces(
            List<String> placeNames,
            int startInclusive,
            int endExclusive
    ) {
        if (placeNames.size() <= startInclusive) {
            return "recommended nearby attractions";
        }

        return placeNames.subList(
                        startInclusive,
                        Math.min(endExclusive, placeNames.size())
                )
                .stream()
                .collect(Collectors.joining(" and "));
    }

    private TourPlanResponse.PlaceSuggestion toPlaceSuggestion(
            HistoricalPlace place
    ) {
        return new TourPlanResponse.PlaceSuggestion(
                place.getId(),
                place.getName(),
                place.getCity(),
                place.getCategory(),
                place.getImageUrl(),
                place.getLatitude(),
                place.getLongitude(),
                place.getClimateType(),
                new ArrayList<>(placeMetadata(place)),
                mapsUrl(place.getName() + " " + place.getCity()
                        + " Sri Lanka")
        );
    }

    private List<String> buildNotes(
            Integer detectedBudget,
            String startingLocation,
            boolean exactPlaceMatch,
            boolean usedInactiveFallback,
            boolean hasNoPlaces
    ) {
        List<String> notes = new ArrayList<>();

        notes.add("Costs are estimated for planning only. Verify transport, "
                + "tickets and accommodation before travelling.");
        notes.add("Climate matching uses saved place tags and city knowledge, "
                + "not live weather readings.");

        if (detectedBudget == null) {
            notes.add("No clear budget was found, so Rs. "
                    + DEFAULT_BUDGET + " was used as a sample budget.");
        }

        if ("Your location".equals(startingLocation)) {
            notes.add("Starting location was not clear. Add a city like "
                    + "'starting from Galle' for a better plan.");
        }

        if (hasNoPlaces) {
            notes.add("No historical places are available in the "
                    + "database yet.");
        } else if (usedInactiveFallback) {
            notes.add("No places were marked active, so the planner used the "
                    + "available database places. Set active=true for final "
                    + "approved recommendations.");
        } else if (!exactPlaceMatch) {
            notes.add("No exact tagged place was found for this destination, "
                    + "so the closest available heritage places are shown.");
        }

        return notes;
    }

    private String confidenceLabel(
            boolean budgetFound,
            boolean startFound,
            boolean exactPlaceMatch
    ) {
        if (budgetFound && startFound && exactPlaceMatch) {
            return "High";
        }

        if ((budgetFound || startFound) && exactPlaceMatch) {
            return "Medium";
        }

        return "Basic";
    }

    private List<String> detectedKeywords(
            PreferenceProfile preference,
            String normalizedPrompt
    ) {
        List<String> keywords = preference.keywords()
                .stream()
                .filter(normalizedPrompt::contains)
                .toList();

        if (!keywords.isEmpty()) {
            return keywords;
        }

        return List.of(preference.code().toLowerCase(Locale.ROOT));
    }

    private Set<String> placeMetadata(HistoricalPlace place) {
        Set<String> tags = new LinkedHashSet<>();

        addToken(tags, place.getClimateType());
        addTokens(tags, place.getTravelTags());

        String text = normalize(
                safeText(place.getName()) + " "
                        + safeText(place.getCity()) + " "
                        + safeText(place.getCategory()) + " "
                        + safeText(place.getDescription())
        );

        if (containsAny(text, "nuwara eliya", "ella", "haputale",
                "bandarawela", "hill", "mountain", "mist", "tea")) {
            tags.add("COLD");
            tags.add("HILL_COUNTRY");
            tags.add("NATURE");
        }

        if (containsAny(text, "galle", "mirissa", "unawatuna",
                "hikkaduwa", "trincomalee", "negombo", "beach", "sea",
                "coast", "fort")) {
            tags.add("BEACH");
            tags.add("COASTAL");
        }

        if (containsAny(text, "ancient", "temple", "fort", "museum",
                "archaeological", "heritage", "vihara", "dagoba",
                "stupa", "palace")) {
            tags.add("HISTORICAL");
            tags.add("CULTURE");
        }

        if (containsAny(text, "sigiriya", "ella", "waterfall", "forest",
                "garden", "lake", "samudraya", "rock", "view")) {
            tags.add("NATURE");
            tags.add("SCENIC");
        }

        if (tags.isEmpty()) {
            tags.add("HISTORICAL");
        }

        return tags;
    }

    private void addTokens(Set<String> tags, String rawTags) {
        if (rawTags == null || rawTags.isBlank()) {
            return;
        }

        for (String item : rawTags.split("[,;|\\s]+")) {
            addToken(tags, item);
        }
    }

    private void addToken(Set<String> tags, String value) {
        if (value == null || value.isBlank()) {
            return;
        }

        tags.add(value.trim().toUpperCase(Locale.ROOT));
    }

    private boolean containsAny(String text, String... words) {
        for (String word : words) {
            if (text.contains(normalize(word))) {
                return true;
            }
        }

        return false;
    }

    private String mapsUrl(String query) {
        String encoded = URLEncoder.encode(query, StandardCharsets.UTF_8);
        return "https://www.google.com/maps/search/?api=1&query=" + encoded;
    }

    private double safeRating(HistoricalPlace place) {
        return place.getRating() == null ? 0.0 : place.getRating();
    }

    private boolean equalsIgnoreCase(String first, String second) {
        return safeText(first).equalsIgnoreCase(safeText(second));
    }

    private String safeText(String value) {
        return value == null ? "" : value.trim();
    }

    private String normalize(String value) {
        return safeText(value)
                .toLowerCase(Locale.ROOT)
                .replaceAll("[^a-z0-9 ]", " ")
                .replaceAll("\\s+", " ")
                .trim();
    }

    private record PreferenceProfile(
            String code,
            String label,
            List<String> keywords,
            List<String> climateTypes,
            List<String> tags,
            List<String> cityHints,
            String defaultDestination
    ) {}

    private record ScoredPlace(
            HistoricalPlace place,
            int score
    ) {}
}
