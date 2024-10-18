function record = calculateSTRTTC(eventsLoop, cameraParam, gtTTC, args, lastOptimizedResult, epochId)
    
    record = struct('NFlowLowerThanTenPerc', [], 'linearTTC', [], 'nonlinearTTC', [], 'calculationTime', [], 'lastOptimizedResult', [], 'boolAddMoreEvents', false);
    epochTime = getEpochTime(eventsLoop);
    tReference = epochTime.reference_time;

    fx = cameraParam.K(1, 1);
    fy = cameraParam.K(2, 2);
    cx = cameraParam.K(1, 3);
    cy = cameraParam.K(2, 3);

    % Generate positive and negative NLTS
    [NLTS_pos, pos_valid, NLTS_neg, neg_valid, NLTS_time] = NearestLinearTimeSurfacePositiveAndNegative(eventsLoop, epochTime, cameraParam, args.boolUndistort);

    NLTS_neg_filter = medfilt2(NLTS_neg);
    NLTS_neg_filter = imbilatfilt(NLTS_neg_filter);
    NLTS_neg_filter = imgaussfilt3(NLTS_neg_filter, 1);

    NLTS_filter = NLTS_neg_filter;
    TS_valid = neg_valid;

    % Get contour points on NLTS
    [Gx, Gy, Gx_vex, Gy_vec, Event_valid] = GetValidPointonNLTS(NLTS_filter,TS_valid, 1e-5, 1e-3, cameraParam, true, args.validPointsMaxNum);

    if length(Event_valid) < args.validPointsMaxNum
        warning("Event_valid is not enough")
        return
    end

    % ---------- get normal flow by plane fitting ----------
    if args.boolUndistort
        eventsLoop(:, 2:3) = args.undistortMap(sub2ind(cameraParam.ImageSize, eventsLoop(:, 3), eventsLoop(:, 2)), :);
    end

    tic
    [nflow_array, nflow_points_array] = PlaneFittingNormalFlowByEventValied(eventsLoop, Event_valid, ...
        args.windowSize, args.eventNumPercent, args.ransecIterNum, args.ransecErrorThreshold, args.ransecBestInPercent, args.flowThreshold);
    fprintf('PlaneFittingNormalFlowByEventValied time：%.2f s。\n', toc);

    if size(nflow_points_array, 1) < 200
        warning('PlaneFitting Normal flow less than 100')
        record.boolAddMoreEvents = true;
    end

    % ------------------ Linear solver TTC -------------------
    tic
    [Affine_minimal, minimalInlierRatio] = strttc_minimal(nflow_points_array, NLTS_time.reference_time, nflow_array, cameraParam, args.minimalRansecIterNum, args.minimalRansecErrorThreshold, args.minimalRansecBestInPercent);
    linearCostTime = toc;

    calMinimalTTC = 1 / Affine_minimal(1,1);

    % Judge if the linear result is not good enough
    if calMinimalTTC < args.minTTCthreshold || calMinimalTTC > args.maxTTCthreshold
        Affine_minimal = lastOptimizedResult;
        calMinimalTTC = 0;
        fprintf("Linear TTC is not good enough, use last optimized result to refine\n");
    end

    % ------------------ Nonlinear solver TTC -------------------
    tic
    opter_refined = strttc_optimize(Affine_minimal, Event_valid, NLTS_time.reference_time, NLTS_filter, cameraParam, args.robustC);
    nonlinearCostTime = toc;
    calOptimizedTTC = 1 / opter_refined(1,1);

    % Judge if the linear result is not good enough 
    if calOptimizedTTC < args.minTTCthreshold || calOptimizedTTC > args.maxTTCthreshold
        opter_refined = lastOptimizedResult;
        calOptimizedTTC = 1 / opter_refined(1,1);
        fprintf("calOptimizedTTC TTC is not good enough, use last optimized result as output\n");
    end
    
    % ------------------ Save result -------------------
    record.linearTTC = [tReference, calMinimalTTC];
    record.nonlinearTTC = [tReference, calOptimizedTTC, 0];
    record.calculationTime = [tReference, linearCostTime, nonlinearCostTime];

    record.lastOptimizedResult = opter_refined;
    fprintf("GT-TTC:  %.2f, strttc-TTC: %.2f, gt-Init-TTC: %.2f\n", gtTTC, calOptimizedTTC, 0);
    fprintf("---------------------------------------------\n");

end