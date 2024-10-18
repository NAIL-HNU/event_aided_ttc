function minIndex = Find_nearest_index(time_seq, e_ts)
    [~, minIndex] = min(abs(time_seq - e_ts));
end