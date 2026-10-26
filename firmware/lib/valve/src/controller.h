// Drives the valve to the end it's asked for, and knows where it is.
//
// The stem has two ends, open and closed, and the motor's current says when it reaches either.
// The controller runs the motor toward the desired end until the current trips, then brakes and
// puts the driver to sleep.  Between ends, or after a failure, it doesn't know where the valve is.
//
// A move fails if it times out without tripping or the motor reports a fault.  After a failure
// the controller waits: it tries again when the desired end changes, when it's cleared, or after
// `retry` seconds, at most `kMaxRetries` times in a row on its own.
#pragma once

#include <stdint.h>

#include "motor.h"
#include "settings.h"
#include "trip_detector.h"

namespace valve {

enum class End : uint8_t { kUnknown, kOpen, kClosed };
enum class State : uint8_t { kIdle, kRunning, kBackoff, kFault };
enum class Outcome : uint8_t { kNone, kReached, kTimeout, kMotorFault, kAborted };

const char* name(End e);
const char* name(State s);
const char* name(Outcome o);

struct MoveReport {
  End target = End::kUnknown;
  Outcome outcome = Outcome::kNone;
  uint32_t duration_ms = 0;
  float running_a = 0;  // the mean current on the way
  float peak_a = 0;     // the highest, past the blanking
  float trip_a = 0;
};

class Controller {
 public:
  static constexpr uint32_t kBrakeMs = 50;        // braked before the driver sleeps
  static constexpr uint32_t kFaultGraceMs = 10;   // the motor's fault ignored after a start
  static constexpr uint32_t kFaultTicks = 3;      // readings in a row that make a fault
  static constexpr uint8_t kMaxRetries = 3;

  Controller(Motor& motor, const Settings& settings) : motor_(motor), s_(settings) {}

  // The end to go to; kUnknown holds still, stopping a move under way.  A change of mind during
  // a move stops it, and after the rest the motor sets off for the new end.
  void setDesired(End end) { desired_ = end; }

  // Forgets a failure, so the controller tries again at once.
  void clearFault() { clear_ = true; }

  // Runs the controller; call it about every millisecond.
  void tick(uint32_t now_ms);

  State state() const { return state_; }
  // The motor is running, toward an end or backing off one.
  bool moving() const { return state_ == State::kRunning || state_ == State::kBackoff; }
  End position() const { return position_; }
  // Where a move under way, or the latest, is going.
  End target() const { return target_; }
  bool awake() const { return awake_; }
  // The latest reading, and its low-passed value, while the motor runs.
  float amps() const { return amps_; }
  float filtered() const { return trip_.filtered(); }
  uint32_t elapsed(uint32_t now_ms) const { return now_ms - started_; }

  // The latest finished move; `moves()` counts them, so a change means a new report.
  const MoveReport& last() const { return last_; }
  uint32_t moves() const { return moves_; }
  uint8_t failures() const { return failures_; }

 private:
  void begin(uint32_t now, End target);
  void finish(uint32_t now, Outcome outcome);
  void stop(uint32_t now);
  void sleepAfterBrake(uint32_t now);
  bool faulted(uint32_t now);
  float ramped(uint32_t since) const;
  bool forward(End toward) const { return (toward == End::kOpen) != s_.motor_invert; }
  float tripAt(End end) const { return end == End::kOpen ? s_.trip_open : s_.trip_close; }
  uint32_t backoffAt(End end) const {
    return end == End::kOpen ? s_.backoff_open : s_.backoff_close;
  }

  Motor& motor_;
  const Settings& s_;
  TripDetector trip_;

  End desired_ = End::kUnknown;
  End position_ = End::kUnknown;
  End target_ = End::kUnknown;
  State state_ = State::kIdle;
  bool awake_ = false;
  bool stopped_ever_ = false;
  bool clear_ = false;
  // `stopped_` also marks when a backoff began and when a move failed; a failed move's end is
  // `target_`, until the next begins.
  uint32_t started_ = 0, stopped_ = 0;
  uint32_t fault_ticks_ = 0;
  uint8_t failures_ = 0;
  float amps_ = 0;

  MoveReport last_;
  uint32_t moves_ = 0;
};

}  // namespace valve
