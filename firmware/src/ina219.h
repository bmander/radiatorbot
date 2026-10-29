// The Adafruit INA219 breakout in the driver's supply, on the high side: the supply's current
// across its 0.1 Ohm shunt and its voltage, over I2C.
#pragma once

#include <stdint.h>

class Ina219 {
 public:
  static constexpr float kShuntOhms = 0.1f;

  explicit Ina219(uint8_t address) : address_(address) {}

  // Starts I2C on `sda` and `scl` and sets the chip converting: +-320 mV across the shunt
  // (+-3.2 A), 32 V on the bus, each 12 bits in 532 us, continuously.  False if it doesn't answer.
  bool begin(int sda, int scl);

  // The latest conversions.  False, leaving `out` alone, if the chip doesn't answer.
  bool amps(float& out);
  bool volts(float& out);

 private:
  bool read(uint8_t reg, uint16_t& out);
  bool write(uint8_t reg, uint16_t value);

  uint8_t address_;
  uint8_t pointer_ = 0xFF;  // the register the chip's pointer is on; reading it again needs no write
};
