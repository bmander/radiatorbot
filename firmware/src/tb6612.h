// The Adafruit TB6612 breakout, its two H-bridges in parallel on one motor, its PWM input at
// 20 kHz, and the INA219 in its supply, which says the motor's current.
//
// The TB6612 is two bridges of 1.2 A each.  The 130 stalls at 1.2 A at 9 V, and every move ends
// in a stall, so the shield ties the bridges together, AIN1 to BIN1, AIN2 to BIN2, PWMA to PWMB and
// each output to its twin: one bridge of twice the current, driven by three pins.
//
// IN1 high and IN2 low drives one way with PWM high, the other way with them swapped; PWM low, or
// both inputs high, short-brakes the motor; both low lets it coast.  STBY low puts the chip to
// sleep, its outputs off.  It has no current limit and no current output.  To drive, the
// direction is held on the inputs and the PWM input pulled low for the off-time, so the bridge
// brakes through it (slow decay): the motor's current runs on through the brake, and the supply
// carries it only while the bridge drives.  The INA219 reads the supply's current averaged over
// ten periods, about the PWM's fraction times the motor's, so the motor's current is the supply's
// over that fraction.
#pragma once

#include <stdint.h>

#include "ina219.h"
#include "motor.h"
#include "settings.h"

class Tb6612 : public valve::Motor {
 public:
  static constexpr uint32_t kPwmHz = 20000;  // above hearing
  static constexpr uint8_t kPwmBits = 10;    // 80 MHz / 20 kHz leaves 12; 10 is plenty
  static constexpr float kMinVolts = 6.5f;   // under this the adapter's unplugged or failing
  static constexpr float kMaxVolts = 13.5f;  // the TB6612's motor supply, at most
  static constexpr float kMinPwm = 0.02f;    // under this the motor's current isn't worked out
  static constexpr uint32_t kVoltsMs = 20;   // how often a move reads the supply's voltage

  explicit Tb6612(const valve::Settings& s);

  // Sets the pins up with the driver asleep, and the INA219 converting.  Call it first thing.
  void begin();

  void wake() override;
  void drive(bool forward, float duty) override;
  void brake() override;
  void sleep() override;
  bool fault() override;
  float amps() override;

  // Reads the supply's current and voltage afresh.
  void refresh();
  // The INA219 answered the latest reading.
  bool monitor_ok() const { return ok_; }
  // The supply's voltage and current at the latest reading.
  float supply_volts() const { return volts_; }
  float supply_amps() const { return supply_amps_; }
  // The fraction of each PWM period the bridge drives.
  float pwm() const { return pwm_; }

 private:
  void set(bool in1, bool in2, float pwm);

  const valve::Settings& s_;
  Ina219 monitor_;
  bool ok_ = false;
  float volts_ = 0, supply_amps_ = 0, pwm_ = 0;
  uint32_t volts_at_ = 0;
  // the pins as last written: both inputs low and the PWM off, as begin() leaves them
  bool in1_ = false, in2_ = false;
  uint32_t pwm_set_ = 0;
};
