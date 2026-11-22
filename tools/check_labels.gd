extends SceneTree
## 2.0.38 바닥 표지판 계획 검사: 네 맵의 구역 표지판이 벽·건물·사물과 겹치지 않는지 확인한다.
func _initialize() -> void:
	const ZL=preload("res://scripts/survival/zone_labels.gd")
	var maps={"gangnam":"res://scripts/survival/gangnam_layout.gd",
		"dongseongno":"res://scripts/survival/dongseongno_layout.gd",
		"haeundae":"res://scripts/survival/haeundae_layout.gd",
		"seowon":"res://scripts/survival/layout.gd"}
	for key in maps:
		var L: Script=load(String(maps[key]))
		var spots: Array=ZL.plan(L)
		print("MAP ",key," zones=",L.ZONES.size()," labels=",spots.size())
		for spot in spots:
			var box: Rect2=spot.rect
			var bad:=0
			for rect in L.HARD:
				if (rect as Rect2).intersects(box):bad+=1
			for entry in L.buildings():
				if (entry.rect as Rect2).intersects(box):bad+=1
			print("   ",spot.id," ",spot.text," at ",spot.at," overlaps=",bad)
	quit(0)
