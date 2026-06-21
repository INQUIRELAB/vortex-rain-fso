clc; clear; close all;

% Parameters to be set
rainfall_rate = 12.5; % Example rainfall rate (mm/h)
scattering_types = [1, 2]; % Scattering types to compare (1: Geometrical Optics, 2: Mie)
mode_type = 1; % Example mode (1: LG00, 2: LG10, 3: LG-40, 4: LG10+LG-40)
max_prop_distance = 1000;
linewidth = 1.5;
fontsize = 13;
lfontsize = 11; % Font size of legends
brightness_scale = 0;

colors = lines(5); % Color for rainfall rates

% Set line style and color based on rainfall rate
if rainfall_rate == 5
    marker_style = '-';
    rain_mode = 1;
elseif rainfall_rate == 12.5
    marker_style = '-';
    rain_mode = 2;
elseif rainfall_rate == 25
    marker_style = '-';
    rain_mode = 3;
elseif rainfall_rate == 100
    marker_style = '-';
    rain_mode = 4;
else
    marker_style = '-';
end

% Define mode type strings
if mode_type == 1
    mode_str = 'LG00';
    mode = 'LG_{00}';
elseif mode_type == 2
    mode_str = 'LG10';
    mode = 'LG_{10}';
elseif mode_type == 3
    mode_str = 'LG-40';
    mode = 'LG_{-40}';
elseif mode_type == 4
    mode_str = 'LG10+LG-40';
    mode = 'LG_{10} + LG_{-40}';
end

% Initialize figures for plots
figure(1); hold on; % Number of Received Photons
figure(2); hold on; % SNR

for s_idx = 1:length(scattering_types)
    scattering_type = scattering_types(s_idx);
    
    % Define scattering type based settings
    if scattering_type == 1
        scattering_str = 'GO';
        scattering = 'Geometrical optics';
        marker_style2 = 'o';
        color = colors(rain_mode,:);
    elseif scattering_type == 2
        scattering = 'Mie';
        scattering_str = 'Mie';
        marker_style2 = 'x';
        color = colors(5,:);
    end

    % Define file path
    baseFolder = 'Results and Figures';
    matFolder = fullfile(baseFolder, 'extracted data', 'mat_data');
    filename = sprintf('data_R_%.1f_%s_%s.mat', rainfall_rate, scattering_str, mode_str);
    filePath = fullfile(matFolder, filename);

    % Load data
    if exist(filePath, 'file')
        load(filePath, 'num_not_lost_photons_model1', 'num_not_lost_photons_avg', ...
            'SNR_model1', 'SNR_avg', 'prop_distances');
    else
        warning('File does not exist: %s', filePath);
        continue;
    end

    % Select marker indices for scattered points
    num_markers = 5;
    marker_indices = round(linspace(1, length(prop_distances), num_markers));
    num_markers2 = 5;
    marker_indices2 = round(linspace(1, length(prop_distances)-1, num_markers));
    
    % Plot Number of Received Photons with log scale on y-axis
    figure(1);
    labels = yticklabels;
    plot(prop_distances, num_not_lost_photons_model1, '--', 'Color', brightness_scale*color, 'HandleVisibility', 'off', 'LineWidth', linewidth);
    plot(prop_distances, num_not_lost_photons_avg, marker_style, 'Color', color, 'HandleVisibility', 'off', 'LineWidth', linewidth);
    plot(prop_distances(marker_indices2), num_not_lost_photons_model1(marker_indices2), marker_style2, 'Color', brightness_scale*color, 'HandleVisibility', 'off', 'LineWidth', linewidth);
    plot(prop_distances(marker_indices2), num_not_lost_photons_avg(marker_indices2), marker_style2, 'Color', color, 'HandleVisibility', 'off', 'LineWidth', linewidth);
    set(gca, 'YScale', 'log'); % Set y-axis to log scale for Figure 1

    % Plot SNR without log scale on y-axis
    figure(2);
    plot(prop_distances, SNR_model1, '--', 'Color', brightness_scale*color, 'HandleVisibility', 'off', 'LineWidth', linewidth);
    plot(prop_distances, SNR_avg, marker_style, 'Color', color, 'HandleVisibility', 'off', 'LineWidth', linewidth);
    plot(prop_distances(marker_indices2), SNR_model1(marker_indices2), marker_style2, 'Color', brightness_scale*color, 'HandleVisibility', 'off', 'LineWidth', linewidth);
    plot(prop_distances(marker_indices2), SNR_avg(marker_indices2), marker_style2, 'Color', color, 'HandleVisibility', 'off', 'LineWidth', linewidth);
end

% Add legends and finalize Number of Received Photons plot
figure(1);
plot(NaN, NaN, '--', 'Color', 'k', 'MarkerSize', 8, 'DisplayName', 'Single simulation', 'LineWidth', linewidth);
plot(NaN, NaN, marker_style, 'Color', 'k', 'MarkerSize', 8, 'DisplayName', '10 simulations', 'LineWidth', linewidth);
plot(NaN, NaN, 'o', 'Color', colors(rain_mode,:), 'MarkerSize', 8, 'DisplayName', 'Geometrical Optics', 'LineWidth', linewidth);
plot(NaN, NaN, 'x', 'Color', colors(5,:), 'MarkerSize', 8, 'DisplayName', 'Mie scattering', 'LineWidth', linewidth);

xlabel('Propagation Distance (m)');
ylabel('Number of Received Photons (a.u.)');
ax = gca;
ax.FontSize = fontsize;
lgd = legend('show');
lgd.FontSize = lfontsize;
grid on;
hold off;

% Add legends and finalize SNR plot
figure(2);
plot(NaN, NaN, '--', 'Color', 'k', 'MarkerSize', 8, 'DisplayName', 'Single simulation', 'LineWidth', linewidth);
plot(NaN, NaN, marker_style, 'Color', 'k', 'MarkerSize', 8, 'DisplayName', '10 simulations', 'LineWidth', linewidth);
plot(NaN, NaN, 'o', 'Color', colors(rain_mode,:), 'MarkerSize', 8, 'DisplayName', 'Geometrical Optics', 'LineWidth', linewidth);
plot(NaN, NaN, 'x', 'Color', colors(5,:), 'MarkerSize', 8, 'DisplayName', 'Mie scattering', 'LineWidth', linewidth);

xlabel('Propagation Distance (m)');
ylabel('SNR (dB)');
ax = gca;
ax.FontSize = fontsize;
lgd = legend('show');
lgd.FontSize = lfontsize;
grid on;
hold off;

% Define the output folder path
outputFolder = fullfile('Results and Figures', 'single vs 10 times average');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Save Photon Number plot
photon_filename = sprintf('Photon_number_%s_%.1f', mode_str, rainfall_rate);
photon_jpgFilePath = fullfile(outputFolder, [photon_filename, '.jpg']);
photon_figFilePath = fullfile(outputFolder, [photon_filename, '.fig']);
saveas(figure(1), photon_jpgFilePath);
saveas(figure(1), photon_figFilePath);

% Save SNR plot
snr_filename = sprintf('SNR_%s_%.1f', mode_str, rainfall_rate);
snr_jpgFilePath = fullfile(outputFolder, [snr_filename, '.jpg']);
snr_figFilePath = fullfile(outputFolder, [snr_filename, '.fig']);
saveas(figure(2), snr_jpgFilePath);
saveas(figure(2), snr_figFilePath);
