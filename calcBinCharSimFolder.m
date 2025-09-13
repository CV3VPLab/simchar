function [sim, names] = calcBinCharSimFolder( folderpath, funcs, invert, direction )
% need two function handles ( similarity function, registration function )
% direction : {'unidir', 'bidir'}

if nargin < 2
    funcs = {@iou, @regCharacter};
end
if nargin < 3
    invert = true;
end
if nargin < 4
    direction = 'unidir';
end

files = listImageFiles( folderpath );
[~, names, ext] = cellfun(@fileparts, files, 'UniformOutput', false);

nImgs = length(files);

img = imread( fullfile( folderpath, strcat(names{1}, ext{1}) ) );
imgsz = size(img);
assert( length(imgsz) == 2 ); % 2-d check

imgs = false( [imgsz, nImgs] );

parfor i = 1:nImgs
    names{i} = strcat(names{i}, ext{i});
    img = imread( fullfile( folderpath, names{i} ) );
    if ~isa( img, 'logical' )
        img = logical(img);
    end
    if invert
        img = ~img;
    end
    imgs(:, :, i) = img;
end

sim = zeros( nImgs );

if strcmp( direction, 'bidir' )
    imgs2sz = [imgsz, nImgs-1];
    parfor i = 1:nImgs
        imgs1 = repmat( imgs(:,:,i), 1, 1, nImgs-1 );
        imgs2 = false( imgs2sz );
        %imgs3 = imgs; imgs3(:,:,i) = [];
        k = 1;
        for j = 1:nImgs
            if j == i, continue; end
            imgs2(:,:,k) = funcs{2}( imgs(:,:,i), imgs(:,:,j) );
            k = k + 1;
        end
        %figure, imshow( double([imgs1, imgs3, imgs2]) )
        s = funcs{1}(imgs1, imgs2);
        s1 = [s(1:(i-1)), 0, s(i:end)];
        sim(i, :) = s1;
    end
    
    sim = (sim + sim') / 2;
else
    parfor i = 1:nImgs
        imgs1 = repmat( imgs(:,:,i), 1, 1, nImgs-i );
        imgs2 = imgs(:,:, (i+1):end);
        for j = 1:(nImgs-i)
            imgs2(:,:,j) = funcs{2}( imgs(:,:,i), imgs2(:,:,j) );
        end
        s = [zeros(1,i), funcs{1}(imgs1, imgs2)];
        sim(i, :) = s;
    end

    sim = sim + sim';
end






