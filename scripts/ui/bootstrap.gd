extends Node
# Minimal host for the same loader used by gameplay; Main's large dependencies load off-thread.
var quitting:=false
var content_loading:=false
var backgrounded:=false
var screen_name:="boot"
var settings: Dictionary={"low_effects":false}
var ui: Control
var player: Node2D
var layer: CanvasLayer
var loading: WooLoadingManager
func _ready() -> void:
 layer=CanvasLayer.new();add_child(layer)
 loading=preload("res://scripts/ui/loading_manager.gd").new();loading.game=self;add_child(loading)
 launch()
func launch() -> void:
 if not loading.begin("initial",launch):return
 if not await loading.prepare(["res://scenes/main.tscn"]):return
 var scene: PackedScene=loading.held_resources[0]
 var main:=scene.instantiate()
 if main==null:loading.failure("시작 화면을 준비하지 못했습니다.");return
 get_tree().root.add_child(main);get_tree().current_scene=main;main.sound.set_backgrounded(backgrounded)
 await get_tree().process_frame
 loading.complete();main.set_meta("bootstrap_metrics",loading.history.duplicate(true))
 await get_tree().create_timer(preload("res://scripts/ui/design.gd").POPUP_TIME+.02).timeout
 queue_free()
func _notification(what: int) -> void:
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT or what==NOTIFICATION_APPLICATION_PAUSED:backgrounded=true
 elif what==NOTIFICATION_APPLICATION_FOCUS_IN or what==NOTIFICATION_APPLICATION_RESUMED:backgrounded=false
 if what==NOTIFICATION_WM_GO_BACK_REQUEST and is_instance_valid(loading) and loading.failed:get_tree().quit()
