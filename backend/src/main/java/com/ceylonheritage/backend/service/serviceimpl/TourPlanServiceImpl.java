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

    private static final int DEFAULT_DAILY_BUDGET = 12_000;
    private static final int DEFAULT_DURATION_DAYS = 2;
    private static final int MAX_SUGGESTED_PLACES = 6;
    private static final int MAX_DURATION_DAYS = 5;

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

    private static final Pattern ROUTE_PATTERN = Pattern.compile(
            "\\b([a-zA-Z ]{2,35})\\s+(?:to|towards)\\s+([a-zA-Z ]{2,35})",
            Pattern.CASE_INSENSITIVE
    );

    private static final Pattern DESTINATION_PATTERN = Pattern.compile(
            "\\b(?:visit|visiting|go(?:ing)?\\s+to|travel(?:ing|ling)?\\s+to|"
                    + "to|around|near|in)\\s+([a-zA-Z ]{2,35})",
            Pattern.CASE_INSENSITIVE
    );

    private static final Pattern DURATION_PATTERN = Pattern.compile(
            "\\b([1-5])\\s*(?:days?|dawas|davas|d)\\b|"
                    + "\\b(one|two|three|four|five)\\s*"
                    + "(?:days?|dawas|davas)\\b",
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

    private static final Map<String, List<String>> CITY_ALIASES = Map.of(
            "Anuradhapura", List.of("anuradha pura", "anuradhapura")
    );

    private static final List<PreferenceProfile> PREFERENCES = List.of(
            new PreferenceProfile(
                    "WARM",
                    "Hot weather",
                    List.of("hot", "warm", "sunny", "dry", "heat",
                            "summer", "hot weather", "hot whether"),
                    List.of("WARM", "DRY"),
                    List.of("HISTORICAL", "ANCIENT", "CULTURE", "SCENIC",
                            "FORT"),
                    List.of("Sigiriya", "Polonnaruwa", "Anuradhapura",
                            "Jaffna", "Galle"),
                    "Sigiriya"
            ),
            new PreferenceProfile(
                    "COLD",
                    "Cold weather",
                    List.of("cold", "cool", "chill", "mist", "misty",
                            "hill", "mountain", "tea", "nuwara", "ella",
                            "cold weather", "cool weather"),
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
                            "forest", "lake", "view", "scenery", "green",
                            "adventure", "climb", "trek", "trekking"),
                    List.of("ANY", "COLD", "HILL_COUNTRY"),
                    List.of("NATURE", "HIKING", "SCENIC", "ANCIENT"),
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
        Integer detectedDuration = extractDurationDays(prompt);
        int durationDays = detectedDuration == null
                ? durationDays(detectedBudget)
                : detectedDuration;
        int budget = detectedBudget == null
                ? estimateBudget(durationDays)
                : detectedBudget;

        PreferenceMatch preferenceMatch = detectPreference(normalizedPrompt);
        String startingLocation = detectStartingLocation(prompt)
                .orElse("Your location");
        Optional<String> requestedDestination = detectRequestedDestination(
                prompt,
                startingLocation
        );

        List<HistoricalPlace> allPlaces = historicalPlaceRepository
                .findByActiveTrueOrderByNameAsc();
        boolean usedInactiveFallback = false;

        if (allPlaces.isEmpty()) {
            allPlaces = historicalPlaceRepository.findAll();
            usedInactiveFallback = !allPlaces.isEmpty();
        }

        List<ScoredPlace> scoredPlaces = scorePlaces(
                allPlaces,
                preferenceMatch,
                normalizedPrompt,
                requestedDestination
        );
        Optional<String> matchedDestination =
                chooseDestination(
                        scoredPlaces,
                        preferenceMatch.primary(),
                        requestedDestination
                );

        String destination = matchedDestination
                .orElse(preferenceMatch.primary().defaultDestination());

        List<ScoredPlace> selectedPlaces = selectPlaces(
                scoredPlaces,
                destination,
                maxPlacesForDuration(durationDays),
                requestedDestination.isPresent()
        );

        boolean exactPlaceMatch = selectedPlaces.stream()
                .anyMatch(place -> place.score() > 0
                        && equalsIgnoreCase(place.place().getCity(), destination));

        List<String> notes = buildNotes(
                detectedBudget,
                detectedDuration,
                startingLocation,
                exactPlaceMatch,
                usedInactiveFallback,
                allPlaces.isEmpty(),
                preferenceMatch.score(),
                requestedDestination.isPresent()
        );

        List<TourPlanResponse.ExpenseItem> expenses =
                buildExpenses(budget, durationDays);

        int totalEstimatedCost = expenses.stream()
                .mapToInt(TourPlanResponse.ExpenseItem::estimatedCost)
                .sum();

        List<TourPlanResponse.ItineraryDay> itinerary = buildItinerary(
                durationDays,
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
                preferenceLabel(preferenceMatch),
                startingLocation,
                durationDays,
                budget,
                totalEstimatedCost,
                mapsUrl(destination + " Sri Lanka"),
                confidenceLabel(
                        detectedBudget != null,
                        detectedDuration != null,
                        !"Your location".equals(startingLocation),
                        exactPlaceMatch,
                        requestedDestination.isPresent(),
                        preferenceMatch.score()
                ),
                preferenceMatch.detectedKeywords(),
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

    private Integer extractDurationDays(String prompt) {
        Matcher durationMatcher = DURATION_PATTERN.matcher(normalize(prompt));

        if (!durationMatcher.find()) {
            return null;
        }

        String number = durationMatcher.group(1);

        if (number != null) {
            return clampDuration(Integer.parseInt(number));
        }

        return switch (durationMatcher.group(2).toLowerCase(Locale.ROOT)) {
            case "one" -> 1;
            case "two" -> 2;
            case "three" -> 3;
            case "four" -> 4;
            case "five" -> 5;
            default -> null;
        };
    }

    private PreferenceMatch detectPreference(String normalizedPrompt) {
        List<ScoredPreference> scoredPreferences = PREFERENCES.stream()
                .map(preference -> new ScoredPreference(
                        preference,
                        preferenceScore(preference, normalizedPrompt),
                        matchedKeywords(preference, normalizedPrompt)
                ))
                .filter(preference -> preference.score() > 0)
                .sorted(Comparator
                        .comparingInt(ScoredPreference::score)
                        .reversed()
                        .thenComparing(preference ->
                                preference.profile().label()))
                .toList();

        if (scoredPreferences.isEmpty()) {
            PreferenceProfile fallback = PREFERENCES.stream()
                    .filter(item -> "HISTORICAL".equals(item.code()))
                    .findFirst()
                    .orElseThrow();

            return new PreferenceMatch(
                    fallback,
                    List.of(fallback),
                    List.of(fallback.code().toLowerCase(Locale.ROOT)),
                    0
            );
        }

        List<PreferenceProfile> profiles = scoredPreferences.stream()
                .map(ScoredPreference::profile)
                .limit(3)
                .toList();

        List<String> keywords = scoredPreferences.stream()
                .flatMap(preference -> preference.detectedKeywords().stream())
                .distinct()
                .toList();

        int totalScore = scoredPreferences.stream()
                .mapToInt(ScoredPreference::score)
                .sum();

        return new PreferenceMatch(
                scoredPreferences.get(0).profile(),
                profiles,
                keywords,
                totalScore
        );
    }

    private int preferenceScore(
            PreferenceProfile preference,
            String normalizedPrompt
    ) {
        int score = 0;

        for (String keyword : preference.keywords()) {
            if (termMatches(normalizedPrompt, keyword)) {
                score += keyword.contains(" ") ? 4 : 2;
            }
        }

        return score;
    }

    private List<String> matchedKeywords(
            PreferenceProfile preference,
            String normalizedPrompt
    ) {
        return preference.keywords()
                .stream()
                .filter(keyword -> termMatches(normalizedPrompt, keyword))
                .distinct()
                .toList();
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

        Matcher routeMatcher = ROUTE_PATTERN.matcher(prompt);

        if (routeMatcher.find()) {
            return findKnownCity(routeMatcher.group(1));
        }

        return Optional.empty();
    }

    private Optional<String> detectRequestedDestination(
            String prompt,
            String startingLocation
    ) {
        Matcher routeMatcher = ROUTE_PATTERN.matcher(prompt);

        if (routeMatcher.find()) {
            Optional<String> routeDestination = findKnownCity(
                    routeMatcher.group(2)
            );

            if (routeDestination.isPresent()) {
                return routeDestination;
            }
        }

        Matcher destinationMatcher = DESTINATION_PATTERN.matcher(prompt);

        while (destinationMatcher.find()) {
            Optional<String> city = findKnownCity(destinationMatcher.group(1));

            if (city.isPresent()
                    && !equalsIgnoreCase(city.get(), startingLocation)) {
                return city;
            }
        }

        List<String> mentionedCities = KNOWN_CITIES.stream()
                .filter(city -> cityMatches(prompt, city))
                .filter(city -> !equalsIgnoreCase(city, startingLocation))
                .toList();

        return mentionedCities.size() == 1
                ? Optional.of(mentionedCities.get(0))
                : Optional.empty();
    }

    private Optional<String> findKnownCity(String text) {
        return KNOWN_CITIES.stream()
                .filter(city -> cityMatches(text, city))
                .findFirst();
    }

    private List<ScoredPlace> scorePlaces(
            List<HistoricalPlace> places,
            PreferenceMatch preferenceMatch,
            String normalizedPrompt,
            Optional<String> requestedDestination
    ) {
        return places.stream()
                .map(place -> new ScoredPlace(
                        place,
                        scorePlace(
                                place,
                                preferenceMatch,
                                normalizedPrompt,
                                requestedDestination
                        )
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
            PreferenceMatch preferenceMatch,
            String normalizedPrompt,
            Optional<String> requestedDestination
    ) {
        Set<String> metadata = placeMetadata(place);
        String searchableText = searchablePlaceText(place);
        int score = 0;

        for (PreferenceProfile preference : preferenceMatch.profiles()) {
            if (metadata.contains(preference.code())) {
                score += 8;
            }

            for (String climateType : preference.climateTypes()) {
                if ("ANY".equals(climateType)) {
                    score += 1;
                } else if (metadata.contains(climateType)) {
                    score += 5;
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
        }

        if (requestedDestination.isPresent()
                && equalsIgnoreCase(place.getCity(), requestedDestination.get())) {
            score += 14;
        }

        if (termMatches(normalizedPrompt, safeText(place.getCity()))) {
            score += 8;
        }

        if (termMatches(normalizedPrompt, safeText(place.getName()))) {
            score += 10;
        }

        for (String keyword : preferenceMatch.detectedKeywords()) {
            if (termMatches(searchableText, keyword)) {
                score += 2;
            }
        }

        if (Boolean.TRUE.equals(place.isFeatured())) {
            score += 1;
        }

        return score;
    }

    private Optional<String> chooseDestination(
            List<ScoredPlace> scoredPlaces,
            PreferenceProfile preference,
            Optional<String> requestedDestination
    ) {
        if (requestedDestination.isPresent()) {
            return requestedDestination;
        }

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
            String destination,
            int maxPlaces,
            boolean strictDestinationOnly
    ) {
        List<ScoredPlace> selectedPlaces = new ArrayList<>();
        Set<Long> selectedIds = new LinkedHashSet<>();

        scoredPlaces.stream()
                .filter(place -> equalsIgnoreCase(
                        place.place().getCity(),
                        destination
                ))
                .limit(maxPlaces)
                .forEach(place -> addSelectedPlace(
                        selectedPlaces,
                        selectedIds,
                        place
                ));

        if (strictDestinationOnly) {
            return selectedPlaces.stream()
                    .limit(maxPlaces)
                    .toList();
        }

        if (selectedPlaces.size() < maxPlaces) {
            scoredPlaces.stream()
                    .filter(place -> place.score() > 0)
                    .limit(maxPlaces * 2L)
                    .forEach(place -> addSelectedPlace(
                            selectedPlaces,
                            selectedIds,
                            place
                    ));
        }

        if (selectedPlaces.isEmpty()) {
            scoredPlaces.stream()
                    .limit(maxPlaces)
                    .forEach(place -> addSelectedPlace(
                            selectedPlaces,
                            selectedIds,
                            place
                    ));
        }

        return selectedPlaces.stream()
                .limit(maxPlaces)
                .toList();
    }

    private void addSelectedPlace(
            List<ScoredPlace> selectedPlaces,
            Set<Long> selectedIds,
            ScoredPlace place
    ) {
        Long id = place.place().getId();

        if (id != null && !selectedIds.add(id)) {
            return;
        }

        if (id == null && selectedPlaces.contains(place)) {
            return;
        }

        selectedPlaces.add(place);
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

    private int durationDays(Integer budget) {
        if (budget == null) {
            return DEFAULT_DURATION_DAYS;
        }

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

    private int estimateBudget(int durationDays) {
        return DEFAULT_DAILY_BUDGET * clampDuration(durationDays);
    }

    private int maxPlacesForDuration(int durationDays) {
        return Math.min(
                MAX_SUGGESTED_PLACES,
                Math.max(3, clampDuration(durationDays) * 2)
        );
    }

    private int clampDuration(int durationDays) {
        return Math.max(1, Math.min(MAX_DURATION_DAYS, durationDays));
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
        List<List<String>> placesByDay = splitPlacesByDay(
                placeNames,
                durationDays
        );
        String returnLocation = "Your location".equals(start)
                ? "your starting point"
                : start;

        for (int day = 1; day <= durationDays; day++) {
            String dayPlaces = joinPlaces(placesByDay.get(day - 1));
            List<String> activities = new ArrayList<>();

            if (day == 1) {
                activities.add("Morning: Travel from " + start + " to "
                        + destination + ".");
                activities.add("Afternoon: Visit " + dayPlaces + ".");
                activities.add("Evening: Explore nearby viewpoints, markets "
                        + "or local food spots.");
            } else if (day == durationDays) {
                activities.add("Morning: Visit " + dayPlaces + ".");
                activities.add("Afternoon: Keep time for lunch, photos and "
                        + "the return journey.");
                activities.add("Evening: Travel back to " + returnLocation
                        + ".");
            } else {
                activities.add("Morning: Visit " + dayPlaces + ".");
                activities.add("Afternoon: Add a relaxed stop for photos, "
                        + "local food or a nearby cultural place.");
                activities.add("Evening: Rest near " + destination + ".");
            }

            days.add(new TourPlanResponse.ItineraryDay(day, activities));
        }

        return days;
    }

    private List<List<String>> splitPlacesByDay(
            List<String> placeNames,
            int durationDays
    ) {
        List<List<String>> placesByDay = new ArrayList<>();
        int index = 0;

        for (int day = 1; day <= durationDays; day++) {
            int remainingPlaces = placeNames.size() - index;
            int remainingDays = durationDays - day + 1;
            int count = remainingPlaces <= 0
                    ? 0
                    : Math.min(
                            2,
                            Math.max(1, (int) Math.ceil(
                                    remainingPlaces / (double) remainingDays
                            ))
                    );

            placesByDay.add(placeNames.subList(index, index + count));
            index += count;
        }

        return placesByDay;
    }

    private String joinPlaces(List<String> placeNames) {
        if (placeNames.isEmpty()) {
            return "recommended nearby attractions";
        }

        return placeNames.stream().collect(Collectors.joining(" and "));
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
            Integer detectedDuration,
            String startingLocation,
            boolean exactPlaceMatch,
            boolean usedInactiveFallback,
            boolean hasNoPlaces,
            int preferenceScore,
            boolean requestedDestinationFound
    ) {
        List<String> notes = new ArrayList<>();

        notes.add("Costs are estimated for planning only. Verify transport, "
                + "tickets and accommodation before travelling.");
        notes.add("Climate matching uses saved place tags and city knowledge, "
                + "not live weather readings.");

        if (detectedBudget == null) {
            if (detectedDuration == null) {
                notes.add("No clear budget was found, so a sample daily "
                        + "budget was used.");
            } else {
                notes.add("No clear budget was found, so a sample budget was "
                        + "estimated from the requested duration.");
            }
        }

        if (detectedDuration == null) {
            if (detectedBudget == null) {
                notes.add("No exact duration was found, so a 2-day sample "
                        + "plan was used.");
            } else {
                notes.add("No exact duration was found, so the planner "
                        + "estimated the number of days from the budget.");
            }
        }

        if ("Your location".equals(startingLocation)) {
            notes.add("Starting location was not clear. Add a city like "
                    + "'starting from Galle' for a better plan.");
        }

        if (hasNoPlaces) {
            notes.add("No historical places are available in the "
                    + "database yet.");
        } else if (requestedDestinationFound && !exactPlaceMatch) {
            notes.add("Only the requested destination city is used for place "
                    + "suggestions. Add places for that city to improve the "
                    + "plan.");
        } else if (preferenceScore == 0) {
            notes.add("No strong trip preference was clear, so the planner "
                    + "used heritage-focused recommendations.");
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
            boolean durationFound,
            boolean startFound,
            boolean exactPlaceMatch,
            boolean destinationFound,
            int preferenceScore
    ) {
        int confidence = 62;

        if (preferenceScore > 0) {
            confidence += Math.min(18, preferenceScore * 2);
        }

        if (destinationFound) {
            confidence += 8;
        }

        if (durationFound) {
            confidence += 7;
        }

        if (budgetFound) {
            confidence += 5;
        }

        if (startFound) {
            confidence += 5;
        }

        if (exactPlaceMatch) {
            confidence += 8;
        } else {
            confidence = Math.min(confidence, 78);
        }

        confidence = Math.max(60, Math.min(95, confidence));
        return confidence + "% Match";
    }

    private String preferenceLabel(PreferenceMatch preferenceMatch) {
        return preferenceMatch.profiles()
                .stream()
                .map(PreferenceProfile::label)
                .distinct()
                .limit(2)
                .collect(Collectors.joining(" + "));
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

    private String searchablePlaceText(HistoricalPlace place) {
        return normalize(
                safeText(place.getName()) + " "
                        + safeText(place.getCity()) + " "
                        + safeText(place.getCategory()) + " "
                        + safeText(place.getClimateType()) + " "
                        + safeText(place.getTravelTags()) + " "
                        + safeText(place.getDescription())
        );
    }

    private boolean termMatches(String text, String term) {
        String normalizedText = " " + normalize(text) + " ";
        String normalizedTerm = normalize(term);

        if (normalizedTerm.isBlank()) {
            return false;
        }

        return normalizedText.contains(" " + normalizedTerm + " ");
    }

    private boolean cityMatches(String text, String city) {
        if (termMatches(text, city)) {
            return true;
        }

        return CITY_ALIASES.getOrDefault(city, List.of())
                .stream()
                .anyMatch(alias -> termMatches(text, alias));
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

    private record PreferenceMatch(
            PreferenceProfile primary,
            List<PreferenceProfile> profiles,
            List<String> detectedKeywords,
            int score
    ) {}

    private record ScoredPreference(
            PreferenceProfile profile,
            int score,
            List<String> detectedKeywords
    ) {}

    private record ScoredPlace(
            HistoricalPlace place,
            int score
    ) {}
}
