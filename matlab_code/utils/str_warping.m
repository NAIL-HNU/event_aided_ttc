function [warp_event] = str_warping(event, t_list, t_reference, affine_model, intrinsics)
    fx = intrinsics.K(1, 1);
    fy = intrinsics.K(2, 2);
    cx = intrinsics.K(1, 3);
    cy = intrinsics.K(2, 3);

    normalized_event = event;
    normalized_event(:, 1) = (normalized_event(:, 1) - cx) / fx;
    normalized_event(:, 2) = (normalized_event(:, 2) - cy) / fy;
    
    warp_event = (-affine_model(1) * normalized_event + affine_model(2:3)') .* (t_list - t_reference) + normalized_event; % eq(4)

    warp_event(:, 1) = fx * warp_event(:, 1) + cx;
    warp_event(:, 2) = fy * warp_event(:, 2) + cy;
    
end 
