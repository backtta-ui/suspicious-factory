class_name WooLoadingManager
extends Node
const Overlay=preload("res://scripts/ui/loading.gd")
const MESSAGES={"initial":"도사의 세계를 불러오는 중...","plaza":"광장으로 향하는 중...","fox_forest":"여우의 숲으로 들어가는 중...","moon_palace":"달빛 궁궐의 문이 열리는 중...","red_sea":"붉은 달의 바다로 향하는 중...","practice":"도술 수련을 준비하는 중...","return":"광장으로 돌아가는 중...","gallery":"그림 세계를 펼치는 중...","network":"다른 도사들과 연결하는 중..."}
var game: Node
var busy:=false
var failed:=false
var overlay: WooLoadingOverlay
var destination:=""
var retry_action: Callable
var recovery_action: Callable
var held_resources: Array[Resource]=[]
var history: Array[Dictionary]=[]
var started:=0
var frames:=0
var max_frame_ms:=0.0
var previous_tick:=0
var generation:=0
var phases: Array[Dictionary]=[]
var phase_tick:=0
static func world_assets(id: String) -> Array:
 var info: Dictionary=preload("res://scripts/worlds/catalog.gd").find(id)
 if info.is_empty():return []
 return [info.thumbnailAsset,"res://assets/woo/worlds/"+("forest" if id=="fox_forest" else id)+"_ground.png"]
func begin(id: String,retry: Callable=Callable(),recovery: Callable=Callable()) -> bool:
 if busy or game.quitting:return false
 busy=true;failed=false;destination=id;retry_action=retry;recovery_action=recovery;generation+=1;started=Time.get_ticks_usec();previous_tick=started;frames=0;max_frame_ms=0;phases.clear();phase_tick=started
 game.content_loading=true
 if is_instance_valid(game.ui):preload("res://scripts/ui/design.gd").cancel_controls(game.ui)
 if is_instance_valid(game.player):game.player.intent=Vector2.ZERO;game.player.velocity=Vector2.ZERO
 overlay=Overlay.new();overlay.title=MESSAGES.get(id,"공간을 준비하는 중...");overlay.reduced=game.settings.low_effects;game.layer.add_child(overlay)
 return true
func alive(ticket: int) -> bool:return is_inside_tree() and not game.quitting and busy and generation==ticket
func prepare(paths: Array) -> bool:
 var ticket:=generation
 # The overlay must reach a real draw opportunity before CPU/resource preparation.
 await get_tree().process_frame
 await get_tree().process_frame
 if not alive(ticket):return false
 for path in paths:
  if not ResourceLoader.exists(path):failure("필요한 리소스를 찾을 수 없습니다.");return false
  var err:=ResourceLoader.load_threaded_request(path)
  if err!=OK and err!=ERR_BUSY:failure("리소스 준비를 시작하지 못했습니다.");return false
 for path in paths:
  while alive(ticket):
   var status:=ResourceLoader.load_threaded_get_status(path)
   if status==ResourceLoader.THREAD_LOAD_LOADED:
    var resource:=ResourceLoader.load_threaded_get(path)
    if resource==null:failure("리소스를 읽지 못했습니다.");return false
    held_resources.append(resource);break
   if status==ResourceLoader.THREAD_LOAD_FAILED or status==ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:failure("리소스를 불러오지 못했습니다.");return false
   await get_tree().process_frame
 return alive(ticket)
func wait_ready(node: Node) -> bool:
 var ticket:=generation
 while alive(ticket) and is_instance_valid(node) and not bool(node.get("build_ready")):await get_tree().process_frame
 if not alive(ticket) or not is_instance_valid(node) or not bool(node.get("build_ready")):return false
 await get_tree().physics_frame
 await get_tree().process_frame
 return alive(ticket) and is_instance_valid(node)
func complete() -> void:
 if not busy:return
 history.append({"destination":destination,"elapsed_ms":(Time.get_ticks_usec()-started)/1000.0,"max_frame_ms":max_frame_ms,"frames":frames,"phases":phases.duplicate(true),"status":"PASS"})
 if history.size()>64:history.pop_front()
 release()
func release() -> void:
 generation+=1;busy=false;failed=false;game.content_loading=false;held_resources.clear()
 if is_instance_valid(overlay):
  overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
  preload("res://scripts/ui/design.gd").popup_exit(overlay)
 overlay=null
func failure(message: String) -> void:
 if not busy or failed:return
 failed=true;held_resources.clear()
 if recovery_action.is_valid():recovery_action.call()
 history.append({"destination":destination,"elapsed_ms":(Time.get_ticks_usec()-started)/1000.0,"status":"FAIL","reason":message})
 if history.size()>64:history.pop_front()
 overlay.title=message+"\n안전한 화면에서 다시 시도할 수 있습니다.";overlay.error=true;overlay.portal_intro=false
 var row:=HBoxContainer.new();row.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM);row.position=Vector2(-240,-120);row.size=Vector2(480,64);row.add_theme_constant_override("separation",16);overlay.add_child(row)
 for spec in [["다시 시도",true],["종료" if game.screen_name=="boot" else "이전 화면으로",false]]:
  var retry: bool=spec[1];var b:=preload("res://scripts/woo/mobile_button.gd").new();b.text=spec[0];b.custom_minimum_size=Vector2(220,64);b.add_theme_font_override("font",preload("res://scripts/ui/design.gd").FONT);b.add_theme_font_size_override("font_size",20);row.add_child(b)
  for state in ["normal","hover","pressed","hover_pressed","disabled"]:b.add_theme_stylebox_override(state,preload("res://scripts/ui/design.gd").button_style(state,retry))
  b.pressed.connect(func()->void:
   if not failed:return
   var action:=retry_action;release()
   if game.screen_name=="playing":game.set_paused(false)
   if retry and action.is_valid():action.call_deferred()
   elif game.screen_name=="boot":get_tree().quit()
  )
func dismiss_failure() -> void:
 if not failed:return
 release()
 if game.screen_name=="playing":game.finish_loading_play()
func input_ready() -> void:
 if not busy and not history.is_empty() and history[-1].status=="PASS":history[-1].playable_ms=(Time.get_ticks_usec()-started)/1000.0
func mark_phase(label: String) -> void:
 var tick:=Time.get_ticks_usec();phases.append({"name":label,"elapsed_ms":(tick-phase_tick)/1000.0});phase_tick=tick
func _process(_delta: float) -> void:
 if not busy:return
 var now:=Time.get_ticks_usec();max_frame_ms=maxf(max_frame_ms,(now-previous_tick)/1000.0);previous_tick=now;frames+=1
