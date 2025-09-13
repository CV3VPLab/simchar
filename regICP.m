function [R, t] = regICP( in1, in2 )

assert( ismatrix(in1) );
assert( isa( in1, 'logical' ) );
assert( isa( in2, 'logical' ) );
assert( isequal(size(in1), size(in2)) );

ih = fliplr( (size(in1)+1) / 2 );

[y, x] = find(in1);
p1 = [x, y] - ih;

[y, x] = find(in2);
p2 = [x, y] - ih;

opts = struct('max_iter', 2000, 'tol', 1e-7, 'trim', 0.9, ...
              'reject_multiplier', 5.0, 'verbose', false, 'use_kd', true, 'plot', false);
[R, t] = icp2d(p2, p1, opts);   % p1 : dst(reference), p2 : src(moving)
