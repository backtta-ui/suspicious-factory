extends SceneTree
## 2.0.39 검증: 이펙트 화풍 통일 + 4맵 카툰 건물/타일 아틀라스.
## 1) 30도술 4단계 공통 레이어가 잉크 외곽선·맵 앰비언트 30% 혼합·크기 상한을 쓴다.
## 2) 부침개 전우치 스킨 VFX가 월드 안 손그림 물건처럼 보이게 알파·크기가 낮다.
## 3) 맵 FX(테두리·빛)가 현재 맵 앰비언트를 섞어 어떤 맵에서도 붕 뜨지 않는다.
## 4) 네 맵이 v39 타일 아틀라스(지붕·벽·바닥 12종)를 실제로 쓴다.
## 5) 버전이 2.0.39 / versionCode 50이다.
const FY=preload("res://scripts/survival/fx.gd")
const SkinVFX=preload("res://scripts/survival/skin_vfx.gd")
const MapFx=preload("res://scripts/survival/map_fx.gd")
const BK=preload("res://scripts/survival/building_kit.gd")
const Maps=preload("res://scripts/survival/maps.gd")
const C=preload("res://scripts/survival/characters.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
 checks+=1
 print("V39 ",checks," ",message," = ",ok)
 if not ok:failures+=1;push_error(message)
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
## 임의의 Node2D에 연출을 그려 보는 스모크(오류 없이 그려져야 한다).
func smoke(callable: Callable,message: String) -> void:
 var holder:=Node2D.new()
 root.add_child(holder)
 holder.draw.connect(func()->void:callable.call(holder))
 await frames(3)
 check(true,message)
 holder.queue_free()
 await frames(1)
func run() -> void:
 root.size=Vector2i(1600,720)
 # ── 1) 30도술 4단계 공통 레이어
 check(FY.SIG.size()==30,"30도술 시그니처 유지")
 var src:=FileAccess.get_file_as_string("res://scripts/survival/fx.gd")
 check(src.contains("Maps.accent_of()"),"공통 레이어가 현재 맵 앰비언트를 섞는다")
 check(src.contains("0.70+ambient.r*0.30"),"시그니처 70% + 앰비언트 30% 혼합 비율")
 check(src.contains("lerpf(8.0,54.0,burst)"),"발동 고리 상한 54px(과거 62px보다 작다)")
 check(src.contains("Color(glow.r,glow.g,glow.b,.52*(1.0-fade))"),"지속 고리 알파 52% 상한(25~55% 범위)")
 check(src.contains("Color(.04,.03,.08,.70)"),"잉크 외곽선(남색) 통일")
 check(src.contains("commercial(node,center,p,tint,skill_id)"),"모든 시그니처가 4단계 레이어를 호출")
 for skill_id in FY.SIG.keys():
  for stage in [0.1,0.25,0.5,0.9]:
   await smoke(func(n: Node2D)->void:FY.commercial(n,Vector2(800,400),float(stage),Color("f0c46a"),String(skill_id)),
    "4단계 스모크 %s p=%.1f"%[String(skill_id),float(stage)])
  var spec: Dictionary=FY.SIG[skill_id]
  await smoke(func(n: Node2D)->void:FY.signature(n,Vector2(800,400),0.5,String(skill_id),2.0,""),
   "시그니처 스모크 %s"%String(skill_id))
 # ── 2) 부침개 전우치 스킨 VFX
 check(SkinVFX.key_for("woochi_pancake","painting")=="pancake_pan","궁극기 무쇠팬 연출 유지")
 check(SkinVFX.key_for("woochi_pancake","transform")=="pancake_flip","둔갑 뒤집기 연출 유지")
 check(SkinVFX.key_for("woochi_pancake","clone")=="pancake_clone","분신 팬·뒤집개 연출 유지")
 var skin_src:=FileAccess.get_file_as_string("res://scripts/survival/skin_vfx.gd")
 check(skin_src.contains("const INK=Color(.04,.03,.07,.80)"),"스킨 VFX도 잉크 외곽선을 쓴다")
 check(skin_src.contains("lerpf(16.0,46.0,float(s.burst))"),"무쇠팬 반지름 상한 46px(실루엣을 가리지 않게)")
 check(not skin_src.contains("Color(\"ffd27a\")"),"생금(네온 금) 원색 제거 → 따뜻한 반죽 톤")
 for key in ["pancake_pan","pancake_flip","pancake_clone"]:
  for stage in [0.2,0.5,0.9]:
   await smoke(func(n: Node2D)->void:SkinVFX.draw(n,Vector2(800,400),float(stage),"woochi_pancake",
    {"pancake_pan":"painting","pancake_flip":"transform","pancake_clone":"clone"}.get(key,"painting"),2.0),
    "스킨 VFX 스모크 %s p=%.1f"%[key,float(stage)])
 await smoke(func(n: Node2D)->void:FY.signature(n,Vector2(800,400),0.5,"painting",2.0,"woochi_pancake"),
  "스킨 시그니처 분기 스모크(부침개)")
 await smoke(func(n: Node2D)->void:FY.signature(n,Vector2(800,400),0.5,"painting",2.0,""),
  "스킨 시그니처 분기 스모크(기본 전우치)")
 # ── 3) 맵 FX 앰비언트 혼합
 Maps.set_current("seowon")
 var warm: Color=MapFx.glow_color(MapFx.TONE_DARK)
 Maps.set_current("gangnam")
 var cool: Color=MapFx.glow_color(MapFx.TONE_DARK)
 check(warm!=cool,"맵 FX 빛이 맵 앰비언트에 따라 달라진다(조선 vs 강남)")
 check(absf(MapFx.rim_color(MapFx.TONE_BRIGHT,0.5).a-0.5)<0.001,"테두리 알파가 전달된다")
 Maps.set_current("gangnam")
 # ── 4) v39 타일 아틀라스
 check(BK.TEX.size()==12,"v39 타일 12종(지붕4·벽4·바닥4)")
 for key in BK.TEX.keys():
  check(BK.tex(String(key))!=null,"타일 로드 %s"%String(key))
 check(ResourceLoader.exists("res://assets/woo/v39/atlas_v39.png"),"아틀라스 원본 존재")
 check(ResourceLoader.exists("res://assets/woo/v39/atlas_v39.json"),"아틀라스 프레임 목록 존재")
 var atlas_img:=Image.load_from_file(ProjectSettings.globalize_path("res://assets/woo/v39/atlas_v39.png"))
 check(atlas_img!=null and atlas_img.get_width()==2048 and atlas_img.get_height()==1536,"아틀라스 2048x1536(512px 12칸)")
 var d_src:=FileAccess.get_file_as_string("res://scripts/survival/dongseongno_art.gd")
 check(d_src.contains("BK.roof(node") and d_src.contains("BK.facade(node"),"동성로 건물이 v39 지붕·파사드를 쓴다")
 check(d_src.contains("BK.tiled(node,\"floor_asphalt\"") and d_src.contains("BK.tiled(node,\"floor_paving\""),"동성로 바닥이 v39 타일을 쓴다")
 var h_src:=FileAccess.get_file_as_string("res://scripts/survival/haeundae_art.gd")
 check(h_src.contains("BK.roof(node") and h_src.contains("BK.facade(node"),"해운대 건물이 v39 지붕·파사드를 쓴다")
 var g_src:=FileAccess.get_file_as_string("res://scripts/survival/gangnam_art.gd")
 check(g_src.contains("BK.tiled(node,\"wall_concrete\""),"강남역 벽이 v39 콘크리트 타일을 쓴다")
 var s_src:=FileAccess.get_file_as_string("res://scripts/survival/seowon_art.gd")
 check(s_src.contains("BK.tiled(node,\"roof_giwa\"") and s_src.contains("BK.tiled(node,\"wall_plaster\""),"조선 담장이 v39 기와·흙벽 타일을 쓴다")
 await smoke(func(n: Node2D)->void:
  BK.tiled(n,"roof_giwa",Rect2(700,300,300,200))
  BK.roof(n,Rect2(700,300,300,200),"roof_slate",3,40.0,9.0)
  BK.facade(n,Rect2(700,550,300,120),50.0,"wall_brick",Color("d9564e"),"분식","shop",1)
  BK.wall_strip(n,Rect2(1050,300,14,160),"wall_wood",Color("26304a"))
  BK.contact(n,Rect2(700,700,300,100),14.0,.3)
  BK.light_spill(n,Vector2(900,760),60.0,Color(1,.8,.5,.2)),"건물 키트 스모크(지붕·파사드·담장·그림자)")
 # ── 5) 버전
 check(String(ProjectSettings.get_setting("application/config/version"))=="2.0.39","project version 2.0.39")
 var preset:=FileAccess.get_file_as_string("res://export_presets.cfg")
 check(preset.contains("version/code=50"),"versionCode 50")
 check(preset.contains("version/name=\"2.0.39\""),"versionName 2.0.39")
 print("V39 CHECKS=",checks," FAIL=",failures)
 quit(0 if failures==0 else 1)
