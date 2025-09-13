function files = listImageFiles(folder, varargin)
% listImageFiles  폴더 내 이미지 파일 경로 목록을 반환
%   files = listImageFiles(folder)                % 하위 폴더 미포함
%   files = listImageFiles(folder, 'Recursive', true)  % 하위 폴더 포함
%
% 반환값:
%   files : 1xN cell array (각 요소는 이미지 파일의 전체 경로)
%
% 비고:
%   - 우선적으로 imageDatastore를 사용해 MATLAB이 인식하는 이미지 포맷을 모두 수집합니다.
%   - imageDatastore가 없거나 문제가 있을 경우, imformats로 확장자를 얻어 수동 필터링합니다.

    % ---- 입력 파서 ----
    p = inputParser;
    addRequired(p, 'folder', @(s) ischar(s) || isstring(s));
    addParameter(p, 'Recursive', false, @(x) islogical(x) && isscalar(x));
    parse(p, folder, varargin{:});
    folder = char(p.Results.folder);
    recursive = p.Results.Recursive;

    if ~(exist(folder, 'dir') == 7)
        error('지정한 경로가 폴더가 아닙니다: %s', folder);
    end

    % ---- 1) 권장 경로: imageDatastore 사용 ----
    try
        % MATLAB이 인식하는 이미지 확장자를 자동으로 포함
        imds = imageDatastore(folder, 'IncludeSubfolders', recursive);
        files = imds.Files(:).';
        return;
    catch
        % imageDatastore가 없는 경우나 에러 시, 수동 경로로 진행
    end

    % ---- 2) 대안: imformats + dir 수동 수집 ----
    % 지원 확장자 추출 (imformats 구조체의 ext 필드를 펼침)
    exts = {};
    try
        fmts = imformats;
        for k = 1:numel(fmts)
            e = fmts(k).ext;  % char 또는 cell일 수 있음
            if ischar(e)
                exts{end+1} = lower(strrep(e, '.', '')); %#ok<AGROW>
            elseif iscell(e)
                exts = [exts, lower(strrep(e(:).', '.', ''))]; %#ok<AGROW>
            end
        end
    catch
        % 최소한의 일반 포맷들(필요 시 여기 추가하세요)
        exts = {'jpg','jpeg','png','tif','tiff','bmp','gif','jp2','j2k','pnm','pbm','pgm','ppm','webp','heic','heif','ico'};
    end
    exts = unique(exts);

    % 파일 나열 후 확장자 기반 필터 (대소문자 무시)
    pattern = recursive * "**" + "*";  % trick: 논리값*문자열은 MATLAB에서 X
    if recursive
        listing = dir(fullfile(folder, '**', '*'));
    else
        listing = dir(fullfile(folder, '*'));
    end
    listing = listing(~[listing.isdir]);  % 폴더 제외

    files = {};
    for i = 1:numel(listing)
        f = fullfile(listing(i).folder, listing(i).name);
        [~, ~, ext] = fileparts(f);      % .jpg 형태
        if ~isempty(ext)
            ext = lower(ext(2:end));     % 'jpg'
            if ismember(ext, exts)
                files{end+1} = f; %#ok<AGROW>
            end
        end
    end

    files = unique(files, 'stable');
    files = files(:).';  % 1xN cell로 정렬
end
