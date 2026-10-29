#include "button.h"

#include <Arduino.h>

#include "pins.h"
#include "storage.h"

namespace button {

namespace {

constexpr uint32_t kSettleMs = 50;    // a press or a release must hold this long: no bounce
constexpr uint32_t kNoticeMs = 1000;  // a hold this long is taken as one, and said
constexpr uint32_t kResetMs = 10000;  // and this long resets
constexpr uint32_t kBlinkMs = 250;

bool pressed = false;   // settled
bool reading = false;   // as last read
uint32_t changed = 0;   // when `reading` last changed
uint32_t since = 0;     // when the settled press began
bool noticed = false;

void led(uint8_t r, uint8_t g, uint8_t b) { rgbLedWrite(RGB_BUILTIN, r, g, b); }

}  // namespace

void begin() {
  pinMode(pins::kButton, INPUT_PULLUP);
  led(0, 0, 0);
}

void poll(uint32_t now, Port& log) {
  bool down = digitalRead(pins::kButton) == LOW;
  if (down != reading) {
    reading = down;
    changed = now;
  }
  if (reading != pressed && now - changed >= kSettleMs) {
    pressed = reading;
    since = now;
    if (!pressed && noticed) {
      led(0, 0, 0);
      log.println("button: let go; nothing reset");
    }
    noticed = false;
  }
  if (!pressed) return;

  uint32_t held = now - since;
  if (held < kNoticeMs) return;
  if (!noticed) {
    noticed = true;
    log.println("button: hold BOOT 10 s to forget the settings and the Wi-Fi, and restart");
  }
  if (held < kResetMs) {
    bool on = (held / kBlinkMs) % 2 == 0;
    led(on ? RGB_BRIGHTNESS : 0, on ? RGB_BRIGHTNESS / 3 : 0, 0);  // amber
    return;
  }
  led(RGB_BRIGHTNESS, 0, 0);
  log.println(storage::erase() ? "button: settings and Wi-Fi forgotten; restarting"
                               : "button: couldn't erase the flash; restarting anyway");
  // the console's buffer, out on the USB port before the restart drops it
  for (uint32_t until = millis() + 300; static_cast<int32_t>(until - millis()) > 0;) {
    log.pump();
    delay(5);
  }
  ESP.restart();
}

}  // namespace button
