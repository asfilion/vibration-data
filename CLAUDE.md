# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MATLAB-based analysis of rotating machinery vibration data for fault diagnosis. The dataset contains multi-sensor measurements (vibration, acoustic, temperature, motor current) under varying load conditions with different fault types.

## Dataset

**Source:** [Mendeley Data - ztmf3m7h5x/6](https://data.mendeley.com/datasets/ztmf3m7h5x/6)

**Location:** `rawdata/`

**File naming:** `{Load}_{FaultType}_{Severity}.{ext}`
- **Loads:** 0Nm, 2Nm, 4Nm
- **Fault types:** Normal, BPFI (inner race), BPFO (outer race), Misalign, Unbalance
- **Formats:** `.mat` (vibration/acoustic), `.tdms` (temperature/current)

### MAT File Structure (Vibration Data)

```matlab
data = load("rawdata/0Nm_Normal.mat");
Signal = data.Signal;

% Time axis
Signal.x_values.increment      % 3.90625e-05 s (25,600 Hz sampling rate)
Signal.x_values.number_of_values  % samples (varies by condition)

% Signal data - 4 channels of vibration (g units)
Signal.y_values.values         % [N x 4] double
Signal.function_record.name    % {'3:Point1', '4:Point2', '5:Point3', '6:Point4'}
```

### TDMS File Structure (Temperature/Current Data)

Requires Data Acquisition Toolbox.

```matlab
info = tdmsinfo("rawdata/0Nm_Normal.tdms");
data = tdmsread("rawdata/0Nm_Normal.tdms");
logData = data{2};  % Group 2 contains sensor data

% Columns:
%   1: Temperature 1 (°C) - cDAQ9185-1F486B5Mod1/ai0
%   2: Temperature 2 (°C) - cDAQ9185-1F486B5Mod1/ai1
%   3: Current Phase 1 (A) - cDAQ9185-1F486B5Mod2/ai0
%   4: Current Phase 2 (A) - cDAQ9185-1F486B5Mod2/ai2
%   5: Current Phase 3 (A) - cDAQ9185-1F486B5Mod2/ai3

temp1 = logData{:, 1};
current = logData{:, 3:5};
```

**Hardware:**
- Temperature: NI 9210 (K-type thermocouples)
- Current: NI 9775 (3-phase motor current)
- Chassis: cDAQ-9185

### Sample Rate Mismatch

| Format | Sample Rate | Increment |
|--------|-------------|-----------|
| MAT (vibration) | 25,600 Hz | 3.90625e-05 s |
| TDMS (temp/current) | 25,608 Hz | 3.905e-05 s |

This 0.03% difference causes slight sample count mismatches. For synchronized analysis, resample TDMS data to 25,600 Hz.

### Recording Durations

| Condition | Duration | MAT Samples | TDMS Samples |
|-----------|----------|-------------|--------------|
| Normal (0Nm only) | 300 s | 7,680,000 | 7,682,458 |
| Normal (2Nm, 4Nm), Misalign, Unbalance | 120 s | 3,072,000 | 3,072,983 |
| BPFI, BPFO | 60 s | 1,536,000 | 1,536,492 |

### Data Characteristics

**Vibration (MAT):** ±6 g peak, 4 channels
**Temperature (TDMS):** 25-27°C operating range
**Motor Current (TDMS):** ±4.5 A peak, ~2.2 A RMS, 50 Hz (European grid)

### Known Data Issues

1. **Filename typo:** 5 files at 2Nm use "Unbalalnce" instead of "Unbalance"
2. **Sample rate mismatch:** MAT (25,600 Hz) vs TDMS (25,608 Hz)
3. **Inconsistent durations:** 60-300s depending on condition

### File Counts

- MAT files: 45 (3.69 GB)
- TDMS files: 45 (4.39 GB)
- Total usable: 8.08 GB

## Processed Data

**Location:** `processed/`

After running the ETL pipeline, data is stored in Parquet format:
- `processed/catalog.parquet` - Metadata index for all sessions
- `processed/data/*.parquet` - Sensor data (nested schema)

### Schema (Nested)

One row per channel per session:

| Column | Type | Description |
|--------|------|-------------|
| SessionID | string | e.g., "0Nm_BPFI_03" |
| Load | string | "0Nm", "2Nm", "4Nm" |
| FaultType | string | "Normal", "BPFI", "BPFO", "Misalign", "Unbalance" |
| Severity | string | Fault severity level |
| SampleRate | double | 25600 Hz (all channels synchronized) |
| ChannelName | string | "Vibration_1", "Temperature_1", etc. |
| ChannelType | string | "Vibration", "Temperature", "Current" |
| Unit | string | "g", "degC", "A" |
| Time | cell | {[N×1 double]} time vector in seconds |
| Values | cell | {[N×1 double]} signal values |

### Query Data

```matlab
% Load by fault type
T = queryData(FaultType="BPFI");

% Load by condition
T = queryData(Load="0Nm", Channels="Vibration");

% Load specific sessions
T = queryData(SessionID=["0Nm_BPFI_03", "2Nm_Normal"]);

% Convert to wide timetable for analysis
tt = nested2wide(T, SessionID="0Nm_BPFI_03");
```

## Commands

Download and extract dataset:
```matlab
run('downloadDataset.m')
```

Build catalog and export to Parquet:
```matlab
catalog = buildCatalog("rawdata", SavePath="processed/catalog.parquet");
exportToParquet(catalog, "processed/data");
```

Run MATLAB scripts:
```matlab
run('scriptName.m')
```

## MATLAB Code Style

- Use `arguments` blocks for input validation
- Follow lowerCamelCase for functions, UpperCamelCase for classes
- Write code to `.m` files and run with `run_matlab_file` (reduces token usage)
- Use MATLAB Testing Framework for unit tests
