class_name WooPracticeLayout
extends RefCounted
const SIZE=Vector2(1280,960)
const SPAWN=Vector2(600,640)
const ENTRANCE=Vector2(2450,620)
const DOOR=Vector2(2450,685)
const PROPS=[["hanok",Vector2(640,190),0.0],["tree",Vector2(150,220),16.0],["tree",Vector2(1100,240),16.0],["tree",Vector2(150,790),16.0],["tree",Vector2(1150,830),16.0],["lantern",Vector2(450,270),10.0],["lantern",Vector2(850,270),10.0],["lantern",Vector2(1080,680),10.0]]
const BLOCKS=[Rect2(578,145,124,55),Rect2(170,300,110,45),Rect2(950,330,45,180)]
static func can_stand(p: Vector2,margin: float=9) -> bool:
 if not Rect2(Vector2(35,45)+Vector2.ONE*margin,SIZE-Vector2(70,80)-Vector2.ONE*margin*2).has_point(p):return false
 for rect in BLOCKS:
  if rect.grow(margin).has_point(p):return false
 for prop in PROPS:
  if prop[2]>0 and p.distance_to(prop[1])<prop[2]+margin:return false
 return true
