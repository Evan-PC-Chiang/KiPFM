classdef Fault_parm < handle
    properties
        meshtype         % Either 'tri' or 'rec'
        trinode          % Nodes for triangular mesh
        tri              % Indices of triangles
        pm               % patch model
        bounds           % [upper, lower]
        Greens           % Original greens function
        G_mcmc           % mcmc Greens
        Results          % ds, ss, locking
        patch_stuff      % patch info (only for tri fault)
        nodes            % indicate the nodes or not for fault
        contribution     % contribution from this fault
    end

    properties (Hidden)
        H                % depth of the elastic layer
        fault_name       % Fault name
        num_e
        num_n
        num_u
        num_lt
    end

    properties (Hidden, Transient)
        rec
    end
        
    methods
        function obj = Fault_parm(fault_name, meshtype, H)
            % Initialize fault data
            obj.fault_name = fault_name;
            obj.H = H;
            switch meshtype
                case 'tri'
                    obj.meshtype = meshtype;
                    obj.tri = readmatrix(['../fault_mesh_files/' fault_name '_tri.txt']);
                    obj.trinode = readmatrix(['../fault_mesh_files/' fault_name '_nodes.txt']);
                    obj.rec = [];
                    obj.pm = [];
                    disp(['Set ' fault_name ' as tri fault']);
                    obj.Results = struct(...
                        'ds',[], ...
                        'ss',[], ...
                        'upperLd',0, ...
                        'lowerLd',H ...
                    );
                    obj.patch_stuff = make_triangular_patch_stuff(obj.tri, obj.trinode);
                case 'rec'
                    obj.meshtype = meshtype;
                    obj.tri = [];
                    obj.trinode = [];
                    obj.rec = readmatrix(['../fault_mesh_files/' fault_name '_rec.txt']);
                    obj.pm = Fault_parm.parm4rec(obj.rec, obj.H);
                    disp(['Set ' fault_name ' as rec fault']);
                    obj.Results = struct(...
                        'ds',[], ...
                        'ss',[] ...
                    );
                    obj.patch_stuff = [];
                otherwise
                    error('Invalid input. Accepted options are "tri" or "rec".');
            end
            % Initialize bounds, Greens, and Results as a nested structure
            obj.bounds = struct(...
                'ss', struct('lower', 0, 'upper', 1), ...
                'ds', struct('lower', 0, 'upper', 1), ...
                'lowerLd', obj.H, ...
                'upperLd', 0 ...
            );

            obj.Greens = struct(...
                'ss', struct( ...
                    'elastic', struct( ...
                        'e', [], ...
                        'n', [], ...
                        'u', []), ...
                    'viscoelastic', struct( ...
                        'e', [], ...
                        'n', [], ...
                        'u', [] ...
                    )), ...
                'ds', struct( ...
                    'elastic', struct( ...
                        'e', [], ...
                        'n', [], ...
                        'u', []), ...
                    'viscoelastic', struct( ...
                        'e', [], ...
                        'n', [], ...
                        'u', []) ...
                    ) ...
            );

            obj.nodes = struct( ...
                'flag', false, ...
                'flag_locking', false, ...
                'segments', struct( ...
                    's_nodes',[], ...
                    'd_nodes',[], ...
                    'nhe',[], ...
                    'nve',[]), ...
                'slip_nodes',[], ...
                'lock_nodes',[], ...
                'locking_patches',[], ...
                'rates',struct( ...
                    'ss', 0, ...
                    'ds', 0, ...
                    'upperLd', 0, ...
                    'lowerLd', H) ...
            );

            obj.contribution = struct( ...
                'Vhat_u_lt', [], ...
                'Vhat_e', [], ...
                'Vhat_n', [], ...
                'Vhat_u', [] ...
            );

        end

        function obj = setSsBounds(obj, ss_1, ss_2)
            % Check if input is numeric
            ss = [ss_1 ss_2];
            if ~isnumeric(ss)
                error('Input must be numeric.');
            end
            
            % Check if input has exactly 2 elements
            if numel(ss) ~= 2
                error('Input must contain exactly 2 separate numeric elements.');
            end

            % Method to set bounds with nested sub-properties
            obj.bounds.ss.upper = max(ss);
            obj.bounds.ss.lower = min(ss);
        end

        function obj = setDsBounds(obj, ds_1, ds_2)
            ds = [ds_1 ds_2];
            % Check if input is numeric
            if ~isnumeric(ds)
                error('Input must be numeric.');
            end
            
            % Check if input has exactly 2 elements
            if numel(ds) ~= 2
                error('Input must contain exactly 2 separate numeric elements.');
            end

            % Method to set bounds with nested sub-properties
            obj.bounds.ds.upper = max(ds);
            obj.bounds.ds.lower = min(ds);
        end

        function obj = setMinLd(obj)
            depth_node = min(obj.tri(:));
            obj.bounds.lowerLd = abs(obj.trinode(depth_node,3));
        end

        function setSlipNodes(obj, strike_nodes, dip_nodes)
            % Check if strike_nodes is numeric and contains exactly one element
            if ~isnumeric(strike_nodes) || numel(strike_nodes) ~= 1
                error('Input strike_nodes must be a single numeric value.');
            end
            
            if ~exist('dip_nodes', 'var') || isempty(dip_nodes)
                dip_nodes = []; % Default value for dip_nodes
            end

            switch obj.fault_name
                case 'detachment'

                    nhe = sum(obj.trinode(:,3)==min(obj.trinode(:,3)));  %number of mesh nodes along strike
                    nve = round(size(obj.trinode,1)/nhe);
                    nodeindex_strike = round(linspace(1,nhe,strike_nodes));  %node indices along strike to use fo slip nodes
                    nodeindex_dip = round(linspace(1,nve,dip_nodes));  %node indices along dip to use fo slip nodes

                    slip_nodes = zeros(strike_nodes*dip_nodes,3);
                    for k=1:dip_nodes
                        rowstart = (k-1)*strike_nodes+1;
                        rowend = k*strike_nodes;
                        slip_nodes(rowstart:rowend,:) = obj.trinode(nodeindex_strike+(nodeindex_dip(k)-1)*nhe,:);
                    end
                    ss = zeros(strike_nodes*dip_nodes,1);
                    ds = zeros(strike_nodes*dip_nodes,1);

                    obj.nodes.segments.nve = nve;
                otherwise
                    depths = obj.trinode(:,3);
                    d_depths = diff(depths);
                    ind = [find(d_depths > 0.25*max(d_depths)); length(depths)];
                    ind_dif = diff(ind);
                    threshold = 0.8*mean(ind_dif);
                    ind_ind = reshape(find(ind_dif<threshold),[],2);
                    ind(ind_ind(:,2)) = [];
                
                    end_nodes_row = cumsum([ind(1);diff(ind)]); %node at end of each row
                    % check any extra point
                    slip_nodes = [];
                    end_nodes_row = [0; end_nodes_row];
                    for loop=2:length(end_nodes_row)-1
                        lockindex_strike = round(linspace(end_nodes_row(loop)+1,end_nodes_row(loop+1),strike_nodes)); 
                        slip_nodes = [slip_nodes; obj.trinode(lockindex_strike,:)]; 
                    end
                    ss = zeros(strike_nodes,1);
                    ds = zeros(strike_nodes,1);

                    obj.nodes.segments.nve = numel(2:length(end_nodes_row)-1);
            end
            obj.nodes.flag = true;
            obj.nodes.segments.s_nodes = strike_nodes;
            obj.nodes.segments.d_nodes = dip_nodes;
            obj.nodes.slip_nodes = slip_nodes;
            obj.nodes.rates.ss = ss;
            obj.nodes.rates.ds = ds;
        end

        function rates_i_filled = GetRate(obj, rates)
            switch obj.meshtype
                case 'tri'
                    centers = obj.patch_stuff.centroids_faces;
                    switch obj.nodes.flag
                        case true
                            slip_nodes = obj.nodes.slip_nodes;
                            switch obj.fault_name
                                case 'detachment'
                                    rates_i = griddata(slip_nodes(:,1),slip_nodes(:,2),rates,centers(:,1),centers(:,2));
                                otherwise
                                    nve = size(slip_nodes,1)/obj.nodes.segments.s_nodes;
                                    rates_i = griddata(slip_nodes(:,1),slip_nodes(:,2),repmat(rates,nve,1),centers(:,1),centers(:,2));
                            end
                            % Identify NaN and non-NaN indices in rates_i
                            nanIdx = find(isnan(rates_i));       % Indices of NaN values
                            nonNanIdx = find(~isnan(rates_i));   % Indices of non-NaN values
                            
                            % Get coordinates of NaN and non-NaN centers
                            nanCenters = centers(nanIdx, :);       % Centers corresponding to NaN values
                            nonNanCenters = centers(nonNanIdx, :); % Centers corresponding to non-NaN values
                            
                            % Find nearest neighbors for NaN centers in the non-NaN centers
                            [nearestIdx, ~] = knnsearch(nonNanCenters, nanCenters);
                            
                            % Replace NaN values in rates_i with the nearest non-NaN values
                            rates_i_filled = rates_i; % Copy original array
                            rates_i_filled(nanIdx) = rates_i(nonNanIdx(nearestIdx));
                        otherwise
                            rates_i_filled = rates(1,1) * ones(size(centers,1),1);
                    end
                case 'rec'
                    rates_i_filled = rates(1,1);
            end
        end

        function setLockNode(obj)
            nhe = sum(obj.trinode(:,3)==min(obj.trinode(:,3)));  %number of mesh nodes along strike
            if nhe >= 16
                obj.nodes.flag_locking = true;
                nve = size(obj.trinode,1)/nhe;
                nodeindex_strike = round(1:8:nhe);  %node indices along strike to use fo slip nodes
                nodeindex_dip = round(1:3:nve);   %node indices along dip to use fo slip nodes
                obj.nodes.segments.nhe = numel(nodeindex_dip);

                locking = [];
                for k=1:numel(nodeindex_dip)
                    locking = [locking; obj.trinode(nodeindex_strike+(nodeindex_dip(k)-1)*nhe,:)];
                end
            else
                locking = [];
            end
            obj.nodes.lock_nodes = locking;
         end

         function Idx = setLockingPatches(obj, upper, lower)
            upper = upper(:);
            lower = lower(:);
            nhe = obj.nodes.segments.nhe;
            if obj.nodes.flag_locking == true
                locking_nodes = obj.nodes.lock_nodes;
                centers = obj.patch_stuff.centroids_faces;
                upperLd = griddata(locking_nodes(:,1),locking_nodes(:,2),repmat(upper,nhe,1),centers(:,1),centers(:,2));
                lowerLd = griddata(locking_nodes(:,1),locking_nodes(:,2),repmat(lower,nhe,1),centers(:,1),centers(:,2));
                
                % Identify NaN and non-NaN indices in rates_i
                nanIdx = find(isnan(upperLd));       % Indices of NaN values
                nonNanIdx = find(~isnan(upperLd));   % Indices of non-NaN values
                
                % Get coordinates of NaN and non-NaN centers
                nanCenters = centers(nanIdx, :);       % Centers corresponding to NaN values
                nonNanCenters = centers(nonNanIdx, :); % Centers corresponding to non-NaN values
            
                % Find nearest neighbors for NaN centers in the non-NaN centers
                [nearestIdx, ~] = knnsearch(nonNanCenters, nanCenters);

                upperLd_i = upperLd; % Copy original array
                upperLd_i(nanIdx) = upperLd(nonNanIdx(nearestIdx));
                lowerLd_i = lowerLd; % Copy original array
                lowerLd_i(nanIdx) = lowerLd(nonNanIdx(nearestIdx));

                Idx = (abs(centers(:,3)) > upperLd_i) & (abs(centers(:,3)) < lowerLd_i);
            else
                Idx = abs(obj.patch_stuff.centroids_faces(:,3)) > upper & abs(obj.patch_stuff.centroids_faces(:,3)) < lower;
            end
        end

        function AssignIniitialValues(obj)
            switch obj.nodes.flag
                case true
                    switch obj.fault_name
                        case 'detachment'
                            obj.nodes.rates.ss = ones(size(obj.nodes.slip_nodes,1),1)*(-20 + obj.bounds.ss.upper() + obj.bounds.ss.lower())/2 ;
                            obj.nodes.rates.ds = ones(size(obj.nodes.slip_nodes,1),1)*(obj.bounds.ds.upper() + obj.bounds.ds.lower())/2;
                            obj.nodes.rates.ds(end) = 0;
                        otherwise
                            obj.nodes.rates.ss = ones(obj.nodes.segments.s_nodes,1)*(obj.bounds.ss.upper() + obj.bounds.ss.lower())/2;
                            obj.nodes.rates.ds = ones(obj.nodes.segments.s_nodes,1)*(obj.bounds.ds.upper() + obj.bounds.ds.lower())/2;
                    end
                otherwise
                    obj.nodes.rates.ss = (obj.bounds.ss.upper() + obj.bounds.ss.lower())/2;
                    obj.nodes.rates.ds = (obj.bounds.ds.upper() + obj.bounds.ds.lower())/2;
            end
            switch obj.nodes.flag_locking
                case true
                    obj.nodes.rates.upperLd = ones(size(obj.nodes.lock_nodes,1)/obj.nodes.segments.nhe,1)*obj.bounds.upperLd();
                    obj.nodes.rates.lowerLd = ones(size(obj.nodes.lock_nodes,1)/obj.nodes.segments.nhe,1)*obj.bounds.lowerLd();
                otherwise
                    obj.nodes.rates.upperLd = obj.bounds.upperLd();
                    obj.nodes.rates.lowerLd = obj.bounds.lowerLd();
            end
            obj.nodes.ss_i = obj.GetRate(obj.nodes.rates.ss);
            obj.nodes.ds_i = obj.GetRate(obj.nodes.rates.ds);
        end


        function getSingleFault_within(obj)
            switch obj.meshtype
                case 'tri'
                    obj.contribution.Vhat_u_lt = obj.G_mcmc.Glt_lt_u_ss*obj.nodes.ss_i + obj.G_mcmc.Glt_lt_u_ds*obj.nodes.ds_i;
                    obj.contribution.Vhat_e = obj.G_mcmc.Glt_e_ss*obj.nodes.ss_i + obj.G_mcmc.Glt_e_ds*obj.nodes.ds_i + obj.G_mcmc.Gbs_e_ss * (obj.nodes.ss_i .* obj.nodes.locking_patches) + obj.G_mcmc.Gbs_e_ds * (obj.nodes.ds_i .* obj.nodes.locking_patches);
                    obj.contribution.Vhat_n = obj.G_mcmc.Glt_n_ss*obj.nodes.ss_i + obj.G_mcmc.Glt_n_ds*obj.nodes.ds_i + obj.G_mcmc.Gbs_n_ss * (obj.nodes.ss_i .* obj.nodes.locking_patches) + obj.G_mcmc.Gbs_n_ds * (obj.nodes.ds_i .* obj.nodes.locking_patches);
                    obj.contribution.Vhat_u = obj.G_mcmc.Glt_u_ss*obj.nodes.ss_i + obj.G_mcmc.Glt_u_ds*obj.nodes.ds_i + obj.G_mcmc.Gbs_u_ss * (obj.nodes.ss_i .* obj.nodes.locking_patches) + obj.G_mcmc.Gbs_u_ds * (obj.nodes.ds_i .* obj.nodes.locking_patches);
                case 'rec'
                    e = obj.G_mcmc.Gloading_e_ss*obj.nodes.rates.ss + obj.G_mcmc.Gloading_e_ds*obj.nodes.rates.ds;
                    n = obj.G_mcmc.Gloading_n_ss*obj.nodes.rates.ss + obj.G_mcmc.Gloading_n_ds*obj.nodes.rates.ds;
                    u = obj.G_mcmc.Gloading_u_ss*obj.nodes.rates.ss + obj.G_mcmc.Gloading_u_ds*obj.nodes.rates.ds;

                    obj.contribution.Vhat_u_lt = u(obj.num_lt==2,:);
                    obj.contribution.Vhat_e = e(obj.num_e,:);
                    obj.contribution.Vhat_n = n(obj.num_n,:);
                    obj.contribution.Vhat_u = u(obj.num_u,:);
            end
        end

        function getSingleFault(obj, rates_struct)
            switch obj.meshtype
                case 'tri'
                    obj.contribution.Vhat_u_lt = obj.G_mcmc.Glt_lt_u_ss*rates_struct.ss_i + obj.G_mcmc.Glt_lt_u_ds*rates_struct.ds_i;
                    obj.contribution.Vhat_e = obj.G_mcmc.Glt_e_ss*rates_struct.ss_i + obj.G_mcmc.Glt_e_ds*rates_struct.ds_i + obj.G_mcmc.Gbs_e_ss * (rates_struct.ss_i .* rates_struct.locking_patches) + obj.G_mcmc.Gbs_e_ds * (rates_struct.ds_i .* rates_struct.locking_patches);
                    obj.contribution.Vhat_n = obj.G_mcmc.Glt_n_ss*rates_struct.ss_i + obj.G_mcmc.Glt_n_ds*rates_struct.ds_i + obj.G_mcmc.Gbs_n_ss * (rates_struct.ss_i .* rates_struct.locking_patches) + obj.G_mcmc.Gbs_n_ds * (rates_struct.ds_i .* rates_struct.locking_patches);
                    obj.contribution.Vhat_u = obj.G_mcmc.Glt_u_ss*rates_struct.ss_i + obj.G_mcmc.Glt_u_ds*rates_struct.ds_i + obj.G_mcmc.Gbs_u_ss * (rates_struct.ss_i .* rates_struct.locking_patches) + obj.G_mcmc.Gbs_u_ds * (rates_struct.ds_i .* rates_struct.locking_patches);
                case 'rec'
                    e = obj.G_mcmc.Gloading_e_ss*rates_struct.ss_i + obj.G_mcmc.Gloading_e_ds*rates_struct.ds_i;
                    n = obj.G_mcmc.Gloading_n_ss*rates_struct.ss_i + obj.G_mcmc.Gloading_n_ds*rates_struct.ds_i;
                    u = obj.G_mcmc.Gloading_u_ss*rates_struct.ss_i + obj.G_mcmc.Gloading_u_ds*rates_struct.ds_i;

                    obj.contribution.Vhat_u_lt = u(obj.num_lt==2,:);
                    obj.contribution.Vhat_e = e(obj.num_e,:);
                    obj.contribution.Vhat_n = n(obj.num_n,:);
                    obj.contribution.Vhat_u = u(obj.num_u,:);
            end
        end

        function [Vhat_u_lt, Vhat_e, Vhat_n, Vhat_u] = getSingleFault_saved(obj, rates_struct)
            switch obj.meshtype
                case 'tri'
                    Vhat_u_lt = obj.G_mcmc.Glt_lt_u_ss*rates_struct.ss_i + obj.G_mcmc.Glt_lt_u_ds*rates_struct.ds_i;
                    Vhat_e = obj.G_mcmc.Glt_e_ss*rates_struct.ss_i + obj.G_mcmc.Glt_e_ds*rates_struct.ds_i + obj.G_mcmc.Gbs_e_ss * (rates_struct.ss_i .* rates_struct.locking_patches) + obj.G_mcmc.Gbs_e_ds * (rates_struct.ds_i .* rates_struct.locking_patches);
                    Vhat_n = obj.G_mcmc.Glt_n_ss*rates_struct.ss_i + obj.G_mcmc.Glt_n_ds*rates_struct.ds_i + obj.G_mcmc.Gbs_n_ss * (rates_struct.ss_i .* rates_struct.locking_patches) + obj.G_mcmc.Gbs_n_ds * (rates_struct.ds_i .* rates_struct.locking_patches);
                    Vhat_u = obj.G_mcmc.Glt_u_ss*rates_struct.ss_i + obj.G_mcmc.Glt_u_ds*rates_struct.ds_i + obj.G_mcmc.Gbs_u_ss * (rates_struct.ss_i .* rates_struct.locking_patches) + obj.G_mcmc.Gbs_u_ds * (rates_struct.ds_i .* rates_struct.locking_patches);
                case 'rec'
                    e = obj.G_mcmc.Gloading_e_ss*rates_struct.ss_i + obj.G_mcmc.Gloading_e_ds*rates_struct.ds_i;
                    n = obj.G_mcmc.Gloading_n_ss*rates_struct.ss_i + obj.G_mcmc.Gloading_n_ds*rates_struct.ds_i;
                    u = obj.G_mcmc.Gloading_u_ss*rates_struct.ss_i + obj.G_mcmc.Gloading_u_ds*rates_struct.ds_i;

                    Vhat_u_lt = u(obj.num_lt==2,:);
                    Vhat_e = e(obj.num_e,:);
                    Vhat_n = n(obj.num_n,:);
                    Vhat_u = u(obj.num_u,:);
            end
        end

        % calculate greens function
        % tri fault
        function tri_green(obj,xy_stats)
            disp(['Now working on: ' obj.fault_name])
            staxy = [xy_stats';zeros(1,size(xy_stats,1))];
            TriCenter = obj.patch_stuff.centroids_faces;
            TriArea = obj.patch_stuff.area_faces;
            TriDip = obj.patch_stuff.dip_faces;
            TriStrike = obj.patch_stuff.strike_faces;
            nd = obj.trinode;
            trind = obj.tri;
            Zro = zeros(size(xy_stats,1),size(trind,1));
            obj.Greens.ss.elastic.e = Zro;
            obj.Greens.ss.elastic.n = Zro;
            obj.Greens.ss.elastic.u = Zro;
            obj.Greens.ss.viscoelastic.e = Zro;
            obj.Greens.ss.viscoelastic.n = Zro;
            obj.Greens.ss.viscoelastic.u = Zro;
            obj.Greens.ds.elastic.e = Zro;
            obj.Greens.ds.elastic.n = Zro;
            obj.Greens.ds.elastic.u = Zro;
            obj.Greens.ds.viscoelastic.e = Zro;
            obj.Greens.ds.viscoelastic.n = Zro;
            obj.Greens.ds.viscoelastic.u = Zro;

            for j=1:size(trind,1)
                % elastic
                temp1{1} = nd;
                temp2{1} = trind(j,:);
                [Uss, ~, ~] = tridisloc3d(staxy, temp1{1}', temp2{1}', [-1 0 0]', 1, .25);   %positive indicates LL slip
                [Uds, ~, ~] = tridisloc3d(staxy, temp1{1}', temp2{1}', [0 -1 0]', 1, .25);  %negative indicates reverse slip
                obj.Greens.ss.elastic.e(:,j) = Uss(1,:)';
                obj.Greens.ss.elastic.n(:,j) = Uss(2,:)';
                obj.Greens.ss.elastic.u(:,j) = Uss(3,:)';
                obj.Greens.ds.elastic.e(:,j) = Uds(1,:)';
                obj.Greens.ds.elastic.n(:,j) = Uds(2,:)';
                obj.Greens.ds.elastic.u(:,j) = Uds(3,:)';
                % viscoelastic
                if -TriCenter(j,3)<obj.H
                    Uss=LayeredBasis_viscous_tri(TriCenter(j,:),TriArea(j),TriDip(j),TriStrike(j),[1 0 0],staxy,obj.H,1,1,10^6,1);  %RL
                    Uds=LayeredBasis_viscous_tri(TriCenter(j,:),TriArea(j),TriDip(j),TriStrike(j),[0 1 0],staxy,obj.H,1,1,10^6,1);  %Reverse
                else
                    Uss = zeros(3,size(xy_stats,1));
                    Uds = zeros(3,size(xy_stats,1));
                end
                obj.Greens.ss.viscoelastic.e(:,j) = Uss(1,:)';
                obj.Greens.ss.viscoelastic.n(:,j) = Uss(2,:)';
                obj.Greens.ss.viscoelastic.u(:,j) = Uss(3,:)';
                obj.Greens.ds.viscoelastic.e(:,j) = Uds(1,:)';
                obj.Greens.ds.viscoelastic.n(:,j) = Uds(2,:)';
                obj.Greens.ds.viscoelastic.u(:,j) = Uds(3,:)';
            end
            disp(['Completed Greens Function for: ' obj.fault_name])
            disp('--------------------')
        end

        % rec fault
        function rec_green(obj,xy_stats)
            disp(['Now working on: ' obj.fault_name])
            pm_rec = obj.pm;
            Zro = zeros(size(xy_stats,1),size(pm_rec,1));
            obj.Greens.ss.elastic.e = Zro;
            obj.Greens.ss.elastic.n = Zro;
            obj.Greens.ss.elastic.u = Zro;
            obj.Greens.ss.viscoelastic.e = Zro;
            obj.Greens.ss.viscoelastic.n = Zro;
            obj.Greens.ss.viscoelastic.u = Zro;
            obj.Greens.ds.elastic.e = Zro;
            obj.Greens.ds.elastic.n = Zro;
            obj.Greens.ds.elastic.u = Zro;
            obj.Greens.ds.viscoelastic.e = Zro;
            obj.Greens.ds.viscoelastic.n = Zro;
            obj.Greens.ds.viscoelastic.u = Zro;

            for j=1:size(pm_rec,1)
                %shift fault down to avoid rounding error at free
                %surface
                pm_rec(j,3) = pm_rec(j,3) + 10^-5;
                %elastic
                [Uss,~,~,~]=disloc3d([pm_rec(j,:) -1 0 0]',[xy_stats';zeros(1,size(xy_stats',2))],1,.25);
                [Uds,~,~,~]=disloc3d([pm_rec(j,:) 0 1 0]',[xy_stats';zeros(1,size(xy_stats',2))],1,.25);
                obj.Greens.ss.elastic.e(:,j) = Uss(1,:)';
                obj.Greens.ss.elastic.n(:,j) = Uss(2,:)';
                obj.Greens.ss.elastic.u(:,j) = Uss(3,:)';
                obj.Greens.ds.elastic.e(:,j) = Uds(1,:)';
                obj.Greens.ds.elastic.n(:,j) = Uds(2,:)';
                obj.Greens.ds.elastic.u(:,j) = Uds(3,:)';

                %viscoelastic
                Uss = LayeredBasis_viscous([pm_rec(j,:) 1 0 0]',xy_stats',obj.H,1,1,10^6,1); 
                Uds = LayeredBasis_viscous([pm_rec(j,:) 0 1 0]',xy_stats',obj.H,1,1,10^6,1);
                obj.Greens.ss.viscoelastic.e(:,j) = Uss(1,:)';
                obj.Greens.ss.viscoelastic.n(:,j) = Uss(2,:)';
                obj.Greens.ss.viscoelastic.u(:,j) = Uss(3,:)';
                obj.Greens.ds.viscoelastic.e(:,j) = Uds(1,:)';
                obj.Greens.ds.viscoelastic.n(:,j) = Uds(2,:)';
                obj.Greens.ds.viscoelastic.u(:,j) = Uds(3,:)';
            end
            disp(['Completed Greens Function for: ' obj.fault_name])
        end

        function plot_trace(obj)
            switch obj.meshtype
                case 'tri'
                plot(obj.trinode(obj.trinode(:,3)==max(obj.trinode(:,3)),1),obj.trinode(obj.trinode(:,3)==max(obj.trinode(:,3)),2),'black','HandleVisibility','off')
                otherwise
                    
            end
        end

        function make_G(obj, data)
            switch obj.meshtype
                case 'tri'
                % general G
                % long-term = elastic + viscoelastic
                lt_e_ss = obj.Greens.ss.elastic.e() + obj.Greens.ss.viscoelastic.e();
                lt_n_ss = obj.Greens.ss.elastic.n() + obj.Greens.ss.viscoelastic.n();
                lt_u_ss = obj.Greens.ss.elastic.u() + obj.Greens.ss.viscoelastic.u();
                
                lt_e_ds = obj.Greens.ds.elastic.e() + obj.Greens.ds.viscoelastic.e();
                lt_n_ds = obj.Greens.ds.elastic.n() + obj.Greens.ds.viscoelastic.n();
                lt_u_ds = obj.Greens.ds.elastic.u() + obj.Greens.ds.viscoelastic.u();
                
                % back-slip = -elastic
                bs_e_ss = -1*obj.Greens.ss.elastic.e();
                bs_n_ss = -1*obj.Greens.ss.elastic.n();
                bs_u_ss = -1*obj.Greens.ss.elastic.u();
                
                bs_e_ds = -1*obj.Greens.ds.elastic.e();
                bs_n_ds = -1*obj.Greens.ds.elastic.n();
                bs_u_ds = -1*obj.Greens.ds.elastic.u();
    
                % setup the actually G for mcmc
                Glt_lt_u_ss = lt_u_ss(data.data_type==2,:);
                Glt_lt_u_ds = lt_u_ds(data.data_type==2,:);
            
                % horizontal and vertical, long-term (for calculate short-term)
                Glt_e_ss = lt_e_ss(data.notnanind_east,:);
                Glt_e_ds = lt_e_ds(data.notnanind_east,:);
                Glt_n_ss = lt_n_ss(data.notnanind_north,:);
                Glt_n_ds = lt_n_ds(data.notnanind_north,:);
                Glt_u_ss = lt_u_ss(data.notnanind_up,:);
                Glt_u_ds = lt_u_ds(data.notnanind_up,:);
            
                % horizontal and vertical, bacl-slip (for calculate short-term)
                Gbs_e_ss = bs_e_ss(data.notnanind_east,:);
                Gbs_e_ds = bs_e_ds(data.notnanind_east,:);
                Gbs_n_ss = bs_n_ss(data.notnanind_north,:);
                Gbs_n_ds = bs_n_ds(data.notnanind_north,:);
                Gbs_u_ss = bs_u_ss(data.notnanind_up,:);
                Gbs_u_ds = bs_u_ds(data.notnanind_up,:);

                obj.G_mcmc = struct( ...
                    'Glt_lt_u_ss',Glt_lt_u_ss, ...
                    'Glt_lt_u_ds',Glt_lt_u_ds, ...
                    'Glt_e_ss',Glt_e_ss, ...
                    'Glt_e_ds',Glt_e_ds, ...
                    'Glt_n_ss',Glt_n_ss, ...
                    'Glt_n_ds',Glt_n_ds, ...
                    'Glt_u_ss',Glt_u_ss, ...
                    'Glt_u_ds',Glt_u_ds, ...
                    'Gbs_e_ss',Gbs_e_ss, ...
                    'Gbs_e_ds',Gbs_e_ds, ...
                    'Gbs_n_ss',Gbs_n_ss, ...
                    'Gbs_n_ds',Gbs_n_ds, ...
                    'Gbs_u_ss',Gbs_u_ss, ...
                    'Gbs_u_ds',Gbs_u_ds ...
                );
            case 'rec'
                Gloading_e_ss = obj.Greens.ss.elastic.e() + obj.Greens.ss.viscoelastic.e();
                Gloading_n_ss = obj.Greens.ss.elastic.n() + obj.Greens.ss.viscoelastic.n();
                Gloading_u_ss = obj.Greens.ss.elastic.u() + obj.Greens.ss.viscoelastic.u();
                
                Gloading_e_ds = obj.Greens.ds.elastic.e() + obj.Greens.ds.viscoelastic.e();
                Gloading_n_ds = obj.Greens.ds.elastic.n() + obj.Greens.ds.viscoelastic.n();
                Gloading_u_ds = obj.Greens.ds.elastic.u() + obj.Greens.ds.viscoelastic.u();
                obj.G_mcmc = struct( ...
                    'Gloading_e_ss',Gloading_e_ss, ...
                    'Gloading_e_ds',Gloading_e_ds, ...
                    'Gloading_n_ss',Gloading_n_ss, ...
                    'Gloading_n_ds',Gloading_n_ds, ...
                    'Gloading_u_ss',Gloading_u_ss, ...
                    'Gloading_u_ds',Gloading_u_ds ...
                );
            end
        end

    end

    methods(Static)

        function pm = parm4rec(rec_data, H)
            SegEnds = rec_data(:,1:4);
            dip = rec_data(:,5);
            

            %calculate lengths of segments
            SegLength=sqrt((SegEnds(:,1)-SegEnds(:,3)).^2+(SegEnds(:,2)-SegEnds(:,4)).^2);
            %calculate strike of segments
            angle=atan2(SegEnds(:,4)-SegEnds(:,2),SegEnds(:,3)-SegEnds(:,1));
            strike=90-angle*180/pi;


            %faults=[length, width, *depth, dip, strike(degrees), *north offset, *east offset]
            % *depth to top edge, north and east offsets refer to location of center of top edge
            widths=H./sin(dip*pi/180);
            temp=abs(widths).*cos(dip*pi/180);
            xoffset=-temp.*cos(pi/2+angle);
            yoffset=-temp.*sin(pi/2+angle);
            faults=[SegLength widths H*ones(size(SegLength)) dip strike .5*(SegEnds(:,1)+SegEnds(:,3))+xoffset .5*(SegEnds(:,2)+SegEnds(:,4))+yoffset];

            nhe = ones(size(SegLength,1));
            nve=1;

            pm=zeros(size(faults,1),7);

            for j=1:size(faults,1)

                %specify components of slip to be calculate ([strike-slip,dip-slip,opening]) -- e.g. [0 1 0] means dip slip only
                dis_geom  = [faults(j,:), [1 1 0]];

                % Create slip patches
                pf = patchfault(dis_geom(1,1:7),nhe(j),nve);
                pm(j,:) = pf;
            end
        end
    end

end