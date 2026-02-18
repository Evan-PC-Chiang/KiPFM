function [name, dipmesh] = make_fault(filepath, origin, dp, dz)
% -------------------------------------------------------------------------
% Generates a 3D fault surface from surface traces and a dipping angle.
%
% This script uses the right-hand rule: if you align your right hand 
% with the fault trace direction, the dipping side is on the palm side.
%
% INPUT:
%   - filepath: .txt file containing fault trace points in WGS84 
%               (latitude, longitude)
%   - origin: [lat long] used to convert WGS84 into local XY coordinates
%   - dp: vector of dip angles (degrees), matched to depth profile
%   - dz: vector of depths (same length as dp), in km or meters
%
% OUTPUT:
%   - name: string, name of the fault (extracted from file name)
%   - dipmesh: structure with 'el' (element list) and 'nodes' (XYZ coords)
%
% The surface is built by projecting from the surface trace down to depth
% using dip and right-hand-rule orientation, and triangulated into a mesh.
%
% This function is based on Yo Fukushima's method, 9 Jul 2010.
%
% Author: Ping-Chen Chiang
% Date: 2025-09-15
% -------------------------------------------------------------------------

    % Input validation for types and dimensions
    assert(ischar(filepath) || isstring(filepath), 'name must be a string or char');
    assert(isvector(dp) && isnumeric(dp), 'dp must be a numeric vector');
    assert(isvector(dz) && isnumeric(dz), 'dz must be a numeric vector');
    assert(length(dp) == length(dz), 'dp and dz must be the same length');

    % Extract fault name from filepath (remove extension)
    filename_cell = regexp(filepath, '([^/\\]+)\.txt$', 'tokens', 'once');
    name = string(filename_cell{1});

    % Load trace data (in WGS84) from the file
    traces_WGS84 = load("traces/" + name + ".txt");

    % Project trace from WGS84 (lat/lon) to local X/Y using provided origin
    local_trace = llh2local(traces_WGS84', origin)';

    % Nominal horizontal spacing of fault patches (km)
    intv = 5;

    % Compute segments from consecutive trace points
    edge_temp = [];
    for i = 1:length(local_trace)-1
        edge_temp = [edge_temp; local_trace(i+1,1) local_trace(i,1) ...
                               local_trace(i+1,2) local_trace(i,2)];
    end

    % Calculate azimuth angle of each segment
    angle = atan2(edge_temp(:,4)-edge_temp(:,3), ...
                  edge_temp(:,2)-edge_temp(:,1));

    % Get segment-normal unit vectors (Right-Hand Rule)
    SegNorm_detach = [sin(angle) -cos(angle)];

    % Construct the upper edge of the fault surface
    if size(edge_temp,1) > 1
        if edge_temp(1,2) == edge_temp(2,1) 
            up_edge = [[edge_temp(:,1) edge_temp(:,3)]; edge_temp(end,[2 4])];
        else
            up_edge = [edge_temp(1,[2 4]); [edge_temp(:,1) edge_temp(:,3)]];
        end   
    else
        up_edge = [edge_temp(1,[1 3]); edge_temp(1,[2 4])];
    end

    % Interpolate more points along the upper edge to densify the surface
    Uedge = [];
    for k = 1:size(up_edge,1)-1
        Uedge = [Uedge; ...
            [linspace(up_edge(k,1), up_edge(k+1,1), 10)', ...
             linspace(up_edge(k,2), up_edge(k+1,2), 10)']];
    end
    up_edge = Uedge;

    % Compute average normal vector (used to project points down-dip)
    avnorm = mean(SegNorm_detach,1);

    % Generate contour depths (from surface to maximum depth)
    numcontrs = 50;
    depths = -linspace(dz(1), dz(end), numcontrs);  % Negative = downward

    % Interpolate dip values along depth profile
    dps = interp1(-dz, dp, depths);

    % Compute horizontal distance for each depth step based on dip
    hspace = -diff(depths) ./ tan(dps(1:end-1) * pi / 180);
    hspace = [0 cumsum(hspace)];

    % Project contours down along dip direction to form 3D structure
    contrkm = [];
    for k = 1:numcontrs
        contrkm = [contrkm; ...
            [up_edge(:,1) + avnorm(1) * hspace(k), ...
             up_edge(:,2) + avnorm(2) * hspace(k), ...
             repmat(depths(k), size(up_edge,1), 1)]];
    end

    %% --- Mesh generation using Yo Fukushima's code ---

    % Identify top and bottom contour points
    ind = (contrkm(:,3) == contrkm(1,3));  % top contour
    nodet0 = contrkm(ind,:);
    ind = (contrkm(:,3) == contrkm(end,3));  % bottom contour
    nodeb0 = contrkm(ind,:);

    % Resample top and bottom edges to have uniform spacing
    N = round(curvlength(nodet0) ./ intv);
    nodet = curvspace(nodet0, N);
    N = round(curvlength(nodeb0) ./ intv);
    nodeb = curvspace(nodeb0, N);

    % Generate triangular mesh between top and bottom contours
    [nd0, el] = meshfrac2(nodet, nodeb, intv);

    % Interpolate Z values (depths) using the full contour set
    [xi, yi, zi] = griddata(contrkm(:,1), contrkm(:,2), contrkm(:,3), ...
                            nd0(:,1), nd0(:,2), 'linear');

    % Fill in NaN gaps in interpolated surface using nearest neighbor
    i = isnan(xi) | isnan(yi) | isnan(zi);
    [xi_p, yi_p, zi_p] = griddata(contrkm(:,1), contrkm(:,2), contrkm(:,3), ...
                                  nd0(i,1), nd0(i,2), 'nearest');
    xi(i) = xi_p; yi(i) = yi_p; zi(i) = zi_p;

    % Replace Z values (except at top and bottom) with interpolated ones
    ind = find(nd0(:,3) ~= nd0(1,3) & nd0(:,3) ~= nd0(end,3));
    nd = nd0;
    nd(ind,:) = [xi(ind), yi(ind), zi(ind)];

    % Store final mesh into dipmesh structure
    faultnum = 1;
    dipmesh.el{faultnum} = el;
    dipmesh.nodes{faultnum} = nd;

    % Optional: visualize the result in 2D
    for k = 1:length(dipmesh.nodes)
        h = trisurf(dipmesh.el{k}, ...
            dipmesh.nodes{k}(:,1), ...
            dipmesh.nodes{k}(:,2), ...
            dipmesh.nodes{k}(:,3));
        colorbar; view(2); daspect([1,1,1]);
        set(h, 'FaceAlpha', 0.5);
    end

end