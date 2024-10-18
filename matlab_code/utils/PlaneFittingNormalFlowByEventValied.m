function [nflow_array, nflow_points_array] = PlaneFittingNormalFlowByEventValied(points_on_NLTS, Event_valid, windowSize, eventNumPercent, ransecIterNum, ransecErrorThreshold, ransecbestInPercent, flowThreshold)

    validEventsNum = size(Event_valid, 1);

    normal_flow_list = cell(validEventsNum,1);
    nflow_point_list = cell(validEventsNum,1);
    
    points_on_NLTS = points_on_NLTS(:, 1:3);

% ------------ LOOP for Calculate Normal flow -----------------
    tic;
    parfor pixel_i = 1:(validEventsNum)
        t = Event_valid(pixel_i, 1);
        x = Event_valid(pixel_i, 2);
        y = Event_valid(pixel_i, 3);

        neighbour_id = points_on_NLTS(:,2) >= x-windowSize/2 & ...
                points_on_NLTS(:,2) <= x+windowSize/2 & ...
                points_on_NLTS(:,3) >= y-windowSize/2 & ...
                points_on_NLTS(:,3) <= y+windowSize/2;
        events_involved = points_on_NLTS(neighbour_id, :);

        input_size = size(events_involved, 1);
       
        eventNuminWindow = round(windowSize^2 * eventNumPercent);
        if input_size > eventNuminWindow
            
            % RANSEC input
            normEvents = events_involved - [events_involved(1,1), x, y];
            inputA = [normEvents(:,2:3), ones(size(normEvents, 1), 1)];
            inputB = normEvents(:,1);
            
            InitbestInNum = round(input_size * ransecbestInPercent);
            
            [finalCoeff, ~, ~] = RANSAC_raw(inputA, inputB, ransecIterNum, ransecErrorThreshold, InitbestInNum);

            if isempty(finalCoeff)
                continue
            end
            
            % Calculate normal flow
            A_coeff = finalCoeff(1);
            B_coeff = finalCoeff(2);
            flow_xy = A_coeff.^2 + B_coeff.^2;
            nflow = [A_coeff, B_coeff]/flow_xy;
            nflow_point = [t, x, y];

            if flow_xy < flowThreshold
                continue
            end  
            
            normal_flow_list{pixel_i} = nflow;
            nflow_point_list{pixel_i} = nflow_point; % (t, x, y)
        end
    end
    toc

    nflow_array = removeEmptycelltoArray(normal_flow_list);        % (u, v) 
    nflow_points_array = removeEmptycelltoArray(nflow_point_list); % (t, x, y)

    if isempty(nflow_array)
        warning("NO normal flow get!!!")
    end
    
end