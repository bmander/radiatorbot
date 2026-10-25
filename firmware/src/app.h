// The bot's state, shared by the control loop and the console.
#pragma once

#include <stdint.h>

#include "controller.h"
#include "drv8874.h"
#include "mode.h"
#include "settings.h"
#include "thermostat.h"

#define RADIATORBOT_VERSION "0.1.0"

struct App {
  valve::Settings settings;
  Drv8874 motor{settings};
  valve::ThermostatInput stat{settings};
  valve::Controller ctl{motor, settings};

  valve::Mode mode = valve::Mode::kAuto;
  valve::End manual = valve::End::kUnknown;  // where manual mode goes; kUnknown holds
  uint32_t trace_ms = 0;  // how often to print the current during a move; 0, never
};
