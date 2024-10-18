function [A, b] = constructA_b(event_data, t_reference, nflow, intrinsics)
%MYFUNCTION
% event_data: [t, x, y] format, and on image plane
% t_reference: reference time
% nflow: normal flow on image plane and is the projection of the pixel's true travel distance onto the image gradient

    fx = intrinsics.K(1, 1);
    fy = intrinsics.K(2, 2);
    cx = intrinsics.K(1, 3);
    cy = intrinsics.K(2, 3);
    A = [];
    b = [];

    for i = 1:size(event_data, 1)
        
        tk = event_data(i, 1) - t_reference;
        x  = event_data(i, 2);
        y  = event_data(i, 3);

        dx = nflow(i, 1) / fx;
        dy = nflow(i, 2) / fy;
        
        xk = (x - cx) / fx;
        yk = (y - cy) / fy;
        
        A_single = [tk*(dx^2 + dy^2) - xk*dx - yk*dy,  -dx, -dy];
        b_single = -(dx^2 + dy^2);

        A = [A ;A_single];
        b = [b ;b_single];
    end
end