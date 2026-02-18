function [Vhat_lt, Vhat_e, Vhat_n, Vhat_u, logrho] = get_result_mcmc(faults, fault_name, Vhat_lt, Vhat_e, Vhat_n, Vhat_u, sig, d, ref, data)

    namelist = fieldnames(faults);
    for i = 1:numel(namelist)
        fieldName = namelist{i};  % Extract field name from the namelist
        switch fieldName
            case fault_name
                continue
            otherwise
                Vhat_lt = Vhat_lt + faults.(fieldName).contribution.Vhat_u_lt;
                Vhat_e = Vhat_e + faults.(fieldName).contribution.Vhat_e;
                Vhat_n = Vhat_n + faults.(fieldName).contribution.Vhat_n;
                Vhat_u = Vhat_u + faults.(fieldName).contribution.Vhat_u;
        end
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

    dhat = [Vhat_e; Vhat_n; Vhat_u; Vhat_lt];
    logrho = -.5*(d./sig-dhat./sig)'*(d./sig-dhat./sig);
end