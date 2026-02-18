function [Vhat_lt, Vhat_e, Vhat_n, Vhat_u] = get_result_within(faults, data, ref)
    Vhat_lt = zeros(size(data.Vup_lt));
    Vhat_e = zeros(sum(data.notnanind_east),1);
    Vhat_n = zeros(sum(data.notnanind_north),1);
    Vhat_u = zeros(sum(data.notnanind_up),1);

    namelist = fieldnames(faults);
    for i = 1:numel(namelist)
        fieldName = namelist{i};  % Extract field name from the namelist
        faults.(fieldName).getSingleFault_within()
        Vhat_lt = Vhat_lt + faults.(fieldName).contribution.Vhat_u_lt;
        Vhat_e = Vhat_e + faults.(fieldName).contribution.Vhat_e;
        Vhat_n = Vhat_n + faults.(fieldName).contribution.Vhat_n;
        Vhat_u = Vhat_u + faults.(fieldName).contribution.Vhat_u;
    end

    %relative to reference sites
    site = zeros(numel(ref),1);
    for r = 1:numel(ref)
        site(r) = sum(data.notnanind_east(1:ref(r)));
    end


    if ~isempty(ref)
        Vhat_e = Vhat_e-mean(Vhat_e(site));
        Vhat_n = Vhat_n-mean(Vhat_n(site));
    end
end