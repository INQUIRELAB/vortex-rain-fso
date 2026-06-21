function simulate_Mie_with_model(R, r1, z, lambda, modelPath, w0, segment_length, model_num)
    % Load required data
    [particle_positions, phi_data, theta_data, ID_data, Phase_data, ID_cdf, ...
        initial_photon_positions, Phase] = load_data(modelPath, lambda, model_num);

    % Define constants
    [num_photons, r, c, k, l, v, N, n_air, n_water, probability, z_R] = define_constants(R, r1, z, lambda, w0);

    % Initialize variables
    [photon_position, photon_direction, time_taken, time_to_hit, z_optical,...
        Phaseshift, final_photon_positions] = initialize_photons(num_photons, initial_photon_positions);
    % Phaseshift here refers to the amount of shift caused by the effects
    % of rain.

    % Define segments
    num_segments = ceil(z / segment_length);
    z_segments = linspace(0, z, num_segments + 1);

    % Sort rain particle positions by z coordinate
    particle_positions = sortrows(particle_positions, 3);

    % Initialize segment indices
    segment_indices = cell(num_segments, 1);

    % Find particles in each segment
    for i = 1:num_segments
        z_start = z_segments(i);
        z_end = z_segments(i + 1);
        
        % Find the indices of particles in the current segment
        segment_indices{i} = find(particle_positions(:, 3) >= z_start & particle_positions(:, 3) < z_end);
    end
    % Initialize segment_info to store photon information for each segment
    segment_info = zeros(num_photons, 6, num_segments+1); % Columns represent: x, y, z, time_taken, Phaseshift
    segment_info(:,:,1) = [photon_position, time_taken, Phaseshift, Phase];


    % Perform photon propagation simulation for each segment
    for photon = 1:num_photons
        current_segment = 1;
        while true
            z1 = z_segments(current_segment);
            if photon_direction(photon, 3)>=0
                z2 = z1 + segment_length;
                particles_in_segment = particle_positions(segment_indices{current_segment}, :);
            else 
                break;
            end
            % Corrected and streamlined code section
            segment_N = size(particles_in_segment, 1); % Number of particles in the current segment
            hit_particles = false(segment_N, 1); % Initialize hit_particles for this photon
            % Calculate the position of photon if there's no scattering.
            w_current = w0 * sqrt(1 + (z_optical(photon) / z_R)^2);
            x_current = photon_position(photon, 1);
            y_current = photon_position(photon, 2);
            if time_to_hit(photon) ~= 0
                z_optical(photon) = z_optical(photon) + segment_length;
                w_new = w0 * sqrt(1 + (z_optical(photon) / z_R)^2);
                x_new = photon_position(photon, 1) * w_new / w0;
                y_new = photon_position(photon, 2) * w_new / w0;
                xdirection = (x_new - x_current)/segment_length; 
                ydirection = (y_new - y_current)/segment_length;
                zdirection = photon_direction(photon,3);
                direction = [xdirection, ydirection, zdirection];
                photon_direction(photon,:) = direction/norm(direction);
            end
            time_to_hit_segment = 0;
            while true
                % Check for collisions within the current segment
                segment_distances = arrayfun(@(idx) point_to_line_distance(particles_in_segment(idx, :), ...
                    photon_position(photon,:), photon_direction(photon,:)), 1:segment_N);
                segment_distances(hit_particles) = Inf; % Set distances for already hit particles to infinity
                valid_indices = find(segment_distances < r); % Find valid indices within the particle radius
                
                if isempty(valid_indices)
                    break; % Exit the loop if there are no valid indices
                end
                
                % Find the nearest raindrop
                [min_dist, nearest_idx] = min(segment_distances(valid_indices));
                nearest_raindrop = particles_in_segment(valid_indices(nearest_idx), :);
                
                % Calculate the photon's foot point on the nearest raindrop
                vector_to_particle = nearest_raindrop - photon_position(photon,:);
                dot_product = dot(vector_to_particle, photon_direction(photon,:));
                foot_point = photon_position(photon, :) + dot_product * photon_direction(photon,:);
                
                % Update the photon's position and calculate the distance
                dist = abs(norm(foot_point - photon_position(photon,:)));
                time_to_hit_segment = time_to_hit_segment + dist/c;
                time_to_hit(photon) = time_to_hit(photon) + dist/c;
                photon_position(photon,:) = foot_point; % Move the photon to the nearest raindrop
                
                random_number = rand;
                if random_number > ID_cdf(end)
                    photon_direction(photon,:) = [0,0,0];
                    break;
                else
                    % Mie scattering
                    index = find(ID_cdf >= random_number, 1);
                    [phi_index, theta_index] = ind2sub(size(ID_data), index);
                    
                    % Determine the actual scattering angles
                    selected_phi = real(phi_data(phi_index));
                    selected_theta = real(theta_data(theta_index));
                    Phi = atan2(real(photon_direction(photon,2)),real(photon_direction(photon,1)));
                    Theta = acos(real(photon_direction(photon,3)));
                    % Get new direction
                    Theta = Theta + selected_theta;
                    Phi = mod(Phi + selected_phi, 2*pi);
                    if Theta > pi
                        Theta = 2*pi - Theta;
                        Phi = mod(Phi + pi, 2*pi);
                    end
                    % Get new time inside the raindrop
                    time_to_hit_segment = time_to_hit_segment + abs(Phase_data(phi_index,theta_index)/(k*c)); % Calculate the time inside the raindrop
                    time_to_hit(photon) = time_to_hit(photon) + abs(Phase_data(phi_index,theta_index)/(k*c));
                    photon_direction(photon,:) = [sin(Theta)*cos(Phi) sin(Theta)*sin(Phi) cos(Theta)];
                    photon_direction(photon,:) = photon_direction(photon,:)/norm(photon_direction(photon,:));
                    Phaseshift(photon) = Phaseshift(photon) + Phase_data(phi_index,theta_index);
                    Phase(photon) = Phase(photon) + Phase_data(phi_index,theta_index);
                    hit_particles(valid_indices(nearest_idx)) = true; % Mark this raindrop as hit
                end
            end
            %}
            if photon_direction(photon, 3) == 0
                break;
            elseif photon_direction(photon,3)>0
                position_shift = photon_direction(photon,:)*(z2-photon_position(photon,3));
                new_photon_position = photon_position(photon,:) + position_shift;
                new_photon_position(3) = z2;
                time_taken(photon) = time_taken(photon) +  abs(norm(new_photon_position - photon_position(photon,:)))/c + time_to_hit_segment;
                photon_position(photon,:) = new_photon_position;
                Phase(photon) = Phase(photon) + real(k)*norm(position_shift);
            else
                position_shift = photon_direction(photon,:)*(z1-photon_position(photon,3));
                new_photon_position = photon_position(photon,:) + position_shift;
                new_photon_position(3) = z1;
                time_taken(photon) = time_taken(photon) +  abs(norm(new_photon_position - photon_position))/c + time_to_hit_segment;
                photon_position(photon,:) = new_photon_position;
                Phase(photon) = Phase(photon) + real(k)*norm(position_shift);
                break;
            end
            % check the boundary
            if check_boundary(photon_position(photon,:),l,z)
                break;
            end
            segment_info(photon, :, current_segment+1) = [photon_position(photon, 1), photon_position(photon, 2), ...
            photon_position(photon, 3), time_taken(photon), Phaseshift(photon), Phase(photon)];  
            if photon_direction(photon,3) > 0
                current_segment = current_segment + 1;
            else
                break; % End calculation for photons moving in negative direction
            end
        end
        final_photon_positions(photon, :) = photon_position(photon,:);
    end

    % Save results
    save_results(final_photon_positions, time_taken, Phaseshift, Phase, modelPath);

    % Display results path
    resultsDir = fullfile(pwd, 'Mie_Simulation_Results');
    [~, modelName, ~] = fileparts(modelPath);
    resultsFilename = sprintf('%s_Mie_results.mat', modelName);
    fullResultsPath = fullfile(resultsDir, resultsFilename);
    fprintf('Results saved to: %s\n', fullResultsPath);
    % After simulation, save the segment information for each segment
    for seg = 1:num_segments+1
        z_segment_end = z_segments(seg); % Get the end z-coordinate of the segment
        if seg == max(num_segments+1)
            segment_info(:,:,seg) = [final_photon_positions, time_taken, Phaseshift, Phase];
        end
        segment_data = segment_info(:, :, seg); % Extract data for the current segment
        save_segment_info(segment_data, modelPath, z_segment_end); % Save the data for the segment
    end
end

function [particle_positions, phi_data, theta_data, ID_data, Phase_data, ID_cdf, initial_photon_positions, Phase] = load_data(modelPath, lambda, model_num)
    modelData = load(modelPath);
    particle_positions = modelData.common_particle_positions;
    particle_positions = sortrows(particle_positions, 3); % Reorder the matrix along the z-axis
    data1 = load(['mie_data_wavelength_' num2str(lambda) '.mat']);
    data2 = load(sprintf('initialphoton/initial_photons%d.mat', model_num));
    phi_data = data1.phi; % Azimuthal angles
    theta_data = data1.theta; % Polar angles
    ID_data = data1.P; % Scattering probabilities
    Phase_data = data1.Phaseshift; % Phaseshift
    ID_cdf = cumsum(ID_data(:));
    initial_photon_positions = data2.initial_photon_positions;
    Phase = data2.Phaseshift;
end

function [num_photons, r, c, k, l, v, N, n_air, n_water, probability, z_R] = define_constants(R, r1, z, lambda, w0)
    num_photons = 1e4;
    r = r1 / 1000;
    c = physconst('LightSpeed');
    k = 2 * pi / lambda * 1e9;
    l = 0.1;
    v = 9.65 - 10.3 * exp(-0.6 * 2 * r1); % [1]
    N = floor((R / (4/3 * pi * r1^3 * v * 3.6e6) * 1e9) * l^2 * z);
    n_air = 1;
    z_R = pi * w0^2 / lambda*1e9;
    if lambda == 1064 % [2]
        n_water = 1.326 + 1i * 5.13e-6;
        probability = 4.0989e-4;
    elseif lambda == 1550
        n_water = 1.318 + 1i * 9.8625e-5;
        probability = 6.3810e-4;
    end
end

function hit_boundary = check_boundary(photon_position, l, z) % if the photon is in the boundary, this function returns true, if else it does false.
    % Check if photon is within the boundaries
    if (photon_position(1) <= -0.5 * l || photon_position(1) >= 0.5 * l || ...
        photon_position(2) <= -0.5 * l || photon_position(2) >= 0.5 * l || ...
        photon_position(3) <= 0 || photon_position(3) >= z)
        hit_boundary = true;
    else
        hit_boundary = false;
    end
end

function [photon_position, photon_direction, time_taken, time_to_hit, z_optical, ...
    Phaseshift, final_photon_positions] = initialize_photons(num_photons, initial_photon_positions)
    photon_position = initial_photon_positions;
    photon_direction = repmat([0, 0, 1], num_photons, 1);
    time_taken = zeros(num_photons, 1);
    time_to_hit = zeros(num_photons, 1);
    z_optical = zeros(num_photons, 1);
    Phaseshift = zeros(num_photons, 1);
    final_photon_positions = zeros(num_photons, 3);
end
%{
function [new_position, new_direction, total_time_taken, total_path, final_Phaseshift] = propagate_photon_segment(photon_position, photon_direction, particle_positions, r, c, k, probability, phi_data, theta_data, ID_data, ID_cdf, Phase_data, z_start, z_end, l, n_air, n_water, w0, lambda)
    % Initialize variables for this segment
    total_time_taken = 0;
    total_path = 0;
    final_Phaseshift = 0;

    % Determine the relevant particles for this segment
    relevant_particles = particle_positions(particle_positions(:,3) >= z_start & particle_positions(:,3) < z_end, :);

    % Propagate the photon through the segment
    % (update photon positions, check for collisions, etc.)

    % Update photon position with beam widening
    z_current = z_end;
    w_z = w0 * sqrt(1 + (z_current / (pi * w0^2 / lambda))^2);
    new_position = photon_position + photon_direction * (z_end - z_start);
    new_position(1) = w_z / w0 * photon_position(1);
    new_position(2) = w_z / w0 * photon_position(2);

    % Return updated values
    new_direction = photon_direction;
end
%}

% Helper function to calculate the distance from a point to a line
function distance = point_to_line_distance(point, line_origin, line_dir)
    distance = norm(cross(line_dir, (point - line_origin))) / norm(line_dir);
end

function save_results(final_photon_positions, time_taken, Phaseshift, Phase, modelPath);
    resultsDir = fullfile(pwd, 'Mie_Simulation_Results');
    if ~exist(resultsDir, 'dir')
        mkdir(resultsDir);
    end
    [~, modelName, ~] = fileparts(modelPath);
    resultsFilename = sprintf('%s_Mie_results.mat', modelName);
    fullResultsPath = fullfile(resultsDir, resultsFilename);
    save(fullResultsPath, 'final_photon_positions', 'time_taken', 'Phaseshift','Phase');
end

function save_segment_info(segment_data, modelPath, z_segment_end)
    resultsDir = fullfile(pwd, 'Mie_Simulation_Results');
    if ~exist(resultsDir, 'dir')
        mkdir(resultsDir);
    end
    [~, modelName, ~] = fileparts(modelPath);
    resultsFilename = sprintf('%s_Mie_segment_z%.2f.mat', modelName, z_segment_end);
    fullResultsPath = fullfile(resultsDir, resultsFilename);
    save(fullResultsPath, 'segment_data');
end

%{
Reference
[1] https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2018JD028307
[2] https://refractiveindex.info/?shelf=other&book=air&page=Ciddor
%}
