function catalog = buildCatalog(rawDir, options)
%BUILDCATALOG Build metadata catalog from raw MAT and TDMS files
%
%   catalog = buildCatalog(rawDir)
%   catalog = buildCatalog(rawDir, SavePath="catalog.parquet")
%
%   Extracts metadata from all MAT/TDMS file pairs and creates a catalog
%   table for efficient querying and filtering.

arguments
    rawDir (1,1) string = "rawdata"
    options.SavePath (1,1) string = ""
end

% Find all MAT files
matFiles = dir(fullfile(rawDir, "*.mat"));
nFiles = numel(matFiles);

fprintf("Building catalog from %d files...\n", nFiles);

% Preallocate catalog columns
SessionID = strings(nFiles, 1);
Load = strings(nFiles, 1);
FaultType = strings(nFiles, 1);
Severity = strings(nFiles, 1);
Duration_s = zeros(nFiles, 1);
MatFile = strings(nFiles, 1);
TdmsFile = strings(nFiles, 1);
MatSamples = zeros(nFiles, 1);
TdmsSamples = zeros(nFiles, 1);
MatFs = zeros(nFiles, 1);
TdmsFs = zeros(nFiles, 1);
NumVibrationChannels = zeros(nFiles, 1);
NumTempChannels = zeros(nFiles, 1);
NumCurrentChannels = zeros(nFiles, 1);
HasTdms = false(nFiles, 1);
FilenameTypo = false(nFiles, 1);

for ii = 1:nFiles
    % Parse filename
    [~, baseName, ~] = fileparts(matFiles(ii).name);
    parts = split(baseName, '_');

    SessionID(ii) = baseName;
    Load(ii) = parts{1};
    FaultType(ii) = parts{2};

    % Fix known typo
    if FaultType(ii) == "Unbalalnce"
        FaultType(ii) = "Unbalance";
        FilenameTypo(ii) = true;
    end

    if length(parts) >= 3
        Severity(ii) = parts{3};
    else
        Severity(ii) = "";
    end

    % MAT file path and metadata
    matPath = fullfile(rawDir, matFiles(ii).name);
    MatFile(ii) = matPath;

    matData = load(matPath);
    Signal = matData.Signal;
    MatSamples(ii) = Signal.x_values.number_of_values;
    MatFs(ii) = 1 / Signal.x_values.increment;
    Duration_s(ii) = MatSamples(ii) / MatFs(ii);
    NumVibrationChannels(ii) = size(Signal.y_values.values, 2);

    % Check for corresponding TDMS file
    tdmsPath = fullfile(rawDir, baseName + ".tdms");
    if isfile(tdmsPath)
        TdmsFile(ii) = tdmsPath;
        HasTdms(ii) = true;

        info = tdmsinfo(tdmsPath);
        dataChannels = info.ChannelList(info.ChannelList.NumSamples > 0, :);
        if height(dataChannels) > 0
            TdmsSamples(ii) = double(dataChannels.NumSamples(1));

            % Get sample rate from properties
            props = tdmsreadprop(tdmsPath, ...
                ChannelGroupName="Log", ...
                ChannelName=string(dataChannels.ChannelName(1)));
            TdmsFs(ii) = props.wf_samples;

            % Count channel types by unit
            units = string(dataChannels.Unit);
            NumTempChannels(ii) = sum(units == "°C");
            NumCurrentChannels(ii) = sum(units == "A");
        end
    else
        TdmsFile(ii) = "";
    end

    % Progress
    if mod(ii, 10) == 0 || ii == nFiles
        fprintf("  Processed %d/%d files\n", ii, nFiles);
    end
end

% Create catalog table
catalog = table( ...
    SessionID, Load, FaultType, Severity, Duration_s, ...
    MatFile, TdmsFile, HasTdms, ...
    MatSamples, TdmsSamples, MatFs, TdmsFs, ...
    NumVibrationChannels, NumTempChannels, NumCurrentChannels, ...
    FilenameTypo);

% Sort by Load, FaultType, Severity
catalog = sortrows(catalog, ["Load", "FaultType", "Severity"]);

% Save if requested
if options.SavePath ~= ""
    % Ensure output directory exists
    [outDir, ~, ~] = fileparts(options.SavePath);
    if outDir ~= "" && ~isfolder(outDir)
        mkdir(outDir);
    end
    parquetwrite(options.SavePath, catalog);
    fprintf("Catalog saved to: %s\n", options.SavePath);
end

fprintf("Catalog complete: %d sessions\n", height(catalog));
end
