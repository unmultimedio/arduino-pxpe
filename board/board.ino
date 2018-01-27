#include <eHealth.h>
#include <eHealthDisplay.h>

void setup() {
  Serial.begin(115200);
  eHealth.initPositionSensor();
  delay(3000);
}

void loop() {

  Serial.print("{\"position\":\"");
  int position = eHealth.getBodyPosition();
  if (position == 1) {
    Serial.print("Supine position");    
  } else if (position == 2) {
    Serial.print("Left lateral decubitus");
  } else if (position == 3) {
    Serial.print("Rigth lateral decubitus");
  } else if (position == 4) {
    Serial.print("Prone position");
  } else if (position == 5) {
    Serial.print("Stand or sit position");
  } else  {
    Serial.print("non-defined position");
  }
  Serial.print("\",\"ECG\":");
  Serial.print(eHealth.getECG());
  Serial.print(",\"temperature\":");
  Serial.print(eHealth.getTemperature());
  Serial.print("}\n");

  delay(100); 
}

