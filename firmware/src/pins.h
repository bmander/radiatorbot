// The XIAO ESP32-C3's pins as wired on the perfboard (see hardware/DESIGN.md, "The electronics").
// D0, D8 and D9 are the C3's strapping pins and stay free.
#pragma once

namespace pins {

constexpr int kCurrent = 3;     // D1, ADC1: the DRV8874's CS, ~1.1 V/A
constexpr int kThermostat = 4;  // D2: the optocoupler, pulled up; low when it conducts
constexpr int kEnable = 5;      // D3: EN/IN1, PWM for speed
constexpr int kPhase = 6;       // D4: PH/IN2, direction
constexpr int kSleep = 7;       // D5: SLEEP, high to run; VREF follows it
constexpr int kFault = 10;      // D10: FAULT, open-drain, low on a fault

}  // namespace pins
