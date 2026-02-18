% This Script is use to calculate the greens function for the inversion.
% Please make sure 

clear
addpath ../../tools/
addpath ../data/

% General input
need4bound = false;                     % TRUE if no load_bounds.m
origin = [121 24];                      % Same as you build fault mesh
H = 30;                                 % Thickness of the elastic crust
data_file = '../data/data_set.txt';
coast_file = '../data/coast_file.txt';
load ../data/namelist.mat

% sepecify loading faults
namelist_loading_faults = {
    'ryukyu_loading';
    'manila_loading';
    'okinawa_north';
    'okinawa_south'
    };

% need a detachment or not
namelist{end+1} = 'detachment'; 
% end of input

%% visualize check the faults and data points


[xy_stats, data, xy_coast] = load_data(data_file,coast_file,origin);


% Initialize the structure
faults = struct();


figure; hold on;
% Loop through the namelist and assign each field
for i = 1:numel(namelist)
    fieldName = namelist{i};  % Extract field name from the namelist
    faults.(fieldName) = Fault_parm(fieldName,'tri',H);  % Create a new instance of the class
    faults.(fieldName).plot_trace
end
title('Fault Traces')
axis equal


% Initialize the structure
faults_loading = struct();

% Loop through the namelist and assign each field
for i = 1:numel(namelist_loading_faults)
    fieldName = namelist_loading_faults{i};  % Extract field name from the namelist
    faults_loading.(fieldName) = Fault_parm(fieldName,'rec',H);  % Create a new instance of the class
end

% visualize the fault geometry
figure('Position', [10 10 900 900]); hold on

hS1 = scatter(data.xy_inter(:,1), data.xy_inter(:,2), 30, 'b', 'filled'); 
hS2 = scatter(data.xy_lt(:,1), data.xy_lt(:,2), 30, 'r', 'filled'); 

legend([hS1 hS2], {'Type 1 (short-term)', 'Type 2 (long-term)'});

plot_tri_mesh_shape(faults)
plot_tri_mesh_shape(faults_loading)


title('Fault Geometry')
colormap(flipud(brewermap([],"Oranges")))
plot(xy_coast(:,1),xy_coast(:,2),'k', 'HandleVisibility','off')
axis equal
xlim([-150 150]); ylim([-250 200])
clim([-40 0])
view(2)
