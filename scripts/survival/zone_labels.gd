extends Node2D
## 2.0.38 구역 바닥 표지판.
##
## 2.0.37까지는 구역 이름을 바닥(ground) 레이어에 그렸기 때문에, 그 위에 얹히는
## 실내 레이어(interior_layer, z=-78)·벽·건물 상자에 글자가 반쯤 가려졌다
## (서울 강남역 '자판기 코너' 잘림). 2.0.38부터 표지판은 실내 레이어보다 위(z=-74)에
## 서고, 벽·건물·사물·기믹·다른 표지판을 모두 피해 '빈 바닥 한가운데'에만 놓인다.
## 좌표는 각 맵 layout.gd의 ZONES/HARD/buildings()/OBJECTS/GIMMICKS만 읽는다.
const FONT=preload("res://assets/fonts/WooTitle.otf")
const LABEL_SIZE=30
const PAD_X=20.0
const PAD_Y=11.0
## 표지판끼리 최소 간격(글자 상자가 겹치지 않게).
const GAP=18.0
var layout: Script
var spots: Array=[]
var planned:=false
func _ready() -> void:
 z_index=-74
 texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
func setup(layout_script: Script) -> void:
 layout=layout_script
 planned=false
 spots=[]
 queue_redraw()
func _draw() -> void:
 if layout==null:return
 if not planned:spots=plan(layout);planned=true
 for spot in spots: paint(self,spot)
## 표지판 하나를 그린다(테스트에서도 같은 함수로 그린다).
static func paint(node: Node2D,spot: Dictionary) -> void:
 var at: Vector2=spot.at
 var width: float=float(spot.width)
 var height: float=float(spot.height)
 var accent: Color=spot.accent
 var box:=Rect2(at-Vector2(width*.5,height*.5),Vector2(width,height))
 # 1) 바닥에 스며든 부드러운 그림자(상자가 아니라 번지는 타원).
 node.draw_set_transform(Vector2(box.get_center().x,box.end.y-4.0),0,Vector2(1,.34))
 for i in range(3):
  node.draw_circle(Vector2.ZERO,width*(.52-float(i)*.10),Color(.01,.02,.04,.10-float(i)*.026))
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 # 2) 바닥 도료판: 아주 옅은 판 + 구역 색 좌측 띠 + 얇은 테두리.
 node.draw_rect(box,Color(.02,.03,.06,.18))
 node.draw_rect(Rect2(box.position,Vector2(4.0,box.size.y)),Color(accent.r,accent.g,accent.b,.65))
 node.draw_rect(Rect2(Vector2(box.position.x+5.0,box.position.y),Vector2(box.size.x-5.0,1.6)),Color(1,1,1,.12))
 # 3) 글자: 검은 외곽선 → 흰 본문 → 구역 색 밑줄.
 var text: String=String(spot.text)
 var font_size: int=int(spot.get("font",LABEL_SIZE))
 var pad_x: float=float(spot.get("pad_x",PAD_X))
 var baseline:=Vector2(box.position.x+pad_x,box.get_center().y+float(font_size)*.36)
 node.draw_string_outline(FONT,baseline,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,6,Color(.02,.02,.04,.85))
 node.draw_string(FONT,baseline,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color(1,1,1,.96))
 node.draw_rect(Rect2(Vector2(box.position.x+pad_x,box.end.y-5.0),Vector2(width-pad_x*2.0,2.0)),Color(accent.r,accent.g,accent.b,.75))
## 표지판 배치 계획. 벽·건물·사물을 피해 가장 넓은 빈 바닥을 고른다.
static func plan(layout_script: Script) -> Array:
 var zones: Array=layout_script.ZONES
 var hard: Array=layout_script.HARD
 var objects: Array=layout_script.OBJECTS
 var gimmicks: Array=layout_script.GIMMICKS
 var buildings: Array=layout_script.buildings()
 var blocks: Array=[]
 for rect in hard: blocks.append(rect)
 for entry in buildings:
  if entry.is_empty():continue
  blocks.append(entry.rect as Rect2)
  blocks.append((entry.interior as Rect2))
 for item in objects: blocks.append(Rect2((item.p as Vector2)-Vector2(26,26),Vector2(52,52)))
 for item in gimmicks:
  if item.has("rect"):blocks.append(item.rect as Rect2)
  else:blocks.append(Rect2((item.pos as Vector2)-Vector2(34,34),Vector2(68,68)))
 var result: Array=[]
 for zone in zones:
  var zone_rect: Rect2=zone.rect
  var text: String=String(zone.name)
  var accent: Color=zone.accent
  var chosen: Dictionary={}
  # 1) 정상 크기 → 2) 좁은 골목용 축소 크기 순으로 빈 바닥을 찾는다.
  for scale in [1.0,.82,.68]:
   var font_size:=maxi(19,int(round(float(LABEL_SIZE)*float(scale))))
   var pad_x:=PAD_X*float(scale)
   var pad_y:=PAD_Y*float(scale)
   var width: float=FONT.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x+pad_x*2.0+8.0
   var height: float=float(font_size)+pad_y*2.0
   var size:=Vector2(width,height)
   var at:=best_spot(zone_rect,size,blocks,result,zone.get("label_at",null))
   if at==Vector2.INF:continue
   chosen={"id":String(zone.id),"text":text,"at":at,"width":width,"height":height,
    "font":font_size,"pad_x":pad_x,"accent":accent,"rect":Rect2(at-size*.5,size)}
   break
  if not chosen.is_empty():result.append(chosen)
 return result
## 후보를 구역 안쪽 격자로 훑어 '장애물과 가장 먼' 자리를 고른다. 없으면 Vector2.INF.
static func best_spot(zone_rect: Rect2,size: Vector2,blocks: Array,placed: Array,hint: Variant=null) -> Vector2:
 var inset:=18.0
 var area:=zone_rect.grow(-inset)
 if area.size.x<size.x+8.0 or area.size.y<size.y+8.0:
  # 아주 좁은 골목·복도는 구역 경계를 조금 넘어도 된다(벽만 피하면 된다).
  area=zone_rect.grow(24.0)
 var best:=Vector2.INF
 var best_score:=-1.0
 var candidates: Array=[]
 if hint is Vector2:candidates.append(hint)
 candidates.append(zone_rect.get_center())
 var step:=42.0
 var y:=area.position.y+size.y*.5
 while y<=area.end.y-size.y*.5:
  var x:=area.position.x+size.x*.5
  while x<=area.end.x-size.x*.5:
   candidates.append(Vector2(x,y))
   x+=step
  y+=step
 for at in candidates:
  var box:=Rect2(at-size*.5,size)
  # 구역 안쪽을 우선하되, 좁은 골목이면 경계를 조금 넘어도 허용한다.
  var soft:=zone_rect.grow(10.0)
  if not soft.encloses(box):continue
  if collides(box,blocks,4.0):continue
  if collides(box,placed,GAP):continue
  var clearance:=clearance_of(box,blocks)
  var score:=clearance
  if not zone_rect.grow(-2.0).encloses(box):score-=40.0
  if hint is Vector2:score+=12.0-at.distance_to(hint)*.05
  if score>best_score:best_score=score;best=at
 return best
static func collides(box: Rect2,list: Array,pad: float) -> bool:
 for item in list:
  var rect: Rect2=(item.get("rect") if item is Dictionary else item) as Rect2
  if rect.size.x<=0.0 or rect.size.y<=0.0:continue
  if rect.grow(pad).intersects(box):return true
 return false
## 글자 상자에서 가장 가까운 장애물까지의 거리(가장자리 기준).
static func clearance_of(box: Rect2,blocks: Array) -> float:
 var best:=999.0
 for item in blocks:
  var rect: Rect2=(item.get("rect") if item is Dictionary else item) as Rect2
  if rect.size.x<=0.0 or rect.size.y<=0.0:continue
  var dx:=maxf(maxf(rect.position.x-box.end.x,box.position.x-rect.end.x),0.0)
  var dy:=maxf(maxf(rect.position.y-box.end.y,box.position.y-rect.end.y),0.0)
  best=minf(best,Vector2(dx,dy).length())
 return best
