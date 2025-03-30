clc; clear; close all;

% SETUP SERIAL COMMUNICATION
serialPort = "COM5";  % Change to your Arduino's COM port
baudRate = 115200;
s = serialport(serialPort, baudRate);
flush(s);  % Clear serial buffer

% SAMPLING SETTINGS
Fs = 10000;  % Sampling Frequency (Hz)
numPoints = 500;  % Data window size for real-time plotting
fftBlockSize = 1024; % Block size for FFT
data = zeros(numPoints, 6);  % [ax1, ay1, az1, ax2, ay2, az2]
time = linspace(-5, 0, numPoints);

% REAL-TIME PLOTS
figure;

% MPU-1 Acceleration Plot
ax1 = subplot(3,1,1);
hold on;
h1 = plot(time, data(:,1), 'r'); % Ax1
h2 = plot(time, data(:,2), 'g'); % Ay1
h3 = plot(time, data(:,3), 'b'); % Az1
title('MPU-1 Acceleration');
xlabel('Time (s)'); ylabel('Acceleration (g)');
legend('Ax1', 'Ay1', 'Az1');
grid on;

% MPU-2 Acceleration Plot
ax2 = subplot(3,1,2);
hold on;
h4 = plot(time, data(:,4), 'r'); % Ax2
h5 = plot(time, data(:,5), 'g'); % Ay2
h6 = plot(time, data(:,6), 'b'); % Az2
title('MPU-2 Acceleration');
xlabel('Time (s)'); ylabel('Acceleration (g)');
legend('Ax2', 'Ay2', 'Az2');
grid on;

% FFT Plot
ax3 = subplot(3,1,3);
fftFreqs = linspace(0, Fs/2, fftBlockSize/2);
hFFT = plot(fftFreqs, zeros(1, fftBlockSize/2));
title('FFT of Acceleration Data');
xlabel('Frequency (Hz)'); ylabel('Magnitude');
grid on;

% CALIBRATION
numSamples = 100;  % Collect 100 samples for calibration
calibrationData = zeros(numSamples, 6);

disp("Calibrating... Keep the MPU-6500 still!");

for i = 1:numSamples
    rawData = readline(s);
    values = str2double(strsplit(strtrim(rawData), ','));
    if numel(values) == 6 && ~any(isnan(values))
        calibrationData(i, :) = values;
    end
end

% Compute mean offset
offsets = mean(calibrationData, 1);
disp("Calibration complete! Offsets: ");
disp(offsets);

% ====== REAL-TIME UPDATE LOOP ======
dataBuffer = zeros(fftBlockSize, 1);
while true
    rawData = readline(s);
    
    % Debug: Display raw data
    disp("Raw Data: " + rawData);
    
    % Ensure valid data format
    if isempty(rawData) || ~contains(rawData, ',')
        disp("Warning: Empty or invalid data received!");
        continue;
    end
    
    values = str2double(strsplit(strtrim(rawData), ',')); % Convert to numbers
    
    % Ensure we received 6 valid numbers
    if numel(values) ~= 6 || any(isnan(values))
        disp("Warning: Incorrect number of values!");
        continue;
    end
    
    % Apply calibration (offset correction)
    values = values - offsets;
    
    % Shift data and update new values
    data(1:end-1, :) = data(2:end, :);
    data(end, :) = values;
    
    % Update real-time acceleration plot
    set(h1, 'YData', data(:,1));
    set(h2, 'YData', data(:,2));
    set(h3, 'YData', data(:,3));
    set(h4, 'YData', data(:,4));
    set(h5, 'YData', data(:,5));
    set(h6, 'YData', data(:,6));
    
    % FFT Processing
    dataBuffer(1:end-1) = dataBuffer(2:end);
    dataBuffer(end) = values(1); % Using Ax1 for FFT
    
    if length(dataBuffer) >= fftBlockSize
        fftResult = fft(dataBuffer, fftBlockSize);
        fftMagnitude = abs(fftResult(1:fftBlockSize/2));
        set(hFFT, 'YData', fftMagnitude);
    end
    
    drawnow;
end
