package com.ceylonheritage.backend.controller;

import com.ceylonheritage.backend.Dtos.GuideDto;
import com.ceylonheritage.backend.enums.GuideApplicationStatus;
import com.ceylonheritage.backend.service.GuideService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/guides")
@PreAuthorize("hasRole('ADMIN')")
public class AdminGuideController {

    private final GuideService guideService;

    public AdminGuideController(
            GuideService guideService
    ) {
        this.guideService = guideService;
    }


    @GetMapping
    public ResponseEntity<List<GuideDto.GuideProfileResponse>>
    getGuidesByStatus(
            @RequestParam GuideApplicationStatus status
    ) {

        return ResponseEntity.ok(
                guideService.getGuidesByStatus(status)
        );
    }


    @PutMapping("/{guideProfileId}/review")
    public ResponseEntity<GuideDto.GuideProfileResponse> reviewGuide(
            Authentication authentication,
            @PathVariable Long guideProfileId,
            @Valid @RequestBody GuideDto.GuideReviewRequest request
    ) {

        return ResponseEntity.ok(
                guideService.reviewGuide(
                        authentication.getName(),
                        guideProfileId,
                        request
                )
        );
    }
}

