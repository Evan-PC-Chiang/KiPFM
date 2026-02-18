function data_table = put_in_result(faults)
    % put result in the right place
    namelist = fieldnames(faults);
    % build a table to store the results of all faults, columns are ss, ds, upperLd, lowerLd, rows are faults
    data_table = table();
    data_table.faults = namelist;
    data_table.ss = zeros(numel(namelist),1);
    data_table.ss_std = zeros(numel(namelist),1);
    data_table.ds = zeros(numel(namelist),1);
    data_table.ds_std = zeros(numel(namelist),1);
    data_table.upperLd = zeros(numel(namelist),1);
    data_table.lowerLd = zeros(numel(namelist),1);
    data_table.ss_upp_bounds = zeros(numel(namelist),1);
    data_table.ss_low_bounds = zeros(numel(namelist),1);
    data_table.ds_upp_bounds = zeros(numel(namelist),1);
    data_table.ds_low_bounds = zeros(numel(namelist),1);
    data_table.eq_Mw = zeros(numel(namelist),1);

    for i = 1:numel(namelist)
        fieldName = namelist{i};  % Extract field name from the namelist
        faults.(fieldName).Results.ss = mean(faults.(fieldName).nodes.ss_i);
        faults.(fieldName).Results.ds = mean(faults.(fieldName).nodes.ds_i);
        data_table.ss(i) = faults.(fieldName).Results.ss;
        data_table.ds(i) = faults.(fieldName).Results.ds;
        data_table.ss_upp_bounds(i) = faults.(fieldName).bounds.ss.upper;
        data_table.ss_low_bounds(i) = faults.(fieldName).bounds.ss.lower;
        data_table.ds_upp_bounds(i) = faults.(fieldName).bounds.ds.upper;
        data_table.ds_low_bounds(i) = faults.(fieldName).bounds.ds.lower;
        switch faults.(fieldName).meshtype
            case 'tri'
                faults.(fieldName).Results.upperLd = mean(faults.(fieldName).nodes.rates.upperLd);
                faults.(fieldName).Results.lowerLd = mean(faults.(fieldName).nodes.rates.lowerLd);
                data_table.upperLd(i) = faults.(fieldName).Results.upperLd;
                data_table.lowerLd(i) = faults.(fieldName).Results.lowerLd;
            otherwise
                continue
        end
    end
end