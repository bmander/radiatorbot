// The thermostat's call for heat, read through the optocoupler on a pulled-up input.
//
// Driven from 24 VAC, the optocoupler conducts only on its half-cycles, so the input pulses low
// at the mains frequency; driven from DC or a dry contact, it holds low.  Either way the input
// counts as low if it was low at any time in the last `kPresenceMs`.  The bot then acts on a state
// only once it has held for `stat_settle` milliseconds, so a thermostat's chatter doesn't run the
// motor; `stat_invert` flips its sense.
#pragma once

#include <stdint.h>

#include "settings.h"

namespace valve {

class ThermostatInput {
 public:
  static constexpr uint32_t kPresenceMs = 60;  // three cycles of 50 Hz

  explicit ThermostatInput(const Settings& settings) : s_(settings) {}

  // `low`: the input reads low, the optocoupler conducting.
  void update(uint32_t now_ms, bool low);

  // A state has held for the settling time since start-up.
  bool known() const { return known_; }
  // The settled state: the thermostat calls for heat.
  bool calling() const { return calling_; }

 private:
  const Settings& s_;
  bool started_ = false, seen_low_ = false;
  uint32_t start_ = 0, last_low_ = 0;
  bool candidate_ = false;
  uint32_t candidate_since_ = 0;
  bool known_ = false, calling_ = false;
};

}  // namespace valve
