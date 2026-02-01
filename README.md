# Vibration Data

Data engineering and analysis of rotating machinery vibration dataset for fault diagnosis.

## Dataset

This project uses the [Vibration, Acoustic, Temperature, and Motor Current Dataset](https://data.mendeley.com/datasets/ztmf3m7h5x/6) from Mendeley Data (CC BY 4.0).

### Sensor Measurements

| Sensor Type | Channels | Hardware | Format |
|-------------|----------|----------|--------|
| Vibration | 4 (x/y at two housing locations) | - | `.mat` |
| Temperature | 2 (housing points) | NI 9210 (K-type thermocouple) | `.tdms` |
| Motor Current | 3 (three-phase) | NI 9775 | `.tdms` |

### Experimental Conditions

**Load levels:** 0Nm, 2Nm, 4Nm

**Fault types:**
| Fault | Description | Severity Levels |
|-------|-------------|-----------------|
| Normal | Healthy baseline | - |
| BPFI | Ball Pass Frequency Inner race | 03, 10, 30 |
| BPFO | Ball Pass Frequency Outer race | 03, 10, 30 |
| Misalign | Shaft misalignment | 01, 03, 05 |
| Unbalance | Rotor imbalance | 0583mg, 1169mg, 1751mg, 2239mg, 3318mg |

### Signal Characteristics

| Parameter | MAT (Vibration) | TDMS (Temp/Current) |
|-----------|-----------------|---------------------|
| Sample rate | 25,600 Hz | 25,608 Hz |
| Duration | 60-300 s | 60-300 s |
| Units | g (acceleration) | °C, A |

- **Total files:** 45 MAT + 45 TDMS pairs
- **Dataset size:** ~8 GB (after extraction)
- **Motor frequency:** 50 Hz (European grid)

## Getting Started

### Download the Dataset

Run the download script in MATLAB:

```matlab
run('downloadDataset.m')
```

This downloads ~4 GB from Mendeley Data and extracts all files to the `rawdata/` folder.

### Load Vibration Data (MAT)

```matlab
data = load("rawdata/0Nm_Normal.mat");
Signal = data.Signal;

% Time vector
fs = 1 / Signal.x_values.increment;  % 25600 Hz
nSamples = Signal.x_values.number_of_values;
t = (0:nSamples-1) / fs;

% Vibration data (4 channels in g units)
vibration = Signal.y_values.values;  % [N x 4] double
```

### Load Temperature/Current Data (TDMS)

Requires Data Acquisition Toolbox.

```matlab
data = tdmsread("rawdata/0Nm_Normal.tdms");
logData = data{2};  % Group 2 contains sensor data

% Temperature (°C)
temp1 = logData{:, 1};
temp2 = logData{:, 2};

% Motor current (A) - 3-phase
current = logData{:, 3:5};
```

## File Naming Convention

Files follow the pattern: `{Load}_{FaultType}_{Severity}.{ext}`

Examples:
- `0Nm_Normal.mat` - Normal condition at 0Nm load
- `2Nm_BPFI_10.mat` - Inner race fault (severity 10) at 2Nm load
- `4Nm_Unbalance_1751mg.mat` - Unbalance fault (1751mg) at 4Nm load

## Requirements

- MATLAB R2020a or later
- Data Acquisition Toolbox (for TDMS files)

## Known Issues

1. Some 2Nm unbalance files have a typo: `Unbalalnce` instead of `Unbalance`
2. Sample rate mismatch: MAT files (25,600 Hz) vs TDMS files (25,608 Hz) - resample for synchronization

## License

Dataset: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)

If you use this dataset, please cite:
> Pariyar, S., & Juokas, A. (2023). Vibration, Acoustic, Temperature, and Motor Current Dataset of Rotating Machine Under Varying Load Conditions for Fault Diagnosis [Data set]. Mendeley Data. https://doi.org/10.17632/ztmf3m7h5x.6
