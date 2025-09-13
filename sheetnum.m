function n = sheetnum(name)
    nums = split(name, '_');
    n = str2double(nums{1});
end