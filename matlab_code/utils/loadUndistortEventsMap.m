function undistortMap = loadUndistortEventsMap(calibFilePath, cameraParams)
%% Function to load events from txt or mat file

    if exist(fullfile(calibFilePath, 'undistortMap.mat'), 'file') == 2
        disp('Load undistortMap from mat file');
        loadValue = load(fullfile(calibFilePath, 'undistortMap.mat'));
        undistortMap = loadValue.undistortMap;
    else
        disp('Generate undistortMap');
        undistortMap = calculateUndistortEventsMap(calibFilePath, cameraParams);
    end
end