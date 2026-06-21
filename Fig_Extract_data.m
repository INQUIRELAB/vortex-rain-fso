% Extract data
clc; clear;close all;
% Parameters to be entered
rainfall_rates = [5.0 12.5 25 100];   % Array of different rainfall rates
max_prop_distance = 1000;                  % Maximum propagation distance (integer)
l = 0.1;  % The length of one side of the detector (m)
model_numbers = 1:10;                    % Model numbers (from 1 to 10)
prop_distances = 0:10:max_prop_distance;                % Propagation distances (from 0m to 50m, in steps of 10m)
scattering_types = [1 2]; % 1 is Geometrical Optics, 2 is Mie scattering.
mode_types = 1:4; % 1 is LG00, 2 is LG10, 3 is LG-40, 4 is LG10 + LG-40
linewidth = 1.5; % Set the linewidth
num_markers = 6; % Set the desired number of markers
marker_indices = round(linspace(1, length(prop_distances), num_markers)); % Generate marker indices

% Colors for each rainfall rate
colors = lines(length(rainfall_rates));  % Use MATLAB's built-in color map   

num_not_lost_photons = zeros(length(mode_types),length(rainfall_rates),...
    length(scattering_types),length(model_numbers),length(prop_distances));
num_not_lost_photons_avg = zeros(length(mode_types),length(rainfall_rates),...
    length(scattering_types),length(prop_distances));
num_noise_photons = zeros(length(mode_types),length(rainfall_rates),...
    length(scattering_types),length(model_numbers),length(prop_distances));
num_noise_photons_avg = zeros(length(mode_types),length(rainfall_rates),...
    length(scattering_types),length(prop_distances));
SNR = zeros(length(mode_types),length(rainfall_rates),...
    length(scattering_types),length(model_numbers),length(prop_distances));
SNR_avg = zeros(length(mode_types),length(rainfall_rates),...
    length(scattering_types),length(prop_distances));

% Save results in specified folder structure
baseFolder = 'Results and Figures';
matFolder = fullfile(baseFolder, 'extracted data', 'mat_data');
excelFolder = fullfile(baseFolder, 'extracted data', 'excel_data');

% Create folders if they do not exist
if ~exist(matFolder, 'dir')
    mkdir(matFolder);
end
if ~exist(excelFolder, 'dir')
    mkdir(excelFolder);
end

% Loop through each combination of conditions
for scattering_type = scattering_types
    for mode_type = mode_types
        for r_idx = 1:length(rainfall_rates)
            rainfall_rate = rainfall_rates(r_idx);  % Current rainfall rate

            % Change file name and folder name based on scattering_type
            if scattering_type == 1
                scattering_str = 'GO';
            elseif scattering_type == 2
                scattering_str = 'Mie';
            end

            if mode_type == 1
                mode_str = 'LG00';
            elseif mode_type == 2
                mode_str = 'LG10';
            elseif mode_type == 3
                mode_str = 'LG-40';
            elseif mode_type == 4
                mode_str = 'LG10+LG-40';
            end

            % Set folder based on scattering_type
            if scattering_type == 1
                folderPath1 = 'GO_Simulation_Results';
            elseif scattering_type == 2
                folderPath1 = 'Mie_Simulation_Results';
            end
            % Combine folderPath and mode_str
            folderPath = [folderPath1 ' ' mode_str];

            % Initialize arrays to store averaged data across models and model_number=1 data
            num_not_lost_photons_avg = zeros(1, length(prop_distances));
            num_noise_photons_avg = zeros(1, length(prop_distances));
            SNR_avg = zeros(1, length(prop_distances));
            num_not_lost_photons_model1 = zeros(1, length(prop_distances));
            num_noise_photons_model1 = zeros(1, length(prop_distances));
            SNR_model1 = zeros(1, length(prop_distances));

            % Loop through each propagation distance
            for j = 1:length(prop_distances)
                prop_distance = prop_distances(j);

                % Initialize variables for accumulating model data
                num_not_lost_photons_models = zeros(1, length(model_numbers));
                num_noise_photons_models = zeros(1, length(model_numbers));
                SNR_models = zeros(1, length(model_numbers));

                % Loop through each model number to calculate averages and store model_number=1 data
                for i = 1:length(model_numbers)
                    model_number = model_numbers(i);

                    % Generate the file name for each model number and propagation distance
                    filename = sprintf('raindrop_positions_R_%.1f_z_%d_model_%d_%s_segment_z%.2f.mat', ...
                                       rainfall_rate, max_prop_distance, model_number, scattering_str, prop_distance);
                    
                    % Generate the full file path
                    filePath = fullfile(folderPath, filename);

                    % Check if the file exists and load the data
                    if exist(filePath, 'file')
                        data = load(filePath);

                        % Extract photon positions (x, y, z)
                        photon_positions = data.segment_data(:, 1:3);
                        
                        % Extract phase shift
                        phase_shift = data.segment_data(:, 5); 

                        % Identify the photons that are not lost (z-coordinate matches the propagation distance)
                        not_lost_photons = (photon_positions(:, 3) == prop_distance & ...
                                            (abs(photon_positions(:,2)) <= l) & ...
                                            (abs(photon_positions(:,1)) <= l));
                        
                        % Count the number of photons that are not lost and noise photons
                        num_not_lost_photons_models(i) = sum(not_lost_photons);
                        noise_photons = not_lost_photons & (phase_shift ~= 0);
                        num_noise_photons_models(i) = sum(noise_photons);

                        % Calculate SNR for the current model
                        if num_noise_photons_models(i) > 0
                            SNR_models(i) = 10*log10((num_not_lost_photons_models(i) - num_noise_photons_models(i)) / ...
                                             num_noise_photons_models(i));
                        else
                            SNR_models(i) = NaN;  % Avoid division by zero
                        end

                        % Store values for model_number=1
                        if model_number == 1
                            num_not_lost_photons_model1(j) = num_not_lost_photons_models(i);
                            num_noise_photons_model1(j) = num_noise_photons_models(i);
                            SNR_model1(j) = SNR_models(i);
                        end
                    else
                        disp(['File does not exist: ', filename]);
                        num_not_lost_photons_models(i) = NaN;
                        num_noise_photons_models(i) = NaN;
                        SNR_models(i) = NaN;
                    end
                end

                % Calculate averages across all models for the current propagation distance
                num_not_lost_photons_avg(j) = mean(num_not_lost_photons_models, 'omitnan');
                num_noise_photons_avg(j) = mean(num_noise_photons_models, 'omitnan');
                SNR_avg(j) = mean(SNR_models, 'omitnan');
            end

            % Generate output file names for MAT and Excel formats
            matFilename = sprintf('data_R_%.1f_%s_%s.mat', rainfall_rate, scattering_str, mode_str);
            matFilePath = fullfile(matFolder, matFilename);
            save(matFilePath, 'num_not_lost_photons_avg', 'num_noise_photons_avg', 'SNR_avg', ...
                 'num_not_lost_photons_model1', 'num_noise_photons_model1', 'SNR_model1', 'prop_distances');
            
            % Save data in Excel format
            excelFilename = sprintf('data_R_%.1f_%s_%s.xlsx', rainfall_rate, scattering_str, mode_str);
            excelFilePath = fullfile(excelFolder, excelFilename);

            % Prepare data for Excel
            T = table(prop_distances', num_not_lost_photons_avg', num_noise_photons_avg', SNR_avg', ...
                      num_not_lost_photons_model1', num_noise_photons_model1', SNR_model1', ...
                      'VariableNames', {'Propagation_Distance', 'Not_Lost_Photons_Avg', 'Noise_Photons_Avg', ...
                                        'SNR_Avg', 'Not_Lost_Photons_Model1', 'Noise_Photons_Model1', 'SNR_Model1'});

            % Write table to Excel file
            writetable(T, excelFilePath);
        end
    end
end
