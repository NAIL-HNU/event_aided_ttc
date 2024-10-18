function  opter_refined = strttc_optimize(initial_minimal, events_txy, t_reference, NLTS, camera_param, robust_c)
    OPTIONS = optimoptions('lsqnonlin','Algorithm','levenberg-marquardt','Display','none','SpecifyObjectiveGradient',false);
    
    [opter_refined] = lsqnonlin(@(x)strttc_error_func(x, events_txy, t_reference, NLTS, camera_param, robust_c), initial_minimal ,[],[],OPTIONS);
end