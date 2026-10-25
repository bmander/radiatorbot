// The radiator bot: opens the valve while the thermostat calls for heat and closes it when it
// stops, finding each end of the stem's travel by the motor's current.  A console on the USB
// serial port shows what it's doing and sets it up; see firmware/README.md.
#include <Arduino.h>
#include <WDT.h>

#include "app.h"
#include "console.h"
#include "pins.h"
#include "port.h"
#include "storage.h"

static constexpr uint32_t kWatchdogMs = 2000;

static App app;
static Port port(Serial);
static Console console(app, port);

void setup() {
  app.motor.begin();
  pinMode(pins::kThermostat, INPUT_PULLUP);
  Serial.begin(115200);

  storage::load(app.settings);
  WDT.begin(kWatchdogMs);

  port.println("radiatorbot " RADIATORBOT_VERSION "; `help` lists the commands");
}

void loop() {
  uint32_t now = millis();
  app.stat.update(now, digitalRead(pins::kThermostat) == LOW);
  app.ctl.setDesired(valve::desiredEnd(app.mode, app.manual, app.stat));
  app.ctl.tick(now);
  console.report(now);
  console.poll();
  port.pump();
  WDT.refresh();
  delay(1);
}
