// The bot's state, shared by the control loop and the console.
#pragma once

#include <stdint.h>

#include "controller.h"
#include "drv8874.h"
#include "settings.h"
#include "thermostat.h"

#define RADIATORBOT_VERSION "0.1.0"

// Auto follows the thermostat; manual goes where the console last said, or holds still.
enum class Mode : uint8_t { kAuto, kManual };

struct App {
  valve::Settings settings;
  Drv8874 motor{settings};
  valve::ThermostatInput stat;
  valve::Controller ctl{motor, settings};

  Mode mode = Mode::kAuto;
  valve::End manual = valve::End::kUnknown;
  uint32_t trace_ms = 0;  // how often to print the current during a move; 0, never
};

// Prints the bot's state.
void printStatus(App& app);
