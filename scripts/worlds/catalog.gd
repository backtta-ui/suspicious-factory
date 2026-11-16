class_name WooPaintingWorlds
extends RefCounted
# IDs of historical, unreleased paintings remain in village_layout for save compatibility.
const ENTRY=Vector2(1900,350)
const WORLDS=[
 {"id":"fox_forest","title":"여우의 숲","description":"흰 여우의 흔적을 따라 안개 낀 대나무숲과 오래된 사당을 탐험하세요.","mapId":"fox_forest","unlocked":true,"entryRequirements":[],"thumbnailAsset":"res://assets/woo/v13/fox_painting.png"},
 {"id":"moon_palace","title":"달빛 궁궐","description":"달이 비치는 궁궐 회랑에서 흩어진 별 문양을 살펴보세요.","mapId":"moon_palace","unlocked":true,"entryRequirements":[],"thumbnailAsset":"res://assets/woo/worlds/moon_palace.png"},
 {"id":"red_sea","title":"붉은 달의 바다","description":"붉은 달의 물결을 따라 해안의 오래된 울림을 찾아보세요.","mapId":"red_sea","unlocked":true,"entryRequirements":[],"thumbnailAsset":"res://assets/woo/worlds/red_sea.png"}]
static func find(id: String) -> Dictionary:
 for world in WORLDS:
  if world.id==id:return world
 return {}
static func known(id: String) -> bool:return not find(id).is_empty()
