function [Affine_minimal, inlierRatio] = strttc_minimal(events_txy, t_reference, nflow, camera_param, num_iter, ransec_threshold, InitNum_percent)
    %MYFUNCTION
    % events_txy: [t, x, y] format, on image plane
    % t_reference: reference time
    % nflow: normal flow on image plane and is the projection of the pixel's true travel distance onto the image gradient
    
        if size(events_txy, 1) ~= size(nflow, 1)
            error('Events length should be equal to nflow')
        end
        % Get A B for RANSEC
        [A, b] = constructA_b(events_txy, t_reference, nflow, camera_param);
    
        [Affine_minimal, ~, inlierRatio] = RANSAC_raw(A, b, num_iter, ransec_threshold, round(size(events_txy, 1)*InitNum_percent));
    
        if isempty(Affine_minimal)
            error('Affine_minimal is  empty');
        end
    end