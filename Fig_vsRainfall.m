clc; clear; close all;

% Parameters
rainfall_rates = [5, 12.5, 25, 100];  % Array of rainfall rates to compare
scattering_type = 1;  % Example scattering type (1: Geometrical Optics, 2: Mie)
mode_type = 4;  % Example mode (1: LG00, 2: LG10, 3: LG-40, 4: LG10+LG-40)
max_prop_distance = 1000;
linewidth = 1.5;
fontsize = 12;
lfontsize = 11;  % Font size of legends
N0 = 1e4; % Initial number of photons
log_R = log10(rainfall_rates);
prop_distances = linspace(0,1000,101);
log_sigma = zeros(length(prop_distances), length(rainfall_rates));
p_all = zeros(length(prop_distances),2); % Coefficients of the linear fit
alpha_values =  zeros(length(prop_distances),1);
k_values = zeros(length(prop_distances),1);

colors = lines(6);  % Use different colors for each rainfall rate

% Define scattering type and mode strings
if scattering_type == 1
    scattering_str = 'GO';
    scattering = 'Geometrical optics';
    marker_style2 = 'o';
elseif scattering_type == 2
    scattering = 'Mie';
    scattering_str = 'Mie';
    marker_style2 = 'x';
end

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

% Initialize figure for Number of Received Photons
figure(1);
hold on;

% Initialize figure for SNR
figure(2);
hold on;

% Initialize figure for log(R) vs log(σ) (figure(3))
figure(3);
hold on;

% Loop over each rainfall rate and plot data
for r_idx = 1:length(rainfall_rates)
    rainfall_rate = rainfall_rates(r_idx);
    
    % Assign marker styles based on rainfall rate
    if rainfall_rate == 5
        marker_style = '--';
    elseif rainfall_rate == 12.5
        marker_style = '-';
    elseif rainfall_rate == 25
        marker_style = ':';
    elseif rainfall_rate == 100
        marker_style = '-.';
    else
        marker_style = '-';
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
        continue;  % Skip this rainfall rate if file not found
    end
    num_markers = 6; % Set the desired number of markers
    marker_indices = round(linspace(1, length(prop_distances), num_markers)); % Generate marker indices

    % Plot Number of Received Photons (figure 1) with log scale on y-axis
    figure(1);
    labels = yticklabels;
    plot(prop_distances, num_not_lost_photons_avg, marker_style, 'DisplayName', sprintf('%.1f mm/h', rainfall_rate), ...
        'Color', colors(r_idx, :), 'LineWidth', linewidth);
    hold on
    plot(prop_distances(marker_indices), num_not_lost_photons_avg(marker_indices), marker_style2, ...
             'Color', colors(r_idx, :), 'HandleVisibility', 'off','LineWidth', linewidth);
    set(gca, 'YScale', 'log'); % Set y-axis to log scale for Figure 1

    % Plot SNR (figure 2) without log scale on y-axis
    figure(2);
    plot(prop_distances, SNR_avg, marker_style, 'DisplayName', sprintf('%.1f mm/h', rainfall_rate), ...
        'Color', colors(r_idx, :), 'LineWidth', linewidth);
    plot(prop_distances(marker_indices), SNR_avg(marker_indices), marker_style2, ...
             'Color', colors(r_idx, :), 'HandleVisibility', 'off','LineWidth', linewidth);

    % Calculate log(σ)
    for d_idx = 1:length(prop_distances)
        dist = prop_distances(d_idx);
        log_sigma(d_idx,r_idx) = log10(10/(dist/1e3)*log10(N0/num_not_lost_photons_avg(d_idx)));
    end

end

for d_idx = 1:length(prop_distances)
    p_all(d_idx,:) = polyfit(log_R, log_sigma(d_idx,:),1);
    alpha_values(d_idx) = p_all(d_idx,1);
    k_values(d_idx) = 10^(p_all(d_idx,2));
end

% Finalize Number of Received Photons plot
figure(1);
xlabel('Propagation Distance (m)');
ylabel('Number of Received Photons (a.u.)');
% title(sprintf('%s/%s', mode, scattering));
ax = gca;
ax.FontSize = fontsize;
lgd = legend('show','Location','southwest');
lgd.FontSize = lfontsize;
grid on;
hold off;

% Finalize SNR plot
figure(2);
xlabel('Propagation Distance (m)');
ylabel('SNR (dB)');
% title(sprintf('%s/%s', mode, scattering));
ax = gca;
ax.FontSize = fontsize;
lgd = legend('show');
lgd.FontSize = lfontsize;
grid on;
hold off;

% Save Photon Number plot
outputFolder = fullfile('Results and Figures', 'compare rainfall');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end
photon_filename = sprintf('Photon_number_comparison_%s_%s', mode_str, scattering_str);
saveas(figure(1), fullfile(outputFolder, [photon_filename, '.jpg']));
saveas(figure(1), fullfile(outputFolder, [photon_filename, '.fig']));

% Save SNR plot
snr_filename = sprintf('SNR_comparison_%s_%s', mode_str, scattering_str);
saveas(figure(2), fullfile(outputFolder, [snr_filename, '.jpg']));
saveas(figure(2), fullfile(outputFolder, [snr_filename, '.fig']));

figure(3);
plot(prop_distances, alpha_values, '-', 'Color', 0.8*colors(1,:), 'LineWidth', linewidth, 'MarkerSize', 8, 'DisplayName', '\alpha');
xlabel('Propagation Distance (m)');
ax = gca;
ax.FontSize = fontsize;
grid on;

figure(4);
plot(prop_distances, k_values, '-', 'Color', colors(1,:), 'LineWidth', linewidth, 'MarkerSize', 8, 'DisplayName', 'k');
xlabel('Propagation Distance (m)');
ax = gca;
ax.FontSize = fontsize;
grid on;

% Save α plot (figure 3)
alpha_filename = sprintf('Alpha_vs_Distance_%s_%s', mode_str, scattering_str);
saveas(figure(3), fullfile(outputFolder, [alpha_filename, '.jpg']));
saveas(figure(3), fullfile(outputFolder, [alpha_filename, '.fig']));

% Save k plot (figure 4)
k_filename = sprintf('K_vs_Distance_%s_%s', mode_str, scattering_str);
saveas(figure(4), fullfile(outputFolder, [k_filename, '.jpg']));
saveas(figure(4), fullfile(outputFolder, [k_filename, '.fig']));

% Initialize alpha and k values for both scattering types
alpha_values_all = zeros(length(prop_distances), 2); % Columns: 1 for GO, 2 for Mie
k_values_all = zeros(length(prop_distances), 2);

% Loop over both scattering types
for scattering_type = 1:2
    % Set scattering strings based on type
    if scattering_type == 1
        scattering_str = 'GO';
        scattering = 'Geometrical optics';
    elseif scattering_type == 2
        scattering = 'Mie';
        scattering_str = 'Mie';
    end
    
    % Loop over each rainfall rate and calculate log(σ)
    for r_idx = 1:length(rainfall_rates)
        rainfall_rate = rainfall_rates(r_idx);
        filename = sprintf('data_R_%.1f_%s_%s.mat', rainfall_rate, scattering_str, mode_str);
        filePath = fullfile(matFolder, filename);

        if exist(filePath, 'file')
            load(filePath, 'num_not_lost_photons_avg', 'prop_distances');
        else
            warning('File does not exist: %s', filePath);
            continue;
        end

        % Calculate log(σ) for each distance
        for d_idx = 1:length(prop_distances)
            dist = prop_distances(d_idx);
            log_sigma(d_idx, r_idx) = log10(10 / (dist / 1e3) * log10(N0 / num_not_lost_photons_avg(d_idx)));
        end
    end

    % Perform linear fitting to calculate α and k for current scattering type
    for d_idx = 1:length(prop_distances)
        p_all(d_idx, :) = polyfit(log_R, log_sigma(d_idx, :), 1);
        alpha_values_all(d_idx, scattering_type) = p_all(d_idx, 1);
        k_values_all(d_idx, scattering_type) = 10^(p_all(d_idx, 2));
    end
end

% Plot α vs Propagation Distance for both scattering types
figure(5);
hold on;
plot(prop_distances, alpha_values_all(:, 1), '-', 'Color', [0.85 0.325 0.098], 'LineWidth', linewidth, ...
    'DisplayName', 'Geometrical Optics');
plot(prop_distances, alpha_values_all(:, 2), '--', 'Color', [0.466 0.674 0.188], 'LineWidth', linewidth, ...
    'DisplayName', 'Mie');
xlabel('Propagation Distance (m)');
ax = gca;
ax.FontSize = fontsize;
legend('show', 'Location', 'best');
grid on;
hold off;

% Save α plot
alpha_filename = sprintf('Alpha_vs_Distance_Combined_%s', mode_str);
saveas(figure(5), fullfile(outputFolder, [alpha_filename, '.jpg']));
saveas(figure(5), fullfile(outputFolder, [alpha_filename, '.fig']));

% Plot k vs Propagation Distance for both scattering types
figure(6);
hold on;
plot(prop_distances, k_values_all(:, 1), '-', 'Color', [0.85 0.325 0.098], 'LineWidth', linewidth, ...
    'DisplayName', 'Geometrical Optics');
plot(prop_distances, k_values_all(:, 2), '--', 'Color', [0.466 0.674 0.188], 'LineWidth', linewidth, ...
    'DisplayName', 'Mie');
xlabel('Propagation Distance (m)');
ax = gca;
ax.FontSize = fontsize;
legend('show', 'Location', 'best');
grid on;
hold off;

% Save k plot
k_filename = sprintf('K_vs_Distance_Combined_%s', mode_str);
saveas(figure(6), fullfile(outputFolder, [k_filename, '.jpg']));
saveas(figure(6), fullfile(outputFolder, [k_filename, '.fig']));

% Select propagation distances for analysis
selected_distances = [500, 1000]; % in meters
selected_indices = arrayfun(@(x) find(abs(prop_distances - x) < 1e-3, 1), selected_distances); % Find indices

% Separate log_sigma for GO and Mie
log_sigma_GO = zeros(length(prop_distances), length(rainfall_rates));
log_sigma_Mie = zeros(length(prop_distances), length(rainfall_rates));

% Loop over both scattering types
for scattering_type = 1:2
    % Set scattering strings based on type
    if scattering_type == 1
        scattering_str = 'GO';
        scattering = 'Geometrical optics';
    elseif scattering_type == 2
        scattering = 'Mie';
        scattering_str = 'Mie';
    end
    
    % Loop over each rainfall rate
    for r_idx = 1:length(rainfall_rates)
        rainfall_rate = rainfall_rates(r_idx);
        filename = sprintf('data_R_%.1f_%s_%s.mat', rainfall_rate, scattering_str, mode_str);
        filePath = fullfile(matFolder, filename);

        if exist(filePath, 'file')
            load(filePath, 'num_not_lost_photons_avg', 'prop_distances');
        else
            warning('File does not exist: %s', filePath);
            continue;
        end

        % Calculate log(σ) for each distance
        for d_idx = 1:length(prop_distances)
            dist = prop_distances(d_idx);
            if scattering_type == 1 % GO
                log_sigma_GO(d_idx, r_idx) = log10(10 / (dist / 1e3) * log10(N0 / num_not_lost_photons_avg(d_idx)));
            elseif scattering_type == 2 % Mie
                log_sigma_Mie(d_idx, r_idx) = log10(10 / (dist / 1e3) * log10(N0 / num_not_lost_photons_avg(d_idx)));
            end
        end
    end
end

% Now use log_sigma_GO and log_sigma_Mie separately in Fig. 7
figure(7);
hold on;

% Colors for each distance
colors_GO = {[0.85, 0.325, 0.098], [1.0, 0.5, 0.2]}; % Red and Orange
colors_Mie = {[0.466, 0.674, 0.188], [0.0, 0.6, 0.5]}; % Green and Teal

% Generate extended x range for linear fit lines
extended_log_R = linspace(0, 2, 100); % Extended range for x-axis

% Common x-coordinate for annotations
annotation_x = 0.3;

% Base y-coordinate for annotations
annotation_y_base = 1.5; % Starting y-coordinate
annotation_y_step = -0.2; % Step size for each annotation

% Loop over selected distances
for dist_idx = 1:length(selected_distances)
    d_idx = selected_indices(dist_idx);
    
    % Plot and fit for GO
    log_sigma_GO_d = log_sigma_GO(d_idx, :);
    p_GO = polyfit(log_R, log_sigma_GO_d, 1); % Linear fit
    plot(log_R, log_sigma_GO_d, 'o', 'Color', colors_GO{dist_idx}, 'LineWidth', linewidth, ...
        'DisplayName', sprintf('GO (%.0fm)', prop_distances(d_idx)));
    plot(extended_log_R, polyval(p_GO, extended_log_R), '-', 'Color', colors_GO{dist_idx}, 'LineWidth', linewidth, ...
        'HandleVisibility', 'off'); % Plot extended fitted line
    text(annotation_x, annotation_y_base + annotation_y_step * ((dist_idx - 1) * 2), ...
        sprintf('y = %.4fx + %.4f', p_GO(1), p_GO(2)), ...
        'Color', colors_GO{dist_idx}, 'FontSize', fontsize);

    % Plot and fit for Mie
    log_sigma_Mie_d = log_sigma_Mie(d_idx, :);
    p_Mie = polyfit(log_R, log_sigma_Mie_d, 1); % Linear fit
    plot(log_R, log_sigma_Mie_d, 'x', 'Color', colors_Mie{dist_idx}, 'LineWidth', linewidth, ...
        'DisplayName', sprintf('Mie (%.0fm)', prop_distances(d_idx)));
    plot(extended_log_R, polyval(p_Mie, extended_log_R), '--', 'Color', colors_Mie{dist_idx}, 'LineWidth', linewidth, ...
        'HandleVisibility', 'off'); % Plot extended fitted line
    text(annotation_x, annotation_y_base + annotation_y_step * ((dist_idx - 1) * 2 + 1), ...
        sprintf('y = %.4fx + %.4f', p_Mie(1), p_Mie(2)), ...
        'Color', colors_Mie{dist_idx}, 'FontSize', fontsize);
end

% Finalize figure
xlim([0, 2]); % Set x-axis limits
ax = gca;
ax.FontSize = fontsize;
legend('show', 'Location', 'best');
grid on;
hold off;

% Save Figure 7
sigma_filename = sprintf('LogSigma_vs_LogR_Combined_%s', mode_str);
saveas(figure(7), fullfile(outputFolder, [sigma_filename, '.jpg']));
saveas(figure(7), fullfile(outputFolder, [sigma_filename, '.fig']));
