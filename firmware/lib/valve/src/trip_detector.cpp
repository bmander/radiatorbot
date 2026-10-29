#include "trip_detector.h"

namespace valve {

void TripDetector::start(uint32_t now_ms, float trip_a, uint32_t blank_ms, uint32_t hold_ms,
                         uint32_t filter_ms, uint32_t breakaway_ms) {
  trip_ = trip_a;
  start_ = last_ = now_ms;
  blank_ = blank_ms;
  hold_ = hold_ms;
  filter_ = filter_ms;
  breakaway_ = breakaway_ms;
  first_ = true;
  moved_ = false;
  above_ = false;
  filtered_ = peak_ = running_sum_ = 0;
  running_n_ = 0;
}

bool TripDetector::update(uint32_t now_ms, float amps) {
  // First-order low-pass, exact for any step between readings.
  uint32_t dt = now_ms - last_;
  last_ = now_ms;
  if (first_ || filter_ == 0) {
    filtered_ = amps;
    first_ = false;
  } else {
    float a = static_cast<float>(dt) / static_cast<float>(filter_ + dt);
    filtered_ += a * (amps - filtered_);
  }

  if (now_ms - start_ < blank_) return false;

  if (filtered_ > peak_) peak_ = filtered_;
  if (filtered_ < trip_) {
    moved_ = true;
    above_ = false;
    running_sum_ += filtered_;
    running_n_++;
    return false;
  }
  if (!moved_ && now_ms - start_ < breakaway_) return false;  // breaking away: the hold waits
  if (!above_) {
    above_ = true;
    above_since_ = now_ms;
  }
  return now_ms - above_since_ >= hold_;
}

}  // namespace valve
