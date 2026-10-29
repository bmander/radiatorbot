// The radiator bot: opens the valve while the thermostat calls for heat and closes it when it
// stops, finding each end of the stem's travel by the motor's current.  A console on the USB
// serial port shows what it's doing and sets it up, and on Wi-Fi the same console is on telnet's
// port and a page for a phone is on port 80; see firmware/README.md.
//
// The control loop runs every millisecond in a task of its own, above the Arduino loop on the
// same core, under a 2 s watchdog.  The Arduino loop runs the consoles and the network, which can
// wait on a client as long as they like: the valve's moves never wait on them.
#include <Arduino.h>
#include <esp_task_wdt.h>
#include <freertos/FreeRTOS.h>
#include <freertos/semphr.h>
#include <freertos/task.h>

#include "app.h"
#include "console.h"
#include "pins.h"
#include "port.h"
#include "remote.h"
#include "storage.h"
#include "wlan.h"

static constexpr uint32_t kWatchdogMs = 2000;
static constexpr UBaseType_t kControlPriority = 5;  // the Arduino loop's is 1
static constexpr uint32_t kControlStack = 4096;

static App app;
static Port port(Serial);
static Console console(app, port);
static Remote remote(app);
static SemaphoreHandle_t app_lock;

AppLock::AppLock() { xSemaphoreTake(app_lock, portMAX_DELAY); }
AppLock::~AppLock() { xSemaphoreGive(app_lock); }

static void control(void*) {
  esp_task_wdt_add(nullptr);
  TickType_t woke = xTaskGetTickCount();
  for (;;) {
    {
      AppLock held;
      uint32_t now = millis();
      app.stat.update(now, digitalRead(pins::kThermostat) == LOW);
      app.ctl.setDesired(valve::desiredEnd(app.mode, app.manual, app.stat));
      app.ctl.tick(now);
    }
    esp_task_wdt_reset();
    vTaskDelayUntil(&woke, pdMS_TO_TICKS(1));
  }
}

void setup() {
  app_lock = xSemaphoreCreateMutex();
  app.motor.begin();
  pinMode(pins::kThermostat, INPUT_PULLUP);
  Serial.begin(115200);

  storage::load(app.settings);

  // The task watchdog watches the control task alone.
  esp_task_wdt_config_t wdt = {};
  wdt.timeout_ms = kWatchdogMs;
  wdt.idle_core_mask = 0;
  wdt.trigger_panic = true;
  if (esp_task_wdt_reconfigure(&wdt) != ESP_OK) esp_task_wdt_init(&wdt);
  xTaskCreatePinnedToCore(control, "control", kControlStack, nullptr, kControlPriority, nullptr,
                          ARDUINO_RUNNING_CORE);

  wifi::begin();
  port.println("radiatorbot " RADIATORBOT_VERSION "; `help` lists the commands");
}

void loop() {
  uint32_t now = millis();
  {
    AppLock held;
    console.report(now);
    console.poll();
  }
  port.pump();
  wifi::poll(now);
  remote.poll(now);
  delay(1);
}
