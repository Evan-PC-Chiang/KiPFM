addpath tools/

%% Setup base map
% The model origin should be fixed for all calculations and is typically 
% selected near the midpoint of the study area to reduce projection distortion.
origin=[121 24];

%load coast file -- must be called coast_file.txt (use "empty", [], if none)
%format of columns: long, lat
%use row of NaN to separate continuous segments
coast_file = load('./data/coast_file.txt');
xy_coast = llh2local(coast_file', origin)';

figure
hold on
plot(xy_coast(:,1), xy_coast(:,2),'k');
axis equal
axis tight
%% Inputs, Example of using Shanchiao Fault.

%{'Shanchiao'}
dz = [0 7 10 30]; %depths of dip values
dp = [-70 -55 -35 -20]; %dip values


%% Runs

[name, dipmesh] = make_fault("./traces/Shanchiao.txt", origin, dp, dz);
write_mesh(name, dipmesh)

