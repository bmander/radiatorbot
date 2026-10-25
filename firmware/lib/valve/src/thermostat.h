// The thermostat's call for heat: a dry contact (an old mercury-switch thermostat's, say) between
// the input and ground, the input pulled up.  The contact closed pulls it low.
//
// The bot acts on a state only once it has held for `stat_settle` milliseconds, so a thermostat's
// chatter, or a bounce as the mercury rolls, doesn't run the motor; `stat_invert` flips its sense.
#pragma once

#include <stdint.h>

#include "settings.h"

namespace valve {

class ThermostatInput {
 public:
  explicit ThermostatInput(const Settings& settings) : s_(settings) {}

  // `closed`: the contact is closed, the input reading low.
  void update(uint32_t now_ms, bool closed);

  // A state has held for the settling time since start-up.
  bool known() const { return known_; }
  // The settled state: the thermostat calls for heat.
  bool calling() const { return calling_; }

 private:
  const Settings& s_;
  bool started_ = false;
  bool candidate_ = false;
  uint32_t candidate_since_ = 0;
  bool known_ = false, calling_ = false;
};

}  // namespace valve
