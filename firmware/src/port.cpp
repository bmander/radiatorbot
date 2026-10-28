#include "port.h"

#include <stdarg.h>
#include <stdio.h>

void Port::pump() {
  while (len_ > 0) {
    int room = usb_.availableForWrite();
    if (room <= 0) return;
    size_t n = len_;
    if (n > kSize - start_) n = kSize - start_;
    if (n > static_cast<size_t>(room)) n = room;
    size_t sent = usb_.write(buf_ + start_, n);
    if (sent == 0) {
      // nobody's there: the USB port takes nothing until a host opens it
      start_ = len_ = 0;
      return;
    }
    start_ = (start_ + sent) % kSize;
    len_ -= sent;
  }
}

size_t Port::take(uint8_t* out, size_t n) {
  size_t got = 0;
  for (; got < n && len_ > 0; got++) {
    out[got] = buf_[start_];
    start_ = (start_ + 1) % kSize;
    len_--;
  }
  return got;
}

size_t Port::write(const uint8_t* buf, size_t n) {
  for (size_t i = 0; i < n && len_ < kSize; i++) {
    buf_[(start_ + len_) % kSize] = buf[i];
    len_++;
  }
  return n;
}

int Port::printf(const char* fmt, ...) {
  char line[160];
  va_list args;
  va_start(args, fmt);
  int n = vsnprintf(line, sizeof line, fmt, args);
  va_end(args);
  if (n < 0) return n;
  size_t len = static_cast<size_t>(n) < sizeof line ? n : sizeof line - 1;
  write(reinterpret_cast<const uint8_t*>(line), len);
  return n;
}

void Port::flush() {
  uint32_t since = millis();
  while (len_ > 0 && millis() - since < 100) pump();
  usb_.flush();
}
