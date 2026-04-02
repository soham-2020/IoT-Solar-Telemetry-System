# ☀️ IoT Solar Telemetry System
### Real-Time PV Performance Monitoring via a 3-Tier Edge–Gateway–Cloud Architecture

[![Arduino](https://img.shields.io/badge/Hardware-Arduino_UNO_R4_Minima-00979D?style=flat-square&logo=arduino)](https://www.arduino.cc/)
[![Python](https://img.shields.io/badge/Gateway-Python_3.x-3776AB?style=flat-square&logo=python)](https://www.python.org/)
[![ThingSpeak](https://img.shields.io/badge/Cloud-ThingSpeak-FF6600?style=flat-square)](https://thingspeak.com/)
[![MATLAB](https://img.shields.io/badge/Analytics-MATLAB-0076A8?style=flat-square)](https://www.mathworks.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)

---

## 📋 Table of Contents

1. [Problem Statement](#1-problem-statement)
2. [System Architecture](#2-system-architecture)
3. [Tech Stack](#3-tech-stack)
4. [Hardware Setup](#4-hardware-setup)
5. [Data Analytics & MATLAB Model](#5-data-analytics--matlab-model)
6. [Results & Dashboard](#6-results--dashboard)
7. [Repository Structure](#7-repository-structure)
8. [Setup & Deployment](#8-setup--deployment)
9. [Future Scope](#9-future-scope)

---

## 1. Problem Statement

Small-scale photovoltaic (PV) installations operate as **black boxes**. Without instrumentation, the operator has no visibility into three critical failure modes:

| Gap | Consequence |
|---|---|
| **No irradiance tracking** | Cannot distinguish between a low-yield day due to weather vs. panel degradation |
| **No thermal monitoring** | Cell temperature rise causes measurable V_oc depression; goes undetected until permanent damage |
| **No performance baseline** | No way to compare actual output against theoretical yield, making efficiency losses invisible |

This system addresses all three gaps with a purpose-built, cloud-connected telemetry stack.

---

## 2. System Architecture

The system is implemented as a **3-tier IoT architecture**, cleanly separating concerns across Edge, Network, and Cloud layers.

```
┌─────────────────────────────────────────────────────────────────┐
│                         SOLAR PANEL (PV)                        │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                   ┌────────────▼────────────┐
                   │      TIER 1: EDGE       │
                   │  Arduino UNO R4 Minima  │
                   │    (ARM Cortex-M4)      │
                   │                         │
                   │  INA219  → I2C Bus      │
                   │  BH1750  → I2C Bus      │
                   │  DS18B20 → One-Wire     │
                   │  LCD 16x2 → GPIO        │
                   └────────────┬────────────┘
                                │ UART Serial (9600 baud)
                                │ CSV: V, I, Lux, T
                   ┌────────────▼────────────┐
                   │    TIER 2: GATEWAY      │
                   │     Python Script       │
                   │    (PC / Raspberry Pi)  │
                   │                         │
                   │  • Serial deserialization│
                   │  • Rate-limit management│
                   │  • REST API dispatch    │
                   └────────────┬────────────┘
                                │ HTTPS GET (REST API)
                                │ ThingSpeak Rate: 1 req / 15s
                   ┌────────────▼────────────┐
                   │     TIER 3: CLOUD       │
                   │       ThingSpeak        │
                   │                         │
                   │  Field 1: Voltage (V)   │
                   │  Field 2: Current (mA)  │
                   │  Field 3: Irradiance(Lx)│
                   │  Field 4: Temperature(°C│
                   │  MATLAB Visualization   │
                   └─────────────────────────┘
```

---

## 3. Tech Stack

### Edge Layer — Firmware (C++)

| Component | Role | Protocol |
|---|---|---|
| **Arduino UNO R4 Minima** (ARM Cortex-M4 @ 48 MHz) | Sensor fusion & data serialization | — |
| **INA219** (Texas Instruments) | Bus voltage & current measurement | **I²C** (addr `0x40`) |
| **BH1750** | Ambient light / irradiance (0–65535 lux) | **I²C** (addr `0x23`) |
| **DS18B20** | 1-wire digital thermometer (±0.5°C) | **1-Wire** |
| **LCD 16×2** | Local real-time display | **4-bit parallel GPIO** |
| **Relay Module** | Load switching for V_oc measurement | Digital GPIO |

### Gateway Layer — Python 3

| Library | Purpose |
|---|---|
| `pyserial` | UART stream ingestion from Arduino |
| `requests` | HTTP REST client for ThingSpeak API |
| `time` | 15-second rate-limit enforcement |

### Cloud & Analytics Layer

| Platform | Tool | Purpose |
|---|---|---|
| **ThingSpeak** | Channel Fields 1–4 | Time-series data storage & visualization |
| **ThingSpeak** | MATLAB Visualization App | Theoretical yield computation & dual-axis plotting |

---

## 4. Hardware Setup

### Wiring Summary

```
Arduino UNO R4 Minima
│
├── I²C Bus (SDA → A4, SCL → A5)
│   ├── INA219  [0x40]   — Voltage & Current
│   └── BH1750  [0x23]   — Irradiance (Lux)
│
├── One-Wire Bus (Pin 7)
│   └── DS18B20          — Cell Surface Temperature
│
├── LCD 16x2 (4-bit mode)
│   └── RS=12, EN=11, D4=5, D5=4, D6=3, D7=2
│
└── Relay (Pin 6)        — Load disconnect for V_oc measurement
```

> **Note:** The INA219 is wired in series with the panel's positive rail. The DS18B20 requires a **4.7kΩ pull-up** resistor between DATA and VCC.

---

## 5. Data Analytics & MATLAB Model

### The Core Problem with Live Current

Open-circuit voltage ($V_{oc}$) testing requires the load to be **disconnected**, which drives $I = 0$. This makes direct power measurement ($P = V \times I$) meaningless. The MATLAB model bypasses this by deriving a **Theoretical Power Yield** from irradiance alone.

### Mathematical Model

Solar irradiance $E$ (W/m²) is estimated from the BH1750 lux reading using the standard photometric conversion factor for sunlight:

$$E \approx \frac{L_{lux}}{120} \quad [\text{W/m}^2]$$

Theoretical DC power output is then:

$$P_{theoretical} = E \times A_{cell} \times \eta$$

$$P_{theoretical} = \frac{L_{lux}}{120} \times 0.005 \; \text{m}^2 \times 0.15$$

Where:
- $L_{lux}$ = BH1750 lux reading
- $A_{cell} = 0.005 \; \text{m}^2$ — effective panel area
- $\eta = 0.15$ — nominal cell efficiency (15%)

This model produces a **performance baseline** independent of load state, enabling correlation between irradiance and actual $V_{oc}$ on a dual-axis plot.

### MATLAB Visualization Output

The dual-axis plot correlates **Bus Voltage** (left Y-axis) with **Predicted Power** (right Y-axis) over the 15 most recent data points. Divergence between these curves is a direct indicator of efficiency loss or thermal degradation.

---

## 6. Results & Dashboard

### ThingSpeak Live Dashboard

> 📺 **[Watch the Full Demo on YouTube →](#)** *(Link to be added)*

| Metric | Observed Range | Notes |
|---|---|---|
| Bus Voltage | 1.65 V – 2.59 V | Peaks correlate with high irradiance events |
| Irradiance | 0 – 510 lux | Sharp spikes indicate direct sunlight exposure |
| Cell Temperature | 30.8°C – 31.4°C | Inverse relationship with voltage confirmed |
| Predicted Power | ~0.6 mW – 3.2 mW | Scaled to 5cm² test cell |

### Dashboard Screenshots

**ThingSpeak channel-

> <img width="2485" height="1351" alt="image" src="https://github.com/user-attachments/assets/0b88e284-88a5-4cf9-80e9-8aff09592fef" />


**MATLAB Dual-Axis Performance Plot:**

> <img width="1372" height="880" alt="image" src="https://github.com/user-attachments/assets/f3b87a6d-7d74-4351-ae21-35862fc6e239" />


---

## 7. Repository Structure

```
/
├── Arduino/
│   └── Solar_Monitor_R4.ino   # Sensor fusion firmware (C++)
├── Python/
│   └── Gateway.py             # Serial-to-cloud bridge
├── MATLAB/
│   └── Analysis.m             # ThingSpeak visualization script
├── requirements.txt           # Python dependencies
└── README.md
```

---

## 8. Setup & Deployment

### Prerequisites

```bash
pip install pyserial requests
```

### Step 1 — Flash Firmware

Open `Arduino/Solar_Monitor_R4.ino` in the Arduino IDE. Install the following libraries via Library Manager:

- `Adafruit INA219`
- `BH1750` by Christopher Laws
- `DallasTemperature` + `OneWire`

Flash to the **Arduino UNO R4 Minima**.

### Step 2 — Configure the Gateway

Edit `Python/Gateway.py`:

```python
PORT    = 'COM3'              # Update to your Arduino's serial port
API_KEY = 'YOUR_WRITE_KEY'   # From your ThingSpeak channel settings
```

Run the gateway:

```bash
python Python/Gateway.py
```

### Step 3 — Deploy MATLAB Visualization

1. Navigate to your ThingSpeak channel → **Apps → MATLAB Visualizations → New**
2. Paste the contents of `MATLAB/Analysis.m`
3. Update `readChannelID` and `readAPIKey` with your channel credentials
4. Click **Save and Run**

---

## 9. Future Scope

| Milestone | Description |
|---|---|
| **Predictive Degradation (ML/DL)** | Train an LSTM or transformer model on historical $V_{oc}$-vs-irradiance time series to forecast panel degradation before it causes measurable power loss |
| **MPPT Algorithm Implementation** | Implement Perturb & Observe (P&O) or Incremental Conductance MPPT in firmware to maximize power extraction under partial shading conditions |
| **Edge AI Inference** | Deploy a TinyML anomaly detection model directly on the Cortex-M4 to flag performance outliers without cloud dependency |
| **Wireless Edge Node** | Replace the PC gateway with an ESP32 module for a fully standalone, battery-backed deployment |
| **Multi-Panel Aggregation** | Extend the architecture to monitor and compare arrays of panels from a single ThingSpeak channel using multiple field sets |

---

## License

Distributed under the MIT License. See `LICENSE` for details.

---

