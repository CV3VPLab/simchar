function in2aligned = regCharacter( in1, in2 )

assert( ismatrix(in1) );
assert( isa( in1, 'logical' ) );
assert( isa( in2, 'logical' ) );
assert( isequal(size(in1), size(in2)) );

% boundary extraction
bnd1 = in1 & ~imerode( in1, ones(3) );
bnd2 = in2 & ~imerode( in2, ones(3) );

% registration
[R, t] = regICP( bnd1, bnd2 );

if R(3) < 0
    angle = (asin(R(3))-acos(R(1))) / 2; 
else
    angle = (asin(R(3))+acos(R(1))) / 2; 
end
angle = rad2deg( angle );
in2r = imrotate( double(in2), angle );

szd = size(in2r) - size(in2);
assert( all(szd >= 0) );

odd = mod(szd, 2);
clipoffset = (szd - odd) / 2;
t1 = t' - fliplr(odd)/2;
in2rt = imtranslate( in2r, t1 );

in2aligned = in2rt( clipoffset(1) + (1:size(in2,1)), clipoffset(2) + (1:size(in2,2)) );
in2aligned = in2aligned >= 0.5;

