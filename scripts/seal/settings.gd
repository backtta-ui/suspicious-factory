class_name SealSettings
extends RefCounted
## Rescue 4s, protection 3s, capture deadline 45s: confirmed user rules.
## Other balance values remain configurable test defaults.
const DEFAULTS={"map_pool":["village","forest"],"object_speed":46.0,"animal_speed":78.0,"missing_spells":"allow_empty","vip_swap":false,"meeting_limit":6,"meeting_cost":1,"meeting_cooldown":45.0,"wrong_seal_seconds":35.0,"extract_range":76.0,"extract_seconds":1.0,"form_capacity":6,"transform_seconds":9.0,"transform_cooldown":12.0,"rescue_seconds":4.0,"protected_seconds":3.0,"capture_seconds":45.0,"capture_range":48.0,"fallback_seconds":4.0,"fallback_cooldown":65.0}
const COLORS=["e76b76","6f9ee8","e9cf68","70bd91","b18bda","e9a069","72d3da","e795c3"]
const COLOR_NAMES=["빨강","파랑","노랑","초록","보라","주황","하늘","분홍"]
static func options(overrides: Dictionary={}) -> Dictionary:
 var out: Dictionary=DEFAULTS.duplicate(true)
 for key in overrides:
  if out.has(key):out[key]=overrides[key]
 return out
