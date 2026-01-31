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

### MAT File Structure

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

### Recording Durations (vary by condition)

| Condition | Duration | Samples |
|-----------|----------|---------|
| Normal (0Nm only) | 300 s | 7,680,000 |
| Normal (2Nm, 4Nm), Misalign, Unbalance | 120 s | 3,072,000 |
| BPFI, BPFO | 60 s | 1,536,000 |

### Known Data Issues

1. **Filename typo:** 5 files at 2Nm use "Unbalalnce" instead of "Unbalance"
   - `2Nm_Unbalalnce_0583mg.mat` (and .tdms)
   - `2Nm_Unbalalnce_1169mg.mat`, `2Nm_Unbalalnce_1751mg.mat`, etc.

2. **TDMS files require Data Acquisition Toolbox** - not currently readable

3. **Inconsistent durations** - may need windowing for ML applications

### File Counts

- MAT files: 45 (3.69 GB)
- TDMS files: 45 (4.39 GB)
- Total usable: 8.08 GB

## Commands

Download and extract dataset:
```matlab
run('downloadDataset.m')
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
