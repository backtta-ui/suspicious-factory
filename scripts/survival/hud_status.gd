extends Control
## 인게임 상단 HUD(《도망가 친구들》 참고).
## 좌측: 내 초상화 + 목숨 하트 3개 + 달리기 기력 게이지(요괴는 추적자 배지).
## 우측: 참가자 생존·봉인·남은 하트 컴팩트 목록.
## 중앙: 봉인·구출·안전구역 축소 실시간 알림 배너.
const NAVY=Color("111a2e")
const NAVY_LIGHT=Color("1d2946")
const GOLD=Color("d9b878")
const GOLD_SOFT=Color("f3dfae")
const RED=Color("ef5a72")
const BLUE=Color("7fc4f0")
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const C=preload("res://scripts/survival/characters.gd")
const TITLE_FONT=preload("res://assets/fonts/WooTitle.otf")
var rules: RefCounted
var portrait: Texture2D
var character_name:=""
var role:="daoist"
var lives:=3
var max_lives:=3
var stamina:=100.0
var captured:=false
var eliminated:=false
var sealed_count:=0
var survivor_count:=0
var banner:=""
var banner_alpha:=0.0
var banner_color:=Color("ffe0a8")
## 2.0.30 지속 효과·버프·디버프 뱃지(이름 + 남은 초)와 마지막 시전 표시.
var buffs: Array=[]
var cast_name:=""
var cast_left:=0.0
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 resized.connect(queue_redraw)
func plate(rect: Rect2,radius: float) -> void:
 draw_rect(Rect2(rect.position+Vector2(0,3),rect.size),Color(.01,.02,.05,.45))
 rounded(rect.grow(2),GOLD.darkened(.45),radius+2)
 rounded(rect,GOLD,radius)
 rounded(rect.grow(-2),GOLD_SOFT,radius-1)
 rounded(rect.grow(-3),NAVY,radius-1)
 rounded(Rect2(rect.position+Vector2(3,3),Vector2(rect.size.x-6,rect.size.y*.42)),NAVY_LIGHT.lightened(.05),radius-2)
func rounded(rect: Rect2,color: Color,radius: float) -> void:
 var r:=maxf(1,minf(radius,minf(rect.size.x,rect.size.y)*.5))
 draw_rect(Rect2(rect.position+Vector2(r,0),rect.size-Vector2(r*2,0)),color)
 draw_rect(Rect2(rect.position+Vector2(0,r),rect.size-Vector2(0,r*2)),color)
 for corner in [rect.position+Vector2(r,r),Vector2(rect.end.x-r,rect.position.y+r),rect.position+Vector2(r,rect.size.y-r),rect.end-Vector2(r,r)]:
  draw_circle(corner,r,color)
## 하트 하나: filled=false면 빈 하트(잃은 목숨).
## 지속 효과·버프·디버프 뱃지: 왼쪽 상태판 아래에 이름·남은 초·남은 비율 바를 쌓는다.
func draw_buffs() -> void:
 if buffs.is_empty():return
 var top:=160.0
 var shown:=mini(buffs.size(),6)
 for i in range(shown):
  var entry: Dictionary=buffs[i]
  var name_value: String=String(entry.get("name",""))
  var tint:=Color(String(entry.get("color","ffe0a8")))
  var left:=maxf(0.0,float(entry.get("left",0.0)))
  var good:=bool(entry.get("good",true))
  var width: float=minf(232.0,74.0+name_value.length()*13.0)
  var rect:=Rect2(16,top+i*27.0,width,23)
  rounded(rect,Color(.03,.04,.09,.68),9)
  draw_rect(rect,Color(tint.r,tint.g,tint.b,.42),false,1.1)
  # 남은 시간을 얇은 채움 바로 깔아 준다.
  var ratio:=clampf(left/8.0,0.0,1.0)
  rounded(Rect2(rect.position+Vector2(1,rect.size.y-3.2),Vector2((rect.size.x-2)*ratio,2.2)),Color(tint.r,tint.g,tint.b,.55),1)
  draw_circle(Vector2(rect.position.x+11,rect.position.y+11.5),3.4,tint)
  draw_string(FONT,Vector2(rect.position.x+20,rect.position.y+16),name_value,HORIZONTAL_ALIGNMENT_LEFT,rect.size.x-58,12,Color("f4ecd8") if good else Color("ffd8cf"))
  draw_string(FONT,Vector2(rect.end.x-34,rect.position.y+16),("%d초"%int(ceil(left))) if left>=0.999 else "지속",HORIZONTAL_ALIGNMENT_RIGHT,30,11,Color(tint.r,tint.g,tint.b,.9))
func heart(center: Vector2,radius: float,filled: bool) -> void:
 var color:=RED if filled else Color(.30,.33,.44,.85)
 draw_circle(center+Vector2(-radius*.5,-radius*.35),radius*.55,color)
 draw_circle(center+Vector2(radius*.5,-radius*.35),radius*.55,color)
 draw_colored_polygon(PackedVector2Array([center+Vector2(-radius*.99,-radius*.12),center+Vector2(radius*.99,-radius*.12),center+Vector2(0,radius)]),color)
 if filled:draw_circle(center+Vector2(-radius*.55,-radius*.5),radius*.2,Color(1,1,1,.45))
 else:
  draw_arc(center+Vector2(-radius*.5,-radius*.35),radius*.55,0,TAU,16,color,1.2,true)
  draw_arc(center+Vector2(radius*.5,-radius*.35),radius*.55,0,TAU,16,color,1.2,true)
func _draw() -> void:
 var w:=size.x
 # ---------------------------------------------------------------- 좌측 내 상태
 var panel:=Rect2(10,8,312,106)
 plate(panel,18)
 var frame:=Rect2(20,16,86,86)
 draw_rect(frame.grow(3),Color(.02,.03,.06,.75))
 draw_rect(frame.grow(1),GOLD,false,1.6)
 if portrait!=null:
  draw_texture_rect(portrait,frame.grow(-2),false)
 else:
  draw_circle(frame.get_center(),26,Color("223052"))
  draw_circle(frame.get_center(),26,GOLD,false,1.6)
 if role=="yokai":
  # 요괴: 하트 대신 추적자 배지 + 봉인 준비 상태.
  var badge:=Rect2(114,20,124,24)
  rounded(badge,Color("3a1f2b"),12)
  rounded(badge,Color("c9556e"),10)
  draw_string(FONT,Vector2(badge.position.x+10,badge.position.y+17),"추적자 · 요괴",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("ffe6ec"))
 else:
  for i in range(max_lives):
   heart(Vector2(128+i*30,34),11,i<lives)
  draw_string(FONT,Vector2(222,40),"목숨 %d/%d"%[lives,max_lives],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("f4e6c6"))
 # 달리기 기력 게이지
 var bar:=Rect2(114,54,188,16)
 rounded(bar,Color(.05,.06,.10,.9),8)
 var ratio:=clampf(stamina/100.0,0,1)
 if ratio>0.01:
  rounded(Rect2(bar.position+Vector2(2,2),Vector2((bar.size.x-4)*ratio,bar.size.y-4)),BLUE.lerp(Color("a8f0d0"),ratio*.35),7)
 draw_rect(bar,GOLD.darkened(.25),false,1.4)
 draw_string(FONT,Vector2(114,88),"달리기 %d%%"%int(stamina),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("dceaff"))
 draw_string(FONT,Vector2(196,88),("봉인 %d"%sealed_count) if role=="yokai" else "생존 도사 %d"%survivor_count,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("f4e6c6"))
 draw_string(FONT,Vector2(114,104),(("탈락 · 관전") if eliminated else ("봉인됨" if captured else character_name)),HORIZONTAL_ALIGNMENT_LEFT,180,12,Color("ffd0d4") if (captured or eliminated) else Color("b9c6dd"))
 # ---------------------------------------------------------------- 지속 효과·버프·디버프 뱃지
 draw_buffs()
 # 마지막으로 쓴 도술 이름을 짧은 칩으로 남긴다(초상화 오른쪽 아래).
 if cast_left>0.01 and cast_name!="":
  # 2.0.31: 도술 이름만 짧게. '발동'까지 붙이면 패널 밖으로 넘쳐 잘렸다.
  var chip:=Rect2(240,86,minf(80.0,20.0+cast_name.length()*12.0),22)
  rounded(chip,Color(.06,.05,.09,.82),8)
  draw_rect(chip,Color(GOLD,.6),false,1.2)
  draw_string(FONT,Vector2(chip.position.x+8,chip.position.y+16),cast_name,HORIZONTAL_ALIGNMENT_LEFT,chip.size.x-14,12,Color(GOLD_SOFT))
 # ---------------------------------------------------------------- 우측 참가자 목록
 if rules!=null:
  var players: Array=rules.players.values()
  var rows:=players.size()
  var list:=Rect2(w-212,206,202,32+rows*23)
  plate(list,14)
  draw_string(FONT,Vector2(list.position.x+14,list.position.y+21),"참가자 · 생존 %d"%survivor_count,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("f0dcae"))
  for i in range(rows):
   var p: Dictionary=players[i]
   var y:=list.position.y+32+i*23
   var gone: bool=bool(p.get("eliminated",false))
   var catch: bool=bool(p.get("captured",false))
   var tint: Color=Color("c9d4ea")
   if gone:tint=Color(.55,.58,.68,.75)
   elif catch:tint=Color("e2b2ff")
   draw_circle(Vector2(list.position.x+16,y+7),4.2,Color("c9556e") if p.get("role","")=="yokai" else Color("7fc4f0"))
   var label: String=String(p.get("name",""))
   var piece: Dictionary=C.find(String(p.get("character","")))
   if p.get("id","")=="human":label="나"
   elif not piece.is_empty():label=String(piece.get("name",label))
   draw_string(FONT,Vector2(list.position.x+26,y+12),label,HORIZONTAL_ALIGNMENT_LEFT,74,11,tint)
   if gone:
    draw_string(FONT,Vector2(list.position.x+150,y+12),"탈락",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(.6,.62,.72))
   elif catch:
    draw_string(FONT,Vector2(list.position.x+118,y+12),"봉인",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("e2b2ff"))
   elif p.get("role","")=="daoist":
    var left:=int(p.get("lives",3))
    for k in range(max_lives):
     heart(Vector2(list.position.x+134+k*19,y+6),6,k<left)
   else:
    draw_string(FONT,Vector2(list.position.x+140,y+12),"추적자",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("f0a8b8"))
 # ---------------------------------------------------------------- 중앙 알림 배너
 if banner_alpha>0.01 and banner!="":
  var alpha:=clampf(banner_alpha,0,1)
  var extent:=620.0
  var box:=Rect2(w*.5-extent*.5,96,extent,38)
  draw_rect(Rect2(box.position+Vector2(0,2),box.size),Color(0,0,0,.35*alpha))
  rounded(box,Color(.05,.06,.10,.86*alpha),12)
  draw_rect(box,Color(banner_color.r,banner_color.g,banner_color.b,.55*alpha),false,1.6)
  draw_string(TITLE_FONT,Vector2(box.position.x,box.position.y+26),banner,HORIZONTAL_ALIGNMENT_CENTER,int(box.size.x),17,Color(banner_color.r,banner_color.g,banner_color.b,alpha))
