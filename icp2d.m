% ===================== icp2d.m =====================
% ICP for 2D point sets (rigid: rotation + translation)
%
% [R, t, rmse, history] = icp2d(src, dst, opts)
%   src: Nx2 source points (will be transformed)
%   dst: Mx2 target points
%   opts (struct, optional):
%       .max_iter (default 50)
%       .tol (default 1e-6)         % stop when |Δrmse| < tol
%       .trim (default 0.7)         % keep this fraction of closest pairs [0<trim<=1]
%       .reject_multiplier (3.0)    % reject pairs with d > k * median(d)
%       .R0 (2x2)                   % initial rotation guess
%       .t0 (2x1)                   % initial translation guess
%       .verbose (false)
%       .use_kd (false)             % if you have knnsearch, set true
%       .plot (false)               % live plotting
%   R: 2x2 rotation matrix
%   t: 2x1 translation vector
%   rmse: final root-mean-square error over inliers
%   history: struct with fields iter, rmse, num_inliers
%
% Pure-MATLAB implementation (no toolboxes required). If you have
% Statistics Toolbox, setting opts.use_kd=true will use knnsearch.
%
% Author: ChatGPT — 2025-09-12
function [R, t, rmse, history] = icp2d(src, dst, opts)
    if nargin < 3, opts = struct(); end
    max_iter = get_opt(opts, 'max_iter', 50);
    tol = get_opt(opts, 'tol', 1e-6);
    trim = get_opt(opts, 'trim', 0.7);            % keep 70% closest pairs by default
    reject_k = get_opt(opts, 'reject_multiplier', 3.0);
    use_kd = get_opt(opts, 'use_kd', false);
    verbose = get_opt(opts, 'verbose', false);
    do_plot = get_opt(opts, 'plot', false);

    src = validate_points(src);
    dst = validate_points(dst);

    % Initial pose
    if isfield(opts,'R0'), R = opts.R0; else, R = eye(2); end
    if isfield(opts,'t0'), t = opts.t0; else, t = zeros(2,1); end

    % For plotting
    if do_plot
        clf; axis equal; grid on; hold on;
        title('ICP 2D — source to target');
        plot(dst(:,1), dst(:,2), 'k.');
        srcT = (R*src' + t); srcT = srcT';
        hSrc = plot(srcT(:,1), srcT(:,2), 'r.');
        legend({'target','source (moving)'}, 'Location','best');
        drawnow;
    end

    history.iter = [];
    history.rmse = [];
    history.num_inliers = [];

    prev_rmse = inf;

    for iter = 1:max_iter
        % Transform source
        srcT = (R*src' + t); srcT = srcT';

        % Nearest neighbors
        if use_kd && exist('knnsearch','file') == 2 %#ok<EXIST>
            idx = knnsearch(dst, srcT);    % returns index in dst for each srcT row
            nn = dst(idx, :);
        else
            idx = nn_bruteforce(srcT, dst);
            nn = dst(idx, :);
        end

        % Compute distances and inlier mask
        d2 = sum((srcT - nn).^2, 2);
        d = sqrt(d2);

        % Robust inlier selection: median-based reject + trimming
        med_d = median(d);
        inlier = d <= reject_k * max(med_d, eps);

        % Trimming by percentile (keep fraction of smallest distances)
        if trim < 1.0
            dd = d(inlier);
            if ~isempty(dd)
                kth = quantile(dd, trim);
                inlier(inlier) = dd <= kth; % keep <= kth among current inliers
            end
        end

        X = srcT(inlier, :);   % transformed source (current)
        Y = nn(inlier, :);     % matched target

        if size(X,1) < 3
            warning('icp2d:TooFewInliers', 'Too few inliers to estimate transform.');
            break;
        end

        % Estimate incremental rigid transform between X and Y
        [dR, dt] = best_rigid_2d(X, Y);

        % Update global pose: new transform applied to original src
        R = dR * R;
        t = dR * t + dt;

        % Compute RMSE over inliers
        rmse = sqrt(mean(sum(( (dR*X' + dt)'-Y ).^2, 2)));

        history.iter(end+1) = iter; %#ok<*AGROW>
        history.rmse(end+1) = rmse;
        history.num_inliers(end+1) = sum(inlier);

        if verbose
            fprintf('Iter %2d | inliers=%4d | rmse=%.6f\n', iter, sum(inlier), rmse);
        end

        if do_plot
            set(hSrc, 'XData', srcT(:,1), 'YData', srcT(:,2));
            drawnow;
        end

        if abs(prev_rmse - rmse) < tol
            break;
        end
        prev_rmse = rmse;
    end
end

% ---- Helpers --------------------------------------------------------------
function pts = validate_points(pts)
    if ~isnumeric(pts) || size(pts,2) ~= 2
        error('Points must be an Nx2 numeric array.');
    end
    pts = double(pts);
end

function v = get_opt(s, f, def)
    if isfield(s, f), v = s.(f); else, v = def; end
end

function [R, t] = best_rigid_2d(X, Y)
    % Find R,t minimizing || R*X + t - Y ||_F using SVD (Kabsch)
    % X,Y: Nx2
    muX = mean(X, 1)';
    muY = mean(Y, 1)';
    Xc = X' - muX;   % 2xN
    Yc = Y' - muY;
    S = Xc * Yc';    % 2x2
    [U, ~, V] = svd(S);
    R = V*U';
    if det(R) < 0
        V(:,2) = -V(:,2);
        R = V*U';
    end
    t = muY - R*muX;
end

function idx = nn_bruteforce(A, B)
    % For each row of A (Nx2), find argmin over rows of B (Mx2)
    % Returns idx (Nx1): index into B
    N = size(A,1);
    M = size(B,1);
    idx = zeros(N,1);
    for i = 1:N
        ai = A(i,:);
        % Compute squared distances to all B
        d2 = sum((B - ai).^2, 2);
        [~, idx(i)] = min(d2);
    end
end

