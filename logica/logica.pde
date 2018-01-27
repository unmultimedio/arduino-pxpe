import processing.serial.*;
import org.json.*;

// Arduino vars
Serial arduinoPort;
int baudios = 115200;

// Window setup
int w = 600, h = 400;
float ecgC = 300, ecgF = 0;
float temperatureC = 45, temperatureF = 0;
int widthFactor = 3;

// Vars of values to print
int arrayLength = w / widthFactor;
float[] ecgValues = new float[arrayLength];
float[] temperatureValues = new float[arrayLength];
String ecgLabel = "No ECG";
String temperatureLabel = "No temperature";
String positionLabel = "No position";
int ecgIndex = 0;
int temperatureIndex = 0;
String ecgUnits = "mV";
String temperatureUnits = "ºC";

// System vars
PrintWriter output;
PFont f;

void setup() {

  size(600, 900);
  println("List of available ports in Serial");
  println(Serial.list());
  
  arduinoPort = new Serial(this, "/dev/cu.usbmodem1421", baudios);
  arduinoPort.bufferUntil('\n');
  output = createWriter(
    // year() + "-" + month() + "-" + day() + "-" + hour() + ":" + minute() + ":" + second() + 
    "-log_voltage.txt");
  f = createFont("Arial", 16, true);

  resetScreen();
}

void resetValues() {
  ecgLabel = "No ECG";
  temperatureLabel = "No temperature";
  positionLabel = "No position";
}

boolean isValid(org.json.JSONObject measurement) {
  return measurement.has("ECG") && measurement.has("position") && measurement.has("temperature");
}

void resetScreen() {
  background(0);
  // Window divisions
  stroke(255);
  line(0, h, w, h);
  line(0, h * 2, w, h * 2);
  // Window divisions
  stroke(100);
  line(0, h * 0.25, w, h * 0.25);
  line(0, h * 0.75, w, h * 0.75);
  line(0, h + (h * 0.25), w, h + (h * 0.25));
  line(0, h + (h * 0.75), w, h + (h * 0.75));
  stroke(150);
  line(0, h + (h * 0.5), w, h + (h * 0.5));
  line(0, h * 0.5, w, h * 0.5);
  // Texts
  textFont(f, 15);
  fill(100);
  // ECG conventions
  text(String.valueOf(ecgC / 1000) + ecgUnits, 10, 15);
  text(String.valueOf((ecgC - ecgF) / (2 * 1000)) + ecgUnits, 10, 15 + (h * 0.5));
  text(String.valueOf(ecgF / 1000) + ecgUnits, 10, h - 5);
  // Temperature conventions
  text(String.valueOf(temperatureC) + temperatureUnits, 10, h + 15);
  text(String.valueOf((temperatureC - temperatureF) / 2) + temperatureUnits, 10, h + 15 + (h * 0.5));
  text(String.valueOf(temperatureF) + temperatureUnits, 10, h + h - 5);
}

void serialEvent(Serial port) {
  try {
    String jsonString = port.readStringUntil('\n');
    println(jsonString);
    org.json.JSONObject measurement = new org.json.JSONObject(jsonString);

    if(!isValid(measurement)) {
      throw new Exception("Invalid measurement");
    }

    // Save to log
    printLog(measurement);

    // ECG Logic
    float ecgValue = (float) measurement.getDouble("ECG");
    ecgLabel = String.valueOf(ecgValue + ecgUnits);
    ecgValues[ecgIndex++] = ecgValue * 1000;
    if(ecgIndex >= arrayLength) {
      ecgIndex = 0;
    }

    // Temperature Logic
    float temperatureValue = (float) measurement.getDouble("temperature");
    temperatureLabel = String.valueOf(temperatureValue + temperatureUnits);
    temperatureValues[temperatureIndex++] = temperatureValue;
    if(temperatureIndex >= arrayLength) {
      temperatureIndex = 0;
    }

    // Position Logic
    positionLabel = measurement.getString("position");

  } catch (Exception e) {
    println("Error!");
    resetValues();
    // e.printStackTrace();
  }
}

void draw() {
  resetScreen();
  printECGGraph();
  printTemperatureGraph();
  printPosition();
}

void printLog(org.json.JSONObject measurement) {
  // Add timestamp
  measurement.put("timestamp", year() + "/" + month() + "/" + day() + " " + hour() + ":" + minute() + ":" + second());
  // Save into the file
  output.println(measurement.toString());
  // println(measurement.toString());
}

void printECGGraph() {
  // Graph
  stroke(0, 255, 0); // Green
  for(int i = 0; i < ecgIndex - 1; i++) {
    float previous = h - ((ecgValues[i] - ecgF) * h) / (ecgC - ecgF);
    float current = h - ((ecgValues[i + 1] - ecgF) * h) / (ecgC - ecgF);
    line(i * widthFactor, previous, (i+1) * widthFactor, current);
  }

  // Text
  textFont(f, 18);
  fill(255);
  text(ecgLabel, (w * 0.5) - 100, 30);
}

void printTemperatureGraph() {
  // Graph
  stroke(255, 255, 255); // White
  for(int i = 0; i < temperatureIndex - 1; i++) {
    float previous = h - ((temperatureValues[i] - temperatureF) * h) / (temperatureC - temperatureF);
    float current = h - ((temperatureValues[i + 1] - temperatureF) * h) / (temperatureC - temperatureF);
    line(i * widthFactor, h + previous, (i+1) * widthFactor, h + current);
  }

  // Text
  textFont(f, 18);
  fill(255);
  text(temperatureLabel, (w * 0.5) - 100, h + 30);
}

void printPosition() {
  // Text
  textFont(f, 25);
  fill(255);
  text(positionLabel, (w * 0.5) - 100, (2 * h) + 30);
}

void keyPressed() {
  output.flush(); // Writes the remaining data to the file
  output.close(); // Finishes the file
  exit(); // Stops the program
}