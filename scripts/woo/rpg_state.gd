class_name WooRpgState
extends RefCounted
## Save-compatible, deterministic gameplay state. No scene or UI dependencies.
const VERSION=1
const CAPACITY=30
const ITEMS={
 "potion":{"name":"회복약","icon":"약","kind":"소모품","description":"체력을 45 회복합니다.","hp":45},
 "mana_potion":{"name":"도력 회복약","icon":"기","kind":"소모품","description":"도력을 30 회복합니다.","mp":30},
 "seal":{"name":"봉인 부적","icon":"符","kind":"부적","description":"부적술에 쓰이는 전통 부적입니다. 전투 도술은 도력을 소모합니다."},
 "leaf":{"name":"신비한 잎","icon":"잎","kind":"재료","description":"여우의 숲에서 발견한 신비로운 재료입니다."},
 "key":{"name":"오래된 열쇠","icon":"쇠","kind":"귀중품","description":"아직 용도를 알 수 없는 오래된 열쇠입니다."}}
const SPELLS={"jar":{"name":"둔갑술","description":"항아리로 변신 · 광장에서도 사용 가능","available":true},"talisman":{"name":"부적술","description":"도력 12 · 금빛 부적과 1.4초 봉인","available":true},"clone":{"name":"분신술","description":"아직 배우지 않은 도술","available":false},"blink":{"name":"축지법","description":"아직 배우지 않은 도술","available":false}}
const RANKS=["견습 도사","하급 도사","중급 도사","상급 도사","대도사"]
const REWARD={"xp":120,"coins":50,"items":{"potion":2,"leaf":3}}
var data: Dictionary
func _init(saved: Dictionary={}) -> void:
 data={"version":VERSION,"level":1,"xp":0,"hp":100,"mp":50,"coins":0,"inventory":{"potion":3,"mana_potion":2,"seal":1,"leaf":1,"key":1},"slots":["talisman","jar",""],"completed":[],"claims":[],"session":{},"effects":{"hit_stop":true,"flash":true,"shake":true,"particles":true}}
 for k in data:
  if saved.has(k):data[k]=saved[k].duplicate(true) if saved[k] is Array or saved[k] is Dictionary else saved[k]
 # JSON numbers are floats in Godot; canonicalize IDs before Array.has/comparisons.
 for k in ["level","xp","hp","mp","coins"]:data[k]=int(data[k])
 for id in data.inventory:data.inventory[id]=int(data.inventory[id])
 if not data.session.is_empty():
  data.session.facing=int(data.session.facing)
  data.session.defeated=data.session.defeated.map(func(id: Variant)->int:return int(id))
static func integer(value: Variant,low: int,high: int) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and float(value)==floorf(float(value)) and value>=low and value<=high
static func valid(value: Variant) -> bool:
 if not value is Dictionary:return false
 if value.is_empty():return true
 if value.get("version",0)!=VERSION:return false
 for k in ["level","xp","hp","mp","coins"]:
  if not integer(value.get(k,-1),1 if k=="level" else 0,99 if k=="level" else 1000000):return false
 if value.hp>100+(int(value.level)-1)*12 or value.mp>50+(int(value.level)-1)*5:return false
 if value.level<99 and value.xp>=int(value.level)*100:return false
 var inv=value.get("inventory",null)
 if not inv is Dictionary or inv.size()>CAPACITY:return false
 for k in inv:
  if not ITEMS.has(k) or not integer(inv[k],1,9999):return false
 var slots=value.get("slots",null)
 if not slots is Array or slots.size()!=3:return false
 var used=[]
 for s in slots:
  if not s is String or (s!="" and (not SPELLS.has(s) or not SPELLS[s].available or used.has(s))):return false
  if s!="":used.append(s)
 for k in ["completed","claims"]:
  if not value.get(k,null) is Array:return false
  if value[k].size()>1:return false
  for id in value[k]:
   if id!="fox_forest":return false
 if not value.get("effects",null) is Dictionary:return false
 for k in ["hit_stop","flash","shake","particles"]:
  if not value.get("effects",{}).get(k,null) is bool:return false
 var session=value.get("session",null)
 if not session is Dictionary:return false
 if not session.is_empty():
  if session.get("map","")!="fox_forest":return false
  var p=session.get("position",null)
  if not p is Array or p.size()!=2:return false
  for n in p:
   if not (n is float or n is int) or not is_finite(float(n)) or n<0 or n>1600:return false
  if not integer(session.get("facing",-1),0,7):return false
  var defeated=session.get("defeated",null)
  if not defeated is Array or defeated.size()>3:return false
  var seen=[]
  for id in defeated:
   if not integer(id,0,2) or seen.has(int(id)):return false
   seen.append(int(id))
  if not session.get("completed",null) is bool:return false
  if session.completed and defeated.size()!=3:return false
 return true
func max_hp() -> int:return 100+(int(data.level)-1)*12
func max_mp() -> int:return 50+(int(data.level)-1)*5
func xp_needed() -> int:return int(data.level)*100
func rank() -> String:
 # Promotion hooks intentionally remain apprentice until training conditions exist.
 return RANKS[0]
func count(id: String) -> int:return int(data.inventory.get(id,0))
func add_item(id: String,amount: int) -> bool:
 if not ITEMS.has(id) or amount<=0 or amount>9999 or count(id)+amount>9999:return false
 if count(id)==0 and data.inventory.size()>=CAPACITY:return false
 data.inventory[id]=count(id)+amount
 return true
func use_item(id: String) -> bool:
 if not ITEMS.has(id) or count(id)<=0:return false
 var item: Dictionary=ITEMS[id]
 if item.has("hp"):
  if data.hp>=max_hp():return false
  data.hp=mini(max_hp(),int(data.hp)+item.hp)
 elif item.has("mp"):
  if data.mp>=max_mp():return false
  data.mp=mini(max_mp(),int(data.mp)+item.mp)
 else:return false
 data.inventory[id]=count(id)-1
 if data.inventory[id]==0:data.inventory.erase(id)
 return true
func grant_xp(amount: int) -> void:
 if amount<=0:return
 data.xp+=amount
 while data.xp>=xp_needed() and data.level<99:
  data.xp-=xp_needed();data.level+=1;data.hp=max_hp();data.mp=max_mp()
func claim_fox_reward() -> bool:
 if data.claims.has("fox_forest"):return false
 for id in REWARD.items:
  if count(id)+REWARD.items[id]>9999 or (count(id)==0 and data.inventory.size()>=CAPACITY):return false
 grant_xp(REWARD.xp);data.coins+=REWARD.coins
 for id in REWARD.items:add_item(id,REWARD.items[id])
 data.claims.append("fox_forest")
 if not data.completed.has("fox_forest"):data.completed.append("fox_forest")
 return true
func equip(slot: int,id: String) -> bool:
 if slot<0 or slot>=3 or not SPELLS.has(id) or not SPELLS[id].available:return false
 var old:int=data.slots.find(id)
 if old>=0:data.slots[old]=""
 data.slots[slot]=id
 return true
