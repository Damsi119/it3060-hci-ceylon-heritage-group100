package com.ceylonheritage.backend.service;

import com.ceylonheritage.backend.Dtos.TourPlanGenerateRequest;
import com.ceylonheritage.backend.Dtos.TourPlanResponse;

public interface TourPlanService {

    TourPlanResponse generatePlan(TourPlanGenerateRequest request);
}
