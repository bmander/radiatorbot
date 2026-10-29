// The SparkFun IoT RedBoard ESP32's pins as wired on the perfboard shield (see hardware/DESIGN.md,
// "The electronics"), each given as the ESP32 GPIO it is.  The RedBoard's silkscreen labels its
// digital pins by their GPIO and its analog ones by their ADC channel, given below.
//
// The INA219 is on I2C at the analog header's first two places, A5 and A4: the header's other
// four (A7, A6, A3, A0) carry GPIO35 to GPIO39, which can only read, and the RedBoard's own I2C
// pins (GPIO21 and GPIO22, the Qwiic socket and the pins labelled SDA and SCL) are off the
// shield's grid, the Qwiic socket's mouth facing the bay's end wall.  The ESP32 puts I2C on any
// two pins that can drive.
#pragma once

#include <stdint.h>

namespace pins {

constexpr int kThermostat = 4;  // the thermostat's contact to ground, pulled up: low closed
constexpr int kStandby = 13;    // the TB6612's STBY, low asleep (pulled up on the breakout)
constexpr int kIn1 = 16;        // the TB6612's AIN1 and BIN1
constexpr int kIn2 = 17;        // its AIN2 and BIN2
constexpr int kPwm = 25;        // its PWMA and PWMB, at 20 kHz (pulled down on the shield)
constexpr int kSda = 33;        // A5: the INA219's SDA
constexpr int kScl = 32;        // A4: its SCL
constexpr int kButton = 0;      // the board's BOOT button, pulled up on it: the factory reset

constexpr uint8_t kMonitorAddress = 0x40;  // the INA219, its A0 and A1 open

}  // namespace pins
