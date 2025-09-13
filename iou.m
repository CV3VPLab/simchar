function res = iou(in1, in2)

assert( ndims(in1) <= 3 );
assert( isa( in1, 'logical' ) );
assert( isa( in2, 'logical' ) );
assert( isequal(size(in1), size(in2)) );

iH = size(in1, 1);
iW = size(in1, 2);
in1 = reshape( in1, iH*iW, [] );
in2 = reshape( in2, iH*iW, [] );

unionArea = sum(in1 | in2);
intscArea = sum(in1 & in2);

res = intscArea ./ unionArea;
res(isnan(res)) = 0;
