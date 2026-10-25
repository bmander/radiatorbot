// A line-at-a-time command console on the USB serial port: `help` lists the commands.
#pragma once

#include <Arduino.h>

#include "app.h"

class Console {
 public:
  Console(App& app, Stream& io) : app_(app), io_(io) {}

  // Reads what has arrived, and runs each line as it completes.  Never blocks.
  void poll();

 private:
  void run(char* line);
  void help();
  void get(const char* name);
  void set(const char* name, const char* value);
  void go(valve::End end);

  App& app_;
  Stream& io_;
  char line_[96];
  size_t len_ = 0;
  int last_ = 0;
};
