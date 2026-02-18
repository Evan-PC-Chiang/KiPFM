function saveStructureToJSON(structVar, fileName)
    % saveStructureToJSON saves all fields of a given structure to a JSON file.
    % structVar: The structure variable to save
    % fileName: The name of the JSON file to create

    % Check if the input is a structure
    if ~isstruct(structVar)
        error('Input must be a structure.');
    end

    % Convert the structure to a JSON string
    jsonString = jsonencode(structVar);

    % Write the JSON string to the specified file
    fid = fopen(fileName, 'w');
    if fid == -1
        error('Could not create JSON file: %s', fileName);
    end
    fprintf(fid, '%s', jsonString);
    fclose(fid);

    disp(['Structure saved to JSON file: ', fileName]);
end