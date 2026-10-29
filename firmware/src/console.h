// The console: a command a line (`help` lists them), and a log of what the bot does as it does it.
// One runs on the USB serial port, one for a telnet client, and one for the web page's commands
// (remote.h).  Each is called holding the app's lock.
#pragma once

#include <Arduino.h>

#include "app.h"
#include "port.h"

class Console {
 public:
  Console(App& app, Port& io) : app_(app), io_(io) {}

  // Reads what has arrived, and runs each line as it completes.  Never blocks.
  void poll();
  // Logs what changed in the last tick: the thermostat, a move's start and end, a failure, the
  // trace, and the Wi-Fi link.
  void report(uint32_t now);
  // Runs one line, as if it had been typed.
  void exec(const char* line);

 private:
  void run(char* line);
  void wifiCommand(char* rest);
  void help();
  void status();
  void get(const char* name);
  void printField(const valve::Field& f);
  void set(const char* name, const char* value);
  void go(valve::End end);
  void printMove(const valve::MoveReport& m);
  const char* statName() const;

  App& app_;
  Port& io_;
  char line_[96];
  size_t len_ = 0;
  int last_ = 0;

  // What `report` last saw.
  bool stat_known_ = false, stat_calling_ = false;
  bool linked_ = false, setup_ = false;
  valve::State state_ = valve::State::kIdle;
  uint32_t moves_ = 0, traced_ = 0;
};
