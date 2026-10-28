// The bot's state, shared by the control loop and the consoles.
//
// The control loop runs in a task of its own (main.cpp), so nothing on the network can hold up a
// move.  Everything else that touches the app, the consoles and the web page, holds `AppLock`
// while it does, and writes only to its own buffers under it.
#pragma once

#include <stdint.h>

#include "controller.h"
#include "mode.h"
#include "settings.h"
#include "tb6612.h"
#include "thermostat.h"

#define RADIATORBOT_VERSION "0.3.0"

struct App {
  valve::Settings settings;
  Tb6612 motor{settings};
  valve::ThermostatInput stat{settings};
  valve::Controller ctl{motor, settings};

  valve::Mode mode = valve::Mode::kAuto;
  valve::End manual = valve::End::kUnknown;  // where manual mode goes; kUnknown holds
  uint32_t trace_ms = 0;  // how often to print the current during a move; 0, never
};

// Holds the app for as long as it lives (main.cpp).
class AppLock {
 public:
  AppLock();
  ~AppLock();
  AppLock(const AppLock&) = delete;
  AppLock& operator=(const AppLock&) = delete;
};
