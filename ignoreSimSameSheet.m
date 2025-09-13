function sim = ignoreSimSameSheet( sim, names )
    shnums = cellfun(@sheetnum, names);
    shnums1 = unique(shnums);
    for i = 1:length(shnums1)
        idx = find( shnums == shnums1(i) );
        if length(idx) == 1, continue; end

        sim( idx, idx ) = 0;
    end
end


