% Make sure load_bounds.m is set up as you prefer
% Change weighting by adjust the sigma as you wish

clear
addpath ../../tools/
addpath ../data/

load ../data/GF.mat
load_bounds

% choose reference station by the row number in data.xy_inter
ref = [1152];

% nodes were set in P02


%% Setup MCMC
namelist = fieldnames(faults);

for i = 1:numel(namelist)
    fieldName = namelist{i};  % Extract field name from the namelist
    switch faults.(fieldName).meshtype
        case 'tri'
            % locking nodes
            faults.(fieldName).setMinLd;
            faults.(fieldName).setLockNode;
            if faults.(fieldName).nodes.flag_locking == true
                upper = faults.(fieldName).bounds.upperLd * ones(size(faults.(fieldName).nodes.lock_nodes,1)/faults.(fieldName).nodes.segments.nhe,1);
                lower = faults.(fieldName).bounds.lowerLd * ones(size(faults.(fieldName).nodes.lock_nodes,1)/faults.(fieldName).nodes.segments.nhe,1);
            else
                upper = faults.(fieldName).bounds.upperLd;
                lower = faults.(fieldName).bounds.lowerLd;
            end

            faults.(fieldName).AssignIniitialValues;
            faults.(fieldName).nodes.locking_patches = faults.(fieldName).setLockingPatches(upper,lower);
        otherwise
            continue
    end
end
faults.detachment.nodes.rates.ds(end) = 0;
faults.detachment.AssignIniitialValues;

rate_struct = struct();
namelist = fieldnames(faults);
for i = 1:numel(namelist)
    fieldName = namelist{i};  % Extract field name from the namelist
    rate_struct.(fieldName).rates.ss = faults.(fieldName).nodes.rates.ss;
    rate_struct.(fieldName).rates.ds = faults.(fieldName).nodes.rates.ds;
    rate_struct.(fieldName).rates.upperLd = faults.(fieldName).nodes.rates.upperLd;
    rate_struct.(fieldName).rates.lowerLd = faults.(fieldName).nodes.rates.lowerLd;
    switch faults.(fieldName).meshtype
        case 'tri'
            rate_struct.(fieldName).ss_i = faults.(fieldName).nodes.ss_i;
            rate_struct.(fieldName).ds_i = faults.(fieldName).nodes.ds_i;
            rate_struct.(fieldName).locking_patches = faults.(fieldName).nodes.locking_patches;
        otherwise
            rate_struct.(fieldName).ss_i = faults.(fieldName).nodes.rates.ss;
            rate_struct.(fieldName).ds_i = faults.(fieldName).nodes.rates.ds;
    end
end

%% Change weighting

% Inflate the sigma for more flexibility, do reference
data_adjusted = selectively_multply(data, 4, ref);

% change the weighting of each dataset 
% set_weighting(data, horizontal_weighting, ver_weighting, ver_lt_weighting, base)
% less than 1 means up weight
% more than 1 means down weight
% base = the floor of sigma
[sig_e,sig_n,sig_u,sig_lt] = set_weighting(data_adjusted, 1, 0.5, 0.15, 0.8);

% Further adjustment
sig_lt(403:405) = sig_lt(403:405)./20;
temp = sig_lt(403);
sig_lt(403) = sig_lt(405);
sig_lt(405) = temp;

sig = [sig_e; sig_n; sig_u; sig_lt];
d = [data.Veast_inter(data.notnanind_east); data.Vnorth_inter(data.notnanind_north); data.Vup_inter(data.notnanind_up); data.Vup_lt];

%% Calculate initials and the logprop
[Vhat_lt, Vhat_e, Vhat_n, Vhat_u, logrho] = get_result(faults, rate_struct, data, sig, d, ref);

%% set up the variables for mcmc
Ld_stepsize = 6;
% build variables matrix and the associated list
count = 1;
command_cell = {};
step_list = [];
namelist = fieldnames(faults);
for i = 1:numel(namelist)
    fieldName = namelist{i};  % Extract field name from the namelist
    % faults.(fieldName).nodes.rates
    obj = faults.(fieldName).nodes.rates;
    step_ss = 0.35 * (faults.(fieldName).bounds.ss.upper - faults.(fieldName).bounds.ss.lower);
    step_ds = 0.35 * (faults.(fieldName).bounds.ds.upper - faults.(fieldName).bounds.ds.lower);
    for j = 1:numel(obj.ss)
        command_cell(count) = {['faults.', fieldName, '.nodes.rates.ss(', num2str(j), ')']};
        step_list(count) = step_ss;
        count = count + 1;
    end
    for j = 1:numel(obj.ds)
        command_cell(count) = {['faults.', fieldName, '.nodes.rates.ds(', num2str(j), ')']};
        step_list(count) = step_ds;
        count = count + 1;
    end
    switch faults.(fieldName).meshtype
        case 'tri'
            for j = 1:numel(obj.lowerLd)
                command_cell(count) = {['faults.', fieldName, '.nodes.rates.lowerLd(', num2str(j), ')']};
                step_list(count) = Ld_stepsize;
                count = count + 1;
            end
            for j = 1:numel(obj.upperLd)
                command_cell(count) = {['faults.', fieldName, '.nodes.rates.upperLd(', num2str(j), ')']};
                step_list(count) = Ld_stepsize;
                count = count + 1;
            end
        otherwise
            continue
    end
end


% Adjust step size for better convergent %
% step_list(355:378) = 14;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

save('../data/command_cell.mat', 'command_cell')

%% do MCMC

% prepare file to write
fid = fopen('../result/M_Results.txt','w'); fclose(fid);
fid = fopen('../result/M_Results_log.txt','w'); fclose(fid);
fidResult = fopen('../result/M_Results.txt','a'); 
fidResult_log = fopen('../result/M_Results_log.txt','a'); 


numaccept = 0;
numaccept_pre = 0;
numsteps = 9*10^6;
logn = [];
for iter=1:numsteps
    randomNumber = randi([1, numel(step_list)]); 
    
    str = command_cell{randomNumber};
    
    % Split the string using both '.' and '(' as delimiters
    chunks = regexp(str, '[.\()]', 'split'); 
    
    % Remove empty strings from the resulting cell array
    chunks = chunks(~cellfun('isempty', chunks)); 
    
    r=(-1).^round(rand(1)).*rand(1); %draw random number for random step
    
    tmp = eval([str, '+r*step_list(randomNumber)']);

    check_bounds = false;
    switch chunks{5}
        case 'ss'
            % check bounds
            eval(['check_bounds = check_bounds | sum(tmp>', strjoin(chunks(1:end-4),'.'), '.bounds.ss.upper)>0;'])
            eval(['check_bounds = check_bounds | sum(tmp<', strjoin(chunks(1:end-4),'.'), '.bounds.ss.lower)>0;'])
        case 'ds'
            % check bounds
            eval(['check_bounds = check_bounds | sum(tmp>', strjoin(chunks(1:end-4),'.'), '.bounds.ds.upper)>0;'])
            eval(['check_bounds = check_bounds | sum(tmp<', strjoin(chunks(1:end-4),'.'), '.bounds.ds.lower)>0;'])
        case 'upperLd'
            % check bounds
            eval(['check_bounds = check_bounds | sum(tmp<', strjoin(chunks(1:end-4),'.'), '.bounds.upperLd)>0;'])
            eval(['check_bounds = check_bounds | sum(tmp>rate_struct.', strjoin(chunks(2:end-4),'.'), '.rates.lowerLd(', chunks{6} ,'))>0;'])
        case 'lowerLd'
            % check bounds
            eval(['check_bounds = check_bounds | sum(tmp<rate_struct.', strjoin(chunks(2:end-4),'.'), '.rates.upperLd(', chunks{6} ,'))>0;'])
            eval(['check_bounds = check_bounds | sum(tmp>', strjoin(chunks(1:end-4),'.'), '.bounds.lowerLd)>0;'])
    end
    
    if check_bounds == true
        logrho2 = -inf;
        accept = 0;
    else %compute new model fit
        rate_struct.(chunks{2}).(chunks{4}).(chunks{5})(str2double(chunks{6})) = tmp;
        switch chunks{5}
            case 'ss'
                rate_struct.(chunks{2}).ss_i = faults.(chunks{2}).GetRate(rate_struct.(chunks{2}).rates.ss);
            case 'ds'
                rate_struct.(chunks{2}).ds_i = faults.(chunks{2}).GetRate(rate_struct.(chunks{2}).rates.ds);
            otherwise
                eval([strjoin(chunks(1:end-4),'.'), '.setLockingPatches(' strjoin(chunks(1:end-2),'.') '.upperLd(),', strjoin(chunks(1:end-2),'.') '.lowerLd());'])
                rate_struct.(chunks{2}).locking_patches = faults.(chunks{2}).setLockingPatches(rate_struct.(chunks{2}).(chunks{4}).upperLd,rate_struct.(chunks{2}).(chunks{4}).lowerLd);
        end
        [Vhat_lt, Vhat_e, Vhat_n, Vhat_u] = faults.(chunks{2}).getSingleFault_saved(rate_struct.(chunks{2}));
        [Vhat_lt_all, Vhat_e_all, Vhat_n_all, Vhat_u_all, logrho2] = get_result_mcmc(faults, chunks{2}, Vhat_lt, Vhat_e, Vhat_n, Vhat_u, sig, d, ref, data);
        accept=metropolis_log(logrho,logrho2);
    end
    
    if accept==1 %assign new values for previous step
        logrho = logrho2;
        switch chunks{5}
            case 'ss'
                faults.(chunks{2}).nodes.ss_i = rate_struct.(chunks{2}).ss_i;
                faults.(chunks{2}).nodes.rates.ss = rate_struct.(chunks{2}).rates.ss;
            case 'ds'
                faults.(chunks{2}).nodes.ds_i = rate_struct.(chunks{2}).ds_i;
                faults.(chunks{2}).nodes.rates.ds = rate_struct.(chunks{2}).rates.ds;
            otherwise
                faults.(chunks{2}).nodes.locking_patches = rate_struct.(chunks{2}).locking_patches;
                faults.(chunks{2}).nodes.rates.upperLd = rate_struct.(chunks{2}).rates.upperLd;
                faults.(chunks{2}).nodes.rates.lowerLd = rate_struct.(chunks{2}).rates.lowerLd;
        end
        faults.(chunks{2}).contribution.Vhat_u_lt = Vhat_lt;
        faults.(chunks{2}).contribution.Vhat_e = Vhat_e;
        faults.(chunks{2}).contribution.Vhat_n = Vhat_n;
        faults.(chunks{2}).contribution.Vhat_u = Vhat_u;
        numaccept = numaccept + 1;
    else %revert to values at previous step
        switch chunks{5}
            case 'ss'
                rate_struct.(chunks{2}).ss_i = faults.(chunks{2}).nodes.ss_i;
                rate_struct.(chunks{2}).rates.ss = faults.(chunks{2}).nodes.rates.ss;
            case 'ds'
                rate_struct.(chunks{2}).ds_i = faults.(chunks{2}).nodes.ds_i;
                rate_struct.(chunks{2}).rates.ds = faults.(chunks{2}).nodes.rates.ds;
            otherwise
                rate_struct.(chunks{2}).locking_patches = faults.(chunks{2}).nodes.locking_patches;
                rate_struct.(chunks{2}).rates.upperLd = faults.(chunks{2}).nodes.rates.upperLd;
                rate_struct.(chunks{2}).rates.lowerLd = faults.(chunks{2}).nodes.rates.lowerLd;
        end
    end
    
    % save parm when accept every 1000 time
    if mod(iter,numel(command_cell)*2)==0

        disp(['iter: ', num2str(iter)])
        disp(['accept rate: ', num2str(round((abs(numaccept_pre-numaccept)/(numel(command_cell)*2))*100,2)), ' %'])
        numaccept_pre = numaccept;
        fprintf(fidResult_log,'%6.5f\t',logrho);
        fprintf(fidResult, '\n');

        for i =1:numel(command_cell)
            fprintf(fidResult,'%6.5f\t',eval(command_cell{i}));
        end
        fprintf(fidResult, '\n');
        disp(['Saved ',  num2str(round(iter/(numel(command_cell)*2),0)), ' times.'])
        dhat = [Vhat_e_all; Vhat_n_all; Vhat_u_all; Vhat_lt_all];
        fit = round((1-(norm(d-dhat)/norm(d)))*100,2);
        disp(['Fit: ',  num2str(fit), ' %'])
        disp('--------------------')
    end
end