class_name WooActor
extends CharacterBody2D
signal landed
var jump_height:=0.0
var jump_velocity:=0.0
var landing_left:=0.0
var air_chain:=false
var action_pose:=-1
var action_left:=0.0
## 마지막으로 사용한 도술 id. 발동 모션(시전 고리 색·형태)에 쓴다.
var action_skill:=""
var push_left:=0.0
var push_direction:=Vector2.ZERO
var hurt_left:=0.0
var hurt_stun:=0.0
var hurt_knock:=Vector2.ZERO
var defeated:=false
var defeat_elapsed:=0.0
var cosmetic: Dictionary=preload("res://scripts/wardrobe/catalog.gd").DEFAULT.duplicate()
var wardrobe_visual: WooWardrobeVisual
var hero_rig: WooHeroRig
var appearance_back: Node2D
var pose_duration:=.3
var jump_preparation:=0.0
var jump_phase:="ground"
var network_remote:=false
var identity_concealed:=false
var appearance_form:="human"
## 둔갑 사물의 월드 크기와 발밑 그림자 반지름. 부르는 쪽(app.gd)이 layout.gd의
## FORM_VISUALS 값을 넣어, 맵에 놓인 같은 사물과 픽셀 크기·위치가 같아진다.
var form_height:=46.0
var form_shadow:=16.0
## 이 액터 노드에 걸린 배율(actor.scale). 둔갑 그림은 월드 크기를 이 값으로 나눠 쓴다.
var costume_scale:=1.0
## 인게임 2.5D 원화 캐릭터 사용 여부. 코드/테스트의 기존 wardrobe 경로는 그대로 둔다.
var ingame_art:=false:
	set(value):
		ingame_art=value
		if is_instance_valid(ingame_sprite):
			ingame_sprite.visible=value
			draw_ground=not value
		if is_instance_valid(wardrobe_visual):wardrobe_visual.visible=not value
		if value and is_instance_valid(sprite):sprite.visible=false
		queue_redraw()
var ingame_sprite: Node2D
var extracted_visual: SealEnvironmentAsset
const SKILL_SHEET=preload("res://assets/woo/v20/skills.png")
const SEOWON_FORMS={"jar":preload("res://assets/woo/seowon/prop_jar.png"),"crate":preload("res://assets/woo/seowon/prop_crate.png"),"lantern":preload("res://assets/woo/seowon/prop_lantern.png"),"stele":preload("res://assets/woo/seowon/prop_stele.png"),"cat":preload("res://assets/woo/seowon/prop_cat.png"),"dog":preload("res://assets/woo/seowon/prop_crate.png")}
## 2.0.27: 맵을 실제로 걷는 고양이·강아지의 2프레임 걷기 원화. 둔갑하면 그 동물과
## 같은 원화·같은 걷기 박자로 움직인다.
const C=preload("res://scripts/survival/characters.gd")
var animal_textures: Dictionary={}
const ANIMAL_KINDS=["cat","dog"]
## 2.0.28: 둔갑한 고양이·강아지도 맵의 동물과 같은 22~26px 크기로 그린다.
const ANIMAL_HEIGHT={"cat":22.0,"dog":26.0}
var dash_left:=0.0
var dash_direction:=Vector2.ZERO
var combat_frozen:=false
var intent := Vector2.ZERO
var enabled := true
var running := false
var jar := false
var npc := false
var npc_variant := 0
var npc_name := ""
var tint := Color.WHITE
## 마켓에서 장착한 도포 색(원화 위에 옅게 얹는다).
var skin_tint := Color.WHITE
## 인게임 원화 id(예: woochi, gumiho). 비어 있으면 cosmetic.character를 쓴다.
var art_id := ""
var facing := 2
var locomotion_velocity:=Vector2.ZERO
var gait_phase:=0.0
var gait_weight:=0.0
var animation_time := 0.0
var cooldown := 0.0
var transforming := 0.0
var transform_target := false
var highlighted := false
var sprite: Sprite2D
var npc_origin := Vector2.ZERO
var npc_phase := 0.0
var npc_driver: WooNpcDriver
var npc_attention:=false
var npc_render_visible:=true
var npc_walking:=false
var npc_stride:=0.0
var npc_visual: Node2D
var npc_torso: Sprite2D
var npc_knees: Sprite2D
var npc_left_foot: Sprite2D
var npc_right_foot: Sprite2D
var npc_head_rect:=Rect2()
var npc_pose_key:=""
var previous_highlighted:=false
const NPC_ART=preload("res://scripts/woo/npc_art.gd")
const WALK_SPEED := 88.0
const RUN_SPEED := 142.0
const JAR_SPEED := 46.0
const TRANSFORM_TIME := 0.42
const SPELL_COOLDOWN := 2.5
const FRAMES = preload("res://scripts/woo/art_frames.gd")
const SHEET = preload("res://assets/woo/hd/hero.png")
const NPC_SHEET = preload("res://assets/woo/hd/villagers_jars.png")
const JAR = preload("res://assets/woo/jar.png")
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	collision_layer = 2
	collision_mask = 1
	var collider := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6
	collider.shape = circle
	add_child(collider)
	sprite = Sprite2D.new()
	sprite.modulate = tint
	if npc:
		common_nameplate=preload("res://scripts/ui/nameplate.gd").new();common_nameplate.title=npc_name;common_nameplate.position=Vector2(0,-65);add_child(common_nameplate)
		npc_visual=Node2D.new();add_child(npc_visual)
		npc_visual.add_child(sprite)
		npc_torso=Sprite2D.new();npc_visual.add_child(npc_torso)
		npc_knees=Sprite2D.new();npc_visual.add_child(npc_knees)
		npc_left_foot=Sprite2D.new();npc_visual.add_child(npc_left_foot)
		npc_right_foot=Sprite2D.new();npc_visual.add_child(npc_right_foot)
	else:
		add_child(sprite)
		appearance_back=Node2D.new();add_child(appearance_back)
		hero_rig=preload("res://scripts/woo/hero_rig.gd").new();hero_rig.actor=self;add_child(hero_rig)
		wardrobe_visual=preload("res://scripts/art/mascot_renderer.gd").new();wardrobe_visual.actor=self;add_child(wardrobe_visual)
		ingame_sprite=preload("res://scripts/art/ingame_sprite.gd").new();ingame_sprite.actor=self;ingame_sprite.visible=false;add_child(ingame_sprite)
		extracted_visual=preload("res://scripts/seal/environment_asset.gd").new();extracted_visual.hide();add_child(extracted_visual)
	npc_origin = position
func jump() -> bool:
	if npc or not enabled or defeated or jump_height>0 or jump_velocity>0 or jump_preparation>0 or transforming>0:return false
	jump_preparation=.07;jump_phase="preparation";return true
func reset_action() -> void:
	locomotion_velocity=Vector2.ZERO
	jump_height=0;jump_velocity=0;jump_preparation=0;jump_phase="ground";action_left=0;action_pose=-1;hurt_stun=0;hurt_left=0;hurt_knock=Vector2.ZERO;defeated=false;defeat_elapsed=0.0;air_chain=false;push_left=0;dash_left=0;combat_frozen=false
func direction() -> Vector2:
	if not enabled or transforming>0 or hurt_stun>0 or defeated: return Vector2.ZERO
	if npc: return intent.limit_length()
	var keyboard := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	return (intent if intent.length()>0.05 else keyboard).limit_length()
func begin_transform() -> bool:
	if npc or not enabled or transforming>0 or cooldown>0: return false
	transform_target = not jar
	transforming = TRANSFORM_TIME
	velocity = Vector2.ZERO
	locomotion_velocity=Vector2.ZERO
	return true
func _physics_process(delta: float) -> void:
	if network_remote:
		transforming=maxf(0,transforming-delta);update_sprite();queue_redraw();return
	if defeated:defeat_elapsed+=delta
	if combat_frozen and not npc:
		velocity=Vector2.ZERO;locomotion_velocity=Vector2.ZERO;return
	if not npc and enabled:
		action_left=maxf(0,action_left-delta);hurt_left=maxf(0,hurt_left-delta);hurt_stun=maxf(0,hurt_stun-delta);landing_left=maxf(0,landing_left-delta)
		if jump_preparation>0:
			jump_preparation=maxf(0,jump_preparation-delta)
			if jump_preparation==0:jump_velocity=215.0
		if jump_velocity!=0 or jump_height>0:
			jump_height=maxf(0,jump_height+jump_velocity*delta);jump_velocity-=590*delta
			jump_phase="apex" if absf(jump_velocity)<35 else ("rising" if jump_velocity>0 else "falling")
			if jump_height==0 and jump_velocity<0:jump_velocity=0;landing_left=.18;jump_phase="landing";landed.emit()
	cooldown = maxf(0,cooldown-delta)
	if transforming>0:
		var before := transforming
		transforming = maxf(0,transforming-delta)
		if before>TRANSFORM_TIME/2 and transforming<=TRANSFORM_TIME/2: jar = transform_target
		if transforming==0: cooldown = SPELL_COOLDOWN
	if npc:
		if not enabled:
			velocity=Vector2.ZERO
			if npc_walking:npc_walking=false;update_sprite()
			return
		intent=npc_driver.step(self,delta,npc_attention) if npc_driver!=null else Vector2.ZERO
	var move := direction()
	var speed := JAR_SPEED if jar else (RUN_SPEED if running or Input.is_physical_key_pressed(KEY_SHIFT) else WALK_SPEED)
	if npc:speed=npc_driver.movement_speed if npc_driver!=null else 24.0
	velocity = move*speed
	if not npc:
		if not enabled or transforming>0 or defeated:locomotion_velocity=Vector2.ZERO;velocity=Vector2.ZERO
		locomotion_velocity=locomotion_velocity.move_toward(velocity,(780.0 if move.length()>.05 else 1000.0)*delta)
		velocity=locomotion_velocity
	if dash_left>0 and enabled and not npc:
		dash_left=maxf(0,dash_left-delta);velocity=dash_direction*360.0
	if not npc and enabled:
		if action_left>0:velocity*=.35
		if push_left>0:push_left=maxf(0,push_left-delta);velocity+=push_direction*70
		velocity+=hurt_knock;hurt_knock=hurt_knock.move_toward(Vector2.ZERO,delta*350)
	if defeated:velocity=Vector2.ZERO
	var previous:=position
	move_and_slide()
	var distance:=position.distance_to(previous)
	if not npc:
		gait_phase+=distance*.13
		gait_weight=move_toward(gait_weight,1.0 if distance>delta*2 and action_left<=0 and jump_height==0 else 0.0,delta*10)
	if npc:
		npc_walking=distance>delta*1.0
		if npc_walking:
			npc_stride+=distance
			facing=posmod(roundi((position-previous).angle()/(PI/4)),8)
		if npc_driver!=null:npc_driver.report_progress(distance,move,delta)
	elif move.length()>0.05:facing=preload("res://scripts/wardrobe/direction.gd").quantize(move.normalized(),facing)
	animation_time += delta*(11 if running and not jar else 7) if velocity.length()>2 else delta
	if not npc or npc_render_visible:update_sprite()
	if not npc or highlighted!=previous_highlighted:queue_redraw()
	if common_nameplate!=null:common_nameplate.visible=highlighted and npc_render_visible;common_nameplate.queue_redraw()
	previous_highlighted=highlighted
func update_sprite() -> void:
	if npc:
		update_npc_art()
		return
	if ingame_art:
		if is_instance_valid(wardrobe_visual):wardrobe_visual.hide()
		if is_instance_valid(ingame_sprite):ingame_sprite.visible=appearance_form=="" or appearance_form=="human"
	if appearance_form.begins_with("seowon:"):
		var form_kind:=appearance_form.trim_prefix("seowon:")
		if form_kind in ANIMAL_KINDS:
			# 동물 둔갑: 맵의 고양이·강아지와 같은 4x4 걷기 시트를 같은 박자로 재생한다.
			var sheet: Dictionary=C.animal_sheet(form_kind)
			var animal_height: float=float(ANIMAL_HEIGHT.get(form_kind,40.0))
			var local_animal: float=animal_height/maxf(costume_scale,.01)
			if not sheet.is_empty():
				var sheet_path: String=String(sheet.get("sheet",""))
				var animal_sheet_texture: Texture2D=animal_textures.get(sheet_path)
				if animal_sheet_texture==null:animal_sheet_texture=load(sheet_path);animal_textures[sheet_path]=animal_sheet_texture
				var cell: Array=sheet.get("cell",[300,260])
				var rows: Array=sheet.get("rows",["front","left","right","back"])
				var mapped: Dictionary=C.sheet_row(rows,facing)
				var row: int=int(mapped.row)
				var cols: int=int(sheet.get("cols",4))
				var column: int=posmod(int(floor(gait_phase/(PI*.62))),cols) if gait_weight>.05 else 0
				var extent:=Vector2(float(cell[0]),float(cell[1]))
				var animal_scale: float=local_animal/maxf(1.0,C.sheet_art_height(sheet))
				sprite.texture=animal_sheet_texture;sprite.region_enabled=true
				sprite.region_rect=Rect2(Vector2(float(column)*extent.x,float(row)*extent.y),extent)
				sprite.centered=false;sprite.offset=Vector2.ZERO
				sprite.scale=Vector2(animal_scale,animal_scale)
				var foot: Array=sheet.get("foot",[150.0,232.0])
				sprite.position=-Vector2(float(foot[0]),float(foot[1]))*animal_scale
				sprite.flip_h=false
			form_height=animal_height
			sprite.visible=true
			sprite.modulate=Color("e5d8ff") if transforming>0 else Color.WHITE
			if is_instance_valid(extracted_visual):extracted_visual.visible=false
			return
		var form_texture: Texture2D=SEOWON_FORMS.get(form_kind,SEOWON_FORMS.jar)
		# 맵 사물과 같은 월드 높이. 액터 배율만큼 나눠 로컬 크기를 맞춘다.
		var local_height: float=form_height/maxf(costume_scale,.01)
		sprite.texture=form_texture;sprite.region_enabled=false;sprite.centered=true
		sprite.scale=Vector2.ONE*(local_height/form_texture.get_height())
		sprite.offset=Vector2.ZERO;sprite.position=Vector2(0,-local_height*.5)
		sprite.visible=true;sprite.flip_h=false
		if is_instance_valid(extracted_visual):extracted_visual.visible=false
		# 둔갑 중에는 캐릭터 색조를 섮지 않는다(진짜 사물과 같은 색).
		sprite.modulate=Color("e5d8ff") if transforming>0 else Color.WHITE
		return
	var region: Array
	var ratio: float
	if jar or appearance_form=="jar":
		sprite.texture=NPC_SHEET
		var view:=2 if facing in [5,6,7] else (0 if facing==2 else 1)
		region=FRAMES.VILLAGERS_JARS[6+view]
		ratio=0.13
	elif appearance_form=="cat":
		sprite.texture=SKILL_SHEET
		var cell:=SKILL_SHEET.get_width()/4.0
		region=[0,cell,cell,cell,cell/2,cell*.92];ratio=.15
	else:
		sprite.texture=SHEET
		var frame:=4
		region=FRAMES.HERO[frame*8+facing]
		ratio=0.34
	sprite.region_enabled=true
	sprite.region_rect=Rect2(region[0],region[1],region[2],region[3])
	sprite.scale=Vector2.ONE*ratio
	sprite.offset=Vector2(region[2]/2.0-region[4],region[3]/2.0-region[5])
	sprite.flip_h=false
	sprite.visible=jar or (appearance_form!="human" and not appearance_form.begins_with("asset:"))
	if is_instance_valid(extracted_visual):
		extracted_visual.visible=appearance_form.begins_with("asset:")
		if extracted_visual.visible:
			extracted_visual.kind=appearance_form.trim_prefix("asset:");extracted_visual.facing=facing;extracted_visual.moving=velocity.length()>2;extracted_visual.queue_redraw()
	sprite.position=Vector2(0,-jump_height)
	sprite.modulate=tint.lerp(Color("e5d8ff"),0.5+sin(transforming*30)*0.25) if transforming>0 else tint

	if hurt_left>0:sprite.modulate=Color(1,.36,.38)
	if defeated:sprite.rotation=-.9*smoothstep(0,.3,defeat_elapsed)
	else:sprite.rotation=0

func npc_part(node: Sprite2D,row: Array,column: int,top: int,bottom: int,left: int=0,width: int=-1) -> void:
	var cell_w: int=row[1]
	var scale_factor: float=row[7]
	node.texture=NPC_ART.SHEET;node.region_enabled=true;node.centered=false
	node.region_rect=Rect2(column*cell_w+left,int(row[0])+top,cell_w if width<0 else width,bottom-top)
	node.scale=Vector2.ONE*scale_factor
	node.position=Vector2((left-cell_w/2.0)*scale_factor,(top-int(row[3]))*scale_factor)

func update_npc_art() -> void:
	var back:=facing in [5,6,7]
	var row_id:=clampi(npc_variant,0,2)*2+(1 if back else 0)
	var row: Array=NPC_ART.ROWS[row_id]
	var gait:=posmod(int(npc_stride/6.0),4) if npc_walking else 1
	var work:=npc_driver!=null and npc_driver.state=="work" and not npc_attention and npc_driver.work_time<2.0
	var torso:=posmod(int(npc_driver.work_time*2),4) if work else gait
	var key: String="%s:%d:%d" % [back,gait,torso]
	if key!=npc_pose_key:
		npc_pose_key=key
		npc_part(sprite,row,1,0,row[4])
		npc_head_rect=sprite.region_rect
		npc_part(npc_torso,row,torso,row[4],row[5])
		npc_part(npc_knees,row,gait,row[5],row[6])
		npc_part(npc_left_foot,row,gait,row[6],row[3],0,int(row[1])/2)
		npc_part(npc_right_foot,row,gait,row[6],row[3],int(row[1])/2,int(row[1])/2)
	npc_visual.scale.x=-1.0 if facing in [3,4,5] else 1.0
	# Only the two feet articulate, with opposite swing/contact phases; no whole-body bob.
	var scale_factor: float=row[7]
	npc_left_foot.position=Vector2(-row[1]/2.0*scale_factor,(row[6]-NPC_ART.FOOT_BOTTOMS[row_id][gait][0])*scale_factor)
	npc_right_foot.position=Vector2(0,(row[6]-NPC_ART.FOOT_BOTTOMS[row_id][gait][1])*scale_factor)
	var phase:=sin(npc_stride/24.0*TAU) if npc_walking else 0.0
	npc_left_foot.position+=Vector2(phase*1.0,-maxf(0,phase)*.8)
	npc_right_foot.position+=Vector2(-phase*1.0,-maxf(0,-phase)*.8)

var common_nameplate: WooNPCNameplate
var draw_ground:=true
func _draw() -> void:
	if not draw_ground:return
	if not appearance_form.begins_with("asset:"):
		draw_colored_polygon(PackedVector2Array([Vector2(-10,0),Vector2(0,-4),Vector2(12,1),Vector2(1,5)]),Color(0.02,0.04,0.06,0.38))
	if landing_left>0:
		draw_arc(Vector2.ZERO,10+(1-landing_left/.18)*12,0,TAU,16,Color(.8,.75,.65,landing_left/.18*.5),2)
	if highlighted:
		draw_colored_polygon(PackedVector2Array([Vector2(-12,0),Vector2(0,-6),Vector2(12,0),Vector2(0,6)]),Color(0.9,0.75,0.4,0.35))
	if transforming>0:
		var phase := 1-transforming/TRANSFORM_TIME
		for i in range(10):
			var angle := TAU*i/10+phase*4
			var p := Vector2(cos(angle)*(10+phase*14),sin(angle)*(6+phase*9)-14)
			draw_rect(Rect2(p.floor(),Vector2(3,3)),Color("f4da8b"))
			if i%2==0: draw_rect(Rect2(p.floor()+Vector2(-4,-4),Vector2(2,2)),Color("8cb5ab"))

		for side in [-1,1]:
			var points:=PackedVector2Array([Vector2(side*17,-40),Vector2(side*24,-30),Vector2(side*15,-22),Vector2(side*22,-12)])
			draw_polyline(points,Color("9abaff"),1.5,true)
