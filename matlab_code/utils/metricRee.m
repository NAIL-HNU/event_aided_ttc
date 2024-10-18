function ree = metricRee(gt_ttc, cal_ttc)

    ree = 100 * abs(gt_ttc - cal_ttc) ./ abs(gt_ttc);

end


