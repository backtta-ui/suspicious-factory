extends Node2D
const ART=preload("res://assets/woo/v14/items.png")
var adventure: WooAdventure
var loot: Dictionary
var clock:=0.0
func _process(delta: float) -> void:
 if not is_instance_valid(adventure) or not is_instance_valid(adventure.game.player):return
 clock+=delta
 if position.distance_squared_to(adventure.game.player.position)<700*700:queue_redraw()
func _draw() -> void:
 var claimed: bool=adventure.game.rpg.data.loot_claims.has(loot.id)
 var index: int={"potion":5,"leaf":3,"seal":2}.get(loot.item,5)
 var cell:=Vector2(ART.get_width()/3.0,ART.get_height()/2.0)
 draw_texture_rect_region(ART,Rect2(-28,-48,56,50),Rect2(Vector2(index%3,floori(index/3.0))*cell,cell),Color(1,1,1,.30 if claimed else 1.0))
 if not claimed:
  for i in range(4):draw_circle(Vector2.from_angle(clock+i*TAU/4)*25+Vector2(0,-20),1.5,Color("f2d086"))
