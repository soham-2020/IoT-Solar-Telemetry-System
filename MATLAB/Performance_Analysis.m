% Performance_Analysis.m
% Read recent ThingSpeak telemetry and compare measured operating-point
% electrical power with sensor readings. Lux is not used to calculate power.
readChannelID = 0000000;
readAPIKey = 'YOUR_THINGSPEAK_READ_KEY';
numPoints = 15;

% ThingSpeak field mapping from Python/Gateway.py:
% field1 = voltage (V), field2 = current (mA),
% field3 = illuminance (lux), field4 = temperature (deg C).
data = thingSpeakRead(readChannelID, 'Fields', [1 2 3 4], ...
    'NumPoints', numPoints, 'ReadKey', readAPIKey, ...
    'OutputFormat', 'matrix');

if isempty(data)
    error('No telemetry was returned. Check the channel ID, read key, and channel data.');
end
if size(data, 2) ~= 4
    error('Expected four ThingSpeak columns in the order fields 1 through 4.');
end

% Discard incomplete or physically invalid sensor rows before analysis.
validRows = all(isfinite(data), 2) & ...
    data(:, 1) >= 0 & ...          % bus voltage cannot be negative
    data(:, 3) >= 0 & ...          % illuminance cannot be negative
    data(:, 4) >= -55 & data(:, 4) <= 125; % DS18B20 operating range

if any(~validRows)
    warning('SolarTelemetry:InvalidRows', ...
        'Ignoring %d incomplete or out-of-range telemetry row(s).', sum(~validRows));
end
data = data(validRows, :);
if isempty(data)
    error('No valid telemetry rows remain after unit and range validation.');
end

[voltageV, currentmA, lux, temperatureC, measuredPowerW] = ...
    validateSolarTelemetry(data(:, 1), data(:, 2), data(:, 3), data(:, 4));

% This is only an illustrative lux-to-irradiance proxy. It is shown separately
% from measured electrical power and is not used in any power calculation.
irradianceProxyWm2 = lux ./ 120;

sample = (1:numel(voltageV))';
figure('Name', 'Solar telemetry: measured electrical quantities');
tiledlayout(3, 2, 'TileSpacing', 'compact');

nexttile;
plot(sample, voltageV, '-o', 'LineWidth', 1.4);
ylabel('Voltage (V)'); xlabel('Valid sample (oldest to newest)');
title('PV bus voltage'); grid on;

nexttile;
plot(sample, currentmA, '-o', 'LineWidth', 1.4);
ylabel('Current (mA)'); xlabel('Valid sample (oldest to newest)');
title('INA219 current'); grid on;

nexttile;
plot(sample, temperatureC, '-o', 'LineWidth', 1.4);
ylabel('Temperature (°C)'); xlabel('Valid sample (oldest to newest)');
title('DS18B20 temperature'); grid on;

nexttile;
plot(sample, measuredPowerW, '-o', 'LineWidth', 1.4);
ylabel('Electrical power (W)'); xlabel('Valid sample (oldest to newest)');
title('Measured operating-point power: V × I'); grid on;

nexttile;
plot(sample, lux, '-o', 'LineWidth', 1.4);
ylabel('Illuminance (lux)'); xlabel('Valid sample (oldest to newest)');
title('BH1750 illuminance'); grid on;

nexttile;
plot(sample, irradianceProxyWm2, '--s', 'LineWidth', 1.4);
ylabel('Indicative proxy (W/m²)'); xlabel('Valid sample (oldest to newest)');
title('Lux ÷ 120 (uncalibrated proxy)'); grid on;
subtitle('Lux-derived proxy is separate from measured electrical power');
