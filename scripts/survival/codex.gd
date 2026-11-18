extends Control
## 캐릭터 안내 (도감) — the lobby's 캐릭터 button opens this screen.
## Read-only roster: tabs filter the grid, a card swaps the standing figure and the
## detail panel, and an ability row reveals its cooldown and full description.
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const TITLE_FONT=preload("res://assets/fonts/WooTitle.otf")
const BG=preload("res://assets/woo/codex/codex_bg.jpg")
const GLOW=preload("res://assets/woo/light.png")
const AURA=preload("res://assets/woo/codex/aura.png")
const C=preload("res://scripts/survival/characters.gd")
const BG_SIZE=Vector2(1672,941)
## Where the painted stone dais sits inside the backdrop, as a fraction of the image.
const DAIS=Vector2(.5,.79)
const GOLD=Color("f0d79b")
const GOLD_DEEP=Color("b08f4f")
const TEXT=Color("f7f0e2")
const MUTED=Color("c2b6d8")
const INK=Color(.045,.04,.105,.9)
const VIOLET=Color("8b6bd6")
const DAOIST_COLOR=Color("f0d79b")
const YOKAI_COLOR=Color("cfa9ff")
const DESIGN_HEIGHT=720.0
const MARGIN=28.0
const CARD_SIZE=Vector2(126,176)
const CARD_GAP=10.0
const GRID_Y=130.0
const PANEL_W=344.0
const PANEL_Y=88.0
const PANEL_H=576.0
const GUIDE_Y=508.0
const GUIDE_H=152.0
const STAND_H=340.0
const FILTERS=[{"id":"all","label":"전체","icon":""},{"id":"daoist","label":"도사 (생존/지원)","icon":"talisman"},{"id":"yokai","label":"요괴 (추적/봉인)","icon":"mask"}]
const WATERMARK_CODE="""shader_type canvas_item;
uniform float strength = 0.18;
void fragment() {
 vec4 art = texture(TEXTURE, UV);
 float d = distance(UV, vec2(0.5, 0.42));
 art.a *= smoothstep(0.62, 0.10, d) * strength;
 COLOR = art;
}
"""
var game: Node
var filter:="all"
var selected_id:=""
var selected: Dictionary={}
var cards: Dictionary={}
var tabs: Dictionary={}
var grid: Control
var detail: Control
var detail_panel: Panel
var detail_name: Label
var detail_team: Panel
var detail_team_label: Label
var detail_role: Panel
var detail_role_label: Label
var detail_intro: Label
var watermark: TextureRect
var ability_root: Control
var tip: Panel
var tip_name: Label
var tip_meta: Label
var tip_body: Label
var hint: Label
var stand: TextureRect
var stand_shadow: TextureRect
var stand_glow: TextureRect
var aura: TextureRect
var dais_glow: TextureRect
var bg: TextureRect
var trim: Frame
var title_label: Label
var subtitle: Label
var back_button: WooMobileButton
var back_arrow: Label
var guide: Panel
var active_ability:=-1
var clock:=0.0
var motion: Tween
## Every scaled control registers its 720px design rectangle here.
var design: Array=[]

## Draws one sheet icon inside a painted circular badge.
class Painted extends Control:
 const SHEET=preload("res://assets/woo/v20/skills.png")
 const INDEX={"attack":0,"jump":1,"dodge":2,"talisman":3,"jar":4,"transform":4,"blink":5,"clone":6,"track":7,"shield":8,"smoke":9,"mask":10,"rescue":11,"capture":12,"darkness":13,"fake_flame":14,"shadow":15}
 var icon:=""
 var ring:=Color("f0d79b")
 var ring2:=Color("8b6bd6")
 var fill:=Color(.10,.07,.20,.95)
 var ring_width:=1.6
 var bare:=false
 var pulse:=0.0
 func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
 func _draw() -> void:
  var radius:=minf(size.x,size.y)*.5
  var center:=size*.5
  if not bare:
   if pulse>0.0:draw_circle(center,radius+2.0+pulse*4.0,Color(ring2.r,ring2.g,ring2.b,.16*pulse))
   draw_circle(center,radius,Color(ring2.r,ring2.g,ring2.b,.12))
   draw_circle(center,radius*.92,fill)
   draw_arc(center,maxf(0.0,radius-1.0),0,TAU,48,ring,ring_width,true)
   draw_arc(center,maxf(0.0,radius-3.0),-PI*.7,PI*.4,32,Color(ring2.r,ring2.g,ring2.b,.75),1.0,true)
  var index: int=INDEX.get(icon,-1)
  if index<0:return
  var cell:=Vector2(SHEET.get_width()/4.0,SHEET.get_height()/4.0)
  var extent:=radius*(1.68 if not bare else 2.05)
  draw_texture_rect_region(SHEET,Rect2(center-Vector2.ONE*extent*.5,Vector2.ONE*extent),Rect2(Vector2(index%4,floori(index/4.0))*cell,cell),Color.WHITE)
  if pulse>0.0:draw_arc(center,radius+2.0,0,TAU,48,Color(ring.r,ring.g,ring.b,.5*pulse),1.6,true)

## Painted gold frame, corner flourishes and the title rule.
class Frame extends Control:
 var accent:=Color("f0d79b")
 var title_box:=Rect2()
 func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
 func _draw() -> void:
  var inset:=12.0
  var border:=Rect2(Vector2(inset,inset),size-Vector2(inset*2,inset*2))
  draw_rect(border,Color(accent.r,accent.g,accent.b,.16),false,1.0)
  var arm:=26.0
  for corner in [[border.position,Vector2(1,1)],[Vector2(border.end.x,border.position.y),Vector2(-1,1)],[Vector2(border.position.x,border.end.y),Vector2(1,-1)],[border.end,Vector2(-1,-1)]]:
   var p: Vector2=corner[0];var d: Vector2=corner[1]
   draw_line(p,p+Vector2(arm*d.x,0),accent,2.0,true)
   draw_line(p,p+Vector2(0,arm*d.y),accent,2.0,true)
   draw_circle(p+Vector2(4*d.x,4*d.y),2.2,accent)
  var y:=title_box.position.y
  if title_box.size.x>0.0:
   draw_line(Vector2(title_box.position.x,y),Vector2(title_box.position.x+title_box.size.x,y),Color(accent.r,accent.g,accent.b,.45),1.0,true)
   diamond(Vector2(title_box.position.x-9,y),3.6)
   diamond(Vector2(title_box.position.x+title_box.size.x+9,y),3.6)
  draw_line(Vector2(inset+16,size.y-inset),Vector2(size.x-inset-16,size.y-inset),Color(accent.r,accent.g,accent.b,.12),1.0,true)
  diamond(Vector2(size.x*.5,size.y-inset),3.0)
 func diamond(center: Vector2,radius: float) -> void:
  draw_colored_polygon(PackedVector2Array([center+Vector2(0,-radius),center+Vector2(radius*.62,0),center+Vector2(0,radius),center+Vector2(-radius*.62,0)]),accent)

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_STOP
 _build()
 resized.connect(_layout)
 _layout()

func _process(delta: float) -> void:
 clock+=delta
 if is_instance_valid(stand_glow):stand_glow.modulate.a=.22+sin(clock*1.6)*.05
 if is_instance_valid(dais_glow):dais_glow.modulate.a=.20+sin(clock*1.1+1.2)*.05
 if is_instance_valid(aura):
  aura.rotation=sin(clock*.5)*.06
  aura.modulate.a=.72+sin(clock*2.1)*.08

# ------------------------------------------------------------------ helpers
func flat(fill_color: Color,border: Color=Color(0,0,0,0),width: int=0,radius: int=10) -> StyleBoxFlat:
 var box:=StyleBoxFlat.new();box.bg_color=fill_color;box.border_color=border;box.set_border_width_all(width);box.set_corner_radius_all(radius)
 box.content_margin_left=0;box.content_margin_right=0;box.content_margin_top=0;box.content_margin_bottom=0
 return box

## Rounded deep-navy panel with a coloured outer glow and a gold rim.
func glass(fill_color: Color,border: Color,radius: int,glow: Color) -> StyleBoxFlat:
 var box:=flat(fill_color,border,1,radius)
 box.shadow_color=glow;box.shadow_size=16
 box.shadow_offset=Vector2(0,2)
 return box

## Registers a control's 720px design rectangle; _layout applies it scaled.
func place(node: Control,rect: Rect2) -> void:
 node.set_meta("design",rect)
 if not design.has(node):design.append(node)
 _apply(node,rect,get_viewport().get_visible_rect().size.y/DESIGN_HEIGHT)

func _apply(node: Control,rect: Rect2,s: float) -> void:
 node.position=rect.position*s;node.size=rect.size*s
 if node is Label and node.has_meta("base_font"):
  node.add_theme_font_size_override("font_size",maxi(10,int(float(node.get_meta("base_font"))*s)))

func label_text(parent: Node,value: String,extent: float,color: Color,weight: bool=false) -> Label:
 var node:=Label.new();node.text=value;node.mouse_filter=Control.MOUSE_FILTER_IGNORE
 node.add_theme_font_override("font",TITLE_FONT if weight else FONT);node.add_theme_font_size_override("font_size",int(extent))
 node.add_theme_color_override("font_color",color);node.set_meta("base_font",extent)
 if weight:
  node.add_theme_color_override("font_shadow_color",Color(0,0,0,.6))
  node.add_theme_constant_override("shadow_offset_x",0);node.add_theme_constant_override("shadow_offset_y",2)
 parent.add_child(node);return node

func button(caption: String,callback: Callable,parent: Control) -> WooMobileButton:
 var node: WooMobileButton=game.button(caption,callback,false,parent)
 for state in ["normal","hover","pressed","hover_pressed","disabled"]:node.add_theme_stylebox_override(state,flat(Color(0,0,0,0)))
 for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_disabled_color"]:node.add_theme_color_override(state,Color(0,0,0,0))
 node.custom_minimum_size=Vector2.ZERO
 return node

func rule(parent: Node,color: Color) -> ColorRect:
 var node:=ColorRect.new();node.color=color;node.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(node);return node

func soft(parent: Node,color: Color,rect: Rect2) -> TextureRect:
 var node:=TextureRect.new();node.texture=GLOW;node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;node.stretch_mode=TextureRect.STRETCH_SCALE
 node.modulate=color;node.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(node);place(node,rect);return node

## Darkened corners keep the eye on the roster, like a painted key art frame.
func vignette() -> void:
 var gradient:=Gradient.new()
 gradient.set_color(0,Color(0,0,0,0));gradient.set_color(1,Color(.02,.01,.06,.55))
 gradient.set_offset(0,.55);gradient.set_offset(1,1.0)
 var texture:=GradientTexture2D.new();texture.gradient=gradient;texture.fill=GradientTexture2D.FILL_RADIAL
 texture.fill_from=Vector2(.5,.5);texture.fill_to=Vector2(1.02,.5);texture.width=256;texture.height=256
 var node:=TextureRect.new();node.texture=texture;node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;node.stretch_mode=TextureRect.STRETCH_SCALE;node.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(node)

func shade(from: Vector2,to: Vector2,start: Color,end: Color,fade: Vector2) -> void:
 var gradient:=Gradient.new()
 gradient.set_color(0,start);gradient.set_color(1,end)
 gradient.set_offset(0,fade.x);gradient.set_offset(1,minf(1.0,fade.y))
 var texture:=GradientTexture2D.new();texture.gradient=gradient;texture.fill_from=from;texture.fill_to=to;texture.width=8;texture.height=256
 var node:=TextureRect.new();node.texture=texture;node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;node.stretch_mode=TextureRect.STRETCH_SCALE;node.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(node)

# ------------------------------------------------------------------ build
func _build() -> void:
 bg=TextureRect.new();bg.texture=BG;bg.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;bg.stretch_mode=TextureRect.STRETCH_SCALE;bg.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(bg)
 shade(Vector2(0,0),Vector2(0,1),Color(.05,.03,.12,.55),Color(0,0,0,0),Vector2(0,.22))
 shade(Vector2(0,1),Vector2(0,0),Color(.04,.03,.10,.55),Color(0,0,0,0),Vector2(.62,1))
 shade(Vector2(0,0),Vector2(1,0),Color(.05,.03,.12,.45),Color(0,0,0,0),Vector2(0,.26))
 vignette()
 trim=Frame.new();add_child(trim)
 dais_glow=soft(self,Color(1,.82,.48,.2),Rect2(0,0,1,1))
 stand_glow=soft(self,Color(.55,.5,1,.22),Rect2(0,0,1,1))
 aura=TextureRect.new();aura.texture=AURA;aura.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;aura.stretch_mode=TextureRect.STRETCH_SCALE;aura.modulate=Color(1,1,1,.72);aura.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(aura)
 stand_shadow=soft(self,Color(0,0,0,.6),Rect2(0,0,1,1))
 stand=TextureRect.new();stand.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;stand.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;stand.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(stand)
 grid=Control.new();grid.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(grid)
 _build_guide()
 _build_detail()
 _build_header()
 _refresh_grid()
 _select("daoist:woochi")

func _build_header() -> void:
 title_label=label_text(self,"캐릭터 안내",36,GOLD,true)
 subtitle=label_text(self,"게임에 등장하는 도사와 요괴를 확인하세요.",16,Color("ddd2f0"))
 back_button=button("",func()->void:game.back(),self)
 back_button.name="CodexBack"
 var disc:=Panel.new();disc.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var disc_box:=glass(Color(.09,.07,.20,.95),Color(1,.88,.62,.95),24,Color(VIOLET.r,VIOLET.g,VIOLET.b,.5))
 disc_box.set_border_width_all(2)
 disc.add_theme_stylebox_override("panel",disc_box)
 back_button.add_child(disc);disc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 back_arrow=label_text(back_button,"←",28,TEXT)
 back_arrow.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;back_arrow.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 place(back_arrow,Rect2(0,0,64,64))
 for spec in FILTERS:
  var key: String=spec.id
  var target:=button("",func()->void:_set_filter(key),self)
  target.name="CodexTab_"+key
  var pill:=Panel.new();pill.mouse_filter=Control.MOUSE_FILTER_IGNORE;target.add_child(pill);pill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  var text:=label_text(target,spec.label,17,TEXT)
  text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
  var badge: Painted=null
  if spec.icon!="":
   badge=Painted.new();badge.icon=spec.icon;badge.bare=true;target.add_child(badge)
   place(text,Rect2(38,0,float(spec.label.length())*17.6+24.0,44))
  else:place(text,Rect2(0,0,float(spec.label.length())*17.6+40.0,44))
  tabs[key]={"button":target,"pill":pill,"label":text,"icon":badge,"width":float(spec.label.length())*17.6+66.0}
 _paint_tabs()

func _build_guide() -> void:
 guide=Panel.new();guide.name="CodexRoleGuide";guide.mouse_filter=Control.MOUSE_FILTER_IGNORE
 guide.add_theme_stylebox_override("panel",glass(INK,Color(GOLD.r,GOLD.g,GOLD.b,.4),14,Color(VIOLET.r,VIOLET.g,VIOLET.b,.28)));add_child(guide)
 place(label_text(guide,"역할 안내",17,GOLD),Rect2(18,7,200,26))
 place(rule(guide,Color(GOLD.r,GOLD.g,GOLD.b,.24)),Rect2(18,38,500,1))
 for row in [{"icon":"talisman","title":"도사 (6명)","body":"술래를 따돌리고, 봉인을 막으며 생존하세요","y":48.0,"color":DAOIST_COLOR},
  {"icon":"mask","title":"요괴 (2명)","body":"도사를 추적해 봉인하고, 모두 봉인하면 승리합니다","y":100.0,"color":YOKAI_COLOR}]:
  var icon:=Painted.new();icon.icon=row.icon;icon.ring=row.color;icon.bare=true;guide.add_child(icon);place(icon,Rect2(16,row.y+2,30,30))
  place(label_text(guide,row.title,18,row.color,true),Rect2(56,row.y,200,26))
  place(label_text(guide,row.body,15.5,MUTED),Rect2(56,row.y+25,474,24))

func _build_detail() -> void:
 detail=Control.new();detail.name="CodexDetail";detail.mouse_filter=Control.MOUSE_FILTER_PASS;detail.clip_contents=true;add_child(detail)
 detail_panel=Panel.new();detail_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 detail_panel.add_theme_stylebox_override("panel",glass(INK,Color(GOLD.r,GOLD.g,GOLD.b,.45),14,Color(VIOLET.r,VIOLET.g,VIOLET.b,.4)))
 detail.add_child(detail_panel);detail_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 watermark=TextureRect.new();watermark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;watermark.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;watermark.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var shader:=Shader.new();shader.code=WATERMARK_CODE
 var material:=ShaderMaterial.new();material.shader=shader;material.set_shader_parameter("strength",0.17);watermark.material=material
 watermark.modulate=Color(.82,.68,1,1)
 detail.add_child(watermark);place(watermark,Rect2(140,-14,200,200))
 detail_name=label_text(detail,"",30,GOLD,true);place(detail_name,Rect2(24,8,220,42))
 detail_team=Panel.new();detail_team.mouse_filter=Control.MOUSE_FILTER_IGNORE;detail.add_child(detail_team);place(detail_team,Rect2(24,54,56,26))
 detail_team_label=label_text(detail_team,"도사",15,Color("231a0c"))
 detail_team_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 detail_team_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;detail_team_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 detail_role=Panel.new();detail_role.mouse_filter=Control.MOUSE_FILTER_IGNORE;detail.add_child(detail_role);place(detail_role,Rect2(88,54,96,26))
 detail_role_label=label_text(detail_role,"",15,Color("efe2ff"))
 detail_role_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 detail_role_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;detail_role_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 detail_intro=label_text(detail,"",15.5,MUTED);detail_intro.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;place(detail_intro,Rect2(24,90,300,64))
 place(rule(detail,Color(GOLD.r,GOLD.g,GOLD.b,.26)),Rect2(24,160,300,1))
 place(label_text(detail,"✦  주요 능력",18,GOLD,true),Rect2(24,166,220,28))
 ability_root=Control.new();ability_root.mouse_filter=Control.MOUSE_FILTER_PASS;detail.add_child(ability_root)
 hint=label_text(detail,"능력을 누르면 쿨타임과 상세 설명이 표시됩니다.",14.5,MUTED);hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 place(hint,Rect2(24,484,300,40))
 tip=Panel.new();tip.mouse_filter=Control.MOUSE_FILTER_IGNORE
 tip.add_theme_stylebox_override("panel",glass(Color(.09,.07,.20,.97),Color(GOLD.r,GOLD.g,GOLD.b,.6),10,Color(VIOLET.r,VIOLET.g,VIOLET.b,.45)))
 detail.add_child(tip);place(tip,Rect2(14,466,316,104))
 tip_name=label_text(tip,"",17,GOLD,true);place(tip_name,Rect2(14,7,286,26))
 tip_meta=label_text(tip,"",14.5,MUTED);place(tip_meta,Rect2(14,32,286,20))
 tip_body=label_text(tip,"",15,TEXT);tip_body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;place(tip_body,Rect2(14,54,288,48))
 tip.hide()

func _fill_detail() -> void:
 detail_name.text=selected.get("name","")
 detail_team_label.text=selected.get("team_name","")
 detail_team.add_theme_stylebox_override("panel",flat(DAOIST_COLOR if selected.get("team","")=="daoist" else YOKAI_COLOR,Color(0,0,0,0),0,11))
 detail_role_label.text=selected.get("role","")
 var role_width:=FONT.get_string_size(selected.get("role",""),HORIZONTAL_ALIGNMENT_LEFT,-1,15).x+28
 place(detail_role,Rect2(88,54,maxf(76.0,role_width),26))
 detail_intro.text=selected.get("intro","")
 var portrait_path:=String(selected.get("portrait",""))
 if portrait_path!="" and ResourceLoader.exists(portrait_path):watermark.texture=load(portrait_path)
 for child in ability_root.get_children():child.free()
 active_ability=-1
 tip.hide();hint.show()
 var abilities: Array=selected.get("abilities",[])
 for i in range(abilities.size()):_ability_row(i,abilities[i])
 _layout()

func _ability_row(index: int,ability: Dictionary) -> void:
 var target:=button("",func()->void:_show_tip(index),ability_root)
 target.name="CodexAbility_%d"%index
 place(target,Rect2(12,196.0+index*94.0,320,90))
 var badge:=Painted.new();badge.icon=ability.get("icon","");target.add_child(badge);place(badge,Rect2(12,20,44,44))
 var title:=label_text(target,ability.get("name",""),17,TEXT);place(title,Rect2(64,4,206,24))
 var body:=label_text(target,ability.get("description",""),15,MUTED)
 body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;place(body,Rect2(64,30,238,56))
 place(label_text(target,"%d초"%int(ability.get("cd",0.0)),15,GOLD_DEEP),Rect2(262,4,52,24))
 target.set_meta("badge",badge);target.set_meta("title",title)
 target.mouse_entered.connect(func()->void:_hover_row(index,true))
 target.mouse_exited.connect(func()->void:_hover_row(index,false))
 _paint_row(target,false,false)

func _rows() -> Array:
 return ability_root.get_children().filter(func(node: Node)->bool:return node is WooMobileButton)

func _hover_row(index: int,inside: bool) -> void:
 if index==active_ability:return
 var rows:=_rows()
 if index>=rows.size():return
 _paint_row(rows[index],inside,false)

func _paint_row(row: WooMobileButton,hover: bool,active: bool) -> void:
 var quiet:=flat(Color(1,1,1,.04),Color(VIOLET.r,VIOLET.g,VIOLET.b,.18),1,10)
 var lit:=glass(Color(.42,.30,.62,.34),Color(GOLD.r,GOLD.g,GOLD.b,.9 if active else .6),10,Color(VIOLET.r,VIOLET.g,VIOLET.b,.45))
 row.add_theme_stylebox_override("normal",lit if active else quiet)
 row.add_theme_stylebox_override("hover",lit)
 row.add_theme_stylebox_override("pressed",lit)
 row.add_theme_stylebox_override("hover_pressed",lit)
 row.add_theme_stylebox_override("disabled",quiet)
 var badge: Painted=row.get_meta("badge")
 badge.pulse=1.0 if active else 0.0;badge.queue_redraw()
 var title: Label=row.get_meta("title")
 title.add_theme_color_override("font_color",GOLD if active or hover else TEXT)

func _show_tip(index: int) -> void:
 var abilities: Array=selected.get("abilities",[])
 if index<0 or index>=abilities.size():return
 active_ability=index
 var ability: Dictionary=abilities[index]
 tip_name.text=ability.get("name","")
 var owned: bool=String(ability.get("key",""))!="" and ability.get("key","")==selected.get("active","")
 tip_meta.text=("쿨타임 %d초 · "%int(ability.get("cd",0.0)))+("전투 중 사용하는 대표 능력" if owned else "보조 능력 · 상황에 맞춰 활용")
 tip_body.text=ability.get("description","")
 tip.show();hint.hide()
 var rows:=_rows()
 for i in range(rows.size()):_paint_row(rows[i],i==index,i==index)
 if is_instance_valid(motion):motion.kill()
 tip.modulate.a=0
 motion=create_tween();motion.tween_property(tip,"modulate:a",1.0,.12)

# ------------------------------------------------------------------ roster
func _entries() -> Array:
 return C.catalog("daoist") if filter=="daoist" else (C.catalog("yokai") if filter=="yokai" else C.roster())

func _refresh_grid() -> void:
 for child in grid.get_children():child.free()
 cards.clear()
 var entries:=_entries()
 for i in range(entries.size()):
  var entry: Dictionary=entries[i]
  var id: String=entry.id
  var target:=button("",func()->void:_select(id),grid)
  target.name="CodexCard_"+id.split(":")[1]
  var row_offset:=0.0 if entries.size()>4 else (CARD_SIZE.y+CARD_GAP)*.5
  place(target,Rect2((i%4)*(CARD_SIZE.x+CARD_GAP),row_offset+float(i/4)*(CARD_SIZE.y+CARD_GAP),CARD_SIZE.x,CARD_SIZE.y))
  var art:=TextureRect.new();art.texture=load(entry.get("portrait",entry.get("sprite","")));art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;art.mouse_filter=Control.MOUSE_FILTER_IGNORE
  target.add_child(art);place(art,Rect2(0,0,CARD_SIZE.x,CARD_SIZE.y))
  var fade:=shade_child(Color(.03,.02,.08,0),Color(.03,.02,.08,.92))
  target.add_child(fade);place(fade,Rect2(0,CARD_SIZE.y-72,CARD_SIZE.x,72))
  var plate:=ColorRect.new();plate.color=Color(.02,.015,.06,.34);plate.mouse_filter=Control.MOUSE_FILTER_IGNORE;target.add_child(plate)
  place(plate,Rect2(0,CARD_SIZE.y-36,CARD_SIZE.x,36))
  var edge:=rule(target,Color(GOLD.r,GOLD.g,GOLD.b,.35));place(edge,Rect2(14,CARD_SIZE.y-37,CARD_SIZE.x-28,1))
  var name_label:=label_text(target,entry.get("name",""),17,TEXT)
  name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;name_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
  place(name_label,Rect2(0,CARD_SIZE.y-36,CARD_SIZE.x,34))
  var sheen:=soft(target,Color(1,.86,.55,.0),Rect2(-16,-40,CARD_SIZE.x+32,120))
  target.set_meta("sheen",sheen);target.set_meta("name",name_label);target.set_meta("id",id)
  cards[id]=target
 _paint_cards()

## Vertical fade used at the bottom of a card.
func shade_child(start: Color,end: Color) -> TextureRect:
 var gradient:=Gradient.new()
 gradient.set_color(0,start);gradient.set_color(1,end)
 var texture:=GradientTexture2D.new();texture.gradient=gradient;texture.fill_from=Vector2(0,0);texture.fill_to=Vector2(0,1);texture.width=8;texture.height=128
 var node:=TextureRect.new();node.texture=texture;node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;node.stretch_mode=TextureRect.STRETCH_SCALE;node.mouse_filter=Control.MOUSE_FILTER_IGNORE
 return node

func _paint_cards() -> void:
 for id in cards:
  if not is_instance_valid(cards[id]):continue
  var card: WooMobileButton=cards[id]
  var chosen: bool=id==selected_id
  if chosen:
   var box:=glass(Color(.16,.10,.26,.62),Color(GOLD.r,GOLD.g,GOLD.b,.95),2,10)
   box.set_border_width_all(2)
   box.shadow_color=Color(GOLD.r,GOLD.g,GOLD.b,.55);box.shadow_size=18
   for state in ["normal","hover","pressed","hover_pressed","disabled"]:card.add_theme_stylebox_override(state,box)
  else:
   var box:=flat(Color(.05,.04,.12,.55),Color(VIOLET.r,VIOLET.g,VIOLET.b,.4),1,10)
   box.shadow_color=Color(VIOLET.r,VIOLET.g,VIOLET.b,.18);box.shadow_size=8
   for state in ["normal","hover","pressed","hover_pressed","disabled"]:card.add_theme_stylebox_override(state,box)
  var sheen: TextureRect=card.get_meta("sheen");sheen.modulate.a=.5 if chosen else .0
  var name_label: Label=card.get_meta("name");name_label.add_theme_color_override("font_color",GOLD if chosen else TEXT)

func _set_filter(id: String) -> void:
 filter=id
 _refresh_grid()
 var entries:=_entries()
 if not entries.is_empty():_select(entries[0].id)
 _paint_tabs()

func _paint_tabs() -> void:
 for key in tabs:
  var spec: Dictionary=tabs[key]
  var chosen: bool=key==filter
  var pill: Panel=spec.pill
  if chosen:
   var box:=flat(Color(.80,.62,.32,.94),Color(1,.92,.72,.95),1,18)
   box.shadow_color=Color(GOLD.r,GOLD.g,GOLD.b,.6);box.shadow_size=18
   pill.add_theme_stylebox_override("panel",box)
  else:
   var box:=glass(Color(.07,.05,.16,.8),Color(VIOLET.r,VIOLET.g,VIOLET.b,.55),18,Color(VIOLET.r,VIOLET.g,VIOLET.b,.3))
   pill.add_theme_stylebox_override("panel",box)
  var text: Label=spec.label
  text.add_theme_color_override("font_color",Color("2a1e0c") if chosen else Color("ded2f2"))
  var badge: Painted=spec.icon
  if badge!=null:
   badge.ring=Color("2a1e0c") if chosen else GOLD_DEEP
   badge.ring2=Color("7a5b2a") if chosen else VIOLET
   badge.queue_redraw()

func _select(id: String) -> void:
 var entry:=C.find(id)
 if entry.is_empty():return
 selected_id=id
 selected=entry
 _paint_cards()
 _fill_detail()
 _set_stand(entry)

func _set_stand(entry: Dictionary) -> void:
 var texture: Texture2D=load(entry.get("sprite",""))
 if texture==null:return
 stand.texture=texture
 if is_instance_valid(motion):motion.kill()
 stand.modulate.a=0
 motion=create_tween()
 motion.set_parallel(true)
 motion.tween_property(stand,"modulate:a",1.0,.24)
 _layout()

# ------------------------------------------------------------------ layout
func _layout() -> void:
 var view:=get_viewport().get_visible_rect().size
 if view.y<=1.0:return
 var s:=view.y/DESIGN_HEIGHT
 var w:=view.x
 var scale_factor:=maxf(w/BG_SIZE.x,view.y/BG_SIZE.y)*1.15
 var drawn:=BG_SIZE*scale_factor
 var panel_x:=w-MARGIN*s-PANEL_W*s
 var grid_w:=CARD_SIZE.x*4.0+CARD_GAP*3.0
 var center_x:=(MARGIN*s+grid_w*s+panel_x)*.5
 var feet:=586.0*s
 var origin:=Vector2(clampf(center_x-DAIS.x*drawn.x,w-drawn.x,0.0),clampf(feet-DAIS.y*drawn.y,view.y-drawn.y,0.0))
 bg.position=origin;bg.size=drawn
 for node in get_children():
  if node is TextureRect and node!=bg and node!=stand and node!=stand_glow and node!=stand_shadow and node!=dais_glow and node!=aura:
   node.position=Vector2.ZERO;node.size=view
 trim.position=Vector2.ZERO;trim.size=view
 var alive: Array=[]
 for node in design:
  if not is_instance_valid(node):continue
  alive.append(node);_apply(node,node.get_meta("design"),s)
 design=alive
 title_label.position=Vector2(52*s,4*s);title_label.size=Vector2(340*s,50*s)
 var title_width:=TITLE_FONT.get_string_size(title_label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,int(36*s)).x
 subtitle.position=Vector2(52*s+title_width+22*s,24*s);subtitle.size=Vector2(470*s,28*s)
 trim.title_box=Rect2(Vector2(52*s,50*s),Vector2(title_width,0))
 trim.queue_redraw()
 back_button.position=Vector2(w-MARGIN*s-64*s,8*s);back_button.size=Vector2(64*s,64*s)
 var x:=MARGIN*s
 for spec in FILTERS:
  var entry: Dictionary=tabs[spec.id]
  var target: WooMobileButton=entry.button
  var tab_width: float=float(entry.width)*s
  target.position=Vector2(x,80*s);target.size=Vector2(tab_width,44*s)
  var badge: Painted=entry.icon
  var label: Label=entry.label
  label.position=Vector2(38*s,0) if badge!=null else Vector2.ZERO
  label.size=Vector2((tab_width-44*s) if badge!=null else tab_width,44*s)
  if badge!=null:
   badge.position=Vector2(10*s,10*s);badge.size=Vector2(24*s,24*s)
  x+=tab_width+8*s
 grid.position=Vector2(MARGIN*s,GRID_Y*s)
 guide.position=Vector2(MARGIN*s,GUIDE_Y*s);guide.size=Vector2(grid_w*s,GUIDE_H*s)
 detail.position=Vector2(panel_x,PANEL_Y*s);detail.size=Vector2(PANEL_W*s,PANEL_H*s)
 var aspect:=1.0
 if stand.texture!=null:aspect=float(stand.texture.get_width())/maxf(1.0,float(stand.texture.get_height()))
 var height:=STAND_H*s
 var width:=height*aspect
 stand.position=Vector2(center_x-width*.5,feet-height);stand.size=Vector2(width,height)
 aura.pivot_offset=Vector2(width*1.25,height*.62)*.5
 aura.size=Vector2(width*1.25,height*1.0);aura.position=Vector2(center_x-aura.size.x*.5,feet-height*.92)
 aura.pivot_offset=aura.size*.5
 stand_glow.size=Vector2(width*1.5,height*1.05);stand_glow.position=Vector2(center_x-stand_glow.size.x*.5,feet-stand_glow.size.y*.92)
 stand_shadow.size=Vector2(width*.62,height*.11);stand_shadow.position=Vector2(center_x-stand_shadow.size.x*.5,feet-stand_shadow.size.y*.45)
 dais_glow.size=Vector2(400*s,190*s);dais_glow.position=Vector2(center_x-dais_glow.size.x*.5,feet-80*s)
