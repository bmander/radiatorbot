// The SparkFun IoT RedBoard ESP32's pins as wired on the perfboard shield (see hardware/DESIGN.md,
// "The electronics").  Each is named for the Uno header place it stands in, which is what the
// shield's wiring follows, and given as the ESP32 GPIO it is.
//
// The INA219 is on I2C at the analog header's first two places: the RedBoard's A4 and A5 places
// carry GPIO39 and GPIO36, which can only read, so I2C can't stay there, and its own I2C pins
// (GPIO21 and GPIO22, the Qwiic socket and the SDA/SCL header) are off the shield's grid, the
// Qwiic socket's mouth facing the bay's end wall.  The ESP32 puts I2C on any two pins that can
// drive.
#pragma once

#include <stdint.h>

namespace pins {

constexpr int kThermostat = 4;  // D2: the thermostat's contact to ground, pulled up: low closed
constexpr int kStandby = 13;    // D3: the TB6612's STBY, low asleep (pulled up on the breakout)
constexpr int kIn1 = 16;        // D5: the TB6612's AIN1 and BIN1
constexpr int kIn2 = 17;        // D6: its AIN2 and BIN2
constexpr int kPwm = 25;        // D7: its PWMA and PWMB, at 20 kHz (pulled down on the shield)
constexpr int kSda = 33;        // A0's place: the INA219's SDA
constexpr int kScl = 32;        // A1's place: its SCL

constexpr uint8_t kMonitorAddress = 0x40;  // the INA219, its A0 and A1 open

}  // namespace pins
