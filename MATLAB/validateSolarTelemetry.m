function [voltageV, currentmA, lux, temperatureC, powerW] = ...
    validateSolarTelemetry(voltageV, currentmA, lux, temperatureC)
%VALIDATESOLARTelemetry Check units, shapes, and ranges; calculate V*I power.
% Inputs are voltage in volts, signed current in milliamperes, illuminance
% in lux, and DS18B20 temperature in degrees Celsius. Power is returned in W.

inputs = {voltageV, currentmA, lux, temperatureC};
names = {'voltageV', 'currentmA', 'lux', 'temperatureC'};
for k = 1:numel(inputs)
    value = inputs{k};
    if ~isnumeric(value) || ~isreal(value) || ~isvector(value) || isempty(value)
        error('SolarTelemetry:InvalidData', ...
            '%s must be a nonempty real numeric vector.', names{k});
    end
    inputs{k} = double(value(:));
    if any(~isfinite(inputs{k}))
        error('SolarTelemetry:InvalidData', ...
            '%s must contain only finite values.', names{k});
    end
end

if numel(inputs{1}) ~= numel(inputs{2}) || ...
        numel(inputs{1}) ~= numel(inputs{3}) || ...
        numel(inputs{1}) ~= numel(inputs{4})
    error('SolarTelemetry:InvalidData', ...
        'Voltage, current, lux, and temperature vectors must have equal lengths.');
end

voltageV = inputs{1};
currentmA = inputs{2};
lux = inputs{3};
temperatureC = inputs{4};

if any(voltageV < 0)
    error('SolarTelemetry:InvalidData', 'Voltage in volts cannot be negative.');
end
if any(lux < 0)
    error('SolarTelemetry:InvalidData', 'Illuminance in lux cannot be negative.');
end
if any(temperatureC < -55 | temperatureC > 125)
    error('SolarTelemetry:InvalidData', ...
        'Temperature is outside the DS18B20 range (-55 to 125 °C).');
end

% INA219 current is signed; preserve its sign to expose reversed polarity.
% mA / 1000 converts milliamperes to amperes, so the result is watts.
powerW = voltageV .* currentmA ./ 1000;
end
