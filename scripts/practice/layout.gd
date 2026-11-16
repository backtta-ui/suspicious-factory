class_name WooPracticeLayout
extends RefCounted
const SIZE=Vector2(1280,960)
const SPAWN=Vector2(600,640)
const ENTRANCE=Vector2(2450,620)
const DOOR=Vector2(2450,685)
const BLOCKS=[Rect2(578,145,124,55),Rect2(170,300,110,45),Rect2(950,330,45,180)]
static func can_stand(p: Vector2,margin: float=9) -> bool:
 if not Rect2(Vector2(35,45)+Vector2.ONE*margin,SIZE-Vector2(70,80)-Vector2.ONE*margin*2).has_point(p):return false
 for rect in BLOCKS:
  if rect.grow(margin).has_point(p):return false
 return true
