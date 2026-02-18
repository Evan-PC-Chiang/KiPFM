addpath ../../tools/
addpath ../data/

load ../data/GF.mat
load command_cell.mat
load ../result/M_Results.txt
load ../result/M_Results_log.txt
load_bounds


% Check Burn-In 
figure
plot(M_Results_log)
title('Burn-In')

%% Select discard number by Burn-In plot
discard = 60;

M_Results(1:discard,:) = [];
parm = mean(M_Results,1);
parm_std = std(M_Results,1);

% reference should be the same
ref = [1152];

%% put parm back 
for i = 1:numel(command_cell)
    str = command_cell{i};
    
    % Split the string using both '.' and '(' as delimiters
    chunks = regexp(str, '[.\()]', 'split'); 
    
    % Remove empty strings from the resulting cell array
    chunks = chunks(~cellfun('isempty', chunks)); 

    faults.(chunks{2}).(chunks{3}).(chunks{4}).(chunks{5})(str2double(chunks{6})) = parm(i);
end


% run result
namelist = fieldnames(faults);
for i = 1:numel(namelist)
    fieldName = namelist{i};  % Extract field name from the namelist
    faults.(fieldName).nodes.ss_i = faults.(fieldName).GetRate(faults.(fieldName).nodes.rates.ss);
    faults.(fieldName).nodes.ds_i = faults.(fieldName).GetRate(faults.(fieldName).nodes.rates.ds);
    switch faults.(fieldName).meshtype
        case 'tri'
            faults.(fieldName).nodes.locking_patches = faults.(fieldName).setLockingPatches(faults.(fieldName).nodes.rates.upperLd,faults.(fieldName).nodes.rates.lowerLd);
        otherwise
            continue
    end
end

%%

% either one or multiple
%fault_name = ["detachment"];
%fault_name = ["ryukyu_loading","manila_loading"];

% or the other round also work
% fault_name_exclude = ["detachment","ryukyu_loading","manila_loading","okinawa_north","okinawa_south","ryukyu","S_oki","N_oki","green_island_left"];
% fault_name = setdiff(namelist, fault_name_exclude, 'stable');  % 'stable' keeps the order in A
% fault_name = reshape(fault_name, 1, []);        % make it 1x51


site = zeros(numel(ref),1);
for r = 1:numel(ref)
    site(r) = sum(data.notnanind_east(1:ref(r)));
end

Vhat_lt = zeros(size(faults.(fault_name(1)).contribution.Vhat_u_lt));
Vhat_e = zeros(size(faults.(fault_name(1)).contribution.Vhat_e));
Vhat_n = zeros(size(faults.(fault_name(1)).contribution.Vhat_n));
Vhat_u = zeros(size(faults.(fault_name(1)).contribution.Vhat_u));

for fault = fault_name
    faults.(fault).getSingleFault_within();
    Vhat_lt = Vhat_lt + faults.(fault).contribution.Vhat_u_lt;
    Vhat_e  = Vhat_e + faults.(fault).contribution.Vhat_e;
    Vhat_n  = Vhat_n + faults.(fault).contribution.Vhat_n;
    Vhat_u  = Vhat_u + faults.(fault).contribution.Vhat_u;
end

if ~isempty(ref)
    Vhat_e = Vhat_e-mean(Vhat_e(site));
    Vhat_n = Vhat_n-mean(Vhat_n(site));
end

figure('Position', [10 10 900 900]); hold on
hold on
scatter(data.xy_lt(:,1),data.xy_lt(:,2),30,Vhat_lt,'filled')
plot(xy_coast(:,1),xy_coast(:,2),'k')
plot_fault_traces_all(faults)
axis equal
xlim([-200 200]); ylim([-250 200])
colorbar
clim([-5 5])
colormap(flipud(brewermap([],"RdBu")))
title([fault_name, ' Long-term Vertical'])


figure('Position', [10 10 900 900]); hold on
hold on
scatter(data.xy_inter(data.notnanind_up,1),data.xy_inter(data.notnanind_up,2),30,Vhat_u,'filled')
plot(xy_coast(:,1),xy_coast(:,2),'k')
plot_fault_traces_all(faults)
axis equal
xlim([-200 200]); ylim([-250 200])
colorbar
clim([-5 5])
colormap(flipud(brewermap([],"RdBu")))
%title([fault_name, ' Short-term Vertical'])

figure('Position', [10 10 900 900]); hold on
scale=1;
quiver(data.xy_inter(data.notnanind_east,1),data.xy_inter(data.notnanind_east,2),scale*Vhat_e,scale*Vhat_n,0,'r','DisplayName','Model');
plot(xy_coast(:,1),xy_coast(:,2),'k','HandleVisibility','off')
plot_fault_traces_all(faults)
axis equal
legend show
xlim([-200 200]); ylim([-250 200])
%title([fault_name, ' Short-term Horizontal'])

% velo for horizontal model & data
% detachment
velo = [data.xy_inter_wgs(data.notnanind_east,1) data.xy_inter_wgs(data.notnanind_east,2) Vhat_e Vhat_n zeros(size(Vhat_e,1), 3)];
writematrix(velo, '../result/velo_detachment.txt', 'Delimiter', 'space');

% % others
% velo = [data.xy_inter_wgs(data.notnanind_east,1) data.xy_inter_wgs(data.notnanind_east,2) Vhat_e Vhat_n zeros(size(Vhat_e,1), 3)];
% writematrix(velo, '../result/velo_fault.txt', 'Delimiter', 'space');
