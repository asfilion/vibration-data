%% downloadDataset.m
% Downloads and extracts the full vibration dataset from Mendeley Data
% Dataset: https://data.mendeley.com/datasets/ztmf3m7h5x/6

datasetUrl = "https://data.mendeley.com/public-api/zip/ztmf3m7h5x/download/6";
zipFilename = "vibration_dataset.zip";
rawdataFolder = "rawdata";

% Download the dataset
fprintf("Downloading dataset from Mendeley Data...\n");
fprintf("URL: %s\n", datasetUrl);
fprintf("This may take several minutes depending on your connection speed.\n\n");

try
    websave(zipFilename, datasetUrl);
    fprintf("Download complete: %s\n", zipFilename);
catch ME
    error("Failed to download dataset: %s", ME.message);
end

% Get file size for confirmation
fileInfo = dir(zipFilename);
fileSizeMB = fileInfo.bytes / (1024 * 1024);
fprintf("Downloaded file size: %.2f MB\n\n", fileSizeMB);

% Unzip the dataset to current folder
fprintf("Extracting main archive...\n");
try
    unzip(zipFilename, pwd);
    fprintf("Extraction complete!\n\n");
catch ME
    error("Failed to extract dataset: %s", ME.message);
end

% Rename the long folder name to rawdata
longFolderName = "Vibration, Acoustic, Temperature, and Motor Current Dataset of Rotating Machine Under Varying Load Conditions for Fault Diagnosis";
if isfolder(longFolderName)
    if isfolder(rawdataFolder)
        rmdir(rawdataFolder, 's');
    end
    movefile(longFolderName, rawdataFolder);
    fprintf("Renamed data folder to: %s\n\n", rawdataFolder);
end

% Extract nested zip files
fprintf("Extracting nested archives...\n");
nestedZips = dir(fullfile(rawdataFolder, "*.zip"));
for i = 1:length(nestedZips)
    zipPath = fullfile(rawdataFolder, nestedZips(i).name);
    fprintf("  Extracting: %s\n", nestedZips(i).name);
    unzip(zipPath, rawdataFolder);
end
fprintf("All nested archives extracted!\n\n");

% List extracted contents
fprintf("Extracted contents in %s:\n", rawdataFolder);
extractedFiles = dir(rawdataFolder);
extractedFiles = extractedFiles(~ismember({extractedFiles.name}, {'.', '..'}));
matCount = sum(endsWith({extractedFiles.name}, '.mat'));
tdmsCount = sum(endsWith({extractedFiles.name}, '.tdms'));
zipCount = sum(endsWith({extractedFiles.name}, '.zip'));
fprintf("  MAT files:  %d\n", matCount);
fprintf("  TDMS files: %d\n", tdmsCount);
fprintf("  ZIP files:  %d (can be deleted to save space)\n", zipCount);

fprintf("\nDataset ready for use!\n");
