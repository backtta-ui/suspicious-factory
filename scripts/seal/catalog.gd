class_name SealCatalog
extends RefCounted
## All cooldowns, durations and phase limits are provisional test balance, not final design.
const COMMON={
 "transform":{"name":"둔갑술","cd":12.0,"duration":7.0,"icon":"jar"},
 "blink":{"name":"축지법","cd":10.0,"duration":0.0,"icon":"blink"},
 "clone":{"name":"분신술","cd":18.0,"duration":8.0,"icon":"clone"},
 "track":{"name":"추적부","cd":16.0,"duration":7.0,"icon":"track"},
 "shield":{"name":"호신부","cd":22.0,"duration":8.0,"icon":"shield"},
 "smoke":{"name":"연막술","cd":20.0,"duration":6.0,"icon":"smoke"},
 "mask":{"name":"천면술","cd":25.0,"duration":9.0,"icon":"mask"},
 "rescue":{"name":"해봉술","cd":20.0,"duration":8.0,"icon":"rescue"}}
const EVIL={
 "capture":{"name":"그림자 포획","cd":13.0,"duration":0.0,"icon":"capture"},
 "darkness":{"name":"어둠의 장막","cd":30.0,"duration":7.0,"icon":"darkness"},
 "fake_flame":{"name":"가짜 혼불","cd":24.0,"duration":12.0,"icon":"fake_flame"},
 "shadow":{"name":"그림자 이동","cd":16.0,"duration":0.0,"icon":"shadow"},
 "mimic":{"name":"타인 둔갑","cd":25.0,"duration":9.0,"icon":"mimic"}}
const PROTOCOL=3
const PORT=10000
const PREPARATION=30.0
const MATCH_TIME=480.0
const DISCUSSION=30.0
const VOTE=20.0
const RECONNECT=40.0
const MOVE_SPEED=88.0
const VISIBILITY=360.0
static func clean_text(value: Variant,limit: int=72) -> String:
 if not value is String:return ""
 var out:=""
 for c in value.strip_edges():
  var n: int=c.unicode_at(0)
  if n>=32 and n!=127 and n not in [8238,8237]:out+=c
 return out.left(limit)
static func clean_name(value: Variant) -> String:
 var clean:=clean_text(value,12)
 return clean if not clean.is_empty() else "도사"
static func finite_number(value: Variant) -> bool:return (value is int or value is float) and is_finite(float(value))
static func vector(value: Variant) -> Vector2:
 if not value is Array or value.size()!=2 or not finite_number(value[0]) or not finite_number(value[1]):return Vector2.ZERO
 var v:=Vector2(float(value[0]),float(value[1]))
 return v.limit_length(1)

static func whole(value: Variant,low: int,high: int) -> bool:
 return finite_number(value) and float(value)==floorf(float(value)) and float(value)>=low and float(value)<=high
