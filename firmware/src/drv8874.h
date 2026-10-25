// The Pololu DRV8874 carrier in PH/EN mode (PMODE tied to GND), and its current output read by
// the C3's ADC.
#pragma once

#include "motor.h"
#include "settings.h"

class Drv8874 : public valve::Motor {
 public:
  static constexpr uint32_t kPwmHz = 20000;  // above hearing
  static constexpr uint8_t kPwmBits = 10;
  static constexpr int kSamples = 8;         // ADC readings averaged a reading: the PWM ripples
  static constexpr float kMaxOffsetMv = 150;

  explicit Drv8874(const valve::Settings& s) : s_(s) {}

  // Sets the pins up with the driver asleep.  Call it first thing.
  void begin();

  void wake() override;
  void drive(bool forward, float duty) override;
  void brake() override;
  void sleep() override;
  bool fault() override;
  float amps() override;

  // The CS reading with no current, taken at each wake and taken off every reading.
  float offset_mv() const { return offset_mv_; }
  // The CS pin's voltage, averaged over `n` readings.
  float read_mv(int n);

 private:
  const valve::Settings& s_;
  float offset_mv_ = 0;
};
