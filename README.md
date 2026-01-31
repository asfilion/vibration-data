# Vibration Data

Data engineering and analysis of rotating machinery vibration dataset for fault diagnosis.

## Dataset

This project uses the [Vibration, Acoustic, Temperature, and Motor Current Dataset](https://data.mendeley.com/datasets/ztmf3m7h5x/6) from Mendeley Data (CC BY 4.0).

**Sensor measurements:**
- Vibration (x/y at two housing locations)
- Acoustic
- Temperature (two housing points)
- Motor current (three-phase)

**Experimental conditions:**
| Load | Fault Types |
|------|-------------|
| 0Nm, 2Nm, 4Nm | Normal, BPFI, BPFO, Misalignment, Unbalance |

- **BPFI** - Ball Pass Frequency Inner race fault
- **BPFO** - Ball Pass Frequency Outer race fault

**Signal characteristics:**
- Sampling rate: 25,600 Hz
- Duration: 60 seconds per recording
- Format: `.mat` (vibration/acoustic), `.tdms` (temperature/current)

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
t = (0:Signal.x_values.number_of_values-1) / fs;

% Vibration data (4 channels)
vibration = Signal.y_values.values;
```

## Requirements

- MATLAB R2020a or later

## License

Dataset: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)

If you use this dataset, please cite:
> Pariyar, S., & Juokas, A. (2023). Vibration, Acoustic, Temperature, and Motor Current Dataset of Rotating Machine Under Varying Load Conditions for Fault Diagnosis [Data set]. Mendeley Data. https://doi.org/10.17632/ztmf3m7h5x.6
