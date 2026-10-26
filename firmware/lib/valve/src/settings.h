// The bot's tunable figures, with their defaults, and a table of them for the console and for
// storing them in flash.
#pragma once

#include <stddef.h>
#include <stdint.h>

namespace valve {

struct Settings {
  // End of travel: the motor's current crossing the trip, held, marks an end of the stem's screw.
  // The current is the motor's, worked out from the supply's (see `motor_volts`).
  float trip_open = 1.0f;     // A, at the open end (the stem's backseat)
  float trip_close = 1.0f;    // A, at the closed end: what seats the valve
  uint32_t hold = 50;         // ms the current must stay over the trip
  uint32_t blank = 150;       // ms after a start that the trip ignores (the inrush is near stall)
  uint32_t filter = 10;       // ms, the current's low-pass time constant (the PWM's ripple)
  uint32_t timeout = 60;      // s a move may take before it's given up as a failure

  // The drive.  The PWM is scaled to the supply, so the motor sees `motor_volts` on average at
  // full `duty` whatever the wall adapter gives.
  float duty = 1.0f;          // the motor's speed, 0-1 of `motor_volts`
  float motor_volts = 6.0f;   // V, the motor's rating: the 130's 6 V
  uint32_t ramp = 80;         // ms to ramp the duty up from 0 at a start
  uint32_t backoff_open = 0;  // ms to run back after reaching the open end, easing the train
  uint32_t backoff_close = 0; // ms to run back after reaching the closed end
  uint32_t rest = 500;        // ms the motor rests between moves
  uint32_t retry = 900;       // s after a failed move before trying again
  bool motor_invert = false;  // swap the motor's directions: set it if "open" closes the valve

  // The thermostat.
  bool stat_invert = false;   // the contact closed means *no* call for heat
  uint32_t stat_settle = 3000;  // ms the thermostat must hold a state before the bot acts on it
};

enum class FieldType : uint8_t { kFloat, kUint, kBool };

struct Field {
  const char* name;           // also its key in flash: at most 15 characters
  FieldType type;
  size_t offset;
  float min, max;
  const char* unit;
  const char* help;
};

// Every field, in the order the console lists them.
const Field* fields(size_t* count);
const Field* findField(const char* name);

// Parses `text` into the field. False, leaving it unchanged, if it's malformed or out of range.
bool setField(Settings& s, const Field& f, const char* text);
// `v` lies in the field's range.
bool inRange(const Field& f, float v);
// The field's value as text, without its unit.
void formatField(const Settings& s, const Field& f, char* buf, size_t len);

// The field's value, by its type.
float& floatField(Settings& s, const Field& f);
uint32_t& uintField(Settings& s, const Field& f);
bool& boolField(Settings& s, const Field& f);
float floatField(const Settings& s, const Field& f);
uint32_t uintField(const Settings& s, const Field& f);
bool boolField(const Settings& s, const Field& f);

}  // namespace valve
