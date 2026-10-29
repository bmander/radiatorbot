// The RedBoard's BOOT button, GPIO0, as the factory reset: held 10 s, the bot forgets its settings
// and its Wi-Fi network and restarts, and so comes up on its defaults with the setup network open
// (wlan.h).  The board's RGB LED says how it's going: amber, blinking, while it's held, and red as
// it resets.  Let go sooner and nothing happens.
//
// GPIO0 is a strapping pin, read at a reset to choose the bootloader: held through RESET or a
// power-up, the button starts the ESP32's programming mode instead.  Once the bot is running it's
// an input like any other, pulled up on the board, low while pressed.  RESET itself is the chip's
// enable pin, out of the firmware's reach.
#pragma once

#include <stdint.h>

#include "port.h"

namespace button {

void begin();
// Watches the button: call every loop.  Says on `log` when a hold starts, is let go, or resets.
void poll(uint32_t now, Port& log);

}  // namespace button
