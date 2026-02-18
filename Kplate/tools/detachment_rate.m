function detachment_rate(obj, xy_coast, origin, output_filename)
% obj: structure data (e.g., faults.detachment)
% xy_coast: coastline coordinates (Nx2) as [x, y]
% origin: reference origin for local2llh conversion
% output_filename: name of the output .txt file, e.g., 'detch_velo.txt'

% Compute slip vector and velocity magnitude
V = -obj.nodes.ss_i .* obj.patch_stuff.strikevec_faces - ...
    obj.nodes.ds_i .* obj.patch_stuff.dipvec_faces;
vel = sqrt(obj.nodes.ss_i.^2 + obj.nodes.ds_i.^2);
Vec = V ./ vel;

% Find the corresponding face centroids
loc = obj.nodes.slip_nodes(:, 1:2);
k = dsearchn(obj.patch_stuff.centroids_faces(:, 1:2), loc);

TriCenter_n = obj.patch_stuff.centroids_faces(k, :);
Vec_n = Vec(k, :);
V_n = V(k, :);
vel_n = vel(k, :);

% Plotting
figure('Position', [10 10 900 900]);
plot(xy_coast(:, 1), xy_coast(:, 2), 'k')
hold on;
axis equal
quiver(TriCenter_n(:, 1), TriCenter_n(:, 2), V_n(:, 1), V_n(:, 2))
title('Detachment Velocity Vectors')
xlabel('X [m]')
ylabel('Y [m]')

% Convert to geographic coordinates and write to file
xxyy = [local2llh([TriCenter_n(:,1), TriCenter_n(:,2)]', origin)' ...
        V_n(:,1), V_n(:,2), zeros(size(TriCenter_n,1), 3)];

writematrix(xxyy, output_filename, 'Delimiter', 'space');

fprintf('Output file saved: %s\n', output_filename)
end