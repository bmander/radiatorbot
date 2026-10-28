#include "ina219.h"

#include <Arduino.h>
#include <Wire.h>

namespace {
constexpr uint8_t kConfig = 0x00;
constexpr uint8_t kShunt = 0x01;
constexpr uint8_t kBus = 0x02;

// BRNG 32 V, PGA /8 (+-320 mV), BADC and SADC 12 bits (532 us), shunt and bus continuous.  It's
// also the chip's power-on value; it's written so a stray reset can't leave it otherwise.
constexpr uint16_t kConfigValue = 0x399F;

constexpr float kShuntLsb = 10e-6f;  // V a count, the shunt register's
constexpr float kBusLsb = 4e-3f;     // V a count, the bus register's, above its three flag bits
}  // namespace

bool Ina219::begin(int sda, int scl) {
  Wire.begin(sda, scl, 400000);
  Wire.setTimeOut(2);  // ms: a wedged bus never holds up the loop for long
  return write(kConfig, kConfigValue);
}

bool Ina219::amps(float& out) {
  uint16_t raw = 0;
  if (!read(kShunt, raw)) return false;
  out = static_cast<int16_t>(raw) * kShuntLsb / kShuntOhms;
  return true;
}

bool Ina219::volts(float& out) {
  uint16_t raw = 0;
  if (!read(kBus, raw)) return false;
  out = (raw >> 3) * kBusLsb;
  return true;
}

bool Ina219::read(uint8_t reg, uint16_t& out) {
  if (pointer_ != reg) {
    Wire.beginTransmission(address_);
    Wire.write(reg);
    pointer_ = Wire.endTransmission() == 0 ? reg : 0xFF;
    if (pointer_ != reg) return false;
  }
  if (Wire.requestFrom(address_, static_cast<size_t>(2)) != 2) {
    pointer_ = 0xFF;
    return false;
  }
  uint8_t hi = Wire.read();
  uint8_t lo = Wire.read();
  out = static_cast<uint16_t>(hi << 8 | lo);
  return true;
}

bool Ina219::write(uint8_t reg, uint16_t value) {
  Wire.beginTransmission(address_);
  Wire.write(reg);
  Wire.write(static_cast<uint8_t>(value >> 8));
  Wire.write(static_cast<uint8_t>(value & 0xFF));
  pointer_ = Wire.endTransmission() == 0 ? reg : 0xFF;
  return pointer_ == reg;
}
