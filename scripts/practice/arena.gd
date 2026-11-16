class_name WooPracticeArena
extends "res://scripts/seal/arena.gd"
const L=preload("res://scripts/practice/layout.gd")
func _init() -> void:
 super("village")
 id="offline_practice";layout=L;altar=Vector2(620,420);jail=Vector2(1080,720)
 data={"name":"도술 익히기","size":L.SIZE,"spawn":L.SPAWN}
 assets.clear();cache.clear();sight_cache.clear();spawn_points.clear()
 for i in range(KINDS.size()):
  var kind: String=KINDS.keys()[i]
  assets.append({"id":"practice_"+kind,"kind":kind,"origin":Vector2(320+(i%5)*120,340+(i/5)*180),"extractable":true,"interactable":true,"transformable":true,"reacts":["transform","track"],"radius":KINDS[kind].radius,"resource":kind})
