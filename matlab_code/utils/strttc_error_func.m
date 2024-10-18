function F = strttc_error_func(x_p, events_txy, t_reference, NLTS, camera_param, robust_c)
    initValue = max(events_txy(:, 1) - t_reference);
    
    F = initValue * ones(1, size(events_txy, 1));
    
    [warp_event] = str_warping(events_txy(:, 2:3), events_txy(:, 1), t_reference, x_p, camera_param);
    
    warp_event_floor = floor(warp_event);
    warp_event_ceil  = warp_event_floor + [1, 1];
    inside_id = warp_event_floor(:, 1) > 1 & warp_event_ceil(:, 1) < camera_param.ImageSize(2) &...
                warp_event_floor(:, 2) > 1 & warp_event_ceil(:, 2) < camera_param.ImageSize(1);
    warp_event = warp_event(inside_id, :);
    warp_event_floor = warp_event_floor(inside_id, :);
    warp_event_ceil = warp_event_ceil(inside_id, :);
    
    min_x_min_y = NLTS(sub2ind(camera_param.ImageSize, warp_event_floor(:, 2), warp_event_floor(:, 1)));
    min_x_max_y = NLTS(sub2ind(camera_param.ImageSize, warp_event_ceil(:, 2),  warp_event_floor(:, 1)));
    max_x_min_y = NLTS(sub2ind(camera_param.ImageSize, warp_event_floor(:, 2), warp_event_ceil(:, 1)));
    max_x_max_y = NLTS(sub2ind(camera_param.ImageSize, warp_event_ceil(:, 2),  warp_event_ceil(:, 1)));

    error_min_x = (warp_event_ceil(:, 2) - warp_event(:, 2)) .* min_x_min_y + (warp_event(:, 2) - warp_event_floor(:, 2)) .* min_x_max_y;
    error_max_x = (warp_event_ceil(:, 2) - warp_event(:, 2)) .* max_x_min_y + (warp_event(:, 2) - warp_event_floor(:, 2)) .* max_x_max_y;
    F(1, inside_id') = (warp_event_ceil(:, 1) - warp_event(:, 1)) .* error_min_x + (warp_event(:, 1) - warp_event_floor(:, 1)) .* error_max_x;

    robust_scale = sqrt(1 ./ (1 + (F .* F ./ robust_c)));
    F = F .* robust_scale;
    
end