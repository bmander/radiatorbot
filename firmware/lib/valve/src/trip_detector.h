// End of travel from the motor's current: past the start's blanking, the current, low-passed,
// held over the trip for `hold` milliseconds.
//
// Breaking away: a valve left at an end, seated or backseated, takes more than the trip to start
// (its seat's friction on top of the torque that seated it), so until the motor gets going (the
// current falls under the trip) the trip waits, up to `breakaway` milliseconds from the start, and
// the motor may pull up to its stall to break the valve free.  Once going, the trip is the trip.
// A start that never gets going trips once the breakaway's over: `moved()` tells it apart.
#pragma once

#include <stdint.h>

namespace valve {

class TripDetector {
 public:
  void start(uint32_t now_ms, float trip_a, uint32_t blank_ms, uint32_t hold_ms,
             uint32_t filter_ms, uint32_t breakaway_ms = 0);

  // Feeds a reading; true once the trip has held.
  bool update(uint32_t now_ms, float amps);

  float trip() const { return trip_; }
  // The motor got going: the current fell under the trip past the blanking.
  bool moved() const { return moved_; }
  float filtered() const { return filtered_; }
  // The highest filtered current past the blanking.
  float peak() const { return peak_; }
  // The mean filtered current past the blanking and under the trip: the running current.
  float running() const { return running_n_ ? running_sum_ / running_n_ : 0.0f; }

 private:
  float trip_ = 0;
  uint32_t start_ = 0, last_ = 0, blank_ = 0, hold_ = 0, filter_ = 0, breakaway_ = 0;
  bool first_ = true;
  bool moved_ = false;
  bool above_ = false;
  uint32_t above_since_ = 0;  // when the current last rose over the trip
  float filtered_ = 0, peak_ = 0;
  float running_sum_ = 0;
  uint32_t running_n_ = 0;
};

}  // namespace valve
