// The Adafruit DRV8871 breakout, its two inputs PWM'd at 20 kHz, and the INA219 in its supply,
// which says the motor's current.
//
// The DRV8871 drives one way with IN1 high and IN2 low, the other with them swapped; both high
// brake, and both low coast and sleep the chip after 1 ms.  It has no current output or fault pin.
// To drive, one input is held high and the other is pulled low for the PWM's on-time, so the
// bridge brakes through the off-time (slow decay): the motor's current runs on through the brake,
// and the supply carries it only while the bridge drives.  The INA219 reads the supply's current
// averaged over ten periods, about the PWM's fraction times the motor's, so the motor's current is
// the supply's over that fraction.
#pragma once

#include <pwm.h>

#include "ina219.h"
#include "motor.h"
#include "settings.h"

class Drv8871 : public valve::Motor {
 public:
  static constexpr float kPwmHz = 20000;     // above hearing
  static constexpr float kMinVolts = 6.5f;   // the DRV8871 locks out below about 6.4 V
  static constexpr float kMinPwm = 0.02f;    // under this the motor's current isn't worked out

  explicit Drv8871(const valve::Settings& s);

  // Sets the pins up with the driver asleep, and the INA219 converting.  Call it first thing.
  void begin();

  void wake() override;
  void drive(bool forward, float duty) override;
  void brake() override;
  void sleep() override;
  bool fault() override;
  float amps() override;

  // Reads the supply afresh, for the console.
  void refresh();
  // The INA219 answered the latest reading.
  bool monitor_ok() const { return ok_; }
  // The supply's voltage and current at the latest reading.
  float supply_volts() const { return volts_; }
  float supply_amps() const { return supply_amps_; }
  // The fraction of each PWM period the bridge drives.
  float pwm() const { return pwm_; }

 private:
  void set(float in1, float in2);

  const valve::Settings& s_;
  PwmOut in1_, in2_;
  Ina219 monitor_;
  bool ok_ = false;
  float volts_ = 0, supply_amps_ = 0, pwm_ = 0;
};
