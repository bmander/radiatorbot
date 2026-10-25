#include "thermostat.h"

namespace valve {

void ThermostatInput::update(uint32_t now_ms, bool low) {
  if (!started_) {
    started_ = true;
    start_ = now_ms;
    candidate_since_ = now_ms;
  }
  if (low) {
    seen_low_ = true;
    last_low_ = now_ms;
  }
  // Until a whole presence window has passed, a pulsing input may not have pulsed yet.
  if (now_ms - start_ < kPresenceMs && !seen_low_) return;

  bool present = seen_low_ && now_ms - last_low_ < kPresenceMs;
  bool calling = present != s_.stat_invert;
  if (calling != candidate_) {
    candidate_ = calling;
    candidate_since_ = now_ms;
  }
  if (now_ms - candidate_since_ >= s_.stat_settle) {
    known_ = true;
    calling_ = candidate_;
  }
}

}  // namespace valve
