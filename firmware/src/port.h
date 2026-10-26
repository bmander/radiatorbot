// The console's side of the USB serial port.  What it writes waits in a buffer and goes out as the
// host takes it, so a long reply never holds up the motor; with no host connected, it's dropped.
#pragma once

#include <Arduino.h>

class Port : public Stream {
 public:
  explicit Port(Stream& usb) : usb_(usb) {}

  // Sends what the host has room for.  Call it every loop.
  void pump();

  int printf(const char* fmt, ...) __attribute__((format(printf, 2, 3)));

  int available() override { return usb_.available(); }
  int read() override { return usb_.read(); }
  int peek() override { return usb_.peek(); }
  size_t write(uint8_t c) override { return write(&c, 1); }
  size_t write(const uint8_t* buf, size_t n) override;
  // Sends everything buffered, for up to 100 ms.
  void flush() override;
  using Print::write;

 private:
  static constexpr size_t kSize = 2048;  // the longest reply (`get`, ~1.4 kB) whole

  Stream& usb_;
  uint8_t buf_[kSize];
  size_t start_ = 0, len_ = 0;
};
