#include "drv8874.h"

#include <Arduino.h>

#include "pins.h"

void Drv8874::begin() {
  // SLEEP low before it's an output, so the driver never wakes on a glitch.  Through a reset the
  // chip's own pull-down holds it asleep.
  digitalWrite(pins::kSleep, LOW);
  pinMode(pins::kSleep, OUTPUT);
  digitalWrite(pins::kPhase, LOW);
  pinMode(pins::kPhase, OUTPUT);
  ledcAttach(pins::kEnable, kPwmHz, kPwmBits);
  ledcWrite(pins::kEnable, 0);
  pinMode(pins::kFault, INPUT_PULLUP);

  // 12 dB attenuation: about 0-2.5 V, so up to about 2.2 A at 1.1 V/A
  analogReadResolution(12);
  analogSetPinAttenuation(pins::kCurrent, ADC_11db);
  read_mv(1);
}

void Drv8874::wake() {
  ledcWrite(pins::kEnable, 0);
  digitalWrite(pins::kSleep, HIGH);
  delay(2);  // the chip's wake-up time, about 1 ms
  // Braked and still, CS sources nothing: what the ADC reads now is its own offset.
  float mv = read_mv(32);
  offset_mv_ = mv < kMaxOffsetMv ? mv : 0;
}

void Drv8874::drive(bool forward, float duty) {
  if (duty < 0) duty = 0;
  if (duty > 1) duty = 1;
  digitalWrite(pins::kPhase, forward ? HIGH : LOW);
  ledcWrite(pins::kEnable, static_cast<uint32_t>(duty * ((1u << kPwmBits) - 1) + 0.5f));
}

void Drv8874::brake() {
  // PH/EN mode: EN low brakes through the low sides
  ledcWrite(pins::kEnable, 0);
}

void Drv8874::sleep() {
  ledcWrite(pins::kEnable, 0);
  digitalWrite(pins::kSleep, LOW);
}

bool Drv8874::fault() { return digitalRead(pins::kFault) == LOW; }

float Drv8874::read_mv(int n) {
  uint32_t sum = 0;
  for (int i = 0; i < n; i++) sum += analogReadMilliVolts(pins::kCurrent);
  return static_cast<float>(sum) / n;
}

float Drv8874::amps() {
  float mv = read_mv(kSamples) - offset_mv_;
  if (mv < 0) mv = 0;
  return mv / 1000.0f / s_.cs_gain;
}
