function firstLargeValueIdx = findBiggerIndex(array, value)
    firstLargeValueIdx = find((array - value)>0, 1, "first");
end