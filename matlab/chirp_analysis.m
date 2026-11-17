% ═══════════════════════════════════════════════════
% ELP311 - Chirp Modulation Analysis
% ═══════════════════════════════════════════════════

% ── Load Data ───────────────────────────────────────
data = readmatrix('chirp_data.txt', 'Delimiter', ',');
data = data(~any(isnan(data), 2), :);

t   = data(:,1) / 1e6;       % microseconds → seconds
adc = double(data(:,2));      % ADC values
fs  = 4761;                   % Sampling frequency

% ── Remove DC + Detrend ─────────────────────────────
adc = detrend(adc);
adc = adc - mean(adc);

% ── High Pass Filter ────────────────────────────────
[b, a]       = butter(3, 300/(fs/2), 'high');
adc_filtered = filtfilt(b, a, adc);

% ── Print Stats ─────────────────────────────────────
fprintf('=== Signal Stats ===\n');
fprintf('Samples        : %d\n',    length(adc));
fprintf('Duration       : %.4f s\n', length(adc)/fs);
fprintf('Mean ADC       : %.2f\n',  mean(adc));
fprintf('Peak-to-peak   : %.2f\n',  max(adc_filtered)-min(adc_filtered));

% ═══════════════════════════════════════════════════
% FIGURE 1 — Signal Analysis
% ═══════════════════════════════════════════════════
figure('Name', 'Chirp Signal Analysis', 'Position', [100 100 900 800]);

% Time Domain
subplot(3,1,1);
plot(t, adc_filtered, 'b', 'LineWidth', 1);
xlabel('Time (s)'); ylabel('ADC Value');
title('Received Chirp - Time Domain');
grid on;

% Spectrogram
subplot(3,1,2);
spectrogram(adc_filtered, hamming(128), 120, 512, fs, 'yaxis');
title('Spectrogram - Frequency Sweep');
ylim([0 2]);
colormap jet;

% FFT
subplot(3,1,3);
N   = length(adc_filtered);
f   = (0:N-1) * (fs/N);
mag = abs(fft(adc_filtered));
plot(f(1:N/2), mag(1:N/2), 'r');
xlabel('Frequency (Hz)'); ylabel('Magnitude');
title('FFT of Received Chirp');
xlim([0 fs/2]);
grid on;

sgtitle('Received Chirp Signal Analysis', ...
        'FontSize', 14, 'FontWeight', 'bold');

% ═══════════════════════════════════════════════════
% FIGURE 2 — Ideal Chirp vs Received
% ═══════════════════════════════════════════════════
figure('Name', 'Ideal vs Received', 'Position', [100 100 900 600]);

% Generate ideal chirp same duration as received
dur         = length(adc_filtered) / fs;
t_ideal     = 0 : 1/fs : dur;
ideal_chirp = chirp(t_ideal, 500, dur, 1500);
ideal_chirp = ideal_chirp / max(abs(ideal_chirp));

subplot(2,1,1);
plot(t_ideal, ideal_chirp, 'g', 'LineWidth', 1);
xlabel('Time (s)'); ylabel('Amplitude');
title('Ideal Chirp (500 Hz → 1500 Hz)');
grid on;

subplot(2,1,2);
adc_norm = adc_filtered / max(abs(adc_filtered));
plot(t, adc_norm, 'b', 'LineWidth', 1);
xlabel('Time (s)'); ylabel('Amplitude');
title('Received Chirp (Normalized)');
grid on;

sgtitle('Ideal vs Received Chirp Comparison', ...
        'FontSize', 14, 'FontWeight', 'bold');

% ═══════════════════════════════════════════════════
% FIGURE 3 — Matched Filter
% ═══════════════════════════════════════════════════
figure('Name', 'Matched Filter', 'Position', [100 100 900 500]);

% Normalize signals
adc_norm   = adc_filtered  / max(abs(adc_filtered));
ideal_norm = ideal_chirp(1:end-1) / max(abs(ideal_chirp));

% Cross-correlation
[corr_out, lags] = xcorr(adc_norm, ideal_norm);
lags_sec         = lags / fs;

% Find peak
[peak_val, peak_idx] = max(abs(corr_out));
peak_lag             = lags_sec(peak_idx);

plot(lags_sec, corr_out, 'm', 'LineWidth', 1);
hold on;
plot(peak_lag, corr_out(peak_idx), 'r*', 'MarkerSize', 14);
xlabel('Lag (s)'); ylabel('Correlation');
title('Matched Filter Output (Cross-Correlation)');
legend('Correlation', sprintf('Peak at %.4f s', peak_lag));
grid on;

sgtitle('Matched Filter Analysis', ...
        'FontSize', 14, 'FontWeight', 'bold');

fprintf('\n=== Matched Filter Results ===\n');
fprintf('Peak Lag         : %.4f s\n', peak_lag);
fprintf('Peak Correlation : %.4f\n',   peak_val);

if abs(peak_lag) < 0.05
    fprintf('Result: GOOD - Chirp detected near zero lag\n');
else
    fprintf('Result: Chirp detected but with delay of %.4f s\n', abs(peak_lag));
end
