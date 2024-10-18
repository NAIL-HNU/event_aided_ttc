function  CellArray = removeEmptycelltoArray(cell_list)
    nonEmptyIndex = ~cellfun(@isempty, cell_list);
    filteredCellArray = cell_list(nonEmptyIndex);
    CellArray = cat(1,filteredCellArray{:});
end