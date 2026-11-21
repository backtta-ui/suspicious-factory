extends Control
## 캐릭터 안내 (도감) — the lobby's 캐릭터 button opens this screen.
## Read-only roster: tabs filter the grid, a card swaps the standing figure and the
## detail panel, and an ability row reveals its cooldown and full description.
const FONT=preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const TITLE_FONT=preload("res://assets/fonts/BlackHanSans.ttf")
const V=preload("res://scripts/ui/ui_v25.gd")
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
## 2.0.28 도감 레이아웃: 10인 로스터(3열 4행) + 오른쪽 상세 패널이 1080px(설계 720px)
## 안전 영역에 모두 들어오고, 스킬 카드·상세·도포 스킨이 서로 겹치지 않게 재배치했다.
const CARD_SIZE=Vector2(84,96)
const CARD_GAP=6.0
const GRID_Y=132.0
const PANEL_W=344.0
const PANEL_Y=88.0
const PANEL_H=600.0
const GUIDE_Y=544.0
const GUIDE_H=150.0
## 왼쪽 안내 패널 폭(카드 격자보다 조금 넓게 잡아 설명이 두 줄로 접힌다).
const GUIDE_W=302.0
const STAND_H=340.0
## 오른쪽 패널 안쪽 세로 위치(패널 로컬 좌표). 능력 행은 82px 높이로 넉넉히 띄운다.
const ROW_Y=160.0
const ROW_H=82.0
const ROW_STEP=86.0
const SKIN_Y=450.0
const TIP_Y=498.0
const TIP_H=96.0
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
var initial:="all"
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
var header_medallion: TextureRect
var emblem_icon: Control
var wallet: Control
var grid_panel: NinePatchRect
var detail_sheet: NinePatchRect
var wallet_pills: Array=[]
var guide: Panel
var active_ability:=-1
var skin_row: Control
## 미리보기 중인 스킨 id. 비어 있으면 현재 장착 스킨이다.
var skin_view:=""
var skin_status: Label
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
 filter=initial if initial in ["all","daoist","yokai"] else "all"
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
 grid_panel=V.patch(self,V.TEX_PANEL,Rect2(MARGIN-10,GRID_Y-12,1,1),64)
 grid_panel.name="CodexGridPanel"
 grid=Control.new();grid.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(grid)
 _build_guide()
 _build_detail()
 _build_header()
 _refresh_grid()
 _select("daoist:woochi")

func _build_header() -> void:
 title_label=label_text(self,"도감",34,Color("ffe6b4"),true)
 subtitle=label_text(self,"조선에 등장하는 도사와 요괴를 확인하세요",14,Color("d8cfe8"))
 back_button=V.PlateButton.new()
 back_button.kind="dark"
 back_button.text="뒤로"
 back_button.glyph="back"
 back_button.font_size=17
 back_button.name="CodexBack"
 back_button.custom_minimum_size=Vector2.ZERO
 back_button.allowed=func()->bool:return game!=null and not game.changing and game.modal==null
 back_button.pressed.connect(func()->void:
  if back_button.usable():game.sound.play_clip("button");game.back())
 add_child(back_button)
 game.button_feel(back_button)
 header_medallion=TextureRect.new()
 header_medallion.texture=V.TEX_MEDALLION
 header_medallion.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 header_medallion.stretch_mode=TextureRect.STRETCH_SCALE
 header_medallion.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(header_medallion)
 var emblem:=Control.new()
 emblem.set_script(V.Glyph)
 emblem.set("glyph","scroll")
 emblem.set("tint",Color("f0d9a2"))
 emblem.mouse_filter=Control.MOUSE_FILTER_IGNORE
 header_medallion.add_child(emblem)
 emblem_icon=emblem
 _build_wallet()
 for spec in FILTERS:
  var key: String=spec.id
  var target:=V.Tab.new()
  target.text=spec.label
  target.glyph="lotus" if key=="daoist" else ("fox" if key=="yokai" else "grid")
  target.font_size=17
  target.name="CodexTab_"+key
  target.custom_minimum_size=Vector2.ZERO
  target.allowed=func()->bool:return game!=null and not game.changing and game.modal==null
  target.pressed.connect(func()->void:
   if target.usable():game.sound.play_clip("button");_set_filter(key))
  add_child(target)
  game.button_feel(target)
  tabs[key]={"button":target,"width":float(spec.label.length())*17.0+64.0}
 _paint_tabs()

## 상단 지갑 알약(칭호·보석·코인).
func _build_wallet() -> void:
 wallet=Control.new()
 wallet.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(wallet)
 var specs: Array=[[V.TEX_ICON_LOTUS,"칭호 ","0",Color("9fe8ff")],
  [V.TEX_ICON_GEM,"보석 ",str(int(game.storage.data.gems)),Color("c9a6ff")],
  [V.TEX_ICON_COIN,"코인 ",str(int(game.storage.data.coins)),Color("f6d896")]]
 var owned:=0
 for item in (game.storage.data.market.owned as Array):
  if String(item).begins_with("title:"):owned+=1
 specs[0][2]=str(owned)
 for spec in specs:
  var pill:=Control.new()
  pill.mouse_filter=Control.MOUSE_FILTER_IGNORE
  wallet.add_child(pill)
  var bg:=V.patch(pill,V.TEX_PILL,Rect2(Vector2.ZERO,Vector2(1,1)),40)
  var art:=TextureRect.new()
  art.texture=spec[0]
  art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  art.mouse_filter=Control.MOUSE_FILTER_IGNORE
  pill.add_child(art)
  var label:=label_text(pill,String(spec[1])+String(spec[2]),15,spec[3])
  pill.set_meta("bg",bg)
  pill.set_meta("icon",art)
  pill.set_meta("label",label)
  wallet_pills.append({"node":pill,"caption":String(spec[1])+String(spec[2])})

func _build_guide() -> void:
 guide=Panel.new();guide.name="CodexRoleGuide";guide.mouse_filter=Control.MOUSE_FILTER_IGNORE
 guide.add_theme_stylebox_override("panel",glass(INK,Color(GOLD.r,GOLD.g,GOLD.b,.4),14,Color(VIOLET.r,VIOLET.g,VIOLET.b,.28)));add_child(guide)
 place(label_text(guide,"역할 안내",17,GOLD),Rect2(16,5,200,26))
 place(rule(guide,Color(GOLD.r,GOLD.g,GOLD.b,.24)),Rect2(16,33,GUIDE_W-32,1))
 for row in [{"icon":"talisman","title":"도사 (%d명)"%C.catalog("daoist").size(),"body":"술래를 따돌리고, 봉인을 막으며 생존하세요","y":38.0,"color":DAOIST_COLOR},
  {"icon":"mask","title":"요괴 (%d명)"%C.catalog("yokai").size(),"body":"도사를 추적해 모두 봉인하면 승리합니다","y":92.0,"color":YOKAI_COLOR}]:
  var icon:=Painted.new();icon.icon=row.icon;icon.ring=row.color;icon.bare=true;guide.add_child(icon);place(icon,Rect2(14,row.y+1,26,26))
  place(label_text(guide,row.title,16.5,row.color,true),Rect2(50,row.y,180,22))
  var body:=label_text(guide,row.body,12.5,MUTED)
  body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  place(body,Rect2(50,row.y+21,GUIDE_W-64,32))

func _build_detail() -> void:
 detail=Control.new();detail.name="CodexDetail";detail.mouse_filter=Control.MOUSE_FILTER_PASS;detail.clip_contents=true;add_child(detail)
 detail_panel=Panel.new();detail_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 detail_panel.add_theme_stylebox_override("panel",flat(Color(0,0,0,0)))
 var sheet:=V.patch(detail,V.TEX_PANEL,Rect2(Vector2.ZERO,Vector2(1,1)),64)
 sheet.name="CodexDetailSheet"
 detail_sheet=sheet
 detail.add_child(detail_panel);detail_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 watermark=TextureRect.new();watermark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;watermark.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;watermark.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var shader:=Shader.new();shader.code=WATERMARK_CODE
 var material:=ShaderMaterial.new();material.shader=shader;material.set_shader_parameter("strength",0.17);watermark.material=material
 watermark.modulate=Color(.82,.68,1,1)
 detail.add_child(watermark);place(watermark,Rect2(140,-14,200,200))
 detail_name=label_text(detail,"",29,GOLD,true);place(detail_name,Rect2(24,6,232,40))
 detail_team=Panel.new();detail_team.mouse_filter=Control.MOUSE_FILTER_IGNORE;detail.add_child(detail_team);place(detail_team,Rect2(24,50,56,24))
 detail_team_label=label_text(detail_team,"도사",14.5,Color("231a0c"))
 detail_team_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 detail_team_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;detail_team_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 detail_role=Panel.new();detail_role.mouse_filter=Control.MOUSE_FILTER_IGNORE;detail.add_child(detail_role);place(detail_role,Rect2(88,50,96,24))
 detail_role_label=label_text(detail_role,"",14.5,Color("efe2ff"))
 detail_role_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 detail_role_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;detail_role_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 detail_intro=label_text(detail,"",14.5,MUTED);detail_intro.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;place(detail_intro,Rect2(24,78,300,44))
 place(rule(detail,Color(GOLD.r,GOLD.g,GOLD.b,.26)),Rect2(24,126,300,1))
 place(label_text(detail,"✦  주요 능력",18,GOLD,true),Rect2(24,130,240,26))
 ability_root=Control.new();ability_root.mouse_filter=Control.MOUSE_FILTER_PASS;detail.add_child(ability_root)
 skin_row=Control.new();skin_row.name="CodexSkinRow";skin_row.mouse_filter=Control.MOUSE_FILTER_PASS
 detail.add_child(skin_row)
 place(rule(detail,Color(GOLD.r,GOLD.g,GOLD.b,.26)),Rect2(24,420,300,1))
 place(label_text(detail,"✦  도포 스킨",17,GOLD,true),Rect2(24,424,150,24))
 skin_status=label_text(detail,"",11.5,MUTED)
 skin_status.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 place(skin_status,Rect2(170,428,154,18))
 hint=label_text(detail,"스킬을 누르면 쿨타임과 상세 설명이 표시됩니다.",13.5,MUTED)
 hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 place(hint,Rect2(24,502,300,44))
 tip=Panel.new();tip.mouse_filter=Control.MOUSE_FILTER_IGNORE
 tip.add_theme_stylebox_override("panel",glass(Color(.09,.07,.20,.97),Color(GOLD.r,GOLD.g,GOLD.b,.6),10,Color(VIOLET.r,VIOLET.g,VIOLET.b,.45)))
 detail.add_child(tip);place(tip,Rect2(12,TIP_Y,320,TIP_H))
 tip_name=label_text(tip,"",16.5,GOLD,true);place(tip_name,Rect2(14,6,290,24))
 tip_meta=label_text(tip,"",13,MUTED);place(tip_meta,Rect2(14,30,290,18))
 tip_body=label_text(tip,"",13.5,TEXT);tip_body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;place(tip_body,Rect2(14,50,292,42))
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
 _fill_skins()
 _layout()

func _ability_row(index: int,ability: Dictionary) -> void:
 var target:=button("",func()->void:_show_tip(index),ability_root)
 target.name="CodexAbility_%d"%index
 place(target,Rect2(12,ROW_Y+float(index)*ROW_STEP,320,ROW_H))
 var badge:=Painted.new();badge.icon=ability.get("icon","");target.add_child(badge);place(badge,Rect2(10,22,38,38))
 var slot_name: String=String(ability.get("slot_name","대표"))
 var title_text: String=String(ability.get("name",""))
 var title:=label_text(target,title_text,16,TEXT);place(title,Rect2(54,7,140,22))
 # 쿨타임과 타입은 한 줄 뱃지('대표 · 18초')로 묶어 서로 겹치지 않는다.
 var meta:=label_text(target,"%s · %d초"%[slot_name,int(ability.get("cd",0.0))],12.5,GOLD_DEEP if slot_name!="궁극기" else Color("c79bff"))
 meta.name="Meta"
 meta.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 place(meta,Rect2(196,8,114,20))
 var body:=label_text(target,ability.get("description",""),13,MUTED)
 body.name="Body"
 body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 place(body,Rect2(54,30,250,48))
 target.set_meta("badge",badge);target.set_meta("title",title)
 target.mouse_entered.connect(func()->void:_hover_row(index,true))
 target.mouse_exited.connect(func()->void:_hover_row(index,false))
 _paint_row(target,false,false)

## 2.0.36 스킨 줄: 이 캐릭터가 입을 수 있는 전용 스킨만 보여 준다(도포 색 스킨 없음).
## 보유 스킨은 눌러서 바로 장착하고, 미보유 스킨은 중앙 원화에 미리보기만 보여 주고
## 구매는 마켓(상점)에서 안내한다(도감은 장착·구경 전용).
func _fill_skins() -> void:
 if not is_instance_valid(skin_row):return
 for child in skin_row.get_children():child.free()
 var equipped: String=String(game.storage.equipped("skin"))
 if equipped=="":equipped="default"
 var options: Array=[preload("res://scripts/survival/market.gd").DEFAULT_SKIN]
 options.append_array(preload("res://scripts/survival/market.gd").skins_for(selected_id))
 if skin_view=="" or not options.any(func(item: Dictionary)->bool:return String(item.id)==skin_view):skin_view=equipped
 var per: float=50.0
 for i in range(options.size()):
  var item: Dictionary=options[i]
  var id: String=String(item.id)
  var owned: bool=id=="default" or game.storage.owns(id)
  var chosen: bool=id==equipped
  var previewing: bool=id==skin_view
  var target:=button("",func()->void:_pick_skin(item),skin_row)
  target.name="CodexSkin_"+id
  place(target,Rect2(24.0+float(i%6)*per,SKIN_Y,per-6.0,44.0))
  # 초상 썸네일(스킨 전용 초상이 없으면 캐릭터 초상)을 금테 판에 넣는다.
  var art_path:=String(item.get("portrait",""))
  if art_path=="" or not ResourceLoader.exists(art_path):art_path=String(selected.get("portrait",""))
  if art_path!="" and ResourceLoader.exists(art_path):
   var thumb:=TextureRect.new()
   thumb.texture=load(art_path)
   thumb.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
   thumb.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
   thumb.mouse_filter=Control.MOUSE_FILTER_IGNORE
   thumb.modulate=Color(1,1,1,1.0 if owned else .45)
   var clip:=Control.new();clip.clip_contents=true;clip.mouse_filter=Control.MOUSE_FILTER_IGNORE
   target.add_child(clip);clip.position=Vector2.ZERO;clip.size=target.size
   clip.add_child(thumb);thumb.position=Vector2.ZERO;thumb.size=target.size
  var border_color:=GOLD if chosen else (VIOLET if previewing else Color(GOLD.r,GOLD.g,GOLD.b,.32))
  var frame:=Panel.new();frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
  frame.add_theme_stylebox_override("panel",flat(Color(0,0,0,0),border_color,3 if chosen or previewing else 1,8))
  target.add_child(frame);frame.position=Vector2.ZERO;frame.size=target.size
  if not owned:
   var lock:=label_text(target,"미보유",10,Color("ffe6c0"))
   lock.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
   lock.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
   place(lock,Rect2(0,0,per-6.0,44.0))
  if chosen:
   var mark:=label_text(target,"✓",13,Color("2a1e08"))
   mark.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
   place(mark,Rect2(0,26,per-6.0,18))
  target.set_meta("skin",item)
  target.tooltip_text=String(item.name)
 _paint_stand_skin()
## 스킨 미리보기·장착을 한 곳에서 처리한다. 미보유는 구경만 하고 안내를 남긴다.
func _pick_skin(item: Dictionary) -> void:
 var id: String=String(item.id)
 skin_view=id
 if id=="default" or game.storage.owns(id):
  game.storage.equip("skin",id)
  game.storage.save()
  # 매칭 전에 갈아입혀도 선택창·경기에 바로 반영되게 rules의 내 스킨도 맞춘다.
  if game.rules!=null and game.rules.players.has("human"):
   game.rules.players.human.skin=id
  game.sound.play_clip("button")
 else:
  # 미보유 스킨은 화면을 가리는 팝업 대신 스킨 줄 옆 안내로 '상점에서 구매'를 알린다.
  game.sound.play_clip("button")
 # 누르는 중인 버튼을 즉시 지우면 신호 처리 중에 노드가 사라진다. 다음 프레임에 다시 그린다.
 _fill_skins.call_deferred()
 _layout.call_deferred()
## 현재 미리보기/장착 스킨의 전용 전신 원화를 중앙 단상에 보여 준다(없으면 캐릭터 원화).
func _paint_stand_skin() -> void:
 var equipped: String=String(game.storage.equipped("skin"))
 if equipped=="":equipped="default"
 var view_id:=skin_view if skin_view!="" else equipped
 var name_value:="기본 모습"
 var owned:=true
 var full:=""
 if view_id!="default":
  var item: Dictionary=preload("res://scripts/survival/market.gd").skin(view_id)
  name_value=String(item.get("name",view_id))
  owned=game.storage.owns(view_id)
  if String(item.get("skin_of",""))!="" and String(selected.get("art",""))==String(item.get("skin_of","")):
   full=String(item.get("full",""))
 # 스킨 전용 원화가 있으면 그것을, 없으면 캐릭터 원화를 그대로 쓴다(색 틴트 없음).
 if is_instance_valid(stand):
  var path:=full if full!="" and ResourceLoader.exists(full) else String(selected.get("sprite",""))
  if path!="" and ResourceLoader.exists(path):
   var texture: Texture2D=load(path)
   if texture!=null:stand.texture=texture
  stand.modulate=Color.WHITE
 if is_instance_valid(skin_status):
  if view_id!=equipped and owned:skin_status.text="미리보기 · "+name_value+" · 장착"
  elif view_id!=equipped:skin_status.text="미리보기 · 상점에서 구매"
  else:skin_status.text="장착 중 · "+name_value
  skin_status.add_theme_color_override("font_color",GOLD if view_id==equipped else Color("c79bff"))
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
 var slot_name: String=String(ability.get("slot_name","대표"))
 var note: String="전투 중 사용하는 대표 능력"
 if slot_name=="보조":note="상황에 맞춰 쓰는 보조 능력"
 elif slot_name=="궁극기":note="기운이 100% 차면 펼치는 궁극기"
 tip_meta.text="%s · 쿨타임 %d초 · %s"%[slot_name,int(ability.get("cd",0.0)),note]
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
 var k:=get_viewport().get_visible_rect().size.y/DESIGN_HEIGHT
 var entries:=_entries()
 for i in range(entries.size()):
  var entry: Dictionary=entries[i]
  var id: String=entry.id
  var target:=button("",func()->void:_select(id),grid)
  target.name="CodexCard_"+id.split(":")[1]
  var col:=i%3
  var row:=i/3
  place(target,Rect2(col*(CARD_SIZE.x+CARD_GAP),float(row)*(CARD_SIZE.y+CARD_GAP),CARD_SIZE.x,CARD_SIZE.y))
  for state in ["normal","hover","pressed","hover_pressed","disabled"]:
   target.add_theme_stylebox_override(state,flat(Color(0,0,0,0)))
  var path:=String(entry.get("portrait",entry.get("sprite","")))
  if path!="" and ResourceLoader.exists(path):
   var portrait_node:=V.CirclePortrait.new()
   portrait_node.texture=load(path)
   portrait_node.focus=0.50
   portrait_node.zoom=1.0
   target.add_child(portrait_node)
   portrait_node.position=Vector2.ZERO
   portrait_node.size=Vector2(CARD_SIZE.x,CARD_SIZE.x*.84)*k
  var ring:=TextureRect.new()
  ring.texture=V.TEX_RING_FRAME
  ring.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  ring.stretch_mode=TextureRect.STRETCH_SCALE
  ring.mouse_filter=Control.MOUSE_FILTER_IGNORE
  target.add_child(ring)
  ring.position=Vector2.ZERO
  ring.size=Vector2(CARD_SIZE.x,CARD_SIZE.x*.84)*k
  var name_label:=label_text(target,String(entry.get("name","")),14,Color("f2e6cc"))
  name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  name_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
  place(name_label,Rect2(0,CARD_SIZE.y-25.0,CARD_SIZE.x,22))
  target.set_meta("ring",ring)
  target.set_meta("name",name_label)
  target.set_meta("id",id)
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
  var ring: TextureRect=card.get_meta("ring")
  if is_instance_valid(ring):
   ring.modulate=Color(1.10,1.02,.86,1.0) if chosen else Color(.72,.66,.86,.92)
   ring.scale=Vector2(1.06,1.06) if chosen else Vector2.ONE
   ring.pivot_offset=ring.size*.5
  var name_label: Label=card.get_meta("name")
  if is_instance_valid(name_label):
   name_label.add_theme_color_override("font_color",Color("ffe6b4") if chosen else Color("cbbfe0"))

func _set_filter(id: String) -> void:
 filter=id
 _refresh_grid()
 var entries:=_entries()
 if not entries.is_empty():_select(entries[0].id)
 _paint_tabs()

func _paint_tabs() -> void:
 for key in tabs:
  var spec: Dictionary=tabs[key]
  var target=spec.button
  if is_instance_valid(target):target.paint(key==filter)

func _select(id: String) -> void:
 var entry:=C.find(id)
 if entry.is_empty():return
 selected_id=id
 selected=entry
 skin_view=""
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
 var grid_w:=CARD_SIZE.x*3.0+CARD_GAP*2.0
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
 title_label.position=Vector2(202*s,0);title_label.size=Vector2(300*s,44*s)
 subtitle.position=Vector2(204*s,42*s);subtitle.size=Vector2(560*s,24*s)
 trim.title_box=Rect2(Vector2.ZERO,Vector2.ZERO)
 trim.queue_redraw()
 back_button.position=Vector2(16*s,10*s);back_button.size=Vector2(116*s,42*s)
 back_button.set("font_size",maxi(10,int(17*s)))
 header_medallion.position=Vector2(154*s,4*s);header_medallion.size=Vector2(48*s,48*s)
 if emblem_icon!=null:
  emblem_icon.position=Vector2(11*s,11*s);emblem_icon.size=Vector2(26*s,26*s)
 if wallet!=null:
  var total:=0.0
  for item in wallet_pills:
   var pill: Control=item.node
   var font: Font=FONT
   total+=font.get_string_size(String(item.caption),HORIZONTAL_ALIGNMENT_LEFT,-1,int(15*s)).x+48*s
  wallet.position=Vector2(w-16*s-total,14*s)
  wallet.size=Vector2(total,36*s)
  var x:=0.0
  for item in wallet_pills:
   var pill: Control=item.node
   var font: Font=FONT
   var pw:=font.get_string_size(String(item.caption),HORIZONTAL_ALIGNMENT_LEFT,-1,int(15*s)).x+48*s
   pill.position=Vector2(x,0);pill.size=Vector2(pw,36*s)
   var bg: NinePatchRect=pill.get_meta("bg")
   bg.position=Vector2.ZERO;bg.size=pill.size;V.refit(bg)
   var art: TextureRect=pill.get_meta("icon")
   art.position=Vector2(12*s,8*s);art.size=Vector2(20*s,20*s)
   var lbl: Label=pill.get_meta("label")
   lbl.position=Vector2(38*s,0);lbl.size=Vector2(pw-42*s,36*s)
   lbl.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
   lbl.add_theme_font_size_override("font_size",maxi(10,int(15*s)))
   x+=pw+8*s
 var x:=MARGIN*s
 for spec in FILTERS:
  var entry: Dictionary=tabs[spec.id]
  var target=entry.button
  var tab_width: float=float(entry.width)*s
  target.position=Vector2(x,76*s);target.size=Vector2(tab_width,44*s)
  target.set("font_size",maxi(10,int(17*s)))
  x+=tab_width+8*s
 grid.position=Vector2(MARGIN*s,GRID_Y*s)
 var guide_w: float=maxf(GUIDE_W,grid_w)
 guide.position=Vector2(MARGIN*s,GUIDE_Y*s);guide.size=Vector2(guide_w*s,GUIDE_H*s)
 if grid_panel!=null:
  grid_panel.position=Vector2((MARGIN-12)*s,(GRID_Y-14)*s)
  grid_panel.size=Vector2((guide_w+24)*s,(GUIDE_Y+GUIDE_H-(GRID_Y-14))*s)
  V.refit(grid_panel)
 detail.position=Vector2(panel_x,PANEL_Y*s);detail.size=Vector2(PANEL_W*s,PANEL_H*s)
 if detail_sheet!=null:
  detail_sheet.position=Vector2.ZERO
  detail_sheet.size=detail.size
  V.refit(detail_sheet)
 var aspect:=1.0
 if stand.texture!=null:aspect=float(stand.texture.get_width())/maxf(1.0,float(stand.texture.get_height()))
 var height:=STAND_H*s
 var width:=height*aspect
 # 스킬 팁·도포 스킨이 화면 밖으로 나가지 않도록 패널 높이를 설계값 그대로 쓴다.
 detail.size=Vector2(PANEL_W*s,PANEL_H*s)
 stand.position=Vector2(center_x-width*.5,feet-height);stand.size=Vector2(width,height)
 aura.pivot_offset=Vector2(width*1.25,height*.62)*.5
 aura.size=Vector2(width*1.25,height*1.0);aura.position=Vector2(center_x-aura.size.x*.5,feet-height*.92)
 aura.pivot_offset=aura.size*.5
 stand_glow.size=Vector2(width*1.5,height*1.05);stand_glow.position=Vector2(center_x-stand_glow.size.x*.5,feet-stand_glow.size.y*.92)
 stand_shadow.size=Vector2(width*.62,height*.11);stand_shadow.position=Vector2(center_x-stand_shadow.size.x*.5,feet-stand_shadow.size.y*.45)
 dais_glow.size=Vector2(400*s,190*s);dais_glow.position=Vector2(center_x-dais_glow.size.x*.5,feet-80*s)
