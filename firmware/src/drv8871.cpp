#include "drv8871.h"

#include <Arduino.h>

#include "pins.h"

Drv8871::Drv8871(const valve::Settings& s)
    : s_(s), in1_(pins::kIn1), in2_(pins::kIn2), monitor_(pins::kMonitorAddress) {}

void Drv8871::begin() {
  // Both inputs low: the chip's own pull-downs have held them so through the reset.
  in1_.begin(kPwmHz, 0.0f);
  in2_.begin(kPwmHz, 0.0f);
  monitor_.begin();
  refresh();
}

void Drv8871::wake() {
  brake();
  delay(1);  // the chip wakes in well under a millisecond
  refresh();
}

void Drv8871::drive(bool forward, float duty) {
  if (duty < 0) duty = 0;
  if (duty > 1) duty = 1;
  // the motor's share of the supply: `motor_volts` on average at full duty
  float pwm = duty;
  if (volts_ > s_.motor_volts) pwm = duty * s_.motor_volts / volts_;
  pwm_ = pwm;
  // the held input high, the other low for the on-time
  float pulled = (1 - pwm) * 100;
  if (forward) {
    set(100, pulled);
  } else {
    set(pulled, 100);
  }
}

void Drv8871::brake() {
  pwm_ = 0;
  set(100, 100);
}

void Drv8871::sleep() {
  pwm_ = 0;
  set(0, 0);
}

bool Drv8871::fault() { return !ok_ || volts_ < kMinVolts; }

float Drv8871::amps() {
  // the current every tick; the supply's voltage, which moves slowly, every kVoltsMs
  if (millis() - volts_at_ >= kVoltsMs) {
    refresh();
  } else {
    ok_ = monitor_.amps(supply_amps_);
  }
  if (!ok_ || pwm_ < kMinPwm || supply_amps_ <= 0) return 0;
  return supply_amps_ / pwm_;
}

void Drv8871::refresh() {
  ok_ = monitor_.amps(supply_amps_) && monitor_.volts(volts_);
  volts_at_ = millis();
}

void Drv8871::set(float in1, float in2) {
  // only what changed: through a move the held input stays put, and the other mostly does
  if (in1 != in1_set_) in1_.pulse_perc(in1_set_ = in1);
  if (in2 != in2_set_) in2_.pulse_perc(in2_set_ = in2);
}
