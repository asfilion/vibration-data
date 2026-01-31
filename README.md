# Vibration Data

Data engineering and analysis of rotating machinery vibration dataset for fault diagnosis.

## Dataset

This project uses the [Vibration, Acoustic, Temperature, and Motor Current Dataset](https://data.mendeley.com/datasets/ztmf3m7h5x/6) from Mendeley Data (CC BY 4.0).

### Sensor Measurements

| Sensor Type | Channels | Format | File Extension |
|-------------|----------|--------|----------------|
| Vibration | 4 (x/y at two housing locations) | MAT | `.mat` |
| Acoustic | - | MAT | `.mat` |
| Temperature | 2 (housing points) | TDMS | `.tdms` |
| Motor Current | 3 (three-phase) | TDMS | `.tdms` |

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

- **Sampling rate:** 25,600 Hz
- **Duration:** 60-300 seconds (varies by condition)
- **Total files:** 45 MAT + 45 TDMS pairs
- **Dataset size:** ~8 GB (after extraction)

## Getting Started

### Download the Dataset

Run the download script in MATLAB:

```matlab
run('downloadDataset.m')
```

This downloads ~4 GB from Mendeley Data and extracts all files to the `rawdata/` folder.

### Load Data

```matlab
data = load("rawdata/0Nm_Normal.mat");
Signal = data.Signal;

% Time vector
fs = 1 / Signal.x_values.increment;  % 25600 Hz
nSamples = Signal.x_values.number_of_values;
t = (0:nSamples-1) / fs;

% Vibration data (4 channels in g units)
vibration = Signal.y_values.values;  % [N x 4] double

% Channel names
channelNames = Signal.function_record.name;  % {'3:Point1', '4:Point2', ...}
```

## File Naming Convention

Files follow the pattern: `{Load}_{FaultType}_{Severity}.{ext}`

Examples:
- `0Nm_Normal.mat` - Normal condition at 0Nm load
- `2Nm_BPFI_10.mat` - Inner race fault (severity 10) at 2Nm load
- `4Nm_Unbalance_1751mg.mat` - Unbalance fault (1751mg) at 4Nm load

## Requirements

- MATLAB R2020a or later
- Data Acquisition Toolbox (optional, for TDMS files)

## Known Issues

1. Some 2Nm unbalance files have a typo: `Unbalalnce` instead of `Unbalance`
2. TDMS files require Data Acquisition Toolbox to read

## License

Dataset: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)

If you use this dataset, please cite:
> Pariyar, S., & Juokas, A. (2023). Vibration, Acoustic, Temperature, and Motor Current Dataset of Rotating Machine Under Varying Load Conditions for Fault Diagnosis [Data set]. Mendeley Data. https://doi.org/10.17632/ztmf3m7h5x.6
