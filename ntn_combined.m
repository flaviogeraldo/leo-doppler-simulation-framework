
clc; clear; close all;

%% === General Parameters ===
G = 6.67430e-11;
M = 5.972e24;
Re = 6371e3;
c = 3e8;
f0 = 3.5e9;

%% === Temporal Parameters ===
T_total = 1200;
t = linspace(-T_total/2, T_total/2, 1200);
dt = mean(diff(t));
t_plot = t + T_total/2;

%% === Orbital Parameters ===
incl_deg = 53;
incl = deg2rad(incl_deg);
h = 550e3;
R = Re + h;

%% === Initial UE position ===
x_usr = 0; y_usr = 0; z_usr = Re;

%% === Satellite trajectory ===
v_orb = sqrt(G * M / R);
omega = v_orb / R;
x_sat = R * sin(omega * t);
y_sat = R * cos(omega * t) * cos(incl);
z_sat = R * cos(omega * t) * sin(incl);
dx = x_sat - x_usr;
dy = y_sat - y_usr;
dz = z_sat - z_usr;
range = sqrt(dx.^2 + dy.^2 + dz.^2);
v_radial = gradient(range, dt);
doppler_shift = -f0 * v_radial / c;

%% === Received Frequency ===
f_rx_no_comp = f0 + doppler_shift;
f_rx_comp_ideal = f0 * ones(size(t));
doppler_est30 = [zeros(1,30), doppler_shift(1:end-30)];
doppler_est40 = [zeros(1,40), doppler_shift(1:end-40)];
f_rx_comp30 = f0 + doppler_shift - doppler_est30;
f_rx_comp40 = f0 + doppler_shift - doppler_est40;

%% === Plot 1: Doppler with shadowed areas ===
limits = [1.8e3, 5e3, 10e3, 18e3];
cores = {'g','m','c','k'};
tempo_total = T_total;
tempos = zeros(4,1);
idx_all = {};

figure;
hold on;
plot(t_plot, doppler_shift/1e3, 'r', 'LineWidth', 1.5);
for i = 1:length(limits)
    fill([t_plot fliplr(t_plot)], ...
         [limits(i)/1e3*ones(size(t)) -limits(i)/1e3*ones(size(t))], ...
         cores{i}, 'FaceAlpha', 0.1, 'EdgeColor', 'none');
end
for i = 1:length(limits)
    yline(limits(i)/1e3, '--k', 'LineWidth', 1);
    yline(-limits(i)/1e3, '--k', 'LineWidth', 1);
end
xlabel('Time (s)'); ylabel('Doppler Shift (kHz)');
legend('Doppler', '±1.8kHz','±5kHz','±10kHz','±18kHz');
grid on;

%% === Plot 2: Distinct Doppler Shift Thresholds ===
delays = [Inf, 40, 30, 0]; % Inf: sem compensação, 0: ideal
labels = {'No Comp.', 'Partial 40', 'Partial 30', 'Ideal Comp.'};
f_limits = [1.8e3, 5e3, 10e3, 18e3];
tempo_util_matriz = zeros(length(delays), length(f_limits));

for i = 1:length(delays)
    delay = delays(i);
    if isinf(delay)
        est = zeros(size(t));
    else
        est = [zeros(1, delay), doppler_shift(1:end-delay)];
    end
    doppler_corrigido = doppler_shift - est;
    for j = 1:length(f_limits)
        limite = f_limits(j);
        idx = abs(doppler_corrigido) <= limite;
        tempo_util_matriz(i, j) = sum(idx) * dt;
    end
end

figure;
bar(categorical(f_limits/1e3), tempo_util_matriz', 1, 'grouped');
xlabel('Doppler Tolerance (kHz)');
ylabel('Link Availability (s)');
legend(labels, 'Location', 'northwest');
grid on;

%% === Plot 3: Maximum Doppler vs altitude and Latency ===
altitudes = 200e3:200e3:800e3;
doppler_max = zeros(size(altitudes));
latency = zeros(size(altitudes));
for i = 1:length(altitudes)
    R_tmp = Re + altitudes(i);
    v_tmp = sqrt(G*M/R_tmp);
    omega_tmp = v_tmp / R_tmp;
    x_tmp = R_tmp * sin(omega_tmp * t);
    y_tmp = R_tmp * cos(omega_tmp * t) * cos(incl);
    z_tmp = R_tmp * cos(omega_tmp * t) * sin(incl);
    d_tmp = sqrt((x_tmp - x_usr).^2 + (y_tmp - y_usr).^2 + (z_tmp - z_usr).^2);
    dr_tmp = gradient(d_tmp, dt);
    dshift = -f0 * dr_tmp / c;
    doppler_max(i) = max(abs(dshift));
    latency(i) = mean(d_tmp) / c;
end

figure;
yyaxis left;
plot(altitudes/1e3, doppler_max/1e3, '-ob', 'LineWidth', 2);
ylabel('Max Doppler Shift (kHz)');
yyaxis right;
plot(altitudes/1e3, latency*1e3, '--sr', 'LineWidth', 2);
ylabel('One-way Propagation Latency (ms)');
xlabel('Altitude (km)');
xline(550, '--k', '550 km (Starlink)', 'LabelVerticalAlignment','bottom');
legend('Doppler Max','Latency');
grid on;

