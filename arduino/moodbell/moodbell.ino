#include <SoftwareSerial.h>
#include <LiquidCrystal.h>
#include "Led.h"

#define DEVICE_SIGNATURE "MOODBELL 1.0"

SoftwareSerial bt(7, 8); // RX, TX
LiquidCrystal lcd(12, 13, 4, 2, 1, 0);

Led red(6);
Led yellow(9);
Led green(10);
Led blue(11);
Led backlight(3);

const int lightSensorPin = A1;
const int lightSensorReadIntervalMs = 1000;
const int lightSensorTolerance = 16;
int lightSensorLastReading = -lightSensorTolerance;
unsigned long lightSensorReadTime = 0;

const int bellPin = A0;
const unsigned long ringThrottleTimeMs = 2000;
unsigned long ringing = 0;

char inputCommand[48];
int inputPtr = 0;

void setup() {
  bt.begin(9600);
  lcd.begin(16, 2);
  backlight.pwm(128);
}

void loop() {
  processLightInput();
  processBellInput();
  processBluetoothInput();
}

void processLightInput() {
  unsigned long now = millis();
  if (now - lightSensorReadTime < lightSensorReadIntervalMs) {
    return;
  }
  lightSensorReadTime = now;
  int light = analogRead(lightSensorPin);
  if (abs(lightSensorLastReading - light) < lightSensorTolerance) {
    return;
  }
  bt.print("LIGHT ");
  bt.println(light);
  lightSensorLastReading = light;
}

void processBellInput() {
  unsigned long now = millis();
  if (ringing && now - ringing <= ringThrottleTimeMs) {
    return;
  }
  if (analogRead(bellPin) > 500) {
    ringing = now;
    bt.println("RING");
  } else {
    ringing = 0;
  }
}

void processBluetoothInput() {
  while (bt.available()) {
    char i = bt.read();
    if (i == '\n') {
      inputCommand[inputPtr] = 0;
      processCommand(inputCommand);
      inputPtr = 0;
    } else {
      inputCommand[inputPtr++] = i;
      if (inputPtr >= sizeof inputCommand) {
        inputPtr = 0;
      }
    }
  }
}

void processCommand(const char* command) {
  if (!strncmp(command, "TXT ", 4)) {
    setText(command + 4);
  } else if (!strncmp(command, "LED ", 4) && strlen(command) > 6) {
    setLed(command + 4);
  } else if (!strncmp(command, "BACK ", 5)) {
    setBacklight(command + 5);
  } else if (!strcmp(command, "HELLO")) {
    handshake();
  }
}

void setText(const char* text) {
  lcd.clear();
  lcd.print(text);
  if (strlen(text) > 16) {
    lcd.setCursor(0, 1);
    lcd.print(text + 16);
  }
}

void setLed(const char* input) {
  char led = input[0];
  int value = atoi(input + 2);
  switch (led) {
  case 'R':
    red.pwm(value);
    break;
  case 'G':
    green.pwm(value);
    break;
  case 'B':
    blue.pwm(value);
    break;
  case 'Y':
    yellow.pwm(value);
    break;
  }
}

void setBacklight(const char* input) {
  backlight.pwm(atoi(input));
}

void handshake() {
  bt.println(DEVICE_SIGNATURE);
  lightSensorLastReading = -lightSensorTolerance;
  ringing = 0;
}
