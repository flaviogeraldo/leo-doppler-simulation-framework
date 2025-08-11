clc; clear; close all;

%% === Constantes Físicas e Orbitais ===
G = 6.67430e-11;
M = 5.972e24;
Re = 6371e3;
h = 550e3;
R = Re + h;
% f0 = 2.6e9;
f0 = 3.5e9;
c = 3e8;

%% === Parâmetros Temporais ===
T_total = 1200;
t = linspace(-T_total/2, T_total/2, 1200);
dt = mean(diff(t));
t_plot = t + T_total/2;

%% === Velocidade Orbital ===
v_orb = sqrt(G * M / R);
omega = v_orb / R;

%% === Inclinações em graus ===
inclinations = 0:15:90;
highlight_incl = 53;  % destaque para Starlink grupo 1
colors = lines(length(inclinations) + 1);

%% === Usuário fixo no solo ===
x_usr = 0;
y_usr = 0;
z_usr = Re;

%% === Inicializar figuras ===
figure(1); hold on;
figure(2); hold on;
figure(3); hold on;
figure(4); hold on;

% Função de plotagem
plot_orbit = @(incl_deg, style, width, col) ...
    plot_inclination_curve(incl_deg, style, width, col, ...
    t, omega, R, x_usr, y_usr, z_usr, dt, f0, c, t_plot);

% Plot das curvas regulares
for i = 1:length(inclinations)
    plot_orbit(inclinations(i), '-', 2, colors(i,:));
end

% Destacar inclinação de 53°
plot_orbit(highlight_incl, '--', 3, 'k');

% Ajustes visuais padrão
figures = [1, 2, 3, 4];
ylabels = {'Doppler Shift (kHz)', 'Elevation (degrees)', ...
           'Distance (km)', 'Azimuth (degrees)'};
leglocs = {'southwest', 'southwest', 'northwest', 'northwest'};

for k = 1:4
    figure(figures(k));
    xlabel('Time (s)', 'FontSize', 14);
    ylabel(ylabels{k}, 'FontSize', 14);
    legend('Location', leglocs{k}, 'FontSize', 12);
    grid on;
    xlim([0 T_total]);
    xticks(0:200:T_total);
    set(gca, 'FontSize', 14);
    if k == 4
        ylim([0 360]);
    end
end

%% === Exportar figuras para PDF vetorial ===
fig_names = {'dopplershift', 'elevation', 'distance', 'azimuth'};

for k = 1:4
    fig = figure(k);
    set(fig, 'Units', 'Inches');
    pos = get(fig, 'Position');
    set(fig, 'PaperPositionMode', 'Auto', ...
             'PaperUnits', 'Inches', ...
             'PaperSize', [pos(3), pos(4)]);
    print(fig, sprintf('%s.pdf', fig_names{k}), '-dpdf');
end

%% === Função auxiliar ===
function plot_inclination_curve(incl_deg, linestyle, linewidth, color, ...
    t, omega, R, x_usr, y_usr, z_usr, dt, f0, c, t_plot)

    incl = deg2rad(incl_deg);
    x_sat = R * sin(omega * t);
    y_sat = R * cos(omega * t) * cos(incl);
    z_sat = R * cos(omega * t) * sin(incl);

    dx = x_sat - x_usr;
    dy = y_sat - y_usr;
    dz = z_sat - z_usr;
    range = sqrt(dx.^2 + dy.^2 + dz.^2);

    elevation = asind(dz ./ range);
    azimuth = mod(atan2d(dx, dz), 360);
    v_radial = gradient(range, dt);
    doppler = -f0 * v_radial / c;

    label = sprintf('\\theta = %.1f^\\circ', incl_deg);

    figure(1); plot(t_plot, doppler / 1e3, linestyle, 'Color', color, ...
        'LineWidth', linewidth, 'DisplayName', label);
    figure(2); plot(t_plot, elevation, linestyle, 'Color', color, ...
        'LineWidth', linewidth, 'DisplayName', label);
    figure(3); plot(t_plot, range / 1e3, linestyle, 'Color', color, ...
        'LineWidth', linewidth, 'DisplayName', label);
    figure(4); plot(t_plot, azimuth, linestyle, 'Color', color, ...
        'LineWidth', linewidth, 'DisplayName', label);
end
