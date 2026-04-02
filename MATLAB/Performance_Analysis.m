% SECURITY: Replace with your specific Channel ID and Read API Key
readChannelID = 0000000; 
readAPIKey = 'YOUR_THINGSPEAK_READ_KEY'; 

% Ingest latest telemetry points
data = thingSpeakRead(readChannelID, 'Fields', [1,3], 'NumPoints', 15, 'ReadKey', readAPIKey);

if ~isempty(data)
    voltage = data(:,1);
    lux = data(:,2);

    % Irradiance-to-Power Model (Efficiency: 15% | Area: 0.005 m^2)
    predicted_power = (lux ./ 120) * 0.005 * 0.15;

    yyaxis left
    plot(voltage, '-bo', 'LineWidth', 2);
    ylabel('PV Bus Voltage (V)');
    grid on;
    
    yyaxis right
    plot(predicted_power, '-rs', 'LineWidth', 2);
    ylabel('Theoretical Power Yield (W)');
    
    title('PV Telemetry Correlation: Voltage vs. Modeled Power');
    legend('Observed Voltage', 'Predicted Yield');
end
