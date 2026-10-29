#include "remote.h"

#include <ctype.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "pins.h"
#include "wifi.h"

using valve::End;
using valve::Mode;
using valve::State;

namespace {

constexpr uint32_t kRequestMs = 3000;  // a request not in by then is dropped

// Telnet's bytes (RFC 854): IAC, then a command; WILL, WONT, DO and DONT take an option, and SB
// opens a subnegotiation that IAC SE closes.
constexpr uint8_t kIac = 255, kSb = 250, kSe = 240, kWill = 251, kDont = 254;
constexpr uint8_t kEcho = 1, kSuppressGoAhead = 3;

// The page: the valve, the thermostat and the motor at a glance, refreshed every two seconds, and
// a button each for heat on (open), heat off (close), back to the thermostat (auto) and stop; and,
// folded away, the console, a line at a time.
const char kPage[] = R"html(<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Radiator</title>
<style>
:root { --bg: #f6f5f2; --card: #fff; --ink: #1d1d1b; --dim: #6b6a66; --line: #dddbd5;
        --warm: #c2410c; --cool: #2563eb; --bad: #b91c1c; }
@media (prefers-color-scheme: dark) {
  :root { --bg: #161615; --card: #22221f; --ink: #ecebe6; --dim: #9c9a93; --line: #3a3935;
          --warm: #fb923c; --cool: #60a5fa; --bad: #f87171; }
}
* { box-sizing: border-box; }
body { margin: 0; padding: 16px; background: var(--bg); color: var(--ink);
       font: 16px/1.4 system-ui, -apple-system, sans-serif; }
main { max-width: 28rem; margin: 0 auto; }
h1 { font-size: 1.1rem; margin: 0 0 12px; color: var(--dim); font-weight: 600; }
.card { background: var(--card); border: 1px solid var(--line); border-radius: 12px;
        padding: 16px; margin-bottom: 12px; }
#valve { font-size: 2rem; font-weight: 700; }
#valve.open { color: var(--warm); } #valve.closed { color: var(--cool); }
#why { color: var(--dim); margin-top: 4px; }
dl { display: grid; grid-template-columns: auto 1fr; gap: 4px 12px; margin: 0; }
dt { color: var(--dim); } dd { margin: 0; }
.bad { color: var(--bad); }
.buttons { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
button { font: inherit; font-weight: 600; padding: 14px 8px; border-radius: 10px;
         border: 1px solid var(--line); background: var(--card); color: var(--ink); }
button.on { border-color: var(--warm); color: var(--warm); }
button.off { border-color: var(--cool); color: var(--cool); }
button:active { opacity: 0.6; }
details summary { color: var(--dim); cursor: pointer; }
form { display: flex; gap: 8px; margin-top: 12px; }
input { flex: 1; min-width: 0; font: inherit; padding: 8px; border-radius: 8px;
        border: 1px solid var(--line); background: var(--bg); color: var(--ink); }
pre { white-space: pre-wrap; word-break: break-word; font-size: 0.85rem; margin: 12px 0 0; }
</style>
</head>
<body>
<main>
<h1>Radiator</h1>
<div class="card">
  <div id="valve">&hellip;</div>
  <div id="why"></div>
</div>
<div class="card buttons">
  <button class="on" data-cmd="open">Heat on</button>
  <button class="off" data-cmd="close">Heat off</button>
  <button data-cmd="auto">Thermostat</button>
  <button data-cmd="stop">Stop</button>
</div>
<div class="card">
  <dl>
    <dt>Thermostat</dt><dd id="stat"></dd>
    <dt>Motor</dt><dd id="motor"></dd>
    <dt>Supply</dt><dd id="supply"></dd>
    <dt>Last move</dt><dd id="last"></dd>
  </dl>
</div>
<div class="card">
  <details>
    <summary>Console</summary>
    <form id="console"><input id="line" autocomplete="off" autocapitalize="off"
      placeholder="status, get, set trip_close 0.9&hellip;"><button>Run</button></form>
    <pre id="out"></pre>
  </details>
</div>
</main>
<script>
const $ = (id) => document.getElementById(id);
async function run(line) {
  const r = await fetch("/cmd", { method: "POST", headers: { "X-Radiatorbot": "1" }, body: line });
  const text = await r.text();
  refresh();
  return text;
}
function show(s) {
  const v = $("valve");
  const moving = s.motor === "running" || s.motor === "backing off";
  v.textContent = moving ? (s.target === "open" ? "Opening…" : "Closing…")
                         : s.valve === "unknown" ? "Unknown" : s.valve[0].toUpperCase() + s.valve.slice(1);
  v.className = moving ? "" : s.valve;
  $("why").textContent = s.mode === "auto" ? "Following the thermostat"
    : s.manual === "open" ? "Heat on until you tap Thermostat"
    : s.manual === "closed" ? "Heat off until you tap Thermostat"
    : "Holding still until you tap Thermostat";
  $("stat").textContent = s.thermostat;
  $("motor").textContent = s.motor + (s.motor === "failed" ? " (" + s.failures + " in a row)" : "");
  $("motor").className = s.motor === "failed" ? "bad" : "";
  $("supply").textContent = s.supply_ok ? s.volts.toFixed(1) + " V" : "the INA219 doesn't answer";
  $("supply").className = s.supply_ok && s.volts >= 6.5 && s.volts <= 13.5 ? "" : "bad";
  $("last").textContent = s.last ? s.last.target + ": " + s.last.outcome + " in " +
    s.last.s.toFixed(1) + " s, peak " + s.last.peak_a.toFixed(2) + " A" : "none yet";
}
async function refresh() {
  try { show(await (await fetch("/status")).json()); }
  catch (e) { $("why").textContent = "Can't reach the bot"; }
}
document.querySelectorAll("button[data-cmd]").forEach((b) =>
  b.addEventListener("click", () => run(b.dataset.cmd)));
$("console").addEventListener("submit", async (e) => {
  e.preventDefault();
  const line = $("line").value.trim();
  if (line) $("out").textContent = await run(line);
});
refresh();
setInterval(refresh, 2000);
</script>
</body>
</html>
)html";

// The value of header `name` in `head`, which ends at its blank line, or null; matched without
// case, as HTTP's names are.
const char* header(const char* head, const char* name) {
  size_t n = strlen(name);
  for (const char* line = strstr(head, "\r\n"); line != nullptr; line = strstr(line + 2, "\r\n")) {
    const char* at = line + 2;
    if (strncasecmp(at, name, n) == 0 && at[n] == ':') {
      at += n + 1;
      while (*at == ' ') at++;
      return at;
    }
  }
  return nullptr;
}

// Appends to `buf`, `n` long so far: -1 once anything has failed to fit.
__attribute__((format(printf, 4, 5))) void append(char* buf, size_t size, int& n,
                                                  const char* fmt, ...) {
  if (n < 0) return;
  va_list args;
  va_start(args, fmt);
  int more = vsnprintf(buf + n, size - n, fmt, args);
  va_end(args);
  n = more >= 0 && static_cast<size_t>(n + more) < size ? n + more : -1;
}

}  // namespace

void Link::attach(NetworkClient client) {
  client_ = client;
  client_.setNoDelay(true);
  telnet_ = Telnet::kData;
  next_ = -1;
  // The bot echoes, a character at a time, as on the USB port: the client stops echoing itself.
  const uint8_t hello[] = {kIac, kWill, kEcho, kIac, kWill, kSuppressGoAhead};
  client_.write(hello, sizeof hello);
}

void Link::fill() {
  while (next_ < 0 && client_.available() > 0) {
    int c = client_.read();
    if (c < 0) return;
    switch (telnet_) {
      case Telnet::kData:
        if (c == kIac) {
          telnet_ = Telnet::kCommand;
        } else {
          next_ = c;
        }
        break;
      case Telnet::kCommand:
        if (c == kIac) {
          next_ = c;  // a doubled IAC is a data byte
          telnet_ = Telnet::kData;
        } else if (c == kSb) {
          telnet_ = Telnet::kSub;
        } else if (c >= kWill && c <= kDont) {
          telnet_ = Telnet::kOption;
        } else {
          telnet_ = Telnet::kData;
        }
        break;
      case Telnet::kOption:
        telnet_ = Telnet::kData;
        break;
      case Telnet::kSub:
        if (c == kIac) telnet_ = Telnet::kSubCommand;
        break;
      case Telnet::kSubCommand:
        telnet_ = c == kSe ? Telnet::kData : Telnet::kSub;
        break;
    }
  }
}

int Link::available() {
  fill();
  return next_ >= 0 ? 1 : 0;
}

int Link::read() {
  fill();
  int c = next_;
  next_ = -1;
  return c;
}

int Link::peek() {
  fill();
  return next_;
}

size_t Link::write(const uint8_t* buf, size_t n) {
  if (!client_.connected()) return 0;
  return client_.write(buf, n);
}

void Remote::poll(uint32_t now) {
  if (!started_) {
    if (!wifi::connected()) return;
    telnet_server_.begin();
    telnet_server_.setNoDelay(true);
    web_server_.begin();
    started_ = true;
  }
  pollTelnet(now);
  pollWeb(now);
}

void Remote::pollTelnet(uint32_t now) {
  if (telnet_server_.hasClient()) {
    // a new client takes the console from the last
    NetworkClient client = telnet_server_.accept();
    if (client) {
      telnet_.stop();
      telnet_.attach(client);
      telnet_port_.clear();
      telnet_port_.println("radiatorbot " RADIATORBOT_VERSION "; `help` lists the commands");
    }
  }
  if (!telnet_.connected()) {
    telnet_.stop();
    return;
  }
  {
    AppLock held;
    telnet_console_.report(now);
    telnet_console_.poll();
  }
  telnet_port_.pump();
}

void Remote::pollWeb(uint32_t now) {
  if (!web_) {
    if (!web_server_.hasClient()) return;
    web_ = web_server_.accept();
    request_len_ = 0;
    request_at_ = now;
    if (!web_) return;
  }
  int n = web_.available();
  if (n > 0) {
    size_t room = sizeof request_ - 1 - request_len_;
    if (static_cast<size_t>(n) > room) n = room;
    int got = web_.read(reinterpret_cast<uint8_t*>(request_ + request_len_), n);
    if (got > 0) request_len_ += got;
  }
  request_[request_len_] = '\0';

  char* blank = strstr(request_, "\r\n\r\n");
  if (blank != nullptr) {
    char kept = blank[2];
    blank[2] = '\0';  // the head alone, for header()
    const char* length = header(request_, "Content-Length");
    size_t body = length != nullptr ? strtoul(length, nullptr, 10) : 0;
    blank[2] = kept;
    if (request_ + request_len_ >= blank + 4 + body) {
      respond();
      web_.stop();
      return;
    }
  }
  if (request_len_ >= sizeof request_ - 1) {
    sendText("413 Content Too Large", "too long\n");
    web_.stop();
  } else if (now - request_at_ >= kRequestMs || !web_.connected()) {
    web_.stop();
  }
}

void Remote::respond() {
  char* blank = strstr(request_, "\r\n\r\n");
  char* body = blank + 4;
  blank[2] = '\0';  // the head, its last line's CRLF kept for header()
  char method[8] = "", path[64] = "";
  sscanf(request_, "%7s %63s", method, path);
  char* query = strchr(path, '?');
  if (query != nullptr) *query = '\0';

  if (strcmp(method, "GET") == 0 && (strcmp(path, "/") == 0 || strcmp(path, "/index.html") == 0)) {
    send("200 OK", "text/html; charset=utf-8", kPage, sizeof kPage - 1);
  } else if (strcmp(method, "GET") == 0 && strcmp(path, "/status") == 0) {
    sendStatus();
  } else if (strcmp(method, "POST") == 0 && strcmp(path, "/cmd") == 0) {
    if (header(request_, "X-Radiatorbot") == nullptr) {
      sendText("403 Forbidden", "commands come from the bot's own page\n");
    } else {
      sendCommand(body);
    }
  } else {
    sendText("404 Not Found", "not here\n");
  }
}

void Remote::sendStatus() {
  static char json[768];
  int n = 0;
#define add(...) append(json, sizeof json, n, __VA_ARGS__)
  {
    AppLock held;
    const valve::Controller& c = app_.ctl;
    Tb6612& m = app_.motor;
    if (!c.moving()) m.refresh();  // while it runs, the loop reads it every tick
    const valve::ThermostatInput& stat = app_.stat;
    add("{\"version\":\"%s\",\"up_s\":%lu,\"mode\":\"%s\",\"manual\":\"%s\",", RADIATORBOT_VERSION,
        static_cast<unsigned long>(millis() / 1000), app_.mode == Mode::kAuto ? "auto" : "manual",
        app_.manual == End::kUnknown ? "hold" : valve::name(app_.manual));
    add("\"thermostat\":\"%s\",\"contact\":\"%s\",",
        !stat.known() ? "settling" : stat.calling() ? "calling for heat" : "not calling",
        digitalRead(pins::kThermostat) == LOW ? "closed" : "open");
    add("\"valve\":\"%s\",\"motor\":\"%s\",\"target\":\"%s\",\"failures\":%u,",
        valve::name(c.position()), valve::name(c.state()), valve::name(c.target()),
        static_cast<unsigned>(c.failures()));
    add("\"supply_ok\":%s,\"volts\":%.2f,\"amps\":%.3f,\"motor_a\":%.3f,",
        m.monitor_ok() ? "true" : "false", m.supply_volts(), m.supply_amps(),
        c.moving() ? c.amps() : 0.0f);
    if (c.moves() > 0) {
      const valve::MoveReport& r = c.last();
      add("\"last\":{\"target\":\"%s\",\"outcome\":\"%s\",\"s\":%.1f,\"running_a\":%.2f,"
          "\"peak_a\":%.2f,\"trip_a\":%.2f},",
          valve::name(r.target), valve::name(r.outcome), r.duration_ms / 1000.0, r.running_a,
          r.peak_a, r.trip_a);
    } else {
      add("\"last\":null,");
    }
  }
  add("\"rssi\":%d,\"ip\":\"%s\"}\n", static_cast<int>(WiFi.RSSI()),
      WiFi.localIP().toString().c_str());
#undef add
  if (n < 0) {
    sendText("500 Internal Server Error", "status too long\n");
    return;
  }
  send("200 OK", "application/json", json, n);
}

void Remote::sendCommand(const char* body) {
  static uint8_t reply[2048];  // a Port's whole buffer
  char line[96];
  while (isspace(static_cast<unsigned char>(*body))) body++;
  size_t n = strcspn(body, "\r\n");
  if (n >= sizeof line) {
    sendText("400 Bad Request", "a command is one line\n");
    return;
  }
  memcpy(line, body, n);
  line[n] = '\0';
  size_t got = 0;
  {
    AppLock held;
    web_port_.clear();
    web_console_.exec(line);
    got = web_port_.take(reply, sizeof reply);
  }
  send("200 OK", "text/plain; charset=utf-8", reinterpret_cast<const char*>(reply), got);
}

void Remote::sendText(const char* status, const char* text) {
  send(status, "text/plain", text, strlen(text));
}

void Remote::send(const char* status, const char* type, const char* body, size_t len) {
  char head[192];
  int n = snprintf(head, sizeof head,
                   "HTTP/1.1 %s\r\nContent-Type: %s\r\nContent-Length: %u\r\n"
                   "Cache-Control: no-store\r\nConnection: close\r\n\r\n",
                   status, type, static_cast<unsigned>(len));
  web_.write(reinterpret_cast<const uint8_t*>(head), n);
  web_.write(reinterpret_cast<const uint8_t*>(body), len);
}
