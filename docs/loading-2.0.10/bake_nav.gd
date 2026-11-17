extends SceneTree
func _initialize() -> void:
 var nav=preload("res://scripts/worlds/plaza_navigation.gd").new();var edges: Array=[]
 for edge in nav.Data.EDGES:
  if nav.segment_clear(nav.Data.POINTS[edge[0]],nav.Data.POINTS[edge[1]]):edges.append(edge)
 var f:=FileAccess.open("res://scripts/worlds/plaza_nav_edges.gd",FileAccess.WRITE);f.store_string("extends RefCounted\n# Generated from the story plaza geometry; checked against all source edges in loading tests.\nconst EDGES="+str(edges)+"\n");print("BAKED EDGES ",edges.size(),"/",nav.Data.EDGES.size());quit()
