// The bot on the network: the console on telnet's port 23, the same as on the USB port, and a page
// on port 80 for a phone, with the valve's state, and heat on, heat off and back to the
// thermostat.  Over Tailscale they're reached through a subnet router on the home network
// (firmware/README.md, "From anywhere").
//
// Neither asks for a password: anyone who can reach the bot can run it, so it belongs on a
// network that's yours.  The page's commands come only from the page itself: a POST without its
// `X-Radiatorbot` header is turned away, so another site open in a browser on the same network
// can't send one.
//
// One client at a time on each, served by the loop, which never holds the app's lock while it
// waits on the network.
#pragma once

#include <WiFi.h>
#include <stdint.h>

#include "app.h"
#include "console.h"
#include "port.h"

// A network client as the console's stream: the client in hand, its telnet negotiation dropped
// on the way in.
class Link : public Stream {
 public:
  void attach(NetworkClient client);
  void stop() { client_.stop(); }
  bool connected() { return client_.connected(); }

  int available() override;
  int read() override;
  int peek() override;
  size_t write(uint8_t c) override { return write(&c, 1); }
  size_t write(const uint8_t* buf, size_t n) override;
  // The client's room, as Port::pump asks it: none once it has gone.
  int availableForWrite() override { return client_.connected() ? kChunk : 0; }
  using Print::write;

 private:
  static constexpr int kChunk = 512;
  enum class Telnet : uint8_t { kData, kCommand, kOption, kSub, kSubCommand };

  // Skips telnet's commands, leaving the next byte of data (or -1) in `next_`.
  void fill();

  NetworkClient client_;
  Telnet telnet_ = Telnet::kData;
  int next_ = -1;
};

class Remote {
 public:
  explicit Remote(App& app) : app_(app), telnet_console_(app, telnet_port_),
                              web_console_(app, web_port_) {}

  // Serves the network: call every loop, not holding the app's lock.  The servers start once the
  // bot first joins a network.
  void poll(uint32_t now);

 private:
  void pollTelnet(uint32_t now);
  void pollWeb(uint32_t now);
  void respond();
  void sendStatus();
  void sendCommand(const char* body);
  void sendText(const char* status, const char* text);
  void send(const char* status, const char* type, const char* body, size_t len);

  App& app_;
  bool started_ = false;

  NetworkServer telnet_server_{23};
  Link telnet_;
  Port telnet_port_{telnet_};
  Console telnet_console_;

  // The page's commands run on a console of their own, its reply taken from its port's buffer.
  struct Sink : Stream {
    int available() override { return 0; }
    int read() override { return -1; }
    int peek() override { return -1; }
    size_t write(uint8_t) override { return 0; }
    int availableForWrite() override { return 0; }
  } sink_;
  Port web_port_{sink_};
  Console web_console_;

  NetworkServer web_server_{80};
  NetworkClient web_;
  char request_[1024];
  size_t request_len_ = 0;
  uint32_t request_at_ = 0;
};
