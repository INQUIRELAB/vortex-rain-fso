% This MATLAB code simulate propagation in rain with both Geometrical
% Optics and Mie Scattering. 
function run_all_simulations()
    % Parameter ranges
    z_values = 1000; % Propagation Distance
    rainfall_rates = [5.0 12.5 25 100]; % Rainfall rate (mm/h)
    model_numbers = 1:10; % Model numbers from 1 to 20
    wavelength = 1550; % Wavelength (nm)
    r1 = 0.5; % Radius of raindrop (mm)
    w0 = 2e-2; % beam waist (m)
    segment_length = 10; % Segment length (m)

    % Directory containing the models
    modelDir = 'Model of rainfall';
    % Iterate over all combinations of z_values, rainfall_rates, and model_numbers
    for z = z_values
        for R = rainfall_rates
            for model_num = model_numbers
                % Construct the model filename
                modelName = sprintf('raindrop_positions_R_%.1f_z_%d_model_%d.mat', R, z, model_num);
                modelPath = fullfile(modelDir, modelName);

                % Check if the model file exists
                if exist(modelPath, 'file')
                    fprintf('Running simulation for: %s\n', modelName);
                    % Run the simulation with the current model
                    simulate_GO_with_model(R, r1, z, wavelength, modelPath, w0, segment_length, model_num);
                    %simulate_Mie_with_model(R, r1, z, wavelength, modelPath, w0, segment_length, model_num);
                    %simulate_GO_Fraunhofer_model(R, r1, z, wavelength, modelPath, w0, segment_length, model_num);
                else
                    fprintf('Model file not found: %s\n', modelPath);
                end
            end
        end
    end
end