function sims = calcBinCharSimSubfolders( folderpath )

foldercontents = dir( folderpath );
foldercontents(1:2, :) = [];

foldercontents = struct2cell(foldercontents)';
isdir = cell2mat( foldercontents(:, 5) );
foldercontents = foldercontents(isdir, :);
nSubfolders = size(foldercontents, 1);

funcs = {@iou, @regCharacter};

sims = cell(nSubfolders, 3);

for i = 1:nSubfolders
    sims{i, 2} = foldercontents{i, 1};
    fprintf('[%d / %d] : %s\n', i, nSubfolders, sims{i, 2})
    [sims{i, 1}, sims{i, 3}] = calcBinCharSimFolder( fullfile(folderpath, sims{i, 2}), funcs );
end