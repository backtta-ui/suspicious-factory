class_name WooActionConfig
extends RefCounted
const AIM_RANGE=220.0
const AIM_HALF_ANGLE=deg_to_rad(80)
const CONE_HALF_ANGLE=deg_to_rad(65)
const RANGES=[112.0,104.0,118.0,138.0]
const DAMAGE=[20,22,26,34]
const DURATION=[.30,.34,.42,.52]
const IMPACT=[.10,.12,.12,.20]
const COMBO_RESET=.95
const BUFFER_SIZE=3
const INVULNERABILITY=.5
const HURT_STUN=.13
const JUMP_SPEED=215.0
const GRAVITY=590.0
const MONSTER_REACH=52.0
const MONSTER_START=43.0
const WINDUP=.42
const TALISMAN_COST=12
const TALISMAN_COOLDOWN=2.2

const TALISMAN_DAMAGE=32
const TALISMAN_RANGE=145.0
const TALISMAN_SEAL_SECONDS=1.4
static func in_cone(origin: Vector2,aim: Vector2,target: Vector2,distance: float) -> bool:
 var delta:=target-origin
 return delta.length()<=distance+12 and absf(aim.angle_to(delta))<=CONE_HALF_ANGLE
