// The radiator bot: opens the valve while the thermostat calls for heat and closes it when it
// stops, finding each end of the stem's travel by the motor's current.  A console on the USB
// serial port shows what it's doing and sets it up; see firmware/README.md.
#include <Arduino.h>

#include "app.h"
#include "console.h"
#include "pins.h"
#include "storage.h"

static App app;
static Console console(app, Serial);

void setup() {
  app.motor.begin();
  pinMode(pins::kThermostat, INPUT_PULLUP);

  // The console never holds up the motor: with no host reading, output is dropped.  The buffer
  // takes the longest reply (`help`, `get`) whole.
  Serial.setTxBufferSize(4096);
  Serial.setTxTimeoutMs(0);
  Serial.begin(115200);

  storage::load(app.settings);
  enableLoopWDT();

  Serial.println("radiatorbot " RADIATORBOT_VERSION "; `help` lists the commands");
}

void loop() {
  uint32_t now = millis();
  app.stat.update(now, digitalRead(pins::kThermostat) == LOW);
  app.ctl.setDesired(valve::desiredEnd(app.mode, app.manual, app.stat));
  app.ctl.tick(now);
  console.report(now);
  console.poll();
  delay(1);
}
