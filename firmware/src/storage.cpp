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
    valve::Settings t = s;
    switch (f.type) {
      case valve::FieldType::kFloat:
        *valve::floatField(t, f) = p.getFloat(f.name, *valve::floatField(s, f));
        break;
      case valve::FieldType::kUint:
        *valve::uintField(t, f) = p.getUInt(f.name, *valve::uintField(s, f));
        break;
      case valve::FieldType::kBool:
        *valve::boolField(t, f) = p.getBool(f.name, *valve::boolField(s, f));
        break;
    }
    // A stored value outside the field's range (an older firmware's) is ignored.
    if (valve::inRange(t, f)) s = t;
  }
  p.end();
}

bool save(const valve::Settings& s) {
  Preferences p;
  if (!p.begin(kNamespace, false)) return false;
  bool ok = true;
  valve::Settings t = s;  // the accessors take a mutable struct
  size_t n = 0;
  const valve::Field* fs = valve::fields(&n);
  for (size_t i = 0; i < n; i++) {
    const valve::Field& f = fs[i];
    switch (f.type) {
      case valve::FieldType::kFloat:
        ok &= p.putFloat(f.name, *valve::floatField(t, f)) > 0;
        break;
      case valve::FieldType::kUint:
        ok &= p.putUInt(f.name, *valve::uintField(t, f)) > 0;
        break;
      case valve::FieldType::kBool:
        ok &= p.putBool(f.name, *valve::boolField(t, f)) > 0;
        break;
    }
  }
  p.end();
  return ok;
}

}  // namespace storage
