function [Gx, Gy, Gx_vex, Gy_vec, Event_valid] = GetValidPointonNLTS(NLTS_filter,TS_valid, fir_thres, sec_thres, camera_param, is_gradient_sampling, max_size)
    
    [Gx,Gy] = imgradientxy(NLTS_filter / 8, 'sobel');
    [Gxx_sec,Gxy_sec] = imgradientxy(Gx / 8, 'sobel');
    [Gyx_sec,Gyy_sec] = imgradientxy(Gy / 8, 'sobel');
    
    G_fir = Gx.^2 + Gy.^2;
    G_sec = Gxx_sec.^2 + Gxy_sec.^2 + Gyx_sec.^2 + Gyy_sec.^2;
    
    [y_id,x_id] = find(G_fir > fir_thres & G_sec < sec_thres & TS_valid ~= 0);
    
    t = NLTS_filter(sub2ind(camera_param.ImageSize, y_id, x_id));  % Catuion
    Event_valid = [t, x_id, y_id];

    t_id = find(t > 100);
    if size(t_id, 1) > 0
        Event_valid(t_id,:) = [];
        y_id(t_id,:) = [];
        x_id(t_id,:) = [];
        disp("Event_valid have outliner point")
    end

    Gx_vex = Gx(sub2ind(camera_param.ImageSize, y_id, x_id));
    Gy_vec = Gy(sub2ind(camera_param.ImageSize, y_id, x_id));

    if is_gradient_sampling
        % 1 | 2
        % 4 | 3
        min_x_id = Gx_vex < 0;
        max_x_id = Gx_vex > 0;
        min_y_id = Gy_vec < 0;
        max_y_id = Gy_vec > 0;
    
        id_1 = find(min_x_id & min_y_id); 
        id_2 = find(max_x_id & min_y_id);
        id_3 = find(max_x_id & max_y_id);
        id_4 = find(min_x_id & max_y_id);
        
        id_id_1 = randperm(size(id_1, 1), min(max_size / 4, size(id_1, 1)));
        id_id_2 = randperm(size(id_2, 1), min(max_size / 4, size(id_2, 1)));
        id_id_3 = randperm(size(id_3, 1), min(max_size / 4, size(id_3, 1)));
        id_id_4 = randperm(size(id_4, 1), min(max_size / 4, size(id_4, 1)));

        id = [id_1(id_id_1); id_2(id_id_2); id_3(id_id_3); id_4(id_id_4)];
        Event_valid = Event_valid(id, :);
        Gx_vex = Gx_vex(id, :);
        Gy_vec = Gy_vec(id, :);
    else
        id = randperm(size(Event_valid, 1), min(max_size, size(Event_valid, 1)));
        Event_valid = Event_valid(id, :);
        Gx_vex = Gx_vex(id, :);
        Gy_vec = Gy_vec(id, :);
    end

end