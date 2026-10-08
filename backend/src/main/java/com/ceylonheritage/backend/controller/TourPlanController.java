package com.ceylonheritage.backend.controller;

import com.ceylonheritage.backend.Dtos.TourPlanGenerateRequest;
import com.ceylonheritage.backend.Dtos.TourPlanResponse;
import com.ceylonheritage.backend.service.TourPlanService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/tour-planner")
public class TourPlanController {

    private final TourPlanService tourPlanService;

    public TourPlanController(TourPlanService tourPlanService) {
        this.tourPlanService = tourPlanService;
    }

    @PostMapping("/generate")
    public ResponseEntity<TourPlanResponse> generatePlan(
            @Valid @RequestBody TourPlanGenerateRequest request
    ) {
        return ResponseEntity.ok(tourPlanService.generatePlan(request));
    }
}
