#include "settings.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

namespace valve {

namespace {

#define FIELD(name, type, min, max, unit, help) \
  {#name, FieldType::type, offsetof(Settings, name), min, max, unit, help}

const Field kFields[] = {
    FIELD(trip_open, kFloat, 0.05f, 3.0f, "A", "current that marks the open end"),
    FIELD(trip_close, kFloat, 0.05f, 3.0f, "A", "current that marks the closed end (seats the valve)"),
    FIELD(hold, kUint, 1, 1000, "ms", "time over the trip before it counts"),
    FIELD(blank, kUint, 0, 2000, "ms", "time after a start that the trip ignores"),
    FIELD(filter, kUint, 0, 200, "ms", "the current's low-pass time constant"),
    FIELD(timeout, kUint, 1, 600, "s", "longest a move may take"),
    FIELD(duty, kFloat, 0.1f, 1.0f, "", "the motor's speed, 0-1 of motor_volts"),
    FIELD(motor_volts, kFloat, 1.0f, 24.0f, "V", "the motor's rating: the PWM gives it this"),
    FIELD(ramp, kUint, 0, 2000, "ms", "soft start"),
    FIELD(backoff_open, kUint, 0, 5000, "ms", "run back after reaching the open end"),
    FIELD(backoff_close, kUint, 0, 5000, "ms", "run back after reaching the closed end"),
    FIELD(rest, kUint, 0, 60000, "ms", "rest between moves"),
    FIELD(retry, kUint, 10, 86400, "s", "wait after a failed move before trying again"),
    FIELD(motor_invert, kBool, 0, 1, "", "swap the motor's directions"),
    FIELD(stat_invert, kBool, 0, 1, "", "the contact closed means no call for heat"),
    FIELD(stat_settle, kUint, 0, 600000, "ms", "time the thermostat must hold a state"),
};

#undef FIELD

template <class T>
T& at(Settings& s, const Field& f) {
  return *reinterpret_cast<T*>(reinterpret_cast<char*>(&s) + f.offset);
}
template <class T>
T at(const Settings& s, const Field& f) {
  return *reinterpret_cast<const T*>(reinterpret_cast<const char*>(&s) + f.offset);
}

}  // namespace

const Field* fields(size_t* count) {
  *count = sizeof(kFields) / sizeof(kFields[0]);
  return kFields;
}

const Field* findField(const char* name) {
  for (const Field& f : kFields) {
    if (strcmp(f.name, name) == 0) return &f;
  }
  return nullptr;
}

float& floatField(Settings& s, const Field& f) { return at<float>(s, f); }
uint32_t& uintField(Settings& s, const Field& f) { return at<uint32_t>(s, f); }
bool& boolField(Settings& s, const Field& f) { return at<bool>(s, f); }
float floatField(const Settings& s, const Field& f) { return at<float>(s, f); }
uint32_t uintField(const Settings& s, const Field& f) { return at<uint32_t>(s, f); }
bool boolField(const Settings& s, const Field& f) { return at<bool>(s, f); }

bool inRange(const Field& f, float v) { return v >= f.min && v <= f.max; }

bool setField(Settings& s, const Field& f, const char* text) {
  if (text == nullptr || *text == '\0') return false;
  char* end = nullptr;
  switch (f.type) {
    case FieldType::kFloat: {
      float v = strtof(text, &end);
      if (*end != '\0' || !inRange(f, v)) return false;
      floatField(s, f) = v;
      return true;
    }
    case FieldType::kUint: {
      if (*text == '-') return false;
      unsigned long v = strtoul(text, &end, 10);
      if (*end != '\0' || !inRange(f, v)) return false;
      uintField(s, f) = static_cast<uint32_t>(v);
      return true;
    }
    case FieldType::kBool: {
      if (strcmp(text, "1") == 0 || strcmp(text, "on") == 0 || strcmp(text, "true") == 0) {
        boolField(s, f) = true;
        return true;
      }
      if (strcmp(text, "0") == 0 || strcmp(text, "off") == 0 || strcmp(text, "false") == 0) {
        boolField(s, f) = false;
        return true;
      }
      return false;
    }
  }
  return false;
}

void formatField(const Settings& s, const Field& f, char* buf, size_t len) {
  switch (f.type) {
    case FieldType::kFloat:
      snprintf(buf, len, "%.6g", static_cast<double>(floatField(s, f)));
      break;
    case FieldType::kUint:
      snprintf(buf, len, "%lu", static_cast<unsigned long>(uintField(s, f)));
      break;
    case FieldType::kBool:
      snprintf(buf, len, "%d", boolField(s, f) ? 1 : 0);
      break;
  }
}

}  // namespace valve
