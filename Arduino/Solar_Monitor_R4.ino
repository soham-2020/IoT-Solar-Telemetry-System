#include <Wire.h>
#include <Adafruit_INA219.h>
#include <LiquidCrystal.h>
#include <BH1750.h>
#include <OneWire.h>
#include <DallasTemperature.h>

// Hardware Configuration
const int relayPin = 6; 
const int tempPin = 7;
const int rs = 12, en = 11, d4 = 5, d5 = 4, d6 = 3, d7 = 2;

LiquidCrystal lcd(rs, en, d4, d5, d6, d7);
Adafruit_INA219 ina219;
BH1750 lightMeter;
OneWire oneWire(tempPin);
DallasTemperature sensors(&oneWire);

void setup() {
  Serial.begin(9600);
  pinMode(relayPin, OUTPUT);
  digitalWrite(relayPin, HIGH); // Engage Load

  lcd.begin(16, 2);
  Wire.begin();
  sensors.begin();

  if (!ina219.begin() || !lightMeter.begin()) {
    lcd.print("I2C Error!");
    while (1);
  }
  lcd.clear();
}

void loop() {
  // Data Acquisition
  float v = ina219.getBusVoltage_V();
  float i = ina219.getCurrent_mA();
  float lux = lightMeter.readLightLevel();
  sensors.requestTemperatures();
  float t = sensors.getTempCByIndex(0);

  // CSV Output for Python Gateway (V, I, Lux, Temp)
  Serial.print(v); Serial.print(",");
  Serial.print(i); Serial.print(",");
  Serial.print(lux); Serial.print(",");
  Serial.println(t);

  // Local HMI (LCD Toggle)
  static bool toggle = true;
  lcd.clear();
  if (toggle) {
    lcd.setCursor(0,0); lcd.print("V: "); lcd.print(v); lcd.print("V");
    lcd.setCursor(0,1); lcd.print("I: "); lcd.print(i); lcd.print("mA");
  } else {
    lcd.setCursor(0,0); lcd.print("Lux: "); lcd.print(lux);
    lcd.setCursor(0,1); lcd.print("Temp: "); lcd.print(t); lcd.print("C");
  }
  toggle = !toggle;
  delay(2000); 
}
