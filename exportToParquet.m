function exportToParquet(catalog, outputPath, options)
%EXPORTTOPARQUET Export sensor data to Parquet format with preprocessing
%
%   exportToParquet(catalog, outputPath)
%   exportToParquet(catalog, outputPath, TargetFs=25600)
%
%   Exports all sessions to Parquet format with:
%   - TDMS resampled to match MAT sample rate
%   - All channels combined per session
%   - Nested schema (one row per channel per session)

arguments
    catalog table
    outputPath (1,1) string = "processed/data"
    options.TargetFs (1,1) double = 25600
    options.MaxFileSize (1,1) double = 1e9  % 1 GB
end

% Ensure output directory exists
if ~isfolder(outputPath)
    mkdir(outputPath);
end

nSessions = height(catalog);
fprintf("Exporting %d sessions to Parquet...\n", nSessions);

% Process each session
allTables = cell(nSessions, 1);
tableSizes = zeros(nSessions, 1);

for ii = 1:nSessions
    try
        [T, sizeBytes] = processOneSession(catalog(ii, :), options.TargetFs);
        allTables{ii} = T;
        tableSizes(ii) = sizeBytes;
    catch ME
        warning("Error processing %s: %s", catalog.SessionID(ii), ME.message);
    end

    % Progress
    if mod(ii, 10) == 0 || ii == nSessions
        fprintf("  Processed %d/%d sessions\n", ii, nSessions);
    end
end

% Remove empty entries
valid = ~cellfun(@isempty, allTables);
allTables = allTables(valid);
tableSizes = tableSizes(valid);

% Partition by size
chunks = partitionBySize(tableSizes, options.MaxFileSize);
fprintf("Writing %d Parquet file(s)...\n", numel(chunks));

% Write each chunk
for cc = 1:numel(chunks)
    idx = chunks{cc};
    combined = vertcat(allTables{idx});
    heights = cellfun(@height, allTables(idx));

    outFile = fullfile(outputPath, sprintf("data_%03d.parquet", cc));
    parquetwrite(outFile, combined, RowGroupHeights=heights);

    fileInfo = dir(outFile);
    fprintf("  Written: %s (%.2f MB)\n", outFile, fileInfo.bytes/1e6);
end

fprintf("Export complete.\n");
end


function [T, sizeBytes] = processOneSession(row, targetFs)
%PROCESSONESESSION Process one MAT/TDMS pair into nested table format

% Load MAT file (vibration data)
matData = load(row.MatFile);
Signal = matData.Signal;

vibration = Signal.y_values.values;  % [N x 4]
matFs = 1 / Signal.x_values.increment;
nSamples = size(vibration, 1);
tMat = (0:nSamples-1)' / matFs;  % Time vector

% Channel names from MAT file (stored as column char vectors, need to transpose)
vibNamesRaw = Signal.function_record.name;
vibNames = cellfun(@(x) string(x'), vibNamesRaw, 'UniformOutput', true);

% Load and resample TDMS if available
if row.HasTdms
    tdmsData = tdmsread(row.TdmsFile);
    logData = tdmsData{2};

    tdmsFs = row.TdmsFs;
    nTdmsSamples = height(logData);
    tTdms = (0:nTdmsSamples-1)' / tdmsFs;

    % Extract TDMS channels
    temp1 = logData{:, 1};
    temp2 = logData{:, 2};
    current1 = logData{:, 3};
    current2 = logData{:, 4};
    current3 = logData{:, 5};

    % Resample TDMS to target sample rate (linear interpolation)
    tTarget = tMat;  % Use MAT time vector as target
    temp1_rs = interp1(tTdms, temp1, tTarget, 'linear', 'extrap');
    temp2_rs = interp1(tTdms, temp2, tTarget, 'linear', 'extrap');
    current1_rs = interp1(tTdms, current1, tTarget, 'linear', 'extrap');
    current2_rs = interp1(tTdms, current2, tTarget, 'linear', 'extrap');
    current3_rs = interp1(tTdms, current3, tTarget, 'linear', 'extrap');
else
    % No TDMS - fill with NaN
    temp1_rs = nan(nSamples, 1);
    temp2_rs = nan(nSamples, 1);
    current1_rs = nan(nSamples, 1);
    current2_rs = nan(nSamples, 1);
    current3_rs = nan(nSamples, 1);
end

% Build nested table (one row per channel)
nChannels = 9;
SessionID = repmat(row.SessionID, nChannels, 1);
Load = repmat(row.Load, nChannels, 1);
FaultType = repmat(row.FaultType, nChannels, 1);
Severity = repmat(row.Severity, nChannels, 1);
SampleRate = repmat(targetFs, nChannels, 1);

% Channel metadata
ChannelName = [
    "Vibration_1"; "Vibration_2"; "Vibration_3"; "Vibration_4";
    "Temperature_1"; "Temperature_2";
    "Current_1"; "Current_2"; "Current_3"
];

ChannelType = [
    "Vibration"; "Vibration"; "Vibration"; "Vibration";
    "Temperature"; "Temperature";
    "Current"; "Current"; "Current"
];

Unit = [
    "g"; "g"; "g"; "g";
    "degC"; "degC";
    "A"; "A"; "A"
];

OriginalName = [
    vibNames(1); vibNames(2); vibNames(3); vibNames(4);
    "cDAQ9185-1F486B5Mod1/ai0"; "cDAQ9185-1F486B5Mod1/ai1";
    "cDAQ9185-1F486B5Mod2/ai0"; "cDAQ9185-1F486B5Mod2/ai2"; "cDAQ9185-1F486B5Mod2/ai3"
];

% Pack time and values into cells
Time = repmat({tMat}, nChannels, 1);
Values = {
    vibration(:,1); vibration(:,2); vibration(:,3); vibration(:,4);
    temp1_rs; temp2_rs;
    current1_rs; current2_rs; current3_rs
};

T = table(SessionID, Load, FaultType, Severity, SampleRate, ...
    ChannelName, ChannelType, Unit, OriginalName, Time, Values);

% Estimate size (conservative: 50% compression for cell arrays)
sizeBytes = nChannels * 200;  % Metadata overhead
for jj = 1:nChannels
    sizeBytes = sizeBytes + numel(Time{jj}) * 8 * 0.5;
    sizeBytes = sizeBytes + numel(Values{jj}) * 8 * 0.5;
end
end


function chunks = partitionBySize(sizes, maxSize)
%PARTITIONBYSIZE Greedy bin-packing to group items by size

chunks = {};
currentChunk = [];
currentSize = 0;

for ii = 1:numel(sizes)
    if currentSize + sizes(ii) > maxSize && ~isempty(currentChunk)
        chunks{end+1} = currentChunk; %#ok<AGROW>
        currentChunk = ii;
        currentSize = sizes(ii);
    else
        currentChunk = [currentChunk, ii]; %#ok<AGROW>
        currentSize = currentSize + sizes(ii);
    end
end

if ~isempty(currentChunk)
    chunks{end+1} = currentChunk;
end
end
