#include "console.h"

#include <string.h>

#include "storage.h"

using valve::End;
using valve::State;

void Console::poll() {
  // Echoes as it reads, for terminals that don't.
  while (io_.available() > 0) {
    int c = io_.read();
    bool crlf = c == '\n' && last_ == '\r';
    last_ = c;
    if (c == '\r' || c == '\n') {
      if (crlf) continue;
      io_.write('\n');
      if (len_ == 0) continue;
      line_[len_] = '\0';
      len_ = 0;
      run(line_);
    } else if (c == '\b' || c == 0x7f) {
      if (len_ > 0) {
        len_--;
        io_.print("\b \b");
      }
    } else if (c >= ' ' && len_ < sizeof(line_) - 1) {
      line_[len_++] = static_cast<char>(c);
      io_.write(static_cast<uint8_t>(c));
    }
  }
}

void Console::run(char* line) {
  const char* cmd = strtok(line, " \t");
  const char* a = strtok(nullptr, " \t");
  const char* b = strtok(nullptr, " \t");
  if (cmd == nullptr) return;

  if (strcmp(cmd, "help") == 0 || strcmp(cmd, "?") == 0) {
    help();
  } else if (strcmp(cmd, "status") == 0 || strcmp(cmd, "s") == 0) {
    printStatus(app_);
  } else if (strcmp(cmd, "open") == 0) {
    go(End::kOpen);
  } else if (strcmp(cmd, "close") == 0) {
    go(End::kClosed);
  } else if (strcmp(cmd, "stop") == 0) {
    go(End::kUnknown);
  } else if (strcmp(cmd, "auto") == 0) {
    app_.mode = Mode::kAuto;
    io_.println("following the thermostat");
  } else if (strcmp(cmd, "clear") == 0) {
    app_.ctl.clearFault();
    io_.println("failure cleared");
  } else if (strcmp(cmd, "get") == 0) {
    get(a);
  } else if (strcmp(cmd, "set") == 0) {
    set(a, b);
  } else if (strcmp(cmd, "save") == 0) {
    if (app_.ctl.state() == State::kRunning || app_.ctl.state() == State::kBackoff) {
      io_.println("not while the motor runs");
    } else {
      io_.println(storage::save(app_.settings) ? "saved" : "save failed");
    }
  } else if (strcmp(cmd, "defaults") == 0) {
    app_.settings = valve::Settings();
    io_.println("settings back to their defaults, not saved: `save` keeps them, `reboot` drops them");
  } else if (strcmp(cmd, "trace") == 0) {
    if (a == nullptr || strcmp(a, "off") == 0) {
      app_.trace_ms = 0;
    } else {
      long ms = atol(a);
      app_.trace_ms = ms > 0 ? static_cast<uint32_t>(ms) : 0;
    }
    if (app_.trace_ms) {
      io_.printf("tracing the current every %lu ms during moves\n",
                 static_cast<unsigned long>(app_.trace_ms));
    } else {
      io_.println("trace off");
    }
  } else if (strcmp(cmd, "reboot") == 0) {
    io_.println("rebooting");
    io_.flush();
    ESP.restart();
  } else {
    io_.printf("unknown command `%s`; `help` lists them\n", cmd);
  }
}

void Console::help() {
  io_.print(
      "commands:\n"
      "  status          the valve, the thermostat, the motor and the last move\n"
      "  open | close    drive the valve to that end, ignoring the thermostat\n"
      "  stop            stop the motor and hold, ignoring the thermostat\n"
      "  auto            follow the thermostat again (the mode at power-up)\n"
      "  clear           forget a failed move and try again now\n"
      "  get [name]      list the settings, or one\n"
      "  set name value  change a setting now (until `save`, it lasts to the next reboot)\n"
      "  save            keep the settings through reboots\n"
      "  defaults        put every setting back to its default\n"
      "  trace ms|off    print the current every `ms` during moves\n"
      "  reboot\n");
}

void Console::get(const char* name) {
  size_t n = 0;
  const valve::Field* fs = valve::fields(&n);
  char buf[24];
  for (size_t i = 0; i < n; i++) {
    const valve::Field& f = fs[i];
    if (name != nullptr && strcmp(name, f.name) != 0) continue;
    valve::formatField(app_.settings, f, buf, sizeof buf);
    io_.printf("  %-14s %8s %-4s %s\n", f.name, buf, f.unit, f.help);
    if (name != nullptr) return;
  }
  if (name != nullptr) io_.printf("no setting `%s`\n", name);
}

void Console::set(const char* name, const char* value) {
  if (name == nullptr || value == nullptr) {
    io_.println("set name value");
    return;
  }
  const valve::Field* f = valve::findField(name);
  if (f == nullptr) {
    io_.printf("no setting `%s`; `get` lists them\n", name);
    return;
  }
  if (!valve::setField(app_.settings, *f, value)) {
    io_.printf("`%s` won't do for %s: it takes %g to %g %s\n", value, name,
               static_cast<double>(f->min), static_cast<double>(f->max), f->unit);
    return;
  }
  get(name);
}

void Console::go(End end) {
  app_.mode = Mode::kManual;
  app_.manual = end;
  app_.ctl.clearFault();
  if (end == End::kUnknown) {
    io_.println("holding; `auto` follows the thermostat again");
  } else {
    io_.printf("going %s; `auto` follows the thermostat again\n",
               end == End::kOpen ? "open" : "closed");
  }
}
