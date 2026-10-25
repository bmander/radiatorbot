#include "storage.h"

#include <Preferences.h>

namespace storage {

namespace {
constexpr const char* kNamespace = "radiatorbot";
}

void load(valve::Settings& s) {
  Preferences p;
  if (!p.begin(kNamespace, true)) return;  // nothing stored yet
  size_t n = 0;
  const valve::Field* fs = valve::fields(&n);
  for (size_t i = 0; i < n; i++) {
    const valve::Field& f = fs[i];
    if (!p.isKey(f.name)) continue;
    // A stored value outside the field's range (an older firmware's) is ignored.
    switch (f.type) {
      case valve::FieldType::kFloat: {
        float v = p.getFloat(f.name);
        if (valve::inRange(f, v)) valve::floatField(s, f) = v;
        break;
      }
      case valve::FieldType::kUint: {
        uint32_t v = p.getUInt(f.name);
        if (valve::inRange(f, v)) valve::uintField(s, f) = v;
        break;
      }
      case valve::FieldType::kBool:
        valve::boolField(s, f) = p.getBool(f.name);
        break;
    }
  }
  p.end();
}

bool save(const valve::Settings& s) {
  Preferences p;
  if (!p.begin(kNamespace, false)) return false;
  bool ok = true;
  size_t n = 0;
  const valve::Field* fs = valve::fields(&n);
  for (size_t i = 0; i < n; i++) {
    const valve::Field& f = fs[i];
    switch (f.type) {
      case valve::FieldType::kFloat:
        ok &= p.putFloat(f.name, valve::floatField(s, f)) > 0;
        break;
      case valve::FieldType::kUint:
        ok &= p.putUInt(f.name, valve::uintField(s, f)) > 0;
        break;
      case valve::FieldType::kBool:
        ok &= p.putBool(f.name, valve::boolField(s, f)) > 0;
        break;
    }
  }
  p.end();
  return ok;
}

}  // namespace storage
