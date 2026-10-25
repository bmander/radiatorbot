// The radiator bot: opens the valve while the thermostat calls for heat and closes it when it
// stops, finding each end of the stem's travel by the motor's current.  A console on the USB
// serial port shows what it's doing and sets it up; see firmware/README.md.
#include <Arduino.h>

#include "app.h"
#include "console.h"
#include "pins.h"
#include "storage.h"

using valve::End;
using valve::State;

static App app;
static Console console(app, Serial);

static bool g_stat_known = false, g_stat_calling = false;
static State g_state = State::kIdle;
static uint32_t g_moves = 0, g_traced = 0;

static const char* modeName(const App& a) { return a.mode == Mode::kAuto ? "auto" : "manual"; }

static const char* statName(const valve::ThermostatInput& s) {
  if (!s.known()) return "not settled yet";
  return s.calling() ? "calling for heat" : "not calling";
}

static void printMove(const valve::MoveReport& m) {
  Serial.printf("%s: %s in %.1f s; running %.2f A, peak %.2f A, trip %.2f A\n",
                m.target == End::kOpen ? "open" : "close", valve::name(m.outcome),
                m.duration_ms / 1000.0, m.running_a, m.peak_a, m.trip_a);
}

void printStatus(App& a) {
  const valve::Controller& c = a.ctl;
  Serial.printf("radiatorbot " RADIATORBOT_VERSION ", up %lu s\n",
                static_cast<unsigned long>(millis() / 1000));
  Serial.printf("  mode        %s", modeName(a));
  if (a.mode == Mode::kManual) Serial.printf(" (%s)", a.manual == End::kUnknown ? "hold" : valve::name(a.manual));
  Serial.printf("\n  thermostat  %s (input %s)\n", statName(a.stat),
                digitalRead(pins::kThermostat) == LOW ? "low" : "high");
  Serial.printf("  valve       %s\n", valve::name(c.position()));
  Serial.printf("  motor       %s", valve::name(c.state()));
  if (c.state() == State::kRunning) Serial.printf(" to %s", valve::name(c.target()));
  if (c.state() == State::kFault) Serial.printf(" (%u in a row)", c.failures());
  Serial.printf(", driver %s%s\n", c.awake() ? "awake" : "asleep",
                a.motor.fault() ? ", FAULT" : "");
  if (c.awake()) {
    Serial.printf("  current     %.2f A (%.2f A filtered), offset %.0f mV\n", c.amps(), c.filtered(),
                  a.motor.offset_mv());
  }
  if (c.moves() > 0) {
    Serial.print("  last move   ");
    printMove(c.last());
  }
}

static void control(uint32_t now) {
  App& a = app;
  a.stat.configure(a.settings.stat_settle, a.settings.stat_invert);
  a.stat.update(now, digitalRead(pins::kThermostat) == LOW);
  if (a.stat.known() && (!g_stat_known || a.stat.calling() != g_stat_calling)) {
    g_stat_known = true;
    g_stat_calling = a.stat.calling();
    Serial.printf("thermostat: %s\n", statName(a.stat));
  }

  End want = End::kUnknown;
  if (a.mode == Mode::kManual) {
    want = a.manual;
  } else if (a.stat.known()) {
    want = a.stat.calling() ? End::kOpen : End::kClosed;
  }
  a.ctl.setDesired(want);
  a.ctl.tick(now);

  const valve::Controller& c = a.ctl;
  if (c.moves() != g_moves) {
    g_moves = c.moves();
    printMove(c.last());
  }
  if (c.state() != g_state) {
    g_state = c.state();
    if (g_state == State::kRunning) {
      Serial.printf("%s\n", c.target() == End::kOpen ? "opening" : "closing");
      g_traced = now;
    } else if (g_state == State::kFault) {
      Serial.printf("move failed (%u in a row); `clear` tries again now\n", c.failures());
    }
  }
  if (a.trace_ms && (g_state == State::kRunning || g_state == State::kBackoff) &&
      now - g_traced >= a.trace_ms) {
    g_traced = now;
    Serial.printf("  %7.3f s  %.2f A  (%.2f A filtered)\n", c.elapsed(now) / 1000.0, c.amps(),
                  c.filtered());
  }
}

void setup() {
  app.motor.begin();
  pinMode(pins::kThermostat, INPUT_PULLUP);

  // The console never holds up the motor: with no host reading, output is dropped.
  Serial.setTxTimeoutMs(0);
  Serial.begin(115200);

  storage::load(app.settings);
  enableLoopWDT();

  Serial.println("radiatorbot " RADIATORBOT_VERSION "; `help` lists the commands");
}

void loop() {
  control(millis());
  console.poll();
  delay(1);
}
