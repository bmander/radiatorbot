// What the controller needs of the motor driver.
#pragma once

namespace valve {

class Motor {
 public:
  virtual ~Motor() = default;

  // Out of sleep and ready to drive, braked.
  virtual void wake() = 0;
  // Drives at `duty` (0-1); `forward` is the driver's PH high.
  virtual void drive(bool forward, float duty) = 0;
  // Both low sides on: the motor brakes.
  virtual void brake() = 0;
  // Outputs off, the driver asleep.
  virtual void sleep() = 0;
  // The driver reports a fault (overcurrent, overheating, undervoltage).
  virtual bool fault() = 0;
  // The motor's current, in amperes.
  virtual float amps() = 0;
};

}  // namespace valve
