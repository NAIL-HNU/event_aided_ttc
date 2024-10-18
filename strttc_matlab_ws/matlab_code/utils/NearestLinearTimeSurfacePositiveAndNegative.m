function [NLTS_positive_undistored, NLTS_positive_count_undistored, NLTS_negative_undistored, NLTS_negative_count_undistored, NLTS_time] = NearestLinearTimeSurfacePositiveAndNegative(event_raw, epoch_time, camera_param, bool_undistort)

    event_raw(:, 1)  = event_raw(:, 1) - epoch_time.reference_time; 
    NLTS_time.max_time = max(event_raw(:, 1));
    NLTS_time.min_time = min(event_raw(:, 1));
    NLTS_time.time_diff = (NLTS_time.max_time - NLTS_time.min_time);
    NLTS_time.reference_time = NLTS_time.max_time - NLTS_time.time_diff/ 2;
    
    NLTS_positive = epoch_time.time_diff / 2 * ones(camera_param.ImageSize);
    NLTS_positive_count = zeros(camera_param.ImageSize);

    NLTS_negative = epoch_time.time_diff / 2 * ones(camera_param.ImageSize);
    NLTS_negative_count = zeros(camera_param.ImageSize);

    for event_i = 1:size(event_raw, 1)
        e_t = event_raw(event_i, 1);
        e_x = event_raw(event_i, 2);
        e_y = event_raw(event_i, 3);
        e_p = event_raw(event_i, 4);

        if e_p == 1
            if NLTS_positive_count(e_y, e_x) == 0 % if there is no events beffore
                NLTS_positive(e_y, e_x) = e_t;
                NLTS_positive_count(e_y, e_x) = 1;
            else
                if abs(NLTS_positive(e_y, e_x)) > abs(e_t)
                    if abs(e_t) == 0
                        NLTS_positive(e_y, e_x) = 1e-10;
                    else
                        NLTS_positive(e_y, e_x) = e_t;
                    end
                end
            end
        else
            if NLTS_negative_count(e_y, e_x) == 0 % if there is no events beffore
                NLTS_negative(e_y, e_x) = e_t;
                NLTS_negative_count(e_y, e_x) = 1;
            else
                if abs(NLTS_negative(e_y, e_x)) > abs(e_t)
                    if abs(e_t) == 0
                        NLTS_negative(e_y, e_x) = 1e-10;
                    else
                        NLTS_negative(e_y, e_x) = e_t;
                    end
                end
            end
        end
    end

    % undistored image
    if bool_undistort
        NLTS_positive_undistored = undistortImage(NLTS_positive, camera_param);
        NLTS_positive_count_undistored = undistortImage(NLTS_positive_count, camera_param);
        NLTS_negative_undistored = undistortImage(NLTS_negative, camera_param);
        NLTS_negative_count_undistored = undistortImage(NLTS_negative_count, camera_param);
    else
        NLTS_positive_undistored = NLTS_positive;
        NLTS_positive_count_undistored = NLTS_positive_count;
        NLTS_negative_undistored = NLTS_negative;
        NLTS_negative_count_undistored = NLTS_negative_count;
    end
end