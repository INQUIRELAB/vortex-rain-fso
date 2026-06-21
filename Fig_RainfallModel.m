clc; clear; close all;

% Define the parameters for filename construction
rainfall_rate = 12.5; % Rainfall rate with one decimal place
max_prop_distance = 1000; % Maximum propagation distance as an integer
model_numbers = 1:3; % List of model numbers to include in the plot

fontsize = 12;
lfontsize = 11; % Font size of legends

% Define the range for filtering and plotting
l = 0.05; % Limit for x, y (m)
zl = 5; % Limit for z (m)

% Define the directory path
directory_path = 'Model of rainfall'; % Directory where data files are stored

% Create a figure for 2D plotting
figure;
hold on; % Allow multiple plots on the same figure

% Define colors for each model
colors = lines(length(model_numbers)); % Use MATLAB's "lines" colormap for distinct colors
colors = [colors(1:4,:);1 0 1];

% Define marker types for each model
markers = {'o', 'x', 's', '*', '^'}; % Circle, cross, square, star, triangle

% Loop through each model number to load and plot data
for i = 1:length(model_numbers)
    model_number = model_numbers(i);
    
    % Construct the full path of the file
    filename = sprintf('raindrop_positions_R_%.1f_z_%d_model_%d.mat', rainfall_rate, max_prop_distance, model_number);
    full_path = fullfile(directory_path, filename);
    
    % Load the .mat file
    data = load(full_path);
    common_particle_positions = data.common_particle_positions;
    
    % Extract x, y, and z coordinates for filtering
    x = common_particle_positions(:, 1);
    y = common_particle_positions(:, 2);
    z = common_particle_positions(:, 3);
    
    % Filter particles within the specified range in XY plane and Z limit
    indices = (x >= -l & x <= l) & (y >= -l & y <= l) & (z >= 0 & z <= zl);
    filtered_x = x(indices);
    filtered_y = y(indices);
    
    % Plot the filtered particles with a distinct marker shape and color
    scatter(filtered_x, filtered_y, 36, 'Marker', markers{i}, 'MarkerFaceColor', colors(i, :), ...
        'DisplayName', sprintf('RP %d', model_number));
end

% Configure the 2D plot
xlabel('X (m)');
ylabel('Y (m)');
axis equal; % Set aspect ratio to 1:1
xlim([-l l]); % Reapply x-axis limits
ylim([-l l]); % Reapply y-axis limits
grid on;

% Set font size for axes and legend
ax = gca;
ax.FontSize = fontsize;
lgd = legend('show', 'Location', 'northeastoutside');
lgd.FontSize = lfontsize;

hold off;

% Define the directory paths
results_dir = 'Results and Figures';
rainfall_dir = fullfile(results_dir, 'rainfall model');

% Create directories if they do not exist
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end
if ~exist(rainfall_dir, 'dir')
    mkdir(rainfall_dir);
end

% Define the filename based on rainfall rate, l, and zl
filename = sprintf('rainfall_%.1f_%.2f_%.2f', rainfall_rate, l, zl);

% Save the figure in .fig format
savefig(fullfile(rainfall_dir, [filename '.fig']));

% Save the figure in .jpg format
saveas(gcf, fullfile(rainfall_dir, [filename '.jpg']));
