// Host tests for the valve library: the trip, the thermostat's input, the settings table and the
// controller against a simulated motor and valve.
//
//     make -C firmware/host_test
#include <math.h>
#include <stdio.h>
#include <string.h>

#include <functional>
#include <vector>

#include "controller.h"
#include "mode.h"
#include "settings.h"
#include "thermostat.h"
#include "trip_detector.h"

using namespace valve;

static int g_failures = 0;
static int g_checks = 0;
static const char* g_test = "";

#define CHECK(cond)                                                              \
  do {                                                                           \
    g_checks++;                                                                  \
    if (!(cond)) {                                                               \
      g_failures++;                                                              \
      printf("FAIL %s: %s:%d: %s\n", g_test, __FILE__, __LINE__, #cond);         \
    }                                                                            \
  } while (0)

#define CHECK_NEAR(a, b, tol) CHECK(fabs((a) - (b)) <= (tol))

// == A simulated valve ===========================================================================
// The stem travels `travel_ms` of motor running between its ends.  The motor draws an inrush near
// stall for the first 60 ms of a start, `run_a` on the way, and `stall_a` against either end.
// Forward (OUT1 high) opens it.
struct SimValve : Motor {
  float travel_ms = 20000;
  float pos = 0.5f;           // 0 closed, 1 open
  float run_a = 0.4f, stall_a = 1.8f, inrush_a = 1.7f;
  uint32_t inrush_ms = 60;

  bool awake = false, driving = false, fwd = false, fault_now = false;
  float duty = 0;
  uint32_t now = 0, drive_since = 0;
  int wakes = 0, sleeps = 0;
  std::vector<int> directions;  // +1 / -1 each time the direction of drive changes from rest

  void wake() override {
    awake = true;
    wakes++;
  }
  void drive(bool forward, float d) override {
    if (!awake) throw "drive while asleep";
    if (!driving || forward != fwd) {
      drive_since = now;
      directions.push_back(forward ? 1 : -1);
    }
    driving = true;
    fwd = forward;
    duty = d;
  }
  void brake() override {
    driving = false;
    duty = 0;
  }
  void sleep() override {
    awake = false;
    driving = false;
    sleeps++;
  }
  bool fault() override { return fault_now; }
  float amps() override {
    if (!driving || duty == 0) return 0;
    if (now - drive_since < inrush_ms) return inrush_a * duty;
    if (at_end()) return stall_a * duty;
    return run_a;
  }
  bool at_end() const { return (fwd && pos >= 1.0f) || (!fwd && pos <= 0.0f); }

  // Advances a millisecond.
  void step() {
    now++;
    if (driving && duty > 0) {
      pos += (fwd ? 1 : -1) * duty / travel_ms;
      if (pos > 1) pos = 1;
      if (pos < 0) pos = 0;
    }
  }
};

struct Rig {
  Settings s;
  SimValve v;
  Controller c{v, s};

  // Runs `ms` milliseconds, ticking the controller each one.
  void run(uint32_t ms) {
    for (uint32_t i = 0; i < ms; i++) {
      v.step();
      c.tick(v.now);
    }
  }
  // Runs until `done` or `limit` ms; true if done.
  bool run_until(std::function<bool()> done, uint32_t limit = 200000) {
    for (uint32_t i = 0; i < limit; i++) {
      if (done()) return true;
      run(1);
    }
    return done();
  }
};

// == The trip ====================================================================================
static void test_trip_ignores_inrush() {
  g_test = "trip ignores inrush";
  TripDetector t;
  t.start(0, 1.0f, 150, 50, 10);
  bool tripped = false;
  for (uint32_t ms = 1; ms <= 140; ms++) tripped |= t.update(ms, 1.8f);  // inrush, blanked
  CHECK(!tripped);
  for (uint32_t ms = 141; ms <= 1000; ms++) tripped |= t.update(ms, 0.4f);
  CHECK(!tripped);
  CHECK_NEAR(t.running(), 0.4f, 0.05f);
}

static void test_trip_holds() {
  g_test = "trip holds";
  TripDetector t;
  t.start(0, 1.0f, 100, 50, 0);
  uint32_t ms = 0;
  for (; ms < 500; ms++) CHECK(!t.update(ms, 0.4f));
  uint32_t rise = ms;
  while (!t.update(ms, 1.5f)) ms++;
  CHECK(ms - rise == 50);
  CHECK_NEAR(t.peak(), 1.5f, 1e-6f);
}

static void test_trip_rejects_spikes() {
  g_test = "trip rejects spikes";
  TripDetector t;
  t.start(0, 1.0f, 100, 50, 10);
  bool tripped = false;
  // 30 ms spikes to stall every 100 ms: the filter and the hold see through them
  for (uint32_t ms = 1; ms < 3000; ms++) tripped |= t.update(ms, (ms % 100) < 30 ? 1.8f : 0.4f);
  CHECK(!tripped);
}

static void test_trip_through_ripple() {
  g_test = "trip through ripple";
  TripDetector t;
  t.start(0, 1.0f, 100, 50, 10);
  // a stall whose readings jitter about 1.4 A, some below the trip
  uint32_t ms = 1;
  bool tripped = false;
  for (; ms < 2000 && !tripped; ms++) {
    float a = ms < 500 ? 0.4f : 1.4f + ((ms % 3) == 0 ? -0.5f : 0.25f);
    tripped = t.update(ms, a);
  }
  CHECK(tripped);
  CHECK(ms > 550 && ms < 650);
}

static void test_trip_wraps() {
  g_test = "trip across millis wrap";
  TripDetector t;
  uint32_t t0 = 0xFFFFFF00u;
  t.start(t0, 1.0f, 100, 50, 0);
  uint32_t ms = t0 + 1;
  for (int i = 0; i < 400; i++, ms++) CHECK(!t.update(ms, 0.4f));
  uint32_t rise = ms;
  while (!t.update(ms, 1.5f)) ms++;
  CHECK(ms - rise == 50);
}

// == The thermostat ==============================================================================
static void test_stat_contact() {
  g_test = "thermostat reads a closed contact as a call";
  Settings s;
  s.stat_settle = 3000;
  s.stat_invert = false;
  ThermostatInput in(s);
  uint32_t ms = 0;
  for (; ms < 3000; ms++) {
    in.update(ms, true);
    CHECK(!in.known());
  }
  in.update(ms++, true);
  CHECK(in.known());
  CHECK(in.calling());
  // the contact opens: not calling once that has held for the settling time
  uint32_t end = ms;
  for (; ms < end + 3000; ms++) {
    in.update(ms, false);
    CHECK(in.calling());
  }
  in.update(ms++, false);
  CHECK(!in.calling());
}

static void test_stat_bounce() {
  g_test = "thermostat rides out a bouncing contact";
  Settings s;
  s.stat_settle = 1000;
  s.stat_invert = false;
  ThermostatInput in(s);
  uint32_t ms = 0;
  for (; ms < 2000; ms++) in.update(ms, false);
  // the contact makes and breaks for 50 ms as it closes, then stays closed
  for (; ms < 2050; ms++) in.update(ms, (ms / 3) % 2 == 0);
  for (; ms < 3049; ms++) {
    in.update(ms, true);
    CHECK(!in.calling());
  }
  for (; ms < 3100; ms++) in.update(ms, true);
  CHECK(in.calling());
}

static void test_stat_idle() {
  g_test = "thermostat idle";
  Settings s;
  s.stat_settle = 1000;
  s.stat_invert = false;
  ThermostatInput in(s);
  for (uint32_t ms = 0; ms < 1200; ms++) in.update(ms, false);
  CHECK(in.known());
  CHECK(!in.calling());
}

static void test_stat_glitch() {
  g_test = "thermostat ignores a glitch";
  Settings s;
  s.stat_settle = 1000;
  s.stat_invert = false;
  ThermostatInput in(s);
  uint32_t ms = 0;
  for (; ms < 2000; ms++) in.update(ms, false);
  for (; ms < 2500; ms++) in.update(ms, true);   // half a second's contact
  for (; ms < 5000; ms++) {
    in.update(ms, false);
    CHECK(!in.calling());
  }
}

static void test_stat_invert() {
  g_test = "thermostat inverted";
  Settings s;
  s.stat_settle = 500;
  s.stat_invert = true;
  ThermostatInput in(s);
  uint32_t ms = 0;
  for (; ms < 700; ms++) in.update(ms, true);
  CHECK(in.known());
  CHECK(!in.calling());
  for (; ms < 1400; ms++) in.update(ms, false);
  CHECK(in.calling());
}

// == The mode ====================================================================================
static void test_desired_end() {
  g_test = "desired end";
  Settings s;
  s.stat_settle = 100;
  ThermostatInput in(s);
  CHECK(desiredEnd(Mode::kAuto, End::kUnknown, in) == End::kUnknown);  // not settled yet
  uint32_t ms = 0;
  for (; ms < 200; ms++) in.update(ms, false);
  CHECK(desiredEnd(Mode::kAuto, End::kOpen, in) == End::kClosed);
  for (; ms < 400; ms++) in.update(ms, true);
  CHECK(desiredEnd(Mode::kAuto, End::kClosed, in) == End::kOpen);
  // manual ignores the thermostat
  CHECK(desiredEnd(Mode::kManual, End::kClosed, in) == End::kClosed);
  CHECK(desiredEnd(Mode::kManual, End::kUnknown, in) == End::kUnknown);
}

static void test_settings_read_live() {
  g_test = "thermostat and controller read live settings";
  Rig r;
  ThermostatInput in(r.s);
  uint32_t ms = 0;
  for (; ms < 4000; ms++) in.update(ms, true);
  CHECK(in.calling());
  r.s.stat_invert = true;  // as the console's `set` does
  in.update(ms++, true);
  r.s.stat_settle = 0;
  in.update(ms++, true);
  CHECK(!in.calling());
}

// == The settings ================================================================================
static void test_settings_table() {
  g_test = "settings table";
  size_t n = 0;
  const Field* fs = fields(&n);
  CHECK(n > 10);
  Settings s;
  for (size_t i = 0; i < n; i++) {
    CHECK(strlen(fs[i].name) <= 15);  // the stored slots' names
    CHECK(findField(fs[i].name) == &fs[i]);
    // every default lies within its own range
    char buf[32];
    formatField(s, fs[i], buf, sizeof buf);
    CHECK(strlen(buf) <= 15);  // and its value as text
    Settings t;
    CHECK(setField(t, fs[i], buf));
    // and it comes back from its text as it was
    char again[32];
    formatField(t, fs[i], again, sizeof again);
    CHECK(strcmp(buf, again) == 0);
  }
  CHECK(fabs(s.motor_volts - 6.0f) < 1e-6f);
  char volts[32];
  formatField(s, *findField("motor_volts"), volts, sizeof volts);
  CHECK(strcmp(volts, "6") == 0);
  CHECK(findField("nope") == nullptr);
}

static void test_settings_parse() {
  g_test = "settings parse";
  Settings s;
  const Field* trip = findField("trip_close");
  CHECK(setField(s, *trip, "0.85"));
  CHECK_NEAR(s.trip_close, 0.85f, 1e-6f);
  CHECK(!setField(s, *trip, "9"));
  CHECK(!setField(s, *trip, "2.5"));  // over the paralleled TB6612's 2 A: it would never trip
  CHECK(!setField(s, *trip, "abc"));
  CHECK(!setField(s, *trip, "1.0x"));
  CHECK(!setField(s, *trip, ""));
  CHECK_NEAR(s.trip_close, 0.85f, 1e-6f);

  const Field* hold = findField("hold");
  CHECK(setField(s, *hold, "75"));
  CHECK(s.hold == 75);
  CHECK(!setField(s, *hold, "-5"));
  CHECK(!setField(s, *hold, "7.5"));
  CHECK(s.hold == 75);

  const Field* inv = findField("motor_invert");
  CHECK(setField(s, *inv, "on"));
  CHECK(s.motor_invert);
  CHECK(setField(s, *inv, "0"));
  CHECK(!s.motor_invert);
  CHECK(!setField(s, *inv, "2"));

  char buf[32];
  formatField(s, *trip, buf, sizeof buf);
  CHECK(strcmp(buf, "0.85") == 0);
  formatField(s, *hold, buf, sizeof buf);
  CHECK(strcmp(buf, "75") == 0);
}

// == The controller ==============================================================================
static void test_holds_without_desire() {
  g_test = "controller holds with no end desired";
  Rig r;
  r.run(5000);
  CHECK(r.v.wakes == 0);
  CHECK(r.c.state() == State::kIdle);
  CHECK(r.c.position() == End::kUnknown);
}

static void test_closes_and_opens() {
  g_test = "controller closes and opens";
  Rig r;
  r.c.setDesired(End::kClosed);
  CHECK(r.run_until([&] { return r.c.moves() == 1; }));
  CHECK(r.c.last().outcome == Outcome::kReached);
  CHECK(r.c.position() == End::kClosed);
  CHECK(r.v.pos == 0.0f);
  CHECK(r.v.directions.size() == 1 && r.v.directions[0] == -1);
  // it stopped soon after the stall: the hold and the filter's lag
  CHECK(r.c.last().duration_ms > 10000 && r.c.last().duration_ms < 10000 + 150);
  CHECK_NEAR(r.c.last().running_a, 0.4f, 0.05f);
  CHECK(r.c.last().peak_a >= 1.0f);
  // it brakes, then sleeps
  CHECK(!r.v.driving);
  r.run(Controller::kBrakeMs + 1);
  CHECK(!r.v.awake);
  CHECK(r.v.sleeps == 1);

  // nothing more while it's where it's wanted
  r.run(5000);
  CHECK(r.c.moves() == 1);

  r.c.setDesired(End::kOpen);
  CHECK(r.run_until([&] { return r.c.moves() == 2; }));
  CHECK(r.c.last().outcome == Outcome::kReached);
  CHECK(r.c.position() == End::kOpen);
  CHECK(r.v.pos == 1.0f);
  CHECK(r.c.last().duration_ms > 20000 && r.c.last().duration_ms < 20000 + 250);
}

static void test_already_there() {
  g_test = "controller at the end already";
  Rig r;
  r.v.pos = 0;
  r.c.setDesired(End::kClosed);
  CHECK(r.run_until([&] { return r.c.moves() == 1; }));
  CHECK(r.c.last().outcome == Outcome::kReached);
  // the blanking, then the hold
  CHECK(r.c.last().duration_ms >= r.s.blank + r.s.hold);
  CHECK(r.c.last().duration_ms < r.s.blank + r.s.hold + 50);
}

static void test_motor_invert() {
  g_test = "controller inverted motor";
  Rig r;
  r.s.motor_invert = true;
  r.c.setDesired(End::kOpen);
  r.run(500);
  CHECK(r.v.directions.size() == 1 && r.v.directions[0] == -1);
}

static void test_ramp() {
  g_test = "controller soft start";
  Rig r;
  r.s.ramp = 100;
  r.s.duty = 0.8f;
  r.c.setDesired(End::kOpen);
  r.run(51);
  CHECK(r.v.duty > 0.3f && r.v.duty < 0.5f);
  r.run(100);
  CHECK_NEAR(r.v.duty, 0.8f, 1e-6f);
}

static void test_timeout() {
  g_test = "controller times out";
  Rig r;
  r.v.stall_a = 0.5f;        // a stall the trip never sees
  r.s.timeout = 30;
  r.c.setDesired(End::kClosed);
  CHECK(r.run_until([&] { return r.c.moves() == 1; }));
  CHECK(r.c.last().outcome == Outcome::kTimeout);
  CHECK(r.c.last().duration_ms == 30000);
  CHECK(r.c.state() == State::kFault);
  CHECK(r.c.position() == End::kUnknown);
  CHECK(r.c.failures() == 1);
  r.run(Controller::kBrakeMs + 1);
  CHECK(!r.v.awake);
}

static void test_retries() {
  g_test = "controller retries, then gives up";
  Rig r;
  r.v.stall_a = 0.5f;
  r.s.timeout = 10;
  r.s.retry = 60;
  r.c.setDesired(End::kClosed);
  CHECK(r.run_until([&] { return r.c.moves() == 1; }));
  // waits the retry interval, then goes again
  r.run(59000);
  CHECK(r.c.moves() == 1);
  CHECK(!r.v.awake);
  CHECK(r.run_until([&] { return r.c.moves() == 2; }, 12000));
  // the first failure and kMaxRetries retries
  const uint32_t tries = 1u + Controller::kMaxRetries;
  CHECK(r.run_until([&] { return r.c.moves() == tries; }, 300000));
  r.run(1000000);
  CHECK(r.c.moves() == tries);
  CHECK(r.c.state() == State::kFault);
  CHECK(r.c.failures() == tries);

  // a change of mind tries again, afresh
  r.c.setDesired(End::kOpen);
  r.run(100);
  CHECK(r.c.state() == State::kRunning);
  CHECK(r.c.failures() == 0);
}

static void test_clear() {
  g_test = "controller cleared after a failure";
  Rig r;
  r.v.stall_a = 0.5f;
  r.s.timeout = 5;
  r.c.setDesired(End::kClosed);
  CHECK(r.run_until([&] { return r.c.moves() == 1; }));
  r.v.stall_a = 1.8f;  // mended
  r.s.timeout = 60;
  r.run(1000);
  CHECK(r.c.state() == State::kFault);
  r.c.clearFault();
  CHECK(r.run_until([&] { return r.c.moves() == 2; }));
  CHECK(r.c.last().outcome == Outcome::kReached);
  CHECK(r.c.failures() == 0);
}

static void test_driver_fault() {
  g_test = "controller stops on a motor fault";
  Rig r;
  r.c.setDesired(End::kOpen);
  r.v.fault_now = true;  // reported from the start: ignored for the grace, then counted
  CHECK(r.run_until([&] { return r.c.moves() == 1; }));
  CHECK(r.c.last().outcome == Outcome::kMotorFault);
  CHECK(r.c.last().duration_ms == Controller::kFaultGraceMs + Controller::kFaultTicks - 1);
  CHECK(r.c.state() == State::kFault);
  CHECK(!r.v.driving);
}

static void test_fault_glitch() {
  g_test = "controller ignores a fault glitch";
  Rig r;
  r.c.setDesired(End::kOpen);
  r.run(1000);
  r.v.fault_now = true;
  r.run(Controller::kFaultTicks - 1);
  r.v.fault_now = false;
  r.run(1000);
  CHECK(r.c.state() == State::kRunning);
}

static void test_change_of_mind() {
  g_test = "controller reverses on a change of mind";
  Rig r;
  r.c.setDesired(End::kOpen);
  r.run(5000);
  float pos = r.v.pos;
  r.c.setDesired(End::kClosed);
  r.run(1);
  CHECK(r.c.moves() == 1);
  CHECK(r.c.last().outcome == Outcome::kAborted);
  CHECK(r.c.position() == End::kUnknown);
  CHECK(!r.v.driving);
  // rests, then goes the other way
  r.run(r.s.rest - 2);
  CHECK(!r.v.driving);
  r.run(2);
  CHECK(r.v.driving && !r.v.fwd);
  CHECK(r.run_until([&] { return r.c.moves() == 2; }));
  CHECK(r.c.position() == End::kClosed);
  CHECK(r.c.last().duration_ms > pos * 20000 - 100);
}

static void test_hold_stops() {
  g_test = "controller stops when told to hold";
  Rig r;
  r.c.setDesired(End::kClosed);
  r.run(3000);
  r.c.setDesired(End::kUnknown);
  r.run(1);
  CHECK(!r.v.driving);
  CHECK(r.c.last().outcome == Outcome::kAborted);
  r.run(10000);
  CHECK(r.c.moves() == 1);
  CHECK(!r.v.awake);
}

static void test_backoff() {
  g_test = "controller backs off";
  Rig r;
  r.s.backoff_open = 300;
  r.s.ramp = 0;
  r.c.setDesired(End::kOpen);
  CHECK(r.run_until([&] { return r.c.moves() == 1; }));
  CHECK(r.c.state() == State::kBackoff);
  r.run(2);
  CHECK(r.v.driving && !r.v.fwd);
  r.run(300);
  CHECK(!r.v.driving);
  CHECK(r.c.state() == State::kIdle);
  CHECK(r.c.position() == End::kOpen);
  CHECK(r.v.pos < 1.0f && r.v.pos > 0.98f);
  // and stays put
  r.run(10000);
  CHECK(r.c.moves() == 1);
}

static void test_wrap() {
  g_test = "controller across millis wrap";
  Rig r;
  r.v.now = 0xFFFFF000u;
  r.c.setDesired(End::kClosed);
  CHECK(r.run_until([&] { return r.c.moves() == 1; }));
  CHECK(r.c.last().outcome == Outcome::kReached);
  CHECK(r.c.last().duration_ms > 10000 && r.c.last().duration_ms < 10200);
}

int main() {
  test_trip_ignores_inrush();
  test_trip_holds();
  test_trip_rejects_spikes();
  test_trip_through_ripple();
  test_trip_wraps();
  test_stat_contact();
  test_stat_bounce();
  test_stat_idle();
  test_stat_glitch();
  test_stat_invert();
  test_settings_table();
  test_desired_end();
  test_settings_read_live();
  test_settings_parse();
  test_holds_without_desire();
  test_closes_and_opens();
  test_already_there();
  test_motor_invert();
  test_ramp();
  test_timeout();
  test_retries();
  test_clear();
  test_driver_fault();
  test_fault_glitch();
  test_change_of_mind();
  test_hold_stops();
  test_backoff();
  test_wrap();
  printf("%d checks, %d failed\n", g_checks, g_failures);
  return g_failures ? 1 : 0;
}
