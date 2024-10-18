clear; 
clc; close all;
root_path = "C:\Users\lijin\Downloads\test\strttc_matlab_ws\";
datasetRootDir = 'C:\Users\lijin\Downloads\test\strttc_matlab_ws\Datasets\FCWD\20240302';

addpath(genpath(root_path));
seqNameList = ["2024-03-02-10-35-27"];

dataType = 'other';

for seq_i = 1:size(seqNameList, 1)

    seqName = seqNameList(seq_i);

    datasetPath = fullfile(datasetRootDir, seqName);

    fprintf('Processing %s\n', datasetPath);

    % Load data
    calib = load(fullfile(datasetRootDir, 'calibration', 'camera_calibration', 'right', 'calibParams.mat'));
    cameraParam = calib.DVScameraParams;
    boxes = readmatrix(fullfile(datasetPath, 'bbox', 'bbox.csv'));
    innerCarBoxes = readmatrix(fullfile(datasetPath, 'bbox', 'innercar_bbox.csv'));

    % reselect innerCarBoxes according to the boxes
    innerCarBoxesStartIdx = Find_nearest_index(innerCarBoxes(:, 1), boxes(1, 1));
    innerCarBoxesEndIdx = Find_nearest_index(innerCarBoxes(:, 1), boxes(end, 1));
    innerCarBoxes = innerCarBoxes(innerCarBoxesStartIdx:innerCarBoxesEndIdx, :);

    if size(innerCarBoxes, 1) ~= size(boxes, 1)
        error('The number of innerCar box is not equal to the number of boxes');
    end

    % load gt TTC
    gtTTC = readmatrix(fullfile(datasetPath, 'ttc', 'gt_ttc.csv'));
    gtTTCStartIdx = Find_nearest_index(gtTTC(:, 1), boxes(1, 1));
    gtTTCEndIdx = Find_nearest_index(gtTTC(:, 1), boxes(end, 1));
    gtTTC = gtTTC(gtTTCStartIdx:gtTTCEndIdx, :);

    % ================ Load events and boxes ================
    eventsDir = fullfile(datasetPath, 'Event', 'right');  
    eventsMsMapIdx = load(fullfile(datasetPath,'eventsMsMapIdx.mat')).eventsMsMapIdx;

    % ==================== Set Parameters ====================
    % process
    timePerEpoch = 0.4;   % s
    gapTime      = 0.05;  % s
    setStartTs   = boxes(1, 2);   % s
    setEndTs     = boxes(end, 2);   % s

    args = struct();
    args.boxes = boxes;
    args.innerCarBoxes = innerCarBoxes;

    %% ------- calculationType: 'strttc', 'cmax', 'cmaxWithOurInit' -------
    args.calculationType = 'strttc';
    args.robustC = 0.04;
    % load by box size STRTTC
    args.widthExpect = 20;
    args.heightExpect = 20;

    %  fix number of events CMax
    args.fixedEventsNumber = 200000;
    %% ------- calculationType: 'strttc', 'cmax', 'cmaxWithOurInit' -------
    args.boolPlotNormalFlow = false;
    args.validPointsMaxNum = 2000;
    args.boolUndistort = true;
    args.boolGtFlowExist = false;
    args.minTTCthreshold = 0.1;
    args.maxTTCthreshold = 3.5;

    % plane fitting
    args.windowSize = 8;
    args.eventNumPercent = 0.5;
    args.ransecIterNum = 1000;
    args.ransecErrorThreshold = 1e-3;
    args.ransecBestInPercent = 0.6;
    args.flowThreshold =1e-4;

    % linear TTC
    args.minimalRansecIterNum = 1000;
    args.minimalRansecErrorThreshold = 1e-3;
    args.minimalRansecBestInPercent = 0.4;

    args.sequenceName = seqName;

    % ==================== Set Parameters ====================
    loopTimeStruct = initLoopTimeStruct(eventsMsMapIdx, timePerEpoch, gapTime, setStartTs, setEndTs, args);

    % undistorted map
    if args.boolUndistort
        undistortMap = loadUndistortEventsMap(fullfile(datasetRootDir, 'calibration', 'camera_calibration', 'right'), cameraParam);
        args.undistortMap = undistortMap;
    end

    % mkdir for data saving
    args.saveResultDir = fullfile(datasetPath, 'saveResult');
    mkdir(args.saveResultDir);
    switch args.calculationType
        case 'strttc'
            args.boolFixEventsNumber = false;
            args.saveStrttcDir = fullfile(datasetPath, 'saveResult', 'strttc');
            if exist(args.saveStrttcDir)
                rmdir(args.saveStrttcDir, 's');
            end
            mkdir(args.saveStrttcDir)
    end

    % set result
    result = struct('NFlowLowerThanTenPerc', [], 'linearTTC', [], 'nonlinearTTC', []);
    result.gtTTC = gtTTC;

    % init lastOptimizedResult
    strttclastOptimizedResult          = [0; 0; 0];
    cmaxlastOptimizedResult            = [0; 0; 0];
    cmaxWithOurInitlastOptimizedResult = [0; 0; 0];

    % ==================== MAIN LOOP ============================

    while ~loopTimeStruct.boolLoopEnd
        
        fprintf(strcat("------ Start epoch: (", string(loopTimeStruct.epochId), "), Events id: (", string(loopTimeStruct.EventStartId), ")--(", string(loopTimeStruct.EventEndId), "), Events number: (", string(loopTimeStruct.EventNum), ") -------- \n"));
        eventsLoop = loadEventsFromTxtInBBox(eventsDir, loopTimeStruct, args.boxes, args.innerCarBoxes);
        epochTime = getEpochTime(eventsLoop);

        gtTTCTimeList = result.gtTTC(:, 2);
        gtTTCInd = Find_nearest_index(gtTTCTimeList, epochTime.reference_time);
        inputGtTTC = result.gtTTC(gtTTCInd, :);
        fprintf(strcat("GT TTC: (", string(inputGtTTC(2)), "), GT TTC time: (", string(inputGtTTC(5)), ")\n"));     
        
        switch args.calculationType
            case 'strttc'
                % -------------- Calculate TTC Using STRTTC ----------------
                strttcResult = calculateSTRTTC(eventsLoop, cameraParam, inputGtTTC(1, 5), args, strttclastOptimizedResult, loopTimeStruct.epochId);
                strttclastOptimizedResult = strttcResult.lastOptimizedResult;

                % log result
                result.strttcLinearTTC(loopTimeStruct.epochId, :) = strttcResult.linearTTC;            %  [tReference, calMinimalTTC]    
                result.strttcNonlinearTTC(loopTimeStruct.epochId, :) = strttcResult.nonlinearTTC;      %  [tReference, calOptimizedTTC, calGTOptimizedTTC];
                result.strttcTimeCost(loopTimeStruct.epochId, :) = strttcResult.calculationTime;       %  [tReference, linearCostTime, nonlinearCostTime];
        end


        % save events size
        result.loopEventSize(loopTimeStruct.epochId, :) = [epochTime.reference_time,  size(eventsLoop, 1)];
                
        % -------------- Reselect events to computition -------------
        loopTimeStruct = updataLoopTimeStruct(loopTimeStruct, eventsMsMapIdx, args);

    end

    result = plotSimpleResult(result, args, loopTimeStruct);

end
    


function loopTimeStruct = initLoopTimeStruct(eventsMsMapIdx, timePerEpoch, gapTime, setStartTs, setEndTs, args)
    loopTimeStruct = struct();
    loopTimeStruct.timePerEpoch = timePerEpoch;  % s
    loopTimeStruct.gapTime = gapTime;       % s
    loopTimeStruct.setEpochId = 1;
    loopTimeStruct.setStartTs = setStartTs;   % s
    loopTimeStruct.setEndTs = setEndTs;   % s
    loopTimeStruct.epochId = loopTimeStruct.setEpochId;
    % for bbox update method

    boxesList = args.boxes;
    nearestBoxInd = Find_nearest_index(boxesList(:, 2), loopTimeStruct.setStartTs);
    
    boxStart = boxesList(nearestBoxInd, :);
    boxEnd = findExpectNextBox(boxStart, boxesList, args.widthExpect, args.heightExpect);
    loopTimeStruct.epochStartTs = boxStart(1, 2);
    loopTimeStruct.epochEndTs = boxEnd(1, 2);
    loopTimeStruct.EventStartId = double(eventsMsMapIdx(int64(loopTimeStruct.epochStartTs*1e3)+1, 1));      % +1 because the matlab index start from 1
    loopTimeStruct.EventEndId   = double(eventsMsMapIdx(int64(loopTimeStruct.epochEndTs*1e3)+1, 1));        % +1 because the matlab index start from 1
    loopTimeStruct.EventNum = loopTimeStruct.EventEndId - loopTimeStruct.EventStartId;
    loopTimeStruct.boolLoopEnd = false;
    loopTimeStruct.boxStart = boxStart;
    loopTimeStruct.boxEnd = boxEnd;
    loopTimeStruct.boolAddMoreEventInEpoch = false;
end


function loopTimeStruct = updataLoopTimeStruct(loopTimeStruct, eventsMsMapIdx, args)
    loopTimeStruct.epochId = loopTimeStruct.epochId + 1;
    loopTimeStruct.epochStartTs = loopTimeStruct.epochStartTs + loopTimeStruct.gapTime; 

    if ~args.boolFixEventsNumber
        boxesList = args.boxes;
        nearestBoxInd = Find_nearest_index(boxesList(:, 2), loopTimeStruct.epochStartTs);
        
        boxStart = boxesList(nearestBoxInd, :);
        boxEnd = findExpectNextBox(boxStart, boxesList, args.widthExpect, args.heightExpect);
        loopTimeStruct.epochStartTs = boxStart(1, 2);
        loopTimeStruct.epochEndTs = boxEnd(1, 2);

        if loopTimeStruct.epochEndTs < loopTimeStruct.setEndTs-0.1  % 0.1s for func loadEventsFromTxtInBBoxFixedNum "txtNameEndIdx = txtNameStartIdx + 100;" out of range
            % if epochStartTsInMS+1 < length(eventsMsMapIdx) && epochEndTsInMs+1 < length(eventsMsMapIdx) 
            loopTimeStruct.EventStartId = double(eventsMsMapIdx(int64(loopTimeStruct.epochStartTs*1e3)+1, 1));      % +1 because the matlab index start from 1
            loopTimeStruct.EventEndId   = double(eventsMsMapIdx(int64(loopTimeStruct.epochEndTs*1e3)+1, 1));        % +1 because the matlab index start from 1 
            loopTimeStruct.EventNum = loopTimeStruct.EventEndId - loopTimeStruct.EventStartId;
            loopTimeStruct.boolLoopEnd = false;
        else
            loopTimeStruct.boolLoopEnd = true;
            return
        end
    
    else  % fix event number
        if loopTimeStruct.epochStartTs < loopTimeStruct.setEndTs-0.1  % 0.1s for func loadEventsFromTxtInBBoxFixedNum "txtNameEndIdx = txtNameStartIdx + 100;" out of range
            loopTimeStruct.EventStartId = double(eventsMsMapIdx(int64(loopTimeStruct.epochStartTs*1e3)+1, 1));      % +1 because the matlab index start from 1
            loopTimeStruct.EventEndId   = double(eventsMsMapIdx(int64(loopTimeStruct.epochEndTs*1e3)+1, 1));        % +1 because the matlab index start from 1 
            loopTimeStruct.EventNum = loopTimeStruct.EventEndId - loopTimeStruct.EventStartId;
            loopTimeStruct.boolLoopEnd = false;
        else
            loopTimeStruct.boolLoopEnd = true;
            return
        end
    end
    
end

function eventsRaw = loadEventsFromTxtInBBox(events_dir, loopTimeStruct, boxes, innerCarBoxes)

    txtNameStartIdx = int64(loopTimeStruct.epochStartTs*1e3 + 1);  % +1 because the 0005.txt saves the events from 4 to 5 ms, so the start text name should be 6 to get 5 to 6 ms events
    txtNameEndIdx   = int64(loopTimeStruct.epochEndTs*1e3);

    eventsRawList = cell(length(txtNameStartIdx:txtNameEndIdx), 1);

    parfor event_i = txtNameStartIdx:txtNameEndIdx
        txtName = strcat(num2str(event_i, '%08d'), '.txt');
        events_sub = readmatrix(fullfile(events_dir, txtName));

        boxIdx = findBiggerIndex(boxes(:,2), events_sub(end, 1));
        box = boxes(boxIdx, 3:6);

        width = box(3) -  box(1);
        removeWidth = width*0.08;
        box(1) = box(1) + removeWidth;
        box(3) = box(3) - removeWidth;

        inliner_id = events_sub(:, 2) > box(1) & events_sub(:, 2) < box(3) & events_sub(:, 3) > box(2) & events_sub(:, 3) < box(4);
        events_sub = events_sub(inliner_id, :);

        innerCarBoxIdx = innerCarBoxes(boxIdx, 3:6);
        inliner_id = events_sub(:, 2) > innerCarBoxIdx(1) & events_sub(:, 2) < innerCarBoxIdx(3) & events_sub(:, 3) > innerCarBoxIdx(2) & events_sub(:, 3) < innerCarBoxIdx(4);
        events_sub = events_sub(~inliner_id, :);

        eventsRawList{event_i} = events_sub;
    end
    eventsRaw = cat(1,eventsRawList{:});
    eventsRaw(eventsRaw(:,4)==0, 4) = -1;
    eventsRaw(:, 2:3) = eventsRaw(:, 2:3) + 1;

    loopTimeStruct.epochEndTs = eventsRaw(end, 1);

end


function boxEnd = findExpectNextBox(boxStart, boxes, widthExpect, heightExpect)
    box = boxStart(1, 3:6);
    boxesWidth = boxes(:, 5) - boxes(:, 3);
    boxesHeight = boxes(:, 6) - boxes(:, 4);
    width = box(3) -  box(1);
    height = box(4) -  box(2);

    nextWidthIdx =  Find_nearest_index(boxesWidth, width + 2*widthExpect);
    nextHeightIdx = Find_nearest_index(boxesHeight, height + 2*heightExpect);

    boxEndIdx = max(nextWidthIdx, nextHeightIdx);
    boxEnd = boxes(boxEndIdx, :);
end