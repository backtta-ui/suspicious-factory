extends RefCounted
## 2.0.37 네 맵 공통 이펙트 렌더러.
## 강남역·해운대·동성로 월드는 draw_floor()에서 장영실 압력기관·도깨비 가짜보물·
## 도깨비장난 장판·어둑시니 등불끄기/무월야 연막을 하나도 그리지 않아 "스킬이 안 보인다"는
## 제보가 있었다. 이제 그 바닥 연출은 전부 이 파일 한 곳에서만 그리고, world.gd와
## 세 맵 월드가 같은 함수를 호출한다(맵마다 다르게 보이던 문제 제거).
##
## 바닥 밝기에 따른 가시성 규칙(4맵 공통):
## - 밝은 바닥(해운대 모래·강남 대리석) = 어두운 외곽선 + 선명한 색 + 발광 테두리
## - 어두운 바닥(조선 흙·동성로 아스팔트) = 밝은 외곽선 + 바닥 투영 링
const FX=preload("res://scripts/survival/fx.gd")
const TONE_BRIGHT="bright"
const TONE_DARK="dark"
## 그리기 횟수(테스트·디버그용): 바닥 연출이 실제로 호출됐는지 이 값으로 확인한다.
static var draw_counts: Dictionary={"traps":0,"mischief":0,"douse":0,"moonless":0,"dash":0,"detect":0}
static func is_bright(tone: String) -> bool:return tone==TONE_BRIGHT
## 함정·장판의 외곽선: 밝은 바닥엔 검은 테, 어두운 바닥엔 흰 테를 겹쳐 어디서도 묻히지 않게.
static func rim_color(tone: String,a: float) -> Color:
 return Color(.02,.02,.05,a) if is_bright(tone) else Color(1,.96,.86,a)
static func glow_color(tone: String) -> Color:
 return Color(1,.86,.42) if is_bright(tone) else Color(.55,1,.85)
## ---------------------------------------------------------------- 바닥 한 겹
## mischief_zones → 등불끄기 연막 → 무월야 연막 → 압력기관/가짜보물 순서로 깐다.
## (연막을 먼저, 장치를 나중에 그려 장치가 연막에 묻히지 않는다.)
static func floor_layer(node: Node2D,rules: RefCounted,clock: float,tone: String=TONE_DARK) -> void:
 if rules==null or node==null:return
 var plan: Array=floor_plan(rules)
 if plan.has("douse"):douse_shade(node,rules,clock)
 if plan.has("moonless"):moonless_shade(node,rules,clock)
 if plan.has("mischief"):mischief_zones(node,rules,clock,tone)
 if plan.has("traps"):traps(node,rules,clock,tone)
## 이번 프레임에 바닥에 깔릴 연출 목록. 그리기와 테스트가 같은 판단을 쓴다.
## (맵이 달라도 rules가 같으면 같은 목록이 나온다 = 함정이 특정 맵에서만 사라지지 않는다.)
static func floor_plan(rules: RefCounted) -> Array:
 var plan: Array=[]
 if rules==null:return plan
 if rules.dark_until>rules.elapsed:plan.append("douse")
 if rules.map_dark_until>rules.elapsed:plan.append("moonless")
 for z in rules.mischief_zones:
  if float(z.until)>rules.elapsed:plan.append("mischief");break
 for t in rules.traps:
  if float(t.until)>rules.elapsed:plan.append("traps");break
 return plan
## ---------------------------------------------------------------- 도깨비장난 지대
## 바닥에서 춤추는 도깨비불 테두리 + 갈라진 흙 + 이동이 느려지는 장판.
static func mischief_zones(node: Node2D,rules: RefCounted,clock: float,tone: String) -> void:
 draw_counts["mischief"]=int(draw_counts.get("mischief",0))+rules.mischief_zones.size()
 for z in rules.mischief_zones:
  if float(z.until)<=rules.elapsed:continue
  var left: float=clampf((float(z.until)-rules.elapsed)/6.0,0.0,1.0)
  var reach: float=float(z.radius)
  var center: Vector2=z.pos
  var pulse: float=.5+.5*sin(clock*3.4)
  var rim:=rim_color(tone,.55*left)
  node.draw_set_transform(center,0,Vector2(1.0,.44))
  node.draw_circle(Vector2.ZERO,reach,Color(.05,.12,.08,.22*left))
  node.draw_arc(Vector2.ZERO,reach,0,TAU,52,rim,4.6,true)
  node.draw_arc(Vector2.ZERO,reach-2.0,0,TAU,52,Color(.42,.98,.74,.42*left),2.6,true)
  node.draw_arc(Vector2.ZERO,reach*.72,0,TAU,40,Color(.30,.80,.60,.22*left),2.0,true)
  node.draw_arc(Vector2.ZERO,reach+pulse*3.0,0,TAU,48,Color(.85,1,.92,.26*left),2.0,true)
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  for i in range(16):
   var a:=float(i)*TAU/16.0+clock*.9
   var spot:=center+Vector2.from_angle(a)*reach*(.94+.04*sin(clock*3.0+float(i)))
   var size:=4.0+2.2*absf(sin(clock*4.0+float(i)*1.7))
   node.draw_circle(spot,size,Color(.40,.98,.74,.30*left))
   node.draw_circle(spot,size*.45,Color(.92,1,.98,.45*left))
  # 균열은 짧고 옅게: 장판 안쪽에만 그어 화면을 가로지르지 않는다.
  for i in range(7):
   var a2:=float(i)*TAU/7.0+0.4
   for k in range(2):
    var from:=center+Vector2.from_angle(a2)*(reach*(.16+.16*float(k)))
    var to:=center+Vector2.from_angle(a2+0.18*sin(float(k)+float(i)))*(reach*(.16+.16*float(k+1)))
    node.draw_line(from,to,Color(rim.r,rim.g,rim.b,.16*left),1.4,true)
## ---------------------------------------------------------------- 등불끄기(어둑시니)
## 단색 원이 아니라 여러 겹의 밤 그림자 + 소용돌이 먹빛 연막 + 그림자 촉수 + 보랏빛 눈빛
## + 꺼진 등불의 불씨. 4맵 어디서든 캐릭터를 덮지 않도록 바닥층에만 깐다.
static func douse_shade(node: Node2D,rules: RefCounted,clock: float) -> void:
 draw_counts["douse"]=int(draw_counts.get("douse",0))+1
 var fade: float=clampf((rules.dark_until-rules.elapsed)/9.0,0.0,1.0)
 var strength: float=.35+.65*clampf(fade*1.6,0.0,1.0)
 var reach: float=rules.dark_radius*(1.0+(1.0-fade)*.06)
 var center: Vector2=rules.dark_center
 var spin:=clock*1.2
 for i in range(16):
  var k: float=1.0-float(i)/16.0
  node.draw_circle(center,reach*k,Color(.010,.008,.030,.030*strength))
 FX.smoke(node,center,reach*.92,.22*strength,Color(.04,.03,.09,.62),12,spin)
 FX.smoke(node,center+Vector2(reach*.18,-reach*.10),reach*.62,.26*strength,Color(.10,.06,.18,.50),9,-spin*.7)
 FX.smoke(node,center+Vector2(-reach*.22,reach*.06),reach*.48,.26*strength,Color(.03,.02,.07,.55),6,spin*1.6)
 for i in range(14):
  var a:=float(i)*TAU/14.0+sin(clock*.4+float(i))*0.16
  var base: Vector2=center+Vector2.from_angle(a)*reach*.86
  var mid: Vector2=center+Vector2.from_angle(a+0.5)*(reach*.58)
  var tip: Vector2=center+Vector2.from_angle(a+0.9)*(reach*.34)
  node.draw_line(base,mid,Color(.05,.035,.10,.22*strength),7.0,true)
  node.draw_line(mid,tip,Color(.09,.06,.15,.14*strength),3.4,true)
 for i in range(5):
  var phase:=clock*.7+float(i)*1.9
  var spot: Vector2=center+Vector2(sin(phase)*reach*.52,cos(phase*.8)*reach*.34)
  var glow:=.45+.55*sin(clock*2.6+float(i)*2.1)
  node.draw_circle(spot,5.0,Color(.42,.24,.68,.16*glow*strength))
  node.draw_circle(spot,1.6,Color(.88,.74,1,.55*glow*strength))
 for i in range(10):
  var lift: float=fmod(clock*.5+float(i)*.31,1.0)
  var spot2: Vector2=center+Vector2(sin(clock*1.3+float(i)*2.3)*(reach*.30),cos(clock*.9+float(i))*reach*.16)-Vector2(0,lift*140.0)
  node.draw_circle(spot2,1.5*(1.0-lift)+.4,Color(1,.55,.24,(1.0-lift)*.30*strength))
## ---------------------------------------------------------------- 무월야
## 밤하늘이 내려앉고 먹구름이 흐르며 달이 잠식된다.
static func moonless_shade(node: Node2D,rules: RefCounted,clock: float) -> void:
 draw_counts["moonless"]=int(draw_counts.get("moonless",0))+1
 var fade: float=clampf((rules.map_dark_until-rules.elapsed)/8.0,0.0,1.0)
 var alpha: float=.30+.18*clampf(fade*1.5,0.0,1.0)
 var camera:=node.get_viewport().get_camera_2d() if node.is_inside_tree() else null
 var center: Vector2=camera.get_screen_center_position() if camera!=null else rules.players.human.position
 var view: Vector2=(node.get_viewport().get_visible_rect().size/(camera.zoom if camera!=null else Vector2.ONE))
 var far: float=view.length()*.62
 for i in range(12):
  var k: float=1.0-float(i)/12.0
  node.draw_circle(center,far*k,Color(.010,.010,.028,.075*alpha))
 FX.smoke(node,center,far*.55,.30*alpha,Color(.04,.04,.09,.40),9,clock*.7)
 FX.smoke(node,center+Vector2(far*.3,far*.2),far*.34,.34*alpha,Color(.06,.05,.12,.34),7,-clock*.5)
 var moon:=center+Vector2(far*.42,-far*.36)
 node.draw_circle(moon,34.0,Color(.82,.86,.96,.16*alpha))
 node.draw_circle(moon+Vector2(10.0,0),33.0,Color(.02,.02,.05,.30*alpha))
## ---------------------------------------------------------------- 함정 두 종
static func traps(node: Node2D,rules: RefCounted,clock: float,tone: String) -> void:
 draw_counts["traps"]=int(draw_counts.get("traps",0))+rules.traps.size()
 for t in rules.traps:
  var pulse: float=.5+.5*sin(clock*2.8+float((t.pos as Vector2).x)*.01)
  var reach: float=float(t.radius)
  if String(t.kind)=="pressure":
   pressure_trap(node,t.pos,reach,pulse,tone,clock)
  else:
   treasure_trap(node,t.pos,reach,pulse,tone,clock)
## 장영실 압력기관: 청동 팔각 기계판 · 톱니 테두리 · 옥빛 맥동 · 황색 경계.
static func pressure_trap(node: Node2D,at: Vector2,radius: float,pulse: float,tone: String=TONE_DARK,clock: float=0.0) -> void:
 var bronze:=Color(.82,.64,.34)
 var bronze_dark:=Color(.36,.27,.14)
 var jade:=Color(.62,.94,.78)
 var rim:=rim_color(tone,.75)
 var halo:=glow_color(tone)
 # 1) 바닥 그림자 + 바닥 투영 링(어두운 바닥에서도 위치가 보이게)
 node.draw_set_transform(at+Vector2(0,3),0,Vector2(1,.45))
 node.draw_circle(Vector2.ZERO,radius*1.18,Color(.01,.02,.04,.42))
 node.draw_arc(Vector2.ZERO,radius*1.18,0,TAU,44,rim,3.0,true)
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 node.draw_set_transform(at,0,Vector2(1,.45))
 # 2) 바깥 청동 테 — 어두운 외곽선과 밝은 테를 겹쳐 밝은 바닥에서도 형태가 남는다.
 node.draw_circle(Vector2.ZERO,radius,Color(.10,.09,.08,.94))
 node.draw_arc(Vector2.ZERO,radius,0,TAU,44,rim,4.2,true)
 node.draw_arc(Vector2.ZERO,radius-4.0,0,TAU,44,bronze,3.0,true)
 node.draw_arc(Vector2.ZERO,radius-6.0,0,TAU,44,bronze_dark,1.6,true)
 # 3) 돌아가는 톱니 12개
 for i in range(12):
  var a:=i*TAU/12+clock*.7
  var inner:=Vector2.from_angle(a)*(radius-1.0)
  var outer:=Vector2.from_angle(a)*(radius+6.0)
  node.draw_line(inner,outer,bronze,3.2,true)
  node.draw_circle(outer,1.7,Color(1,.9,.58,.95))
 # 4) 안쪽 청동 고리와 팔각 압력판
 node.draw_circle(Vector2.ZERO,radius*.62,Color(.09,.10,.09,.92))
 node.draw_arc(Vector2.ZERO,radius*.62,0,TAU,36,bronze_dark,2.0,true)
 var plate: Array=PackedVector2Array()
 for i in range(8):
  plate.append(Vector2.from_angle(i*TAU/8+PI/8)*radius*.44)
 node.draw_colored_polygon(plate,Color(.17,.19,.19,.98))
 for i in range(8):
  var a0:=Vector2.from_angle(i*TAU/8+PI/8)*radius*.44
  var a1:=Vector2.from_angle((i+1)*TAU/8+PI/8)*radius*.44
  node.draw_line(a0,a1,bronze,2.4,true)
 # 5) 중심 옥빛 맥동 + 나사 핀
 node.draw_circle(Vector2.ZERO,radius*.17,Color(.04,.06,.06,.96))
 node.draw_circle(Vector2.ZERO,radius*.13+pulse*1.8,Color(jade.r,jade.g,jade.b,.60+.38*pulse))
 node.draw_arc(Vector2.ZERO,radius*.3+pulse*3.0,0,TAU,26,Color(jade.r,jade.g,jade.b,.24+.20*(1.0-pulse)),1.8,true)
 for i in range(4):
  var a:=i*TAU/4+PI/4
  var pin:=Vector2.from_angle(a)*radius*.5
  node.draw_circle(pin,2.4,bronze)
  node.draw_circle(pin,1.0,Color(.12,.10,.07))
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 # 6) 황색 경계 발광(밝은 바닥·어두운 바닥 모두에서 읽히는 표식)
 node.draw_arc(at,radius+2.0,0,TAU,48,Color(halo.r,halo.g,halo.b,.35+.25*pulse),1.8,true)
 glow(node,at,radius*1.6,Color(1,.82,.45,.14+.08*pulse))
## 도깨비 가짜보물: 금빛 보물함 · 자물쇠 · 별빛 입자.
static func treasure_trap(node: Node2D,at: Vector2,radius: float,pulse: float,tone: String=TONE_DARK,clock: float=0.0) -> void:
 var gold:=Color(.98,.80,.38)
 var wood:=Color(.30,.21,.11)
 var rim:=rim_color(tone,.8)
 node.draw_set_transform(at+Vector2(0,2),0,Vector2(1,.45))
 node.draw_circle(Vector2.ZERO,radius*1.02,Color(.01,.02,.04,.46))
 node.draw_arc(Vector2.ZERO,radius*1.10,0,TAU,40,rim,3.0,true)
 node.draw_circle(Vector2.ZERO,radius*.72,Color(gold.r,gold.g,gold.b,.12+.06*pulse))
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 var box:=Rect2(at-Vector2(radius*.78,radius*.62),Vector2(radius*1.56,radius*.92))
 node.draw_rect(box.grow(2.0),rim)
 node.draw_rect(box,wood)
 node.draw_rect(Rect2(box.position,Vector2(box.size.x,box.size.y*.34)),Color(.38,.27,.13))
 node.draw_rect(box,gold,false,2.4)
 node.draw_line(Vector2(box.position.x,box.position.y+box.size.y*.34),Vector2(box.end.x,box.position.y+box.size.y*.34),gold,1.6,true)
 for i in range(3):
  var x:=box.position.x+box.size.x*(.22+.28*float(i))
  node.draw_line(Vector2(x,box.position.y+2),Vector2(x,box.end.y-2),Color(gold.r,gold.g,gold.b,.55),1.4,true)
 var lock:=Rect2(at-Vector2(4,4),Vector2(8,9))
 node.draw_rect(lock,gold)
 node.draw_rect(lock,Color(.35,.24,.08),false,1.0)
 node.draw_arc(Vector2(at.x,lock.position.y),3.4,PI,TAU,10,gold,1.4,true)
 node.draw_circle(Vector2(at.x,lock.position.y+4),1.4,Color(.25,.16,.05))
 for i in range(7):
  var a:=i*TAU/7+clock*1.3
  var r: float=radius*(.75+.35*(float((i*37)%11)/11.0))+pulse*3.0
  var star:=at+Vector2.from_angle(a)*r+Vector2(0,-radius*.55)
  var size:=1.6+1.4*pulse
  node.draw_line(star-Vector2(size,0),star+Vector2(size,0),Color(1,.95,.72,.9),1.2,true)
  node.draw_line(star-Vector2(0,size),star+Vector2(0,size),Color(1,.95,.72,.9),1.2,true)
  node.draw_circle(star,.9,Color(1,1,.96,.98))
 glow(node,at+Vector2(0,-6),radius*1.7,Color(1,.86,.48,.16+.09*pulse))
static func glow(node: Node2D,at: Vector2,radius: float,color: Color) -> void:
 for i in range(4):
  var k: float=1.0-float(i)*.22
  node.draw_circle(at,radius*k,Color(color.r,color.g,color.b,color.a*.20))
## ---------------------------------------------------------------- 감지·표식
## 발자국·야광표식·혼길표식·핑을 네 맵이 같은 모양으로 그린다.
## 밝은 바닥에서는 진한 파랑, 어두운 바닥에서는 밝은 하늘색으로 바닥에 묻히지 않게 한다.
static func detection(node: Node2D,rules: RefCounted,clock: float,tone: String=TONE_DARK) -> void:
 if rules==null:return
 draw_counts["detect"]=int(draw_counts.get("detect",0))+1
 var trail:=Color(.30,.62,.95) if is_bright(tone) else Color(.62,.95,1)
 var human: Dictionary=rules.players.get("human",{})
 var sense: bool=rules.trail_all_until>rules.elapsed or (String(human.get("role",""))=="daoist" and float(human.buff.get("sense",0.0))>rules.elapsed)
 if sense:
  for p in rules.players.values():
   if p.role!="daoist" or p.eliminated or p.id=="human":continue
   if rules.hidden(p):continue
   for i in range(p.trail.size()):
    var mark: Dictionary=p.trail[i]
    if rules.gimmicks!=null and rules.gimmicks.trail_blocked(mark.position):continue
    var age: float=rules.elapsed-float(mark.time)
    var alpha: float=clampf(1.0-age/6.0,0,1)*.62
    var facing: float=float(mark.facing)*PI/4
    node.draw_set_transform(mark.position,0,Vector2(1,.5))
    node.draw_arc(Vector2.ZERO,7,0,TAU,12,Color(trail.r,trail.g,trail.b,alpha*.6),1.6,true)
    node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
    node.draw_line(mark.position-Vector2.from_angle(facing)*5,mark.position+Vector2.from_angle(facing)*5,Color(trail.r,trail.g,trail.b,alpha*.8),1.8,true)
 for mark in rules.marks:
  if String(mark.get("kind",""))=="glow":
   var target: Dictionary=rules.players.get(String(mark.get("target","")),{})
   if target.is_empty():continue
   var pulse: float=.5+.5*sin(clock*3.0)
   node.draw_set_transform(target.position,0,Vector2(1,.45))
   node.draw_arc(Vector2.ZERO,20+pulse*6,0,TAU,26,Color(.85,1,.92,.5+.3*pulse),2.4,true)
   node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  elif String(mark.get("kind",""))=="":
   # 혼길표식(강림도령): 바닥에 놓인 푸른 원형 저승문 + 작은 혼불.
   soul_gate(node,mark.pos,clock,tone)
  else:
   var pulse2: float=.5+.5*sin(clock*2.4)
   node.draw_set_transform(mark.pos,0,Vector2(1,.42))
   node.draw_arc(Vector2.ZERO,14+pulse2*5,0,TAU,24,Color(1,.9,.6,.55),2.2,true)
   node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 for ping in rules.pings:
  var t: float=clampf((float(ping.until)-rules.elapsed)/3.0,0,1)
  node.draw_set_transform(ping.pos,0,Vector2(1,.45))
  node.draw_arc(Vector2.ZERO,18+(1.0-t)*50,0,TAU,30,Color(1,.85,.55,.34*t+.16),2.6,true)
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
## 혼길표식: 청록 저승문 고리 + 떠오르는 혼불 3개(저승문 귀환 지점).
static func soul_gate(node: Node2D,at: Vector2,clock: float,tone: String) -> void:
 var pulse: float=.5+.5*sin(clock*2.6)
 var rim:=rim_color(tone,.6)
 node.draw_set_transform(at,0,Vector2(1,.42))
 node.draw_circle(Vector2.ZERO,30,Color(.06,.12,.22,.28))
 node.draw_arc(Vector2.ZERO,30,0,TAU,40,rim,3.2,true)
 node.draw_arc(Vector2.ZERO,27,0,TAU,40,Color(.42,.86,1,.75),2.2,true)
 node.draw_arc(Vector2.ZERO,19+pulse*3.0,0,TAU,32,Color(.65,1,1,.45+.25*pulse),1.6,true)
 for i in range(6):
  var a:=float(i)*TAU/6.0-clock*.8
  var p:=Vector2.from_angle(a)*27.0
  node.draw_line(p,p+Vector2.from_angle(a)*6.0,Color(.7,1,1,.6),2.0,true)
 node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 for i in range(3):
  var rise: float=fmod(clock*.45+float(i)/3.0,1.0)
  var spot:=at+Vector2(sin(clock*1.4+float(i)*2.1)*12.0,-rise*46.0)
  node.draw_circle(spot,2.4*(1.0-rise)+.6,Color(.62,1,1,(1.0-rise)*.7))
## ---------------------------------------------------------------- 몸에 붙는 이펙트의 기준점
## 점프 높이(player.height)와 맵 고도(에스컬레이터 등 layout.elevation)를 더한 머리/몸 중심.
## 보호막·족자·이름표처럼 '몸에 붙는' 연출은 반드시 이 좌표를 쓴다(점프해도 바닥에 남지 않게).
static func body_anchor(p: Dictionary,layout: RefCounted=null) -> Vector2:
 var at: Vector2=p.get("position",Vector2.ZERO)
 var lift: float=float(p.get("height",0.0))
 if layout!=null and layout.has_method("elevation"):lift+=float(layout.elevation(at))
 return at-Vector2(0,lift)
## ---------------------------------------------------------------- 몸에 붙는 보호 연출
## 생명등불·저승꽃·귀환의 길 보호막은 점프 높이를 따라 몸에 붙고,
## 생명등불은 머리 위에 작은 등불이 떠오른다(4맵 공통).
static func shield_bubbles(node: Node2D,rules: RefCounted,clock: float,layout: RefCounted=null) -> void:
 if rules==null:return
 for p in rules.players.values():
  if p.eliminated or p.captured:continue
  var shield: bool=float(p.buff.get("shield",0.0))>rules.elapsed
  var flower: bool=float(p.buff.get("deathflower",0.0))>rules.elapsed
  var lamp: bool=float(p.buff.get("lifelamp",0.0))>rules.elapsed
  if not shield and not flower and not lamp:continue
  var tint: Color=Color("d9c0ff") if flower else (Color("ffd08a") if lamp else Color("ffb9cf"))
  var at: Vector2=body_anchor(p,layout)
  FX.shield_bubble(node,at,clock,tint,1.0 if shield else .72)
  if lamp:
   # 생명등불: 머리 위로 떠오르는 금빛 등불과 옥빛 연결선.
   var lift: float=fmod(clock*.5,1.0)
   var lamp_at:=at+Vector2(sin(clock*1.6)*6.0,-54.0-lift*10.0)
   node.draw_line(at+Vector2(0,-30),lamp_at,Color(1,.9,.6,.20),1.4,true)
   node.draw_circle(lamp_at,10.0,Color(1,.86,.52,.22))
   node.draw_rect(Rect2(lamp_at-Vector2(4,6),Vector2(8,12)),Color(1,.9,.66,.9))
   node.draw_rect(Rect2(lamp_at-Vector2(4,6),Vector2(8,12)),Color(.55,.34,.12,.7),false,1.0)
   node.draw_arc(lamp_at,14.0,0,TAU,18,Color(1,.92,.7,.35),1.6,true)
## ---------------------------------------------------------------- 달리는 도사 궤적
## 홍길동 바람발(이속 증가)처럼 빨라진 캐릭터 뒤로 바람 줄기·발밑 파문이 남는다.
## 어느 맵에서든 "달릴 때 효과"가 보이도록 4맵 draw_effects가 함께 호출한다.
static func dash_trails(node: Node2D,rules: RefCounted,clock: float) -> void:
 if rules==null:return
 draw_counts["dash"]=int(draw_counts.get("dash",0))+1
 for p in rules.players.values():
  if p.eliminated or p.captured:continue
  if float(p.get("speed_factor",1.0))<=1.15 or float(p.get("speed_until",0.0))<=rules.elapsed:continue
  if p.intent.length()<.05 and not bool(p.get("running",false)):continue
  var dir: Vector2=p.intent.normalized()
  var perp:=Vector2(-dir.y,dir.x)
  var at: Vector2=p.position-Vector2(0,10)
  var tint:=Color(.55,.85,1) if p.role=="daoist" else Color(1,.62,.72)
  # 몸 뒤로 남는 잔상 실루엣 3개(달리는 느낌이 한눈에 보이게).
  for i in range(3):
   var ghost:=at-dir*(22.0+float(i)*20.0)
   node.draw_set_transform(ghost,0,Vector2(1,.86))
   node.draw_circle(Vector2(0,-18),10.0-float(i)*2.0,Color(tint.r,tint.g,tint.b,.16-.03*float(i)))
   node.draw_rect(Rect2(Vector2(-7,-8),Vector2(14,20)),Color(tint.r,tint.g,tint.b,.10))
   node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  for i in range(5):
   var back: float=16.0+float(i)*15.0
   var spread: float=sin(clock*7.0+float(i)*1.7)*8.0
   var a:=at-dir*back+perp*spread
   var b:=a-dir*(34.0+float(i)*8.0)
   node.draw_line(a,b,Color(tint.r,tint.g,tint.b,.55-.07*float(i)),3.2-float(i)*.4,true)
  node.draw_set_transform(at,0,Vector2(1,.42))
  node.draw_arc(Vector2.ZERO,16.0+fmod(clock*18.0,20.0),0,TAU,24,Color(tint.r,tint.g,tint.b,.30),2.0,true)
  node.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
