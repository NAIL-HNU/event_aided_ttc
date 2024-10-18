
function [finalCoeff, bestInlierIdx, inlierRatio] = RANSAC_raw(inputA, inputB, numIter, threshold, bestInNum)
    
    oneIterPointNum = 12;
    bestInlierIdx = [];
    
    if size(inputA, 1) ~= size(inputB, 1)
        error("Length of A, B should be equal!")
    end

    for i = 1:numIter
        rand_id = randperm(size(inputA, 1), oneIterPointNum);
        
        A_sample = inputA(rand_id, :);
        b_sample = inputB(rand_id, :);

        coeff_sample = A_sample\b_sample;

        errorVec = inputA * coeff_sample - inputB;
        errorValue = errorVec .* errorVec;

        % Get inlier points
        inlierIdx = find(errorValue < threshold);
        inNum = length(inlierIdx);
        
        % Update best plane fitting result
        if inNum > bestInNum
            bestInNum = inNum;
            bestCoeff = coeff_sample;
            bestInlierIdx = inlierIdx;
        end
    end

    if ~isempty(bestInlierIdx)
        A_inliers = inputA(bestInlierIdx,:);
        b_inliers = inputB(bestInlierIdx,:);
        finalCoeff = A_inliers\b_inliers;
        inlierRatio = bestInNum/size(inputA, 1);
    else
        finalCoeff = [];
        bestInlierIdx = [];
        inlierRatio = [];
    end

end