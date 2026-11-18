extends Control
## 캐릭터 선택 & 경기 준비 — 롤 스타일 직행 선택 화면.
## 왼쪽: 내 진영 캐릭터 카드 4장(금빛 발광 선택 테두리) / 가운데: 선택한 캐릭터의
## 인게임 원화 대형 프리뷰 / 오른쪽: 이름·역할·소개·주요 능력 3개·큰 선택 확정 버튼.
## 1280×720 디자인 좌표를 화면 높이에 맞춰 확대하고, 가로가 넓으면 가운데에 둔다.
const LC=preload("res://scripts/ui/lobby_theme.gd")
const LArt=preload("res://scripts/ui/lobby_art.gd")
const C=preload("res://scripts/survival/characters.gd")
const Market=preload("res://scripts/survival/market.gd")
const TITLE_FONT=preload("res://assets/fonts/WooTitle.otf")
const DESIGN=Vector2(1280,720)
var game: Node
var root_nodes: Array=[]
var card_id:=""
var preview_holder: Control
var timer_label: Label
var team_label: Label
var confirm_button: WooMobileButton
var built:=false
var selection_id:=""
var locked:=false

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_STOP
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 resized.connect(layout)
 build()
 built=true
 layout()

## app.gd가 rules·storage를 넣고 다시 그린다.
func setup(game_node: Node,selected: String,confirmed: bool) -> void:
 game=game_node
 selection_id=selected
 locked=confirmed
 if built:build();layout()

# ------------------------------------------------------------------ helpers
func place(node: Control,rect: Rect2) -> void:
 var parent:=node.get_parent()
 var base:=Vector2.ZERO
 if parent!=null and parent!=self and parent.has_meta("design"):
  base=(parent.get_meta("design") as Rect2).position
 node.set_meta("design",rect)
 node.set_meta("design_base",base)
 root_nodes.append(node)
 apply(node,rect,base)

func apply(node: Control,rect: Rect2,base: Vector2) -> void:
 var view:=get_viewport().get_visible_rect().size
 var s:=clampf(view.y/DESIGN.y,.45,3.4)
 var origin:=Vector2((view.x-DESIGN.x*s)*.5,0)
 var local:=(rect.position-base)*s
 node.position=(origin+local) if node.get_parent()==self else local
 node.size=rect.size*s
 if node is Label and node.has_meta("base_font"):
  node.add_theme_font_size_override("font_size",maxi(11,int(float(node.get_meta("base_font"))*s)))

func label(parent: Node,value: String,extent: float,color: Color,brush: bool=false) -> Label:
 var node:=Label.new()
 node.text=value
 node.mouse_filter=Control.MOUSE_FILTER_IGNORE
 node.add_theme_font_override("font",TITLE_FONT if brush else LC.FONT)
 node.add_theme_font_size_override("font_size",int(extent))
 node.add_theme_color_override("font_color",color)
 node.set_meta("base_font",extent)
 if brush:
  node.add_theme_color_override("font_shadow_color",Color(0,0,0,.6))
  node.add_theme_constant_override("shadow_offset_x",0)
  node.add_theme_constant_override("shadow_offset_y",2)
 parent.add_child(node)
 return node

func panel(parent: Node,rect: Rect2,glow: Color=Color(0,0,0,0)) -> Panel:
 var node:=Panel.new()
 node.mouse_filter=Control.MOUSE_FILTER_IGNORE
 node.add_theme_stylebox_override("panel",LC.panel_box(Color(0.028,0.034,0.072,0.93),16,Color(0.85,0.72,0.47,0.45),1,glow,18 if glow.a>0.0 else 0))
 parent.add_child(node)
 place(node,rect)
 var trim:=LArt.Filigree.new()
 trim.color=Color(0.85,0.72,0.47,0.4)
 trim.arm=20.0
 node.add_child(trim)
 return node

func button(caption: String,callback: Callable,parent: Node,primary: bool=false,font_size: int=18) -> WooMobileButton:
 var node: WooMobileButton=game.button(caption,callback,primary,parent)
 node.custom_minimum_size=Vector2.ZERO
 node.add_theme_font_size_override("font_size",font_size)
 for state in ["normal","hover","pressed","hover_pressed","disabled"]:
  node.add_theme_stylebox_override(state,LC.button_box(state,primary))
 var ink:=Color("2a1e0c") if primary else LC.IVORY
 for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color"]:
  node.add_theme_color_override(state,ink)
 node.add_theme_color_override("font_disabled_color",Color(0.90,0.84,0.68,0.95) if primary else Color(0.62,0.64,0.72,0.9))
 node.set_meta("base_font",font_size)
 return node

func me() -> Dictionary:
 return game.rules.players.human

func team() -> String:
 return String(me().get("role","daoist"))

func owned(id: String) -> bool:
 return game.storage.owns_character(id)

func money(value: int) -> String:
 return game.number(value)

# ------------------------------------------------------------------ build
func build() -> void:
 for child in get_children():child.queue_free()
 root_nodes.clear()
 if game==null:return
 var back:=LArt.Backdrop.new()
 back.mood=.6
 add_child(back)
 back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var scrim:=ColorRect.new()
 scrim.color=Color(.015,.018,.045,.42)
 scrim.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(scrim)
 scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var box:=panel(self,Rect2(0,0,DESIGN.x,DESIGN.y),Color(0,0,0,0))
 box.add_theme_stylebox_override("panel",LC.panel_box(Color(0,0,0,0),0,Color(0,0,0,0),0))
 _header()
 _cards()
 _preview()
 _detail()
 _footer()

func _header() -> void:
 var r=game.rules
 var daoists: int=int(r.players.size())-int(r.yokai_count)
 var back=button("← 뒤로",func()->void:game.back(),self,false,19)
 back.name="SelectionBack"
 place(back,Rect2(24,16,132,56))
 var title:=label(self,"캐릭터 선택",36,LC.GOLD_SOFT,true)
 place(title,Rect2(176,8,540,52))
 var sub:=label(self,"월하의 서원 · 8인 생존전",16,LC.MUTED)
 place(sub,Rect2(178,58,540,26))
 var mine: String=team()
 var badge:=label(self,"내 진영 · %s" % ("도사" if mine=="daoist" else "요괴"),18,Color(0.98,0.90,0.66) if mine=="daoist" else Color(0.86,0.78,1.0),true)
 badge.name="MySideBadge"
 badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 badge.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 badge.add_theme_stylebox_override("normal",LC.panel_box(Color(0.10,0.08,0.05,0.92) if mine=="daoist" else Color(0.09,0.06,0.14,0.92),24,Color(0.90,0.76,0.48,0.85) if mine=="daoist" else Color(0.72,0.58,1.0,0.85),2,Color(0,0,0,0),0))
 place(badge,Rect2(690,20,150,46))
 var roster:=label(self,"도사 %d명  :  요괴 %d명" % [daoists,int(r.yokai_count)],16,LC.GOLD_SOFT)
 roster.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 roster.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 roster.add_theme_stylebox_override("normal",LC.panel_box(Color(0.10,0.08,0.05,0.85),24,Color(0.90,0.76,0.48,0.8),1,Color(0,0,0,0),0))
 place(roster,Rect2(848,20,162,46))
 var ready:=label(self,"출발 준비",15,LC.MUTED)
 ready.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 place(ready,Rect2(1040,10,214,24))
 timer_label=label(self,"00:25",34,LC.GOLD_SOFT,true)
 timer_label.name="SelectionTimer"
 timer_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 place(timer_label,Rect2(1040,34,214,48))

func _cards() -> void:
 var frame:=panel(self,Rect2(24,104,392,572),Color(0.55,0.45,1.0,0.14))
 var heading:=label(frame,"%s 선택" % ("도사" if team()=="daoist" else "요괴"),19,LC.GOLD_SOFT,true)
 place(heading,Rect2(24+18,104+10,300,28))
 var note:=label(frame,"카드를 눌러 고르세요 · 같은 캐릭터도 허용됩니다",14,LC.MUTED)
 place(note,Rect2(24+18,104+38,356,22))
 var catalog:=C.catalog(team())
 for i in range(catalog.size()):
  var item: Dictionary=catalog[i]
  var id: String=String(item.id)
  var col:=i%2
  var row:=i/2
  var rect:=Rect2(24+16+col*(174+10),104+76+row*(186+10),174,186)
  _card(item,rect)
 team_label=label(frame,"",15,LC.MUTED)
 team_label.name="TeamSelection"
 place(team_label,Rect2(24+18,104+470,356,28))

func _card(item: Dictionary,rect: Rect2) -> void:
 var id: String=String(item.id)
 var owned_now:=owned(id)
 var card:=button("",func()->void:_pick(id),self,false,16)
 card.name="SelectCard_"+id.split(":")[1]
 place(card,rect)
 card.disabled=locked or not owned_now
 var art:=TextureRect.new()
 art.texture=load(String(item.portrait))
 art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 art.mouse_filter=Control.MOUSE_FILTER_IGNORE
 card.add_child(art)
 place(art,Rect2(rect.position.x+4,rect.position.y+4,rect.size.x-8,132))
 var fade:=TextureRect.new()
 fade.texture=LC.fade_texture(Color(0.03,0.035,0.08,0.0),Color(0.02,0.024,0.06,.97))
 fade.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 fade.stretch_mode=TextureRect.STRETCH_SCALE
 fade.mouse_filter=Control.MOUSE_FILTER_IGNORE
 card.add_child(fade)
 place(fade,Rect2(rect.position.x+4,rect.position.y+86,rect.size.x-8,50))
 var name_label:=label(card,String(item.name),18,LC.IVORY,true)
 name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 place(name_label,Rect2(rect.position.x+6,rect.position.y+134,rect.size.x-12,26))
 var role:=label(card,String(item.get("role","")),14,LC.MUTED)
 role.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 place(role,Rect2(rect.position.x+6,rect.position.y+160,rect.size.x-12,20))
 if not owned_now:
  var tag:=label(card,"미해금",14,Color(0.95,0.78,0.52))
  tag.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  tag.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
  tag.add_theme_stylebox_override("normal",LC.panel_box(Color(0.10,0.05,0.05,0.9),10,Color(0.85,0.45,0.4,0.8),1,Color(0,0,0,0),0))
  place(tag,Rect2(rect.position.x+8,rect.position.y+8,78,28))
 var chosen:=id==selection_id
 var box:=LC.lit_box(Color(0.22,0.16,0.06,0.95),14) if chosen else LC.panel_box(Color(0.035,0.042,0.085,0.92),14,Color(0.85,0.72,0.47,0.45),1)
 for state in ["normal","hover","pressed","hover_pressed","disabled"]:
  card.add_theme_stylebox_override(state,box)
 card.modulate=Color(1.03,1.02,1.0) if chosen else Color(0.92,0.93,1.0)
 if chosen:card_id=id

func _preview() -> void:
 var frame:=panel(self,Rect2(428,104,432,572),Color(0.62,0.5,1.0,0.16))
 var pedestal:=LArt.Pedestal.new()
 frame.add_child(pedestal)
 place(pedestal,Rect2(428+14,104+412,432-28,148))
 preview_holder=game.portrait(frame,selection_id,Vector2(384,470))
 place(preview_holder,Rect2(428+24,104+136,384,470))

func _detail() -> void:
 var spec:=C.find(selection_id)
 var frame:=panel(self,Rect2(872,104,384,572),Color(0.55,0.45,1.0,0.12))
 var name_label:=label(frame,String(spec.get("name","")),30,LC.GOLD_SOFT,true)
 place(name_label,Rect2(872+22,104+10,340,38))
 var team_chip:=label(frame,String(spec.get("team_name","")),16,Color(0.06,0.04,0.02))
 team_chip.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 team_chip.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 team_chip.add_theme_stylebox_override("normal",LC.panel_box(Color(0.90,0.78,0.52),10,Color(0,0,0,0),0))
 place(team_chip,Rect2(872+22,104+52,64,30))
 var role_chip:=label(frame,String(spec.get("role","")),16,Color(0.92,0.88,0.98))
 role_chip.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 role_chip.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 role_chip.add_theme_stylebox_override("normal",LC.panel_box(Color(0.14,0.11,0.24,0.95),10,Color(0.75,0.6,1.0,0.6),1,Color(0,0,0,0),0))
 place(role_chip,Rect2(872+94,104+52,170,30))
 var intro:=label(frame,String(spec.get("intro","")),17,Color(0.86,0.90,0.98))
 intro.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 place(intro,Rect2(872+22,104+88,340,56))
 var rule_line:=ColorRect.new()
 rule_line.color=Color(0.85,0.72,0.47,0.3)
 rule_line.mouse_filter=Control.MOUSE_FILTER_IGNORE
 frame.add_child(rule_line)
 place(rule_line,Rect2(872+22,104+150,340,1))
 var ability_head:=label(frame,"주요 능력",18,LC.GOLD_SOFT,true)
 place(ability_head,Rect2(872+22,104+156,220,26))
 var abilities: Array=spec.get("abilities",[])
 for i in range(mini(3,abilities.size())):
  var ability: Dictionary=abilities[i]
  var row_rect:=Rect2(872+18,104+188+i*100,348,92)
  var row:=panel(frame,row_rect,Color(0,0,0,0))
  row.add_theme_stylebox_override("panel",LC.panel_box(Color(0.05,0.055,0.11,0.85),12,Color(0.6,0.5,1.0,0.25),1))
  var ability_name:=label(row,String(ability.get("name","")),17,LC.GOLD_SOFT,true)
  place(ability_name,Rect2(row_rect.position.x+14,row_rect.position.y+6,200,24))
  var cd:=label(row,"쿨타임 %d초" % int(ability.get("cd",0.0)),15,LC.MUTED)
  cd.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
  place(cd,Rect2(row_rect.position.x+196,row_rect.position.y+6,138,24))
  var desc:=label(row,String(ability.get("description","")),15,Color(0.82,0.86,0.94))
  desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  place(desc,Rect2(row_rect.position.x+14,row_rect.position.y+32,320,56))
 var locked_now:=locked or bool(me().get("confirmed",false))
 confirm_button=button("확정 완료 · 팀원 대기" if locked_now else "선택 확정",func()->void:game.confirm_selection(selection_id,self),self,true,22)
 confirm_button.name="SelectionConfirm"
 confirm_button.disabled=locked_now or not owned(selection_id)
 place(confirm_button,Rect2(872+22,104+508,340,62))

func _footer() -> void:
 var tip:=label(self,"상대팀 캐릭터는 경기 시작 때 공개됩니다 · 확정 후에는 변경할 수 없습니다",14,Color(0.78,0.82,0.92,0.95))
 tip.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 place(tip,Rect2(24,684,1232,24))

# ------------------------------------------------------------------ actions
func _pick(id: String) -> void:
 if locked:return
 if not owned(id):return
 if game.rules.select_character("human",id):
  selection_id=id
  game.selection_id=id
  game.build("selection")

func set_timer(left: float) -> void:
 if is_instance_valid(timer_label):
  var seconds:=maxi(0,int(ceil(left)))
  timer_label.text="00:%02d" % seconds

func set_team(stats: Dictionary) -> void:
 if not is_instance_valid(team_label):return
 team_label.text="팀원 확정 %d / %d  ·  나머지는 자동 배정" % [int(stats.get("done",0)),int(stats.get("total",0))]

# ------------------------------------------------------------------ layout
func layout() -> void:
 if not built:return
 var view:=get_viewport().get_visible_rect().size
 if view.y<=1.0:return
 for node in root_nodes:
  if not is_instance_valid(node):continue
  apply(node,node.get_meta("design"),node.get_meta("design_base",Vector2.ZERO))
