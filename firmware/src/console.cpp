#include "console.h"

#include <ctype.h>
#include <string.h>

#include "pins.h"
#include "storage.h"
#include "wlan.h"

using valve::End;
using valve::Mode;
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

void Console::exec(const char* line) {
  strncpy(line_, line, sizeof line_ - 1);
  line_[sizeof line_ - 1] = '\0';
  len_ = 0;
  run(line_);
}

void Console::run(char* line) {
  while (*line == ' ' || *line == '\t') line++;
  // `wifi` takes the rest of its line whole: a network's name, or its password, may have spaces
  if (strncmp(line, "wifi", 4) == 0 && (line[4] == '\0' || line[4] == ' ' || line[4] == '\t')) {
    wifiCommand(line + 4);
    return;
  }
  const char* cmd = strtok(line, " \t");
  const char* a = strtok(nullptr, " \t");
  const char* b = strtok(nullptr, " \t");
  if (cmd == nullptr) return;

  if (strcmp(cmd, "help") == 0 || strcmp(cmd, "?") == 0) {
    help();
  } else if (strcmp(cmd, "status") == 0 || strcmp(cmd, "s") == 0) {
    status();
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
    if (app_.ctl.moving()) {
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
      "  wifi            the network: how the link is doing\n"
      "  wifi ssid NAME  join the network NAME (kept through reboots)\n"
      "  wifi pass WORD  its password, and join it\n"
      "  wifi forget     leave the network, and forget it (the setup network opens)\n"
      "  wifi setup      open the setup network, radiatorbot-setup; `wifi setup off` closes it\n"
      "  reboot\n");
}

void Console::wifiCommand(char* rest) {
  while (*rest == ' ' || *rest == '\t') rest++;
  char* end = rest + strlen(rest);
  while (end > rest && isspace(static_cast<unsigned char>(end[-1]))) *--end = '\0';
  char* arg = rest;
  while (*arg != '\0' && *arg != ' ' && *arg != '\t') arg++;
  if (*arg != '\0') *arg++ = '\0';
  while (*arg == ' ' || *arg == '\t') arg++;

  if (*rest == '\0') {
    // just the link, below
  } else if (strcmp(rest, "ssid") == 0) {
    if (!wifi::setSsid(arg)) {
      io_.println("wifi ssid NAME: the network's name, 1 to 32 characters");
      return;
    }
  } else if (strcmp(rest, "pass") == 0) {
    if (!wifi::setPass(arg)) {
      io_.println("wifi pass PASSWORD: 8 to 63 characters, or none for an open network");
      return;
    }
  } else if (strcmp(rest, "forget") == 0) {
    wifi::forget();
  } else if (strcmp(rest, "setup") == 0 && *arg == '\0') {
    wifi::openSetup();
  } else if (strcmp(rest, "setup") == 0 && strcmp(arg, "off") == 0) {
    wifi::closeSetup();
  } else {
    io_.println("wifi [ssid NAME | pass PASSWORD | forget | setup [off]]");
    return;
  }
  io_.print("wifi: ");
  wifi::describe(io_);
  io_.println();
}

void Console::get(const char* name) {
  if (name != nullptr) {
    const valve::Field* f = valve::findField(name);
    if (f != nullptr) {
      printField(*f);
    } else {
      io_.printf("no setting `%s`\n", name);
    }
    return;
  }
  size_t n = 0;
  const valve::Field* fs = valve::fields(&n);
  for (size_t i = 0; i < n; i++) printField(fs[i]);
}

void Console::printField(const valve::Field& f) {
  char buf[24];
  valve::formatField(app_.settings, f, buf, sizeof buf);
  io_.printf("  %-14s %8s %-4s %s\n", f.name, buf, f.unit, f.help);
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
  printField(*f);
}

void Console::go(End end) {
  app_.mode = Mode::kManual;
  app_.manual = end;
  app_.ctl.clearFault();
  if (end == End::kUnknown) {
    io_.println("holding; `auto` follows the thermostat again");
  } else {
    io_.printf("going %s; `auto` follows the thermostat again\n", valve::name(end));
  }
}

const char* Console::statName() const {
  if (!app_.stat.known()) return "not settled yet";
  return app_.stat.calling() ? "calling for heat" : "not calling";
}

void Console::printMove(const valve::MoveReport& m) {
  io_.printf("%s: %s in %.1f s; running %.2f A, peak %.2f A, trip %.2f A\n",
             m.target == End::kOpen ? "open" : "close", valve::name(m.outcome),
             m.duration_ms / 1000.0, m.running_a, m.peak_a, m.trip_a);
}

void Console::status() {
  const valve::Controller& c = app_.ctl;
  io_.printf("radiatorbot " RADIATORBOT_VERSION ", up %lu s\n",
             static_cast<unsigned long>(millis() / 1000));
  io_.printf("  mode        %s", app_.mode == Mode::kAuto ? "auto" : "manual");
  if (app_.mode == Mode::kManual) {
    io_.printf(" (%s)", app_.manual == End::kUnknown ? "hold" : valve::name(app_.manual));
  }
  io_.printf("\n  thermostat  %s (contact %s)\n", statName(),
             digitalRead(pins::kThermostat) == LOW ? "closed" : "open");
  io_.printf("  valve       %s\n", valve::name(c.position()));
  io_.printf("  motor       %s", valve::name(c.state()));
  if (c.state() == State::kRunning) io_.printf(" to %s", valve::name(c.target()));
  if (c.state() == State::kFault) io_.printf(" (%u in a row)", c.failures());
  io_.printf(", driver %s\n", c.awake() ? "awake" : "asleep");
  Tb6612& m = app_.motor;
  if (!c.moving()) m.refresh();  // while it runs, the loop reads it every tick
  if (!m.monitor_ok()) {
    io_.println("  supply      the INA219 doesn't answer: check its wiring (SDA A5, SCL A4)");
  } else {
    const char* why = "";
    if (m.supply_volts() < Tb6612::kMinVolts) why = ": too low to run the motor";
    if (m.supply_volts() > Tb6612::kMaxVolts) why = ": too high for the TB6612, 13.5 V at most";
    io_.printf("  supply      %.2f V, %.2f A%s\n", m.supply_volts(), m.supply_amps(), why);
  }
  if (c.moving()) {
    io_.printf("  current     %.2f A (%.2f A filtered) at %.0f%% PWM\n", c.amps(), c.filtered(),
               m.pwm() * 100);
  }
  if (c.moves() > 0) {
    io_.print("  last move   ");
    printMove(c.last());
  }
  io_.print("  wifi        ");
  wifi::describe(io_);
  io_.println();
}

void Console::report(uint32_t now) {
  const valve::ThermostatInput& stat = app_.stat;
  if (stat.known() && (!stat_known_ || stat.calling() != stat_calling_)) {
    stat_known_ = true;
    stat_calling_ = stat.calling();
    io_.printf("thermostat: %s\n", statName());
  }

  const valve::Controller& c = app_.ctl;
  if (c.moves() != moves_) {
    moves_ = c.moves();
    printMove(c.last());
  }
  if (c.state() != state_) {
    state_ = c.state();
    if (state_ == State::kRunning) {
      io_.println(c.target() == End::kOpen ? "opening" : "closing");
      traced_ = now;
    } else if (state_ == State::kFault) {
      io_.printf("move failed (%u in a row); `clear` tries again now\n", c.failures());
    }
  }
  if (wifi::connected() != linked_) {
    linked_ = !linked_;
    io_.print("wifi: ");
    if (linked_) {
      wifi::describe(io_);
      io_.println();
    } else {
      io_.println("link lost");
    }
  }
  if (wifi::inSetup() != setup_) {
    setup_ = !setup_;
    if (setup_) {
      io_.printf("wifi: setup network %s open: join it, and open http://%s/\n", wifi::kSetupSsid,
                 wifi::setupAddress().toString().c_str());
    } else {
      io_.println("wifi: setup network closed");
    }
  }
  if (app_.trace_ms && c.moving() && now - traced_ >= app_.trace_ms) {
    traced_ = now;
    io_.printf("  %7.3f s  %.2f A  (%.2f A filtered)\n", c.elapsed(now) / 1000.0, c.amps(),
               c.filtered());
  }
}
