#include "thermostat.h"

namespace valve {

void ThermostatInput::update(uint32_t now_ms, bool closed) {
  bool calling = closed != s_.stat_invert;
  if (!started_ || calling != candidate_) {
    started_ = true;
    candidate_ = calling;
    candidate_since_ = now_ms;
  }
  if (now_ms - candidate_since_ >= s_.stat_settle) {
    known_ = true;
    calling_ = candidate_;
  }
}

}  // namespace valve
