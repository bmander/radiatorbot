// The Uno R4 Minima's pins as wired on the perfboard shield (see hardware/DESIGN.md, "The
// electronics").  The INA219 is on the I2C pins, A4 (SDA) and A5 (SCL).
#pragma once

#include <stdint.h>

namespace pins {

constexpr int kThermostat = 2;  // D2: the thermostat's contact to ground, pulled up: low closed
constexpr int kIn1 = 5;         // D5: the DRV8871's IN1, PWM (GPT2)
constexpr int kIn2 = 6;         // D6: its IN2, PWM (GPT0)

constexpr uint8_t kMonitorAddress = 0x40;  // the INA219, its A0 and A1 open

}  // namespace pins
