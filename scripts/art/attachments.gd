extends RefCounted
## Native-character local space, foot origin, shared by preview/game/skin rig.
const PROFILES={"woochi":{"waist_y":-12.0,"side":6.0},"yeonhwa":{"waist_y":-14.0,"side":5.5},"muyeong":{"waist_y":-12.0,"side":5.5},"hongryeon":{"waist_y":-13.0,"side":6.5}}
static func rest(character: String,part: String,direction: int) -> Vector2:
 var profile: Dictionary=PROFILES.get(character,PROFILES.woochi)
 if part=="back":return Vector2(0,float(profile.waist_y)-3)
 if part=="crown":return Vector2(0,-37)
 var x: float=profile.side
 if direction==1:x=-x
 elif direction in [2,3]:x=-2.5 if direction==2 else 2.5
 elif direction in [4,5,6,7]:x=4 if direction in [4,7] else -4
 return Vector2(x,float(profile.waist_y))
