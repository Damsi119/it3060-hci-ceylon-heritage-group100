package com.ceylonheritage.backend.controller;

import com.ceylonheritage.backend.Dtos.GuideDto;
import com.ceylonheritage.backend.service.GuideService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
public class GuideRequestController {

    private final GuideService guideService;

    public GuideRequestController(GuideService guideService) {
        this.guideService = guideService;
    }


    @PostMapping("/api/guide-requests")
    public ResponseEntity<GuideDto.GuideProfileResponse> submitGuideRequest(
            @Valid @RequestBody GuideDto.GuideApplicationRequest request
    ) {

        return ResponseEntity.ok(
                guideService.submitGuideRequest(request)
        );
    }


    @GetMapping("/api/guides/approved")
    public ResponseEntity<List<GuideDto.GuideProfileResponse>> getApprovedGuides() {

        return ResponseEntity.ok(
                guideService.getApprovedGuides()
        );
    }
}
