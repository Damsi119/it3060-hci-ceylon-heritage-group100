package com.ceylonheritage.backend.service;

import com.ceylonheritage.backend.Dtos.GuideDto;
import com.ceylonheritage.backend.enums.GuideApplicationStatus;

import java.util.List;

public interface GuideService {

    GuideDto.GuideProfileResponse submitGuideRequest(
            GuideDto.GuideApplicationRequest request
    );

    List<GuideDto.GuideProfileResponse> getGuidesByStatus(
            GuideApplicationStatus status
    );

    List<GuideDto.GuideProfileResponse> getApprovedGuides();

    GuideDto.GuideProfileResponse getGuideRequestStatus(
            String email,
            String phone
    );

    GuideDto.GuideProfileResponse reviewGuide(
            String adminUsername,
            Long guideProfileId,
            GuideDto.GuideReviewRequest request
    );
}
