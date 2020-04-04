#include <SoftwareSerial.h>
#include <LiquidCrystal.h>
#include "Led.h"


SoftwareSerial bt(7, 8); // RX, TX
LiquidCrystal lcd(12, 13, 5, 4, 3, 2);

Led red(6);
Led yellow(9);
Led green(10);
Led blue(11);

const int bellPin = A0;
const unsigned long ringThrottleTimeMs = 2000;
unsigned long ringing = 0;

char inputCommand[48];
int inputPtr = 0;


void setup() {
  Serial.begin(9600);
  bt.begin(9600);
  lcd.begin(16, 2);
}

void loop() {
  processBellInput();
  processBluetoothInput();
}

void processBellInput() {
  unsigned long now = millis();
  if (ringing && now - ringing <= ringThrottleTimeMs) {
    return;
  }
  if (analogRead(bellPin) > 500) {
    ringing = now;
    bt.println("RING");
    Serial.println("RING");
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
  Serial.println(command);
  if (!strncmp(command, "TXT ", 4)) {
    setText(command + 4);
  } else if (!strncmp(command, "LED ", 4) && strlen(command) > 6) {
    setLed(command + 4); 
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
