#include "tb6612.h"

#include <Arduino.h>

#include "pins.h"

Tb6612::Tb6612(const valve::Settings& s) : s_(s), monitor_(pins::kMonitorAddress) {}

void Tb6612::begin() {
  // Asleep, both inputs low and the PWM off.  Through the reset the pins float: the shield's
  // pull-down on PWM holds the bridge braked or coasting, whatever the inputs do.  An ESP32 pin
  // takes a level only once it's an output, and comes up low.
  pinMode(pins::kStandby, OUTPUT);
  digitalWrite(pins::kStandby, LOW);
  pinMode(pins::kIn1, OUTPUT);
  digitalWrite(pins::kIn1, LOW);
  pinMode(pins::kIn2, OUTPUT);
  digitalWrite(pins::kIn2, LOW);
  ledcAttach(pins::kPwm, kPwmHz, kPwmBits);
  ledcWrite(pins::kPwm, 0);
  monitor_.begin(pins::kSda, pins::kScl);
  refresh();
}

void Tb6612::wake() {
  brake();
  digitalWrite(pins::kStandby, HIGH);
  delay(1);  // the chip wakes in well under a millisecond
  refresh();
}

void Tb6612::drive(bool forward, float duty) {
  if (duty < 0) duty = 0;
  if (duty > 1) duty = 1;
  // the motor's share of the supply: `motor_volts` on average at full duty
  float pwm = duty;
  if (volts_ > s_.motor_volts) pwm = duty * s_.motor_volts / volts_;
  pwm_ = pwm;
  set(forward, !forward, pwm);
}

void Tb6612::brake() {
  pwm_ = 0;
  set(true, true, 0);
}

void Tb6612::sleep() {
  pwm_ = 0;
  set(false, false, 0);
  digitalWrite(pins::kStandby, LOW);
}

bool Tb6612::fault() { return !ok_ || volts_ < kMinVolts || volts_ > kMaxVolts; }

float Tb6612::amps() {
  // the current every tick; the supply's voltage, which moves slowly, every kVoltsMs
  if (millis() - volts_at_ >= kVoltsMs) {
    refresh();
  } else {
    ok_ = monitor_.amps(supply_amps_);
  }
  if (!ok_ || pwm_ < kMinPwm || supply_amps_ <= 0) return 0;
  return supply_amps_ / pwm_;
}

void Tb6612::refresh() {
  ok_ = monitor_.amps(supply_amps_) && monitor_.volts(volts_);
  volts_at_ = millis();
}

void Tb6612::set(bool in1, bool in2, float pwm) {
  // Only what changed: through a move the inputs stay put, and the PWM mostly does.  The PWM is
  // written first: from the brake (both inputs high) that changes nothing, and the input then
  // pulled low starts the drive at its duty.
  uint32_t full = (1u << kPwmBits) - 1;  // ledcWrite takes it as always on
  uint32_t duty = static_cast<uint32_t>(pwm * full + 0.5f);
  if (duty > full) duty = full;
  if (duty != pwm_set_) ledcWrite(pins::kPwm, pwm_set_ = duty);
  if (in1 != in1_) digitalWrite(pins::kIn1, (in1_ = in1) ? HIGH : LOW);
  if (in2 != in2_) digitalWrite(pins::kIn2, (in2_ = in2) ? HIGH : LOW);
}
