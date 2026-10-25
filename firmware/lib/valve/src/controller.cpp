#include "controller.h"

namespace valve {

const char* name(End e) {
  switch (e) {
    case End::kOpen: return "open";
    case End::kClosed: return "closed";
    default: return "unknown";
  }
}

const char* name(State s) {
  switch (s) {
    case State::kIdle: return "idle";
    case State::kRunning: return "running";
    case State::kBackoff: return "backing off";
    case State::kFault: return "failed";
  }
  return "?";
}

const char* name(Outcome o) {
  switch (o) {
    case Outcome::kReached: return "reached";
    case Outcome::kTimeout: return "timed out";
    case Outcome::kDriverFault: return "driver fault";
    case Outcome::kAborted: return "stopped";
    default: return "none";
  }
}

void Controller::tick(uint32_t now) {
  switch (state_) {
    case State::kIdle: {
      clear_ = false;
      if (awake_ && now - stopped_ >= kBrakeMs) {
        motor_.sleep();
        awake_ = false;
      }
      if (desired_ == End::kUnknown || desired_ == position_) return;
      if (stopped_ever_ && now - stopped_ < s_.rest) return;
      begin(now, desired_);
      return;
    }

    case State::kRunning: {
      amps_ = motor_.amps();
      if (faulted(now)) {
        finish(now, Outcome::kDriverFault);
      } else if (desired_ != target_) {
        finish(now, Outcome::kAborted);
      } else if (trip_.update(now, amps_)) {
        finish(now, Outcome::kReached);
      } else if (now - started_ >= s_.timeout * 1000) {
        finish(now, Outcome::kTimeout);
      } else {
        motor_.drive(forward(target_), ramped(now - started_));
      }
      return;
    }

    case State::kBackoff: {
      amps_ = motor_.amps();
      uint32_t backoff = target_ == End::kOpen ? s_.backoff_open : s_.backoff_close;
      if (faulted(now) || desired_ != target_ || now - backoff_from_ >= backoff) {
        stop(now);
        state_ = State::kIdle;
      } else {
        motor_.drive(!forward(target_), ramped(now - backoff_from_));
      }
      return;
    }

    case State::kFault: {
      if (awake_ && now - stopped_ >= kBrakeMs) {
        motor_.sleep();
        awake_ = false;
      }
      bool fresh = clear_ || desired_ != failed_target_;
      bool retry = failures_ <= kMaxRetries && now - failed_at_ >= s_.retry * 1000;
      clear_ = false;
      if (fresh) failures_ = 0;
      if (fresh || retry) state_ = State::kIdle;
      return;
    }
  }
}

void Controller::begin(uint32_t now, End target) {
  if (!awake_) {
    motor_.wake();
    awake_ = true;
  }
  target_ = target;
  position_ = End::kUnknown;
  started_ = now;
  fault_ticks_ = 0;
  amps_ = 0;
  float trip = target == End::kOpen ? s_.trip_open : s_.trip_close;
  trip_.start(now, trip, s_.blank, s_.hold, s_.filter);
  last_trip_ = trip;
  state_ = State::kRunning;
  motor_.drive(forward(target_), ramped(0));
}

void Controller::finish(uint32_t now, Outcome outcome) {
  stop(now);
  last_.target = target_;
  last_.outcome = outcome;
  last_.duration_ms = now - started_;
  last_.running_a = trip_.running();
  last_.peak_a = trip_.peak();
  last_.trip_a = last_trip_;
  moves_++;

  switch (outcome) {
    case Outcome::kReached: {
      position_ = target_;
      failures_ = 0;
      uint32_t backoff = target_ == End::kOpen ? s_.backoff_open : s_.backoff_close;
      if (backoff > 0 && desired_ == target_) {
        backoff_from_ = now;
        state_ = State::kBackoff;
      } else {
        state_ = State::kIdle;
      }
      break;
    }
    case Outcome::kAborted:
      position_ = End::kUnknown;
      state_ = State::kIdle;
      break;
    default:
      position_ = End::kUnknown;
      if (failures_ < 255) failures_++;
      failed_at_ = now;
      failed_target_ = target_;
      state_ = State::kFault;
      break;
  }
}

void Controller::stop(uint32_t now) {
  motor_.brake();
  stopped_ = now;
  stopped_ever_ = true;
}

bool Controller::faulted(uint32_t now) {
  if (now - started_ < kFaultGraceMs || !motor_.fault()) {
    fault_ticks_ = 0;
    return false;
  }
  return ++fault_ticks_ >= kFaultTicks;
}

float Controller::ramped(uint32_t since) const {
  if (since >= s_.ramp) return s_.duty;
  return s_.duty * static_cast<float>(since) / static_cast<float>(s_.ramp);
}

}  // namespace valve
