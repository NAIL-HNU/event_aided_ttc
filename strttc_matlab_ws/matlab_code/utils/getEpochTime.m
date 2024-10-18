function epoch_time = getEpochTime(eventsRaw)
    % Update epoch_time
    epoch_time = struct();
    epoch_time.max_time = max(eventsRaw(:, 1));
    epoch_time.min_time = min(eventsRaw(:, 1));
    epoch_time.time_diff = (epoch_time.max_time - epoch_time.min_time);
    epoch_time.reference_time = epoch_time.max_time - epoch_time.time_diff/ 2;
    fprintf(strcat("Epoch reference time: (", string(epoch_time.reference_time), ")  Epoch Min time: (", string(epoch_time.min_time), ") Max time: (", string(epoch_time.max_time), ")  \n"));
end