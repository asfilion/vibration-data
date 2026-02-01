function T = queryData(options)
%QUERYDATA Query sensor data with catalog-based filtering
%
%   T = queryData()                          % Load all data
%   T = queryData(FaultType="BPFI")          % Filter by fault type
%   T = queryData(Load="0Nm", Channels="Vibration")
%   T = queryData(SessionID=["0Nm_BPFI_03", "0Nm_BPFI_10"])
%
%   Uses catalog for pre-filtering when querying by session metadata.
%   Uses rowfilter for channel filtering (always efficient).

arguments
    options.DataPath (1,1) string = "processed/data"
    options.CatalogPath (1,1) string = "processed/catalog.parquet"
    options.SessionID (:,1) string = []
    options.FaultType (:,1) string = []
    options.Load (:,1) string = []
    options.Severity (:,1) string = []
    options.Channels (:,1) string = []  % "Vibration", "Temperature", "Current", or specific names
end

PUSHDOWN_THRESHOLD = 50;

% Load catalog for metadata filtering
catalog = parquetread(options.CatalogPath);
sessionFilter = catalog.SessionID;

% Apply metadata filters using catalog (fast, in-memory)
if ~isempty(options.FaultType)
    mask = ismember(catalog.FaultType, options.FaultType);
    sessionFilter = intersect(sessionFilter, catalog.SessionID(mask));
end

if ~isempty(options.Load)
    mask = ismember(catalog.Load, options.Load);
    sessionFilter = intersect(sessionFilter, catalog.SessionID(mask));
end

if ~isempty(options.Severity)
    mask = ismember(catalog.Severity, options.Severity);
    sessionFilter = intersect(sessionFilter, catalog.SessionID(mask));
end

if ~isempty(options.SessionID)
    sessionFilter = intersect(sessionFilter, options.SessionID);
end

% Build datastore
pds = parquetDatastore(fullfile(options.DataPath, "*.parquet"));

% Determine query strategy
nSessions = numel(sessionFilter);
useInMemoryFilter = nSessions > PUSHDOWN_THRESHOLD || nSessions == height(catalog);

% Build rowfilter
info = parquetinfo(pds.Files{1});
hasFilter = false;

% Session filter - only pushdown for small queries
if nSessions < height(catalog) && ~useInMemoryFilter
    rf = buildOrFilter(rowfilter(info), "SessionID", sessionFilter);
    pds.RowFilter = rf;
    hasFilter = true;
end

% Channel filter - always use pushdown (few conditions, very efficient)
if ~isempty(options.Channels)
    % Map channel type to specific names if needed
    channelFilter = options.Channels;
    if any(ismember(channelFilter, ["Vibration", "Temperature", "Current"]))
        % Filter by type
        channelRf = buildOrFilter(rowfilter(info), "ChannelType", channelFilter);
    else
        % Filter by name
        channelRf = buildOrFilter(rowfilter(info), "ChannelName", channelFilter);
    end

    if hasFilter
        pds.RowFilter = pds.RowFilter & channelRf;
    else
        pds.RowFilter = channelRf;
    end
end

% Read data
T = readall(pds);

% In-memory filter for large session queries
if useInMemoryFilter && nSessions < height(catalog)
    T = T(ismember(T.SessionID, sessionFilter), :);
end

fprintf("Loaded %d rows (%d sessions, %d channels)\n", ...
    height(T), numel(unique(T.SessionID)), numel(unique(T.ChannelName)));
end


function condition = buildOrFilter(rf, column, values)
%BUILDORFILTER Build OR filter for rowfilter
    condition = rf.(column) == values(1);
    for ii = 2:numel(values)
        condition = condition | rf.(column) == values(ii);
    end
end
