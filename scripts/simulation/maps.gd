extends RefCounted
const Arena=preload("res://scripts/seal/arena.gd")
static func playable() -> Array:
 var out: Array=[]
 for id in Arena.REGISTRY:
  var data: Dictionary=Arena.REGISTRY[id]
  if data.get("playable",false) and ResourceLoader.exists(data.scene) and data.stations.size()>=4:out.append(id)
 return out
