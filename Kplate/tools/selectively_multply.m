function data_adjusted = selectively_multply(data, inflat, ref)
    data_adjusted = data;
    x = data.Veast_inter(data.notnanind_east);
    y = data.Vnorth_inter(data.notnanind_east);

    % ref the data
    site = zeros(numel(ref),1);
    for r = 1:numel(ref)
        site(r) = sum(data.notnanind_east(1:ref(r)));
    end

    if ~isempty(ref)
        x = x-mean(x(site));
        y = y-mean(y(site));
    end

    % get length
    l = sqrt(x.^2+y.^2);
    % get length > wish
    mask = (l >= 5.2);
    % change the sig for those vector
    data_adjusted.Sigeast_inter(mask,:) = data.Sigeast_inter(mask,:) .* inflat;
    data_adjusted.Signorth_inter(mask,:) = data.Signorth_inter(mask,:) .* inflat;
    data_adjusted.Sigup_inter = data.Sigup_inter .* inflat;
    data_adjusted.Sigup_lt = data.Sigup_lt .* inflat;
end