import serial
import time
import requests

# Network Configuration
PORT = 'COM3' 
BAUD = 9600
API_KEY = 'Replace with your ThingSpeak Write Key'
TS_URL = "https://api.thingspeak.com/update"

try:
    ser = serial.Serial(PORT, BAUD, timeout=1)
    time.sleep(2) # Stabilization delay for Arduino R4
    print(f"IoT Gateway Online: {PORT} syncing to ThingSpeak...")
except Exception as e:
    print(f"Connection Error: {e}")
    exit()

last_sync = 0

while True:
    if ser.in_waiting > 0:
        try:
            line = ser.readline().decode('utf-8').strip()
            parts = line.split(',')
            
            if len(parts) == 4:
                v, i, lux, t = parts
                current_time = time.time()
                
                # Enforce REST API Rate Limiting (16 seconds)
                if current_time - last_sync >= 16:
                    payload = {
                        'api_key': API_KEY,
                        'field1': v,
                        'field2': i,
                        'field3': lux,
                        'field4': t
                    }
                    res = requests.get(TS_URL, params=payload)
                    if res.text != '0':
                        print(f"[{time.strftime('%H:%M:%S')}] Cloud Sync Success. ID: {res.text}")
                        last_sync = current_time
                    else:
                        print("Sync Failed: Rate Limit Error")
        except Exception as e:
            print(f"Data Processing Error: {e}")
            
    time.sleep(0.5)
