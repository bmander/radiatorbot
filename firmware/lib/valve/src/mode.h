// Where the bot wants the valve: in auto, where the thermostat says; in manual, where the console
// last said, or nowhere (hold still).
#pragma once

#include <stdint.h>

#include "controller.h"
#include "thermostat.h"

namespace valve {

enum class Mode : uint8_t { kAuto, kManual };

// Calling for heat opens the valve, and the end of the call closes it.  Until the thermostat has
// settled, auto wants nothing.
inline End desiredEnd(Mode mode, End manual, const ThermostatInput& stat) {
  if (mode == Mode::kManual) return manual;
  if (!stat.known()) return End::kUnknown;
  return stat.calling() ? End::kOpen : End::kClosed;
}

}  // namespace valve
