# ☀️ IoT Solar Telemetry System

Arduino-based solar telemetry using an INA219 voltage/current sensor, BH1750 light sensor, DS18B20 temperature sensor, a Python serial gateway, ThingSpeak, and MATLAB.

## System and ThingSpeak field mapping

The Arduino emits comma-separated values in this order: voltage (V), current (mA), illuminance (lux), and temperature (°C). `Python/Gateway.py` uploads them to:

| ThingSpeak field | Measurement | Unit |
| --- | --- | --- |
| 1 | INA219 bus voltage | V |
| 2 | INA219 current | mA |
| 3 | BH1750 illuminance | lux |
| 4 | DS18B20 temperature | °C |

The current reading is the sensor's signed current at the operating point created by the connected circuit/load. Confirm sensor polarity and wiring before interpreting its sign. The measurements do not by themselves establish maximum-power-point tracking, panel efficiency, or total energy yield.

## Electrical power calculation

`MATLAB/Performance_Analysis.m` reads fields 1–4 and computes measured operating-point electrical power as:

```
P (W) = V (V) × I (mA) / 1000
```

The factor of 1000 converts milliamperes to amperes. For example, 5 V × 200 mA / 1000 = 1 W. Current remains signed: a negative result can indicate reversed current polarity or power flowing opposite to the assumed direction. Check wiring and sensor orientation before drawing conclusions.

The script validates that readings are numeric and finite, rejects negative voltage/lux and temperatures outside the DS18B20 range (-55 to 125 °C), and drops incomplete or invalid ThingSpeak rows. Current is allowed to be negative because the INA219 reports direction. The resulting charts show voltage, current, temperature, calculated electrical power, illuminance, and an optional lux-derived irradiance proxy.

## Illuminance is not calibrated solar irradiance

Lux measures light weighted for human visual sensitivity. Solar irradiance measures radiant power per area (W/m²). A conversion such as `lux / 120` is only a rough, condition-dependent proxy; it varies with the light spectrum, sensor response, angle, shading, and environment. This repository does not document a calibration against a reference pyranometer or equivalent irradiance instrument.

The MATLAB chart therefore labels `lux / 120` only as an **uncalibrated irradiance proxy** and plots it separately. It is not used to calculate electrical power or efficiency. The previous illustrative area/efficiency estimate has been removed. No calibrated solar efficiency is reported because panel area, reference irradiance, and a validated efficiency measurement procedure are not established here.

## Reproducible MATLAB analysis

1. Configure the Arduino and Python gateway as described below, and enable ThingSpeak channel fields 1–4 with the units above.
2. Set `readChannelID` and `readAPIKey` near the top of `MATLAB/Performance_Analysis.m`. For a public channel, use the read-key settings supported by your ThingSpeak account.
3. In MATLAB, change to the repository directory and run:
   ```matlab
   addpath('MATLAB');
   run('MATLAB/Performance_Analysis.m');
   ```
4. Run the offline synthetic checks without hardware or cloud access:
   ```matlab
   addpath('MATLAB');
   run('MATLAB/test_synthetic_telemetry.m');
   ```
   The test checks known power values, including 5 V × 200 mA = 1 W, signed current, and rejection of invalid ranges, non-finite data, and mismatched vector lengths.

The synthetic checks verify the unit conversion and input validation only. They do not exercise Arduino sensors, the serial gateway, ThingSpeak credentials/data, or real hardware behavior. A live analysis requires valid channel data and credentials.

## Hardware and gateway setup

### Prerequisites

- Arduino IDE and the libraries: Adafruit INA219, BH1750 by Christopher Laws, DallasTemperature, OneWire, and LiquidCrystal.
- Python 3 with `pyserial` and `requests`.

Install Python dependencies:

```bash
pip install pyserial requests
```

1. Open `Arduino/Solar_Monitor_R4.ino` in Arduino IDE, select the Arduino UNO R4 Minima, and upload the sketch.
2. In `Python/Gateway.py`, set `PORT` to the serial port for your board and `API_KEY` to the ThingSpeak channel write key. Keep credentials private.
3. Start the gateway:
   ```bash
   python Python/Gateway.py
   ```
4. Confirm fields 1–4 are receiving values before running the MATLAB analysis.

## Repository layout

```
Arduino/Solar_Monitor_R4.ino          Sensor acquisition and CSV serial output
Python/Gateway.py                     Serial-to-ThingSpeak gateway
MATLAB/Performance_Analysis.m         ThingSpeak analysis and plots
MATLAB/validateSolarTelemetry.m       Unit/range validation and power calculation
MATLAB/test_synthetic_telemetry.m     Offline synthetic checks
```

## License

Distributed under the MIT License. See [LICENSE](LICENSE).
