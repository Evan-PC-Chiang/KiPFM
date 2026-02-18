function [] = write_mesh(name, dipmesh)
% -------------------------------------------------------------------------
% Save the file into nodes and tri file.
%
% INPUT: output from make_fault
%
% OUTPUT: two file for ine inversion
%
% Author: Ping-Chen Chiang
% Date: 2025-09-15
% -------------------------------------------------------------------------
    filename = './fault_mesh_files/' + name + '_nodes.txt'; 
    writematrix(dipmesh.nodes{1}, filename, 'Delimiter', 'tab')
    filename = './fault_mesh_files/' + name + '_tri.txt';
    writematrix(dipmesh.el{1}, filename, 'Delimiter', 'tab')
disp("File " + name + " has saved in folder fault_mesh_files")
end

