extends Polygon2D
## Continuous 2D skinning of original pixels: hands and feet have independent
## weights; the head is rigid. Attachments evaluate the same deformation.
var rest:=PackedVector2Array()
var frame_size:=Vector2.ONE
var foot:=Vector2.ZERO
var unit_scale:=1.0
var neck:=.68
var phase:=0.0
var weight:=0.0
var sprint:=false
var heading:=Vector2.DOWN
var frame_key:=""
var hands: Array=[]
var foot_nodes: Array[Sprite2D]=[]
var foot_rest: Array[Vector2]=[]
var leg_nodes: Array[Line2D]=[]
var foot_copied:=false
var sine:=0.0
var cosine:=1.0
func configure(source: Texture2D,frame: Dictionary,factor: float) -> void:
 if frame_key==str(source.resource_path):return
 frame_key=str(source.resource_path);texture=load(frame.get("motion_body",source.resource_path));texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 frame_size=source.get_size();foot=Vector2(frame.foot[0],frame.foot[1]);unit_scale=factor
 hands=frame.get("hands",[]);neck=float(frame.get("neck",.68))
 for node in foot_nodes:node.queue_free()
 for node in leg_nodes:node.queue_free()
 leg_nodes.clear()
 foot_nodes.clear();foot_rest.clear()
 for item in frame.get("feet",[]):
  var node:=Sprite2D.new();node.centered=false;node.texture=load(item.path);node.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS;add_child(node);foot_nodes.append(node)
  foot_rest.append((Vector2(item.rect[0],item.rect[1])-foot)*factor)
  var leg:=Line2D.new();leg.width=1.6;leg.default_color=Color("292332");leg.antialiased=true;leg.show_behind_parent=true;add_child(leg);leg_nodes.append(leg)
  foot_copied=item.derived_occluded
 rest.clear();var coords:=PackedVector2Array();var cells: Array[PackedInt32Array]=[]
 for row in range(21):
  for col in range(13):
   var pixel:=Vector2(col/12.0,row/20.0)*frame_size
   rest.append((pixel-foot)*factor);coords.append(pixel)
 for row in range(20):
  for col in range(12):
   var i:=row*13+col;cells.append(PackedInt32Array([i,i+1,i+14,i+13]))
 polygon=rest;uv=coords;polygons=cells
func deform(point: Vector2) -> Vector2:
 if weight<=0:return point
 var pixel:=point/unit_scale+foot
 var t:=pixel.y/frame_size.y
 var side:=clampf(point.x/2.0,-1,1)
 var step:=sine*side
 var leg:=smoothstep(.87,.98,t)
 var arm:=0.0
 var arm_step:=0.0
 for i in range(hands.size()):
  var center: Vector2=(Vector2(hands[i][0],hands[i][1])-foot)*unit_scale
  var influence:=exp(-point.distance_squared_to(center)/24.5)
  arm=maxf(arm,influence)
  arm_step+=influence*(-1 if i==0 and hands.size()>1 else 1)
 if hands.is_empty():
  arm=smoothstep(.08,.19,absf(point.x)/(frame_size.y*unit_scale))*smoothstep(.60,.72,t)*(1-smoothstep(.87,.95,t));arm_step=side*arm
 arm_step*=smoothstep(neck,neck+.12,t)
 arm*=smoothstep(neck,neck+.12,t)
 var amplitude:=2.7 if sprint else 1.45
 var offset:=Vector2.ZERO
 # The left/right foot moves in the direction of travel and lifts on its swing.
 offset.x+=step*leg*.15
 # Opposite arm swing, with sleeve flex below a rigid shoulder/head region.
 offset-=heading*sine*arm_step*amplitude
 offset.x+=cosine*side*arm*(.9 if sprint else .35)
 offset.y-=absf(cosine)*(.5 if sprint else .3)*(1-leg)
 offset+=heading*(.85 if sprint else .2)*(1-smoothstep(neck,1,t))
 return point+offset*weight
func animate(value: float,strength: float,is_running: bool,facing: int) -> void:
 phase=value;sine=sin(value);cosine=cos(value);weight=clampf(strength,0,1);sprint=is_running;heading=Vector2.from_angle(facing*PI/4)
 var deformed:=PackedVector2Array()
 for point in rest:deformed.append(deform(point))
 polygon=deformed
 for i in range(foot_nodes.size()):
  var angle: float=phase+(PI if i==0 else 0)
  var step:=sin(angle)
  var offset:=heading*step*(2.1 if sprint else 1.3)
  offset.y-=maxf(0,cos(angle))*(3.2 if sprint else 1.8)
  if foot_copied:offset+=Vector2(-heading.y,heading.x)*(1 if i==0 else -1)
  foot_nodes[i].position=foot_rest[i]+offset*weight
  foot_nodes[i].scale=Vector2.ONE*unit_scale
  foot_nodes[i].modulate.a=weight if foot_copied and i==1 else 1.0
  foot_nodes[i].show_behind_parent=(heading.y*step+heading.x*(1 if i==0 else -1)*.25)<0
  var native_top: Vector2=foot_rest[i]+Vector2(foot_nodes[i].texture.get_width()*.5,0)*unit_scale
  var hip:=native_top+Vector2(0,-1.5)
  var ankle: Vector2=foot_nodes[i].position+Vector2(foot_nodes[i].texture.get_width()*.5,0)*unit_scale
  var knee: Vector2=hip.lerp(ankle,.55)+Vector2(0,.6)*weight
  leg_nodes[i].points=PackedVector2Array([hip,knee,ankle]);leg_nodes[i].modulate.a=weight
func anchor(name: String) -> Vector2:
 var p: Vector2={"waist":Vector2(0,-12),"back":Vector2(0,-15),"crown":Vector2(0,-37),"left_hand":Vector2(-10,-12),"right_hand":Vector2(10,-12),"left_foot":Vector2(-3,-1),"right_foot":Vector2(3,-1)}.get(name,Vector2.ZERO)
 return deform(p)
