% Synthetic telemetry checks; no hardware or ThingSpeak connection is used.
[voltageV, currentmA, lux, temperatureC, powerW] = ...
    validateSolarTelemetry([5; 6], [200; -100], [400; 800], [25; 26]);

assert(isequal(voltageV, [5; 6]));
assert(isequal(currentmA, [200; -100]));
assert(isequal(lux, [400; 800]));
assert(isequal(temperatureC, [25; 26]));
assert(max(abs(powerW - [1; -0.6])) < 1e-12, ...
    'Expected 5 V × 200 mA = 1 W and 6 V × -100 mA = -0.6 W.');

% Invalid ranges, missing values, and unit-shape mismatches must be rejected.
assertRejected(@() validateSolarTelemetry(-1, 10, 100, 20));
assertRejected(@() validateSolarTelemetry(5, 10, -1, 20));
assertRejected(@() validateSolarTelemetry(5, 10, 100, 126));
assertRejected(@() validateSolarTelemetry(5, Inf, 100, 20));
assertRejected(@() validateSolarTelemetry([5; 6], 10, [100; 200], [20; 21]));

disp('Synthetic telemetry checks passed.');

function assertRejected(callable)
try
    callable();
catch exception
    assert(strcmp(exception.identifier, 'SolarTelemetry:InvalidData'), ...
        'Unexpected error while checking invalid synthetic telemetry.');
    return;
end
error('SyntheticTelemetry:ExpectedRejection', ...
    'The validator accepted invalid synthetic telemetry.');
end
