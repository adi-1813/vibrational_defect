clc; clear; close all;

% Seting up SErial communications
serialPort = "COM5";  % Arduino's COM port
baudRate = 115200;
s = serialport(serialPort, baudRate);
flush(s);  % Clearing the buffer data

% sampling settings
Fs = 1000;  % Sampling Frequency (Hz)
numPoints = 500;  % Data window size for real-time plotting
data = zeros(numPoints, 6);  % [ax1, ay1, az1, ax2, ay2, az2]
time = linspace(-5, 0, numPoints);
freq = (0:numPoints/2-1) * (Fs / numPoints);
fftAx1 = zeros(numPoints/2,1);
fftAx2 = zeros(numPoints/2,1);

% real time plots
figure;

% MPU-1 Plot
ax1 = subplot(4,1,1);
hold on;
h1 = plot(time, data(:,1), 'r'); % Ax1
h2 = plot(time, data(:,2), 'g'); % Ay1
h3 = plot(time, data(:,3), 'b'); % Az1
title('MPU-1 Acceleration');
xlabel('Time (s)'); ylabel('Acceleration (g)');
legend('Ax1', 'Ay1', 'Az1'); grid on;

% MPU-2 Plot
ax2 = subplot(4,1,2);
hold on;
h4 = plot(time, data(:,4), 'r'); % Ax2
h5 = plot(time, data(:,5), 'g'); % Ay2
h6 = plot(time, data(:,6), 'b'); % Az2
title('MPU-2 Acceleration');
xlabel('Time (s)'); ylabel('Acceleration (g)');
legend('Ax2', 'Ay2', 'Az2'); grid on;

% FFT MPU-1
ax3 = subplot(4,1,3);
hold on;
h7 = plot(freq, fftAx1, 'k');
peak1Marker = plot(0, 0, 'ro', 'MarkerSize', 8, 'LineWidth', 1.5);
title('FFT of MPU-1 Ax1');
xlabel('Frequency (Hz)'); ylabel('Magnitude');
annot1 = text(0, 0, '', 'FontSize', 10, 'Color', 'r');
grid on;

% FFT MPU-2
ax4 = subplot(4,1,4);
hold on;
h8 = plot(freq, fftAx2, 'k');
peak2Marker = plot(0, 0, 'ro', 'MarkerSize', 8, 'LineWidth', 1.5);
title('FFT of MPU-2 Ax2');
xlabel('Frequency (Hz)'); ylabel('Magnitude');
annot2 = text(0, 0, '', 'FontSize', 10, 'Color', 'r');
grid on;

% calibration part
numSamples = 1000;
calibrationData = zeros(numSamples, 6);
disp("Calibrating... Keep the MPU-9250 still!");
flush(s);
pause(2);

for i = 1:numSamples
    rawData = readline(s);
    values = str2double(strsplit(strtrim(rawData), ','));
    if numel(values) == 6 && ~any(isnan(values))
        calibrationData(i, :) = values;
    end
end

offsets = mean(calibrationData, 1, 'omitnan');
disp("Calibration complete! Offsets: ");
disp(offsets);

%real time update loop
updateInterval = 5;
counter = 0;

while true
    try
        rawData = readline(s);
        values = str2double(strsplit(strtrim(rawData), ','));

        if numel(values) ~= 6 || any(isnan(values))
            continue;
        end

        values = values - offsets;
        data(1:end-1, :) = data(2:end, :);
        data(end, :) = values;

        counter = counter + 1;

        if mod(counter, updateInterval) == 0
            % Enhanced FFT
            % Demean
            signal1 = data(:,1) - mean(data(:,1));
            signal2 = data(:,4) - mean(data(:,4));

            % Hann window
            window = hann(numPoints);
            win1 = signal1 .* window;
            win2 = signal2 .* window;

            % FFT and normalize
            fftRaw1 = fft(win1);
            fftRaw2 = fft(win2);
            fftAx1 = abs(fftRaw1(1:numPoints/2)) / (sum(window)/2);
            fftAx2 = abs(fftRaw2(1:numPoints/2)) / (sum(window)/2);

            % Noise thresholding
            noiseThreshold1 = 0.05 * max(fftAx1);
            noiseThreshold2 = 0.05 * max(fftAx2);
            fftAx1(fftAx1 < noiseThreshold1) = 0;
            fftAx2(fftAx2 < noiseThreshold2) = 0;

            % Peak detection
            [maxMag1, idx1] = max(fftAx1);
            maxFreq1 = freq(idx1);
            [maxMag2, idx2] = max(fftAx2);
            maxFreq2 = freq(idx2);

            %Plot updates
            set(h1, 'YData', data(:,1));
            set(h2, 'YData', data(:,2));
            set(h3, 'YData', data(:,3));
            set(h4, 'YData', data(:,4));
            set(h5, 'YData', data(:,5));
            set(h6, 'YData', data(:,6));

            set(h7, 'YData', fftAx1);
            set(h8, 'YData', fftAx2);

            % Annotations
            set(annot1, 'Position', [maxFreq1, maxMag1], ...
                        'String', sprintf('%.1f Hz, %.2f', maxFreq1, maxMag1));
            set(annot2, 'Position', [maxFreq2, maxMag2], ...
                        'String', sprintf('%.1f Hz, %.2f', maxFreq2, maxMag2));

            % Peak markers
            set(peak1Marker, 'XData', maxFreq1, 'YData', maxMag1);
            set(peak2Marker, 'XData', maxFreq2, 'YData', maxMag2);

            drawnow;
        end
    catch
        continue;
    end
end
