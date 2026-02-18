% This Script is use to calculate the greens function for the inversion.
% Please make setup section is the same as P01_setup_Kplate 

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

tic; % Start timer
% Loop through the namelist and assign each field
for i = 1:numel(namelist)
    fieldName = namelist{i};  % Extract field name from the namelist
    faults.(fieldName) = Fault_parm(fieldName,'tri',H);  % Create a new instance of the class
    faults.(fieldName).tri_green(xy_stats); % Build greens
    faults.(fieldName).make_G(data)
end


% Initialize the structure
faults_loading = struct();

% Loop through the namelist and assign each field
for i = 1:numel(namelist_loading_faults)
    fieldName = namelist_loading_faults{i};  % Extract field name from the namelist
    faults_loading.(fieldName) = Fault_parm(fieldName,'rec',H);  % Create a new instance of the class
    faults_loading.(fieldName).rec_green(xy_stats); % Build greens
    faults_loading.(fieldName).make_G(data)
end

% put loading into fault
namelist = fieldnames(faults_loading);
for i = 1:numel(namelist)
    fieldName = namelist{i};  % Extract field name from the namelist
    faults.(fieldName) = faults_loading.(fieldName);
    faults.(fieldName).num_e = data.notnanind_east;
    faults.(fieldName).num_n = data.notnanind_north;
    faults.(fieldName).num_u = data.notnanind_up;
    faults.(fieldName).num_lt = data.data_type;
    faults.(fieldName).nodes.ss_i = faults.(fieldName).nodes.rates.ss;
    faults.(fieldName).nodes.ds_i = faults.(fieldName).nodes.rates.ds;
end

%% Setup Slip nodes

% USAGE: faults.detachment.setSlipNodes(STRIKE,DIP)
% USAGE: faults.detachment.setSlipNodes(STRIKE_ONLY)
% e.g.:
faults.detachment.setSlipNodes(10,5)
% faults.CRF.setSlipNodes(5)
% faults.NCRF.setSlipNodes(5)

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
            faults.(fieldName).nodes.locking_patches = faults.(fieldName).setLockingPatches(upper,lower);
            faults.(fieldName).AssignIniitialValues;
        otherwise
            continue
    end
end

%% Save file
save('../data/GF.mat','faults', 'data', 'xy_coast', 'origin','-v7.3')

elapsedTime = toc; % Stop timer and get elapsed time
disp(['Elapsed Time: ', num2str(elapsedTime), ' seconds']);

%% Make boundary file

if need4bound == true
    fid = fopen('load_bounds.m','w'); fclose(fid);
    
    fidBounds = fopen('load_bounds.m','a'); 
    
    for i = 1:numel(namelist)
        fieldName = namelist{i};
        setss = ['faults.' fieldName '.setSsBounds(0, -10);'];
        fprintf(fidBounds,'%s\n',setss);
        setds = ['faults.' fieldName '.setDsBounds(0, 10);'];
        fprintf(fidBounds,'%s\n',setds);
        fprintf(fidBounds,'\n');
    end
    
    %loading faults
    for i = 1:numel(namelist_loading_faults)
        fieldName = namelist_loading_faults{i};
        setss = ['faults_loading.' fieldName '.setSsBounds(55, -55);'];
        fprintf(fidBounds,'%s\n',setss);
        setds = ['faults_loading.' fieldName '.setDsBounds(0, 100);'];
        fprintf(fidBounds,'%s\n',setds);
        fprintf(fidBounds,'\n');
    end
else
    disp('No need to produce boundary file.')
end
