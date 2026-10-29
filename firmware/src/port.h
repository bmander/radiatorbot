// The console's side of a serial link, the USB port's or a network client's.  What it writes waits
// in a buffer and goes out as the other end takes it, so a long reply never holds up the loop;
// with nobody there, it's dropped.
#pragma once

#include <Arduino.h>

class Port : public Stream {
 public:
  explicit Port(Stream& usb) : usb_(usb) {}

  // Sends what the host has room for.  Call it every loop.
  void pump();
  // Takes up to `n` bytes of what's buffered instead of sending them, as the web page's console
  // does; returns how many.
  size_t take(uint8_t* out, size_t n);
  // Drops what's buffered, for a new client.
  void clear() { start_ = len_ = 0; }

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
