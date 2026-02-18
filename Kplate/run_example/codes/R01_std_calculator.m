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

run_to = 'full';  % 'plot_only' or 'full'

% reference should be the same
ref = [1152];
%% set up matrix for Vhat_lt, Vhat_e, Vhat_n, Vhat_u
Vhat_lt_matrix = zeros(size(M_Results,1),size(data.Vup_lt,1));
Vhat_e_matrix = zeros(size(M_Results,1),size(data.Veast_inter(data.notnanind_east),1));
Vhat_n_matrix = zeros(size(M_Results,1),size(data.Veast_inter(data.notnanind_east),1));
Vhat_u_matrix = zeros(size(M_Results,1),size(data.Vup_inter(data.notnanind_up),1));

%% set up structures for locking

% get field names from faults
fields = fieldnames(faults);

locking_patches = struct();
ss = struct();
ds = struct();


% set up locking_patches structure field names
for i = 1:numel(fields)
    fieldName = fields{i};
    switch faults.(fieldName).meshtype
        case 'tri'
            faults.(fieldName).setLockNode
            locking_patches.(fieldName) = zeros(size(faults.(fieldName).nodes.locking_patches));
        otherwise
            continue
    end
    ss.(fieldName) = zeros(size(M_Results,1),size(faults.(fieldName).nodes.rates.ss,1));
    ds.(fieldName) = zeros(size(M_Results,1),size(faults.(fieldName).nodes.rates.ds,1));
end

%% calculate

% loop through all rows in M_Results
for i = 1:size(M_Results,1)
    parm = M_Results(i,:);

    % put parameters into the faults structure
    for j = 1:numel(command_cell)
        str = command_cell{j};
        
        % Split the string using both '.' and '(' as delimiters
        chunks = regexp(str, '[.\()]', 'split'); 
        
        % Remove empty strings from the resulting cell array
        chunks = chunks(~cellfun('isempty', chunks)); 
    
        faults.(chunks{2}).(chunks{3}).(chunks{4}).(chunks{5})(str2double(chunks{6})) = parm(j);
    end


    % run result
    namelist = fieldnames(faults);
    for k = 1:numel(namelist)
        fieldName = namelist{k};  % Extract field name from the namelist
        ss.(fieldName)(i,:) = faults.(fieldName).nodes.rates.ss;
        ds.(fieldName)(i,:) = faults.(fieldName).nodes.rates.ds;
        faults.(fieldName).nodes.ss_i = faults.(fieldName).GetRate(faults.(fieldName).nodes.rates.ss);
        faults.(fieldName).nodes.ds_i = faults.(fieldName).GetRate(faults.(fieldName).nodes.rates.ds);
        switch faults.(fieldName).meshtype
            case 'tri'
                faults.(fieldName).setLockNode
                faults.(fieldName).nodes.locking_patches = faults.(fieldName).setLockingPatches(faults.(fieldName).nodes.rates.upperLd,faults.(fieldName).nodes.rates.lowerLd);
                locking_patches.(fieldName) = locking_patches.(fieldName) + double(faults.(fieldName).nodes.locking_patches);
            otherwise
                locking_patches.(fieldName) = [];
        end
    end



    
    [Vhat_lt, Vhat_e, Vhat_n, Vhat_u] = get_result_within(faults, data, ref);

    % store results
    Vhat_lt_matrix(i,:) = Vhat_lt';
    Vhat_e_matrix(i,:) = Vhat_e';
    Vhat_n_matrix(i,:) = Vhat_n';
    Vhat_u_matrix(i,:) = Vhat_u';
end

namelist = fieldnames(faults);
for i=1:numel(namelist)
    fieldName = namelist{i};
    faults.(fieldName).nodes.locking_patches = locking_patches.(fieldName)./size(M_Results,1);
end

% put ss and ds back to the faults
namelist = fieldnames(faults);
for k = 1:numel(namelist)
    fieldName = namelist{k};  % Extract field name from the namelist
    faults.(fieldName).nodes.ss_i = faults.(fieldName).GetRate(mean(ss.(fieldName)));
    faults.(fieldName).nodes.ds_i = faults.(fieldName).GetRate(mean(ds.(fieldName)));
end

%% calculate std and mean for each column
Vhat_lt_std = std(Vhat_lt_matrix)';
Vhat_e_std = std(Vhat_e_matrix)';
Vhat_n_std = std(Vhat_n_matrix)';
Vhat_u_std = std(Vhat_u_matrix)';

Vhat_lt_mean = mean(Vhat_lt_matrix)';
Vhat_e_mean  = mean(Vhat_e_matrix)';
Vhat_n_mean  = mean(Vhat_n_matrix)';
Vhat_u_mean  = mean(Vhat_u_matrix)';

%% Plot

% long-term vertical
figure('Position', [10 10 1800 600]);
subplot(1,3,1)
hold on
scatter(data.xy_lt(:,1),data.xy_lt(:,2),30,data.Vup_lt,'filled')
plot(xy_coast(:,1),xy_coast(:,2),'k')
plot_fault_traces_all(faults)
axis equal
xlim([-200 200]); ylim([-250 200])
colorbar
clim([-20 20])
colormap(flipud(brewermap([],"RdBu")))

subplot(1,3,2)
hold on
scatter(data.xy_lt(:,1),data.xy_lt(:,2),30,Vhat_lt_mean,'filled')
plot(xy_coast(:,1),xy_coast(:,2),'k')
plot_fault_traces_all(faults)
axis equal
xlim([-200 200]); ylim([-250 200])
colorbar
clim([-20 20])
colormap(flipud(brewermap([],"RdBu")))

subplot(1,3,3)
hold on
scatter(data.xy_lt(:,1),data.xy_lt(:,2),30,data.Vup_lt-Vhat_lt_mean,'filled')
plot(xy_coast(:,1),xy_coast(:,2),'k')
plot_fault_traces_all(faults)
axis equal
xlim([-200 200]); ylim([-250 200])
colorbar
clim([-20 20])
colormap(flipud(brewermap([],"RdBu")))

% short-term vertical
figure('Position', [10 10 1800 600]);
subplot(1,3,1)
hold on
scatter(data.xy_inter(data.notnanind_up,1),data.xy_inter(data.notnanind_up,2),30,data.Vup_inter,'filled')
plot(xy_coast(:,1),xy_coast(:,2),'k')
plot_fault_traces_all(faults)
axis equal
xlim([-200 200]); ylim([-250 200])
colorbar
clim([-20 20])
colormap(flipud(brewermap([],"RdBu")))

subplot(1,3,2)
hold on
scatter(data.xy_inter(data.notnanind_up,1),data.xy_inter(data.notnanind_up,2),30,Vhat_u_mean,'filled')
plot(xy_coast(:,1),xy_coast(:,2),'k')
plot_fault_traces_all(faults)
axis equal
xlim([-200 200]); ylim([-250 200])
colorbar
clim([-20 20])
colormap(flipud(brewermap([],"RdBu")))

subplot(1,3,3)
hold on
scatter(data.xy_inter(data.notnanind_up,1),data.xy_inter(data.notnanind_up,2),30,data.Vup_inter-Vhat_u_mean,'filled')
plot(xy_coast(:,1),xy_coast(:,2),'k')
plot_fault_traces_all(faults)
axis equal
xlim([-200 200]); ylim([-250 200])
colorbar
clim([-20 20])
colormap(flipud(brewermap([],"RdBu")))

% Horizontal
figure('Position', [10 10 900 900]); hold on
scale=0.5;
quiver(data.xy_inter(data.notnanind_east,1),data.xy_inter(data.notnanind_east,2),scale*data.Veast_inter(data.notnanind_east),scale*data.Vnorth_inter(data.notnanind_east),0,'b')
quiver(data.xy_inter(data.notnanind_east,1),data.xy_inter(data.notnanind_east,2),scale*Vhat_e_mean,scale*Vhat_n_mean,0,'r')
legend('data','model')
plot(xy_coast(:,1),xy_coast(:,2),'k')
plot_fault_traces_all(faults)
axis equal
xlim([-200 200]); ylim([-250 200])

% ss
figure('Position', [10 10 900 900]); hold on
plot_tri_mesh(faults,'ss_i')
title('mean strike slip')
colormap(flipud(brewermap([],"RdYlBu")))
plot(xy_coast(:,1),xy_coast(:,2),'k')
plot_fault_traces_all(faults)
xlim([-150 150]); ylim([-250 200])
clim([-80 80])
view(2)

% ds
figure('Position', [10 10 900 900]); hold on
plot_tri_mesh(faults,'ds_i')
title('mean dip slip')
colormap(flipud(brewermap([],"RdYlBu")))
plot(xy_coast(:,1),xy_coast(:,2),'k')
plot_fault_traces_all(faults)
xlim([-150 150]); ylim([-250 200])
clim([-80 80])
view(2)


figure('Position', [10 10 1800 900]); 
ax1 = subplot(1,2,1); 
hold(ax1, 'on')
scatter(ax1, data.xy_lt(:,1), data.xy_lt(:,2), 30, Vhat_lt_mean, 'filled')
plot(ax1, xy_coast(:,1), xy_coast(:,2), 'k')
plot_fault_traces_all(faults)
axis(ax1, 'equal')
xlim(ax1, [-200 200]); ylim(ax1, [-250 200])
cb1 = colorbar(ax1);
clim(ax1, [-20 20])
colormap(ax1, flipud(brewermap([], 'RdBu')))
title(ax1, 'Long-term Vertical')

ax2 = subplot(1,2,2); 
hold(ax2, 'on')
scatter(ax2, data.xy_lt(:,1), data.xy_lt(:,2), 30, Vhat_lt_std, 'filled')
plot(ax2, xy_coast(:,1), xy_coast(:,2), 'k')
plot_fault_traces_all(faults)
axis(ax2, 'equal')
xlim(ax2, [-200 200]); ylim(ax2, [-250 200])
cb2 = colorbar(ax2);
clim(ax2, [0 1])
colormap(ax2, brewermap([], 'RdPu'))
title(ax2, 'Long-term Vertical Uncertainty')



figure('Position', [10 10 1800 900]); 
ax1 = subplot(1,2,1); 
hold(ax1, 'on')
scatter(ax1, data.xy_inter(data.notnanind_up,1),data.xy_inter(data.notnanind_up,2), 30, Vhat_u_mean, 'filled')
plot(ax1, xy_coast(:,1), xy_coast(:,2), 'k')
plot_fault_traces_all(faults)
axis(ax1, 'equal')
xlim(ax1, [-200 200]); ylim(ax1, [-250 200])
cb1 = colorbar(ax1);
clim(ax1, [-20 20])
colormap(ax1, flipud(brewermap([], 'RdBu')))
title(ax1, 'Short-term Vertical')

ax2 = subplot(1,2,2); 
hold(ax2, 'on')
scatter(ax2, data.xy_inter(data.notnanind_up,1),data.xy_inter(data.notnanind_up,2), 30, Vhat_u_std, 'filled')
plot(ax2, xy_coast(:,1), xy_coast(:,2), 'k')
plot_fault_traces_all(faults)
axis(ax2, 'equal')
xlim(ax2, [-200 200]); ylim(ax2, [-250 200])
cb2 = colorbar(ax2);
clim(ax2, [0 3])
colormap(ax2, brewermap([], 'RdPu'))
title(ax2, 'Short-term Vertical Uncertainty')

figure('Position', [10 10 1800 900]); 
subplot(1,2,2)
hold on;
scatter(data.xy_inter(data.notnanind_east,1),data.xy_inter(data.notnanind_east,2), 30, sqrt(Vhat_e_std.^2+Vhat_n_std.^2), 'filled');
plot(xy_coast(:,1),xy_coast(:,2),'k','HandleVisibility','off')
plot_fault_traces_all(faults)
clim([0 3])
colormap(brewermap([], 'RdPu'))
colorbar
axis equal
legend show
xlim([-200 200]); ylim([-250 200])
title('Short-term Horizontal')

subplot(1,2,1)
hold on;
scale=1;
quiver(data.xy_inter(data.notnanind_east,1),data.xy_inter(data.notnanind_east,2),scale*Vhat_e_mean,scale*Vhat_n_mean,0,'r','DisplayName','Model');
plot(xy_coast(:,1),xy_coast(:,2),'k','HandleVisibility','off')
plot_fault_traces_all(faults)
axis equal
legend show
xlim([-200 200]); ylim([-250 200])
title('Short-term Horizontal')

% locking
figure('Position', [10 10 900 900]); hold on
plot_locking(faults)
title('Locking Probability')
colormap("hot")
plot(xy_coast(:,1),xy_coast(:,2),'k')
plot_fault_traces_all(faults)
axis equal
xlim([-150 150]); ylim([-250 200])
clim([0 1])
view(2)


% 1. Get the original 'hot' colormap with 256 steps (same as PyGMT default)
cmap = hot(256);

% 2. Reverse it
%cmap = flipud(cmap);

% 3. Truncate it: take only from 0.55 to 1
% That means take rows from index round(0.55*256) to 256
idx_start = round(0.55 * 256);
cmap_truncated = cmap(idx_start:end, :);

cmap_truncated_flip = flipud(cmap_truncated);

colormap(cmap_truncated_flip);

%% write files for plot

data_table = put_in_result(faults);

% std for faults

for i=1:numel(namelist)
    fieldName = namelist{i};
    data_table.ss_std(i) = mean(std(ss.(fieldName)));
    data_table.ds_std(i) = mean(std(ds.(fieldName)));
end

if strcmp(run_to, 'plot_only')
    return
end

% slip rates & equivalent Mw

data_table = slip_rates_Mw('../result/ss_slip.txt', '../result/ds_slip.txt', faults , origin, data_table);

% velo for horizontal model & data
% model
velo = [data.xy_inter_wgs(data.notnanind_east,1) data.xy_inter_wgs(data.notnanind_east,2) Vhat_e_mean Vhat_n_mean Vhat_e_std Vhat_n_std zeros(size(Vhat_e_mean,1), 1)];
writematrix(velo, '../result/velo_fit_horizontal.txt', 'Delimiter', 'space');
% data
velo = [data.xy_inter_wgs(data.notnanind_east,1) data.xy_inter_wgs(data.notnanind_east,2) data.Veast_inter(data.notnanind_east,1) data.Vnorth_inter(data.notnanind_east,1) zeros(size(Vhat_e_mean,1), 3)];
writematrix(velo, '../result/velo_data_horizontal.txt', 'Delimiter', 'space');

% velo for detachment rate

detachment_rate(faults.detachment, xy_coast, origin, '../result/detch_velo.txt')

% change the order
new_order = fliplr([33 35 42 22 11 19 18 20 39 28 40 9 34 32 41 2 4 38 6 27 51 30 7 21 16 5 17 23 3 14 15 29 24 1 26 37 31 36 8 13 50 25 43 12 10 45]);
data_table_order = data_table(new_order, :);
name_full % file setup for figure only.

bounds_plot(data_table_order, 'ss')
resize_axes([800,800],[300,600])



bounds_plot(data_table_order, 'ds')
resize_axes([800,800],[300,600])


% compare
compare_e = [data.Veast_inter(data.notnanind_east) Vhat_e_mean Vhat_e_std];
compare_n = [data.Vnorth_inter(data.notnanind_east) Vhat_n_mean Vhat_n_std];
compare_u = [data.Vup_inter Vhat_u_mean Vhat_u_std];
compare_lt = [data.Vup_lt Vhat_lt_mean Vhat_lt_std];

writematrix(compare_e, '../result/compare_e.txt', 'Delimiter', 'space');
writematrix(compare_n, '../result/compare_n.txt', 'Delimiter', 'space');
writematrix(compare_u, '../result/compare_u.txt', 'Delimiter', 'space');
writematrix(compare_lt, '../result/compare_lt.txt', 'Delimiter', 'space');


data_table_out = removevars(data_table_order, {'ss_upp_bounds', 'ds_upp_bounds','ss_low_bounds', 'ds_low_bounds','lowerLd','upperLd'});
writetable(data_table_out, '../result/fault_detail.csv', 'WriteRowNames', false);



% lt-Data
Lt = [data.xy_lt_wgs data.Vup_lt];
writematrix(Lt, '../result/data_lt.txt', 'Delimiter', 'space');

