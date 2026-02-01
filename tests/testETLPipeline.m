classdef testETLPipeline < matlab.unittest.TestCase
    %TESTETLPIPELINE Tests for the ETL pipeline functions

    properties (Constant)
        ProjectRoot = fileparts(fileparts(mfilename('fullpath')))
    end

    properties (Dependent)
        CatalogPath
        DataPath
    end

    methods
        function val = get.CatalogPath(testCase)
            val = fullfile(testCase.ProjectRoot, "processed", "catalog.parquet");
        end

        function val = get.DataPath(testCase)
            val = fullfile(testCase.ProjectRoot, "processed", "data");
        end
    end

    methods (TestClassSetup)
        function addProjectToPath(testCase)
            addpath(testCase.ProjectRoot);
        end
    end

    methods (TestClassTeardown)
        function removeProjectFromPath(testCase)
            rmpath(testCase.ProjectRoot);
        end
    end

    methods (Test)
        function testCatalogExists(testCase)
            %TESTCATALOGEXISTS Verify catalog file exists
            testCase.verifyTrue(isfile(testCase.CatalogPath), ...
                "Catalog file should exist");
        end

        function testCatalogStructure(testCase)
            %TESTCATALOGSTRUCTURE Verify catalog has expected columns
            catalog = parquetread(testCase.CatalogPath);

            expectedCols = ["SessionID", "Load", "FaultType", "Severity", ...
                "Duration_s", "MatFile", "TdmsFile", "HasTdms", ...
                "MatSamples", "TdmsSamples", "MatFs", "TdmsFs"];

            for col = expectedCols
                testCase.verifyTrue(ismember(col, catalog.Properties.VariableNames), ...
                    sprintf("Catalog should have column: %s", col));
            end
        end

        function testCatalogSessionCount(testCase)
            %TESTCATALOGSESSIONCOUNT Verify correct number of sessions
            catalog = parquetread(testCase.CatalogPath);
            testCase.verifyEqual(height(catalog), 45, ...
                "Catalog should have 45 sessions");
        end

        function testCatalogFaultTypes(testCase)
            %TESTCATALOGFAULTTYPES Verify fault types are normalized
            catalog = parquetread(testCase.CatalogPath);

            expectedFaults = ["BPFI", "BPFO", "Misalign", "Normal", "Unbalance"];
            actualFaults = unique(catalog.FaultType);

            testCase.verifyEqual(sort(actualFaults), sort(expectedFaults)', ...
                "Catalog should have expected fault types (typos fixed)");
        end

        function testDataFilesExist(testCase)
            %TESTDATAFILESEXIST Verify Parquet data files exist
            files = dir(fullfile(testCase.DataPath, "*.parquet"));
            testCase.verifyGreaterThan(numel(files), 0, ...
                "Data folder should contain Parquet files");
        end

        function testDataSchema(testCase)
            %TESTDATASCHEMA Verify data has expected schema
            files = dir(fullfile(testCase.DataPath, "*.parquet"));
            info = parquetinfo(fullfile(files(1).folder, files(1).name));

            expectedCols = ["SessionID", "ChannelName", "ChannelType", ...
                "Unit", "SampleRate", "Time", "Values"];

            for col = expectedCols
                testCase.verifyTrue(ismember(col, info.VariableNames), ...
                    sprintf("Data should have column: %s", col));
            end
        end

        function testQueryByFaultType(testCase)
            %TESTQUERYBYFAULTTYPE Test querying by fault type
            T = queryData(FaultType="BPFI", ...
                DataPath=testCase.DataPath, CatalogPath=testCase.CatalogPath);

            % Should have 9 sessions * 9 channels = 81 rows
            testCase.verifyEqual(height(T), 81, ...
                "BPFI query should return 81 rows (9 sessions x 9 channels)");

            % All rows should be BPFI
            testCase.verifyTrue(all(T.FaultType == "BPFI"), ...
                "All returned rows should have FaultType BPFI");
        end

        function testQueryByChannel(testCase)
            %TESTQUERYBYCHANNEL Test querying by channel type
            T = queryData(FaultType="Normal", Channels="Temperature", ...
                DataPath=testCase.DataPath, CatalogPath=testCase.CatalogPath);

            % 3 Normal sessions * 2 temperature channels = 6 rows
            testCase.verifyEqual(height(T), 6, ...
                "Normal+Temperature query should return 6 rows");

            % All should be temperature
            testCase.verifyTrue(all(T.ChannelType == "Temperature"), ...
                "All returned rows should be Temperature channels");
        end

        function testNested2Wide(testCase)
            %TESTNESTED2WIDE Test nested to wide conversion
            T = queryData(SessionID="0Nm_BPFI_03", ...
                DataPath=testCase.DataPath, CatalogPath=testCase.CatalogPath);
            tt = nested2wide(T);

            % Should have 9 columns (channels)
            testCase.verifyEqual(width(tt), 9, ...
                "Wide timetable should have 9 columns");

            % Should have correct sample count
            testCase.verifyEqual(height(tt), 1536000, ...
                "Wide timetable should have 1,536,000 rows (60s at 25600 Hz)");

            % Check metadata
            testCase.verifyEqual(tt.Properties.UserData.SessionID, "0Nm_BPFI_03", ...
                "Metadata should contain correct SessionID");
        end

        function testSampleRateUniform(testCase)
            %TESTSAMPLERATEUNIFORM Verify all data is at 25600 Hz
            T = queryData(SessionID="0Nm_BPFI_03", ...
                DataPath=testCase.DataPath, CatalogPath=testCase.CatalogPath);

            testCase.verifyTrue(all(T.SampleRate == 25600), ...
                "All channels should be at 25600 Hz");
        end

        function testChannelAlignment(testCase)
            %TESTCHANNELALIGNMENT Verify all channels have same sample count
            T = queryData(SessionID="0Nm_BPFI_03", ...
                DataPath=testCase.DataPath, CatalogPath=testCase.CatalogPath);

            sampleCounts = cellfun(@numel, T.Values);
            testCase.verifyTrue(all(sampleCounts == sampleCounts(1)), ...
                "All channels should have same sample count");
        end
    end
end
