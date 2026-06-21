clc; clear; close all;

% Parameters
rainfall_rate = 12.5;  % Example rainfall rate for comparison
scattering_type = 1;  % Example scattering type (1: Geometrical Optics, 2: Mie)
mode_types = [2, 3, 4];  % Modes to compare (1: LG00, 2: LG10, 3: LG-40, 4: LG10+LG-40)
max_prop_distance = 1000;
linewidth = 1.5;
fontsize = 12;
lfontsize = 11;  % Font size of legends

colors = [0.0704 0.7457 0.7258;0.9184 0.7308 0.1890;0 0 0.5; 0.85 0.325 0.098];  % Use different colors for each mode

% Define scattering type string
if scattering_type == 1
    scattering_str = 'GO';
    scattering = 'Geometrical optics';
    marker = 'o';
elseif scattering_type == 2
    scattering = 'Mie';
    scattering_str = 'Mie';
    marker = 'x';
end

if rainfall_rate == 5
    marker_style = '--';
elseif rainfall_rate == 12.5
    marker_style = '-';
elseif rainfall_rate == 25
    marker_style = ':';
elseif rainfall_rate == 100
    marker_style = '-.';
end

% Initialize figure for Number of Received Photons
figure(1);
hold on;

% Initialize figure for SNR
figure(2);
hold on;

% Loop over each mode type and plot data
for m_idx = 1:length(mode_types)
    mode_type = mode_types(m_idx);
    
    % Assign marker styles based on mode type
    if mode_type == 1
        mode_str = 'LG00';
        mode = 'LG_{00}';
        marker_style2 = 'pentagram';
        color = colors(1,:);
    elseif mode_type == 2
        mode_str = 'LG10';
        mode = 'LG_{10}';
        marker_style2 = 'square';
        color = colors(2,:);
    elseif mode_type == 3
        mode_str = 'LG-40';
        mode = 'LG_{-40}';
        marker_style2 = '^';
        color = colors(3,:);
    elseif mode_type == 4
        mode_str = 'LG10+LG-40';
        mode = 'LG_{10} + LG_{-40}';
        color = colors(4,:);
        marker_style2 = marker;
    end

    % Define file path and load data
    baseFolder = 'Results and Figures';
    matFolder = fullfile(baseFolder, 'extracted data', 'mat_data');
    filename = sprintf('data_R_%.1f_%s_%s.mat', rainfall_rate, scattering_str, mode_str);
    filePath = fullfile(matFolder, filename);

    if exist(filePath, 'file')
        load(filePath, 'num_not_lost_photons_avg', 'SNR_avg', 'prop_distances');
    else
        warning('File does not exist: %s', filePath);
        continue;  % Skip this mode type if file not found
    end
    
    % Set the number of markers
    num_markers = 6;
    marker_indices = round(linspace(1, length(prop_distances), num_markers));

    % Plot Number of Received Photons (figure 1)
    figure(1);
    plot(prop_distances(marker_indices), num_not_lost_photons_avg(marker_indices), marker_style2,'DisplayName', mode, ...
        'Color', color, 'LineWidth', linewidth);
    plot(prop_distances, num_not_lost_photons_avg, marker_style, ...
             'Color', color, 'HandleVisibility', 'off','LineWidth', linewidth);

    % Plot SNR (figure 2)
    figure(2);
    plot(prop_distances(marker_indices), SNR_avg(marker_indices), marker_style2,'DisplayName', mode, ...
        'Color', color, 'LineWidth', linewidth);
    plot(prop_distances, SNR_avg, marker_style, ...
             'Color', color, 'HandleVisibility', 'off','LineWidth', linewidth);
end

% Finalize Number of Received Photons plot
figure(1);
xlabel('Propagation Distance (m)');
ylabel('Number of Received Photons');
title(sprintf('Rainfall Rate: %.1f mm/h, %s', rainfall_rate, scattering));
ax = gca;
ax.FontSize = fontsize;
lgd = legend('show');
lgd.FontSize = lfontsize;
grid on;
hold off;

% Finalize SNR plot
figure(2);
xlabel('Propagation Distance (m)');
ylabel('SNR (dB)');
% title(sprintf('Rainfall Rate: %.1f mm/h, %s', rainfall_rate, scattering));
ax = gca;
ax.FontSize = fontsize;
lgd = legend('show');
lgd.FontSize = lfontsize;
grid on;
hold off;

% Save Photon Number plot
outputFolder = fullfile('Results and Figures', 'compare modes');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end
photon_filename = sprintf('Photon_number_comparison_%s_R_%.1f', scattering_str, rainfall_rate);
saveas(figure(1), fullfile(outputFolder, [photon_filename, '.jpg']));
saveas(figure(1), fullfile(outputFolder, [photon_filename, '.fig']));

% Save SNR plot
snr_filename = sprintf('SNR_comparison_%s_R_%.1f', scattering_str, rainfall_rate);
saveas(figure(2), fullfile(outputFolder, [snr_filename, '.jpg']));
saveas(figure(2), fullfile(outputFolder, [snr_filename, '.fig']));
