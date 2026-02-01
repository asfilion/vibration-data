function wideTable = nested2wide(nestedTable, options)
%NESTED2WIDE Convert nested sensor data to wide timetable format
%
%   wideTable = nested2wide(nestedTable)
%   wideTable = nested2wide(nestedTable, SessionID="0Nm_BPFI_03")
%
%   Converts nested format (one row per channel) to wide timetable format
%   (one column per channel, rows are time samples).
%
%   Input: Table with SessionID, ChannelName, Time, Values columns
%   Output: Timetable with time as row times and channels as columns

arguments
    nestedTable table
    options.SessionID (1,1) string = ""
end

% Filter to single session if specified
if options.SessionID ~= ""
    nestedTable = nestedTable(nestedTable.SessionID == options.SessionID, :);
end

% Get unique sessions
sessions = unique(nestedTable.SessionID);

if numel(sessions) > 1
    % Multiple sessions - return cell array of timetables
    wideTable = cell(numel(sessions), 1);
    for ii = 1:numel(sessions)
        sessionData = nestedTable(nestedTable.SessionID == sessions(ii), :);
        wideTable{ii} = convertOneSession(sessionData);
    end
else
    % Single session - return timetable directly
    wideTable = convertOneSession(nestedTable);
end
end


function tt = convertOneSession(sessionData)
%CONVERTONESESSION Convert one session's nested data to timetable

% Get time vector (same for all channels after resampling)
timeVec = sessionData.Time{1};
fs = sessionData.SampleRate(1);

% Create time vector as duration
timeDuration = seconds(timeVec);

% Build data matrix and variable names
nChannels = height(sessionData);
nSamples = numel(timeVec);
dataMatrix = zeros(nSamples, nChannels);
varNames = cell(1, nChannels);

for ii = 1:nChannels
    dataMatrix(:, ii) = sessionData.Values{ii};
    varNames{ii} = char(matlab.lang.makeValidName(sessionData.ChannelName(ii)));
end

% Create timetable
tt = array2timetable(dataMatrix, 'RowTimes', timeDuration, 'VariableNames', varNames);

% Add metadata
tt.Properties.UserData.SessionID = sessionData.SessionID(1);
tt.Properties.UserData.Load = sessionData.Load(1);
tt.Properties.UserData.FaultType = sessionData.FaultType(1);
tt.Properties.UserData.Severity = sessionData.Severity(1);
tt.Properties.UserData.SampleRate = fs;

% Add variable units
for ii = 1:height(sessionData)
    varName = matlab.lang.makeValidName(sessionData.ChannelName(ii));
    tt.Properties.VariableUnits{varName} = char(sessionData.Unit(ii));
end
end
