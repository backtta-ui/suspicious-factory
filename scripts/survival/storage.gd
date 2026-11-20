extends RefCounted
const PATH="user://survival_v13.json"
var error:=""
var data: Dictionary={"version":1,"daoist":"daoist:woochi","yokai":"yokai:woochi","music":.7,"sfx":.8,"music_mute":false,"sfx_mute":false,"vibration":false,"quality":"보통","sensitivity":1.0,"debug_map":"random",
 "nickname":"",
 "coins":0,"gems":0,
 "stats":{"matches":0,"wins":0,"seals":0,"rescues":0,"doors":0,"disguises":0},
 "market":{"owned":["default"],"equipped":{"skin":"default","title":"","effect":""}},
 "characters":{"owned":["daoist:woochi","daoist:yeonhwa","yokai:gumiho","yokai:jangsanbeom"]},
 "achievements":{"claimed":[]},
 "mail":{"read":[],"claimed":[]},
 "alerts":{"read":[]},
 "room_codes":[]}
func _init() -> void:
 backup_legacy()
 if FileAccess.file_exists(PATH):
  var raw=JSON.parse_string(FileAccess.get_file_as_string(PATH))
  if raw is Dictionary:
   for key in data:
    if not raw.has(key):continue
    # 2.0.32: JSON은 모든 숫자를 실수로 읽어 오므로, 정수 기본값(코인·보석)이
    # 타입 불일치로 버려져 재실행 시 0이 되던 문제를 바로잡는다.
    if data[key] is int and raw[key] is float:
     data[key]=int(raw[key]);continue
    if data[key] is float and raw[key] is int:
     data[key]=float(raw[key]);continue
    if typeof(raw[key])!=typeof(data[key]):continue
    if raw[key] is Dictionary:
     # A save written before a new field existed keeps the new default for it.
     var merged: Dictionary=data[key].duplicate(true)
     merged.merge(raw[key],true)
     data[key]=merged
    else:data[key]=raw[key]
 var roster: RefCounted=preload("res://scripts/survival/characters.gd")
 for team in ["daoist","yokai"]:
  # A save written before a roster change falls back to that team's first entry.
  if roster.find(data[team]).is_empty():data[team]=roster.catalog(team)[0].id
 # 2.0.28 테스트·체험 단계: 도사 5인 · 요괴 5인 10명 전원을 저장 상태와 무관하게
 # 기본 해금한다(캐릭터 선택·빠른 매치·연습에서 모두 바로 고를 수 있다).
 var owned: Array=data.characters.owned
 for team in ["daoist","yokai"]:
  for entry in roster.catalog(team):
   var id: String=String(entry.id)
   if not owned.has(id):owned.append(id)
 data.characters.owned=owned
 data.music=clampf(data.music,0,1);data.sfx=clampf(data.sfx,0,1);data.sensitivity=clampf(data.sensitivity,.6,1.5)
 # 2.0.34 무료 스킨(부침개 전우치)은 처음부터 보유 목록에 둔다(결제 없음).
 var owned_skins: Array=data.market.owned
 if not owned_skins.has("woochi_pancake"):owned_skins.append("woochi_pancake")
 data.market.owned=owned_skins
 # 2.0.32: 재화는 정수로만 다룬다(JSON이 실수로 읽어 와도 지갑·상점 표시가 흔들리지 않게).
 data.coins=maxi(0,int(data.coins));data.gems=maxi(0,int(data.gems))
func backup_legacy() -> void:
 var dir:="user://legacy-backup-v13"
 if FileAccess.file_exists(dir+"/manifest.json"):return
 if DirAccess.make_dir_recursive_absolute(dir)!=OK:error="기존 저장 백업 폴더를 만들 수 없습니다.";return
 var manifest: Dictionary={}
 for name in DirAccess.get_files_at("user://"):
  if name.begins_with("survival_v13"):continue
  var from:="user://"+name;var to:=dir+"/"+name
  if DirAccess.copy_absolute(from,to)!=OK:error="기존 저장 백업에 실패했습니다.";return
  manifest[name]={"sha256":FileAccess.get_sha256(from),"bytes":FileAccess.get_file_as_bytes(from).size()}
 var f:=FileAccess.open(dir+"/manifest.json",FileAccess.WRITE)
 if f==null:error="백업 기록을 저장하지 못했습니다.";return
 f.store_string(JSON.stringify(manifest,"  "))
func save() -> Error:
 var f:=FileAccess.open(PATH+".tmp",FileAccess.WRITE)
 if f==null:return FileAccess.get_open_error()
 f.store_string(JSON.stringify(data));f.flush();var result:=f.get_error();f.close()
 if result!=OK:return result
 return DirAccess.rename_absolute(PATH+".tmp",PATH)
## 2.0.32 닉네임: 최초 실행 시 화면에서 정하고, 친구 방·결과 화면·로비 상단 프로필에 쓴다.
## 인게임 필드 이름표는 인간둔갑 위장을 위해 기존처럼 캐릭터 이름을 쓴다.
func nickname() -> String:return String(data.get("nickname","")).strip_edges()
func has_nickname() -> bool:return nickname().length()>0
func set_nickname(value: String) -> void:data.nickname=nickname_rules(value)
## 검증을 통과한 닉네임을 돌려준다(공백 제거).
static func nickname_rules(value: String) -> String:return value.strip_edges()
## 닉네임 검증: 2~10자, 한글·영문·숫자만. 문제가 있으면 안내 문구를, 없으면 ""를 돌려준다.
static func nickname_error(value: String) -> String:
 var text:=value.strip_edges()
 if text.length()<2:return "닉네임은 2자 이상이어야 합니다."
 if text.length()>10:return "닉네임은 10자까지 정할 수 있습니다."
 for index in range(text.length()):
  var code:=text.unicode_at(index)
  var hangul: bool=(code>=0xAC00 and code<=0xD7A3) or (code>=0x3131 and code<=0x318E)
  var latin: bool=(code>=0x41 and code<=0x5A) or (code>=0x61 and code<=0x7A)
  var digit: bool=code>=0x30 and code<=0x39
  if not (hangul or latin or digit):return "공백과 특수문자는 쓸 수 없습니다. 한글·영문·숫자로 정해 주세요."
 return ""
## 마켓·업적·우편에서 쓰는 재화/통계 갱신. 저장은 호출한 쪽이 결정한다.
## 2.0.32: 이 게임에는 레벨·경험치가 없다. 재화는 코인과 보석 두 가지뿐이다.
func coins() -> int:return int(data.coins)
func gems() -> int:return int(data.gems)
func add_coins(value: int) -> void:data.coins=maxi(0,int(data.coins)+value)
func add_gems(value: int) -> void:data.gems=maxi(0,int(data.gems)+value)
## 잔액이 모자라면 아무것도 바꾸지 않고 false를 돌려준다(상점·해금 공통).
func spend_coins(value: int) -> bool:
 if value<0 or int(data.coins)<value:return false
 data.coins=int(data.coins)-value;return true
func spend_gems(value: int) -> bool:
 if value<0 or int(data.gems)<value:return false
 data.gems=int(data.gems)-value;return true
## 경기·업적·우편 보상 지급을 한 곳에서 처리한다.
func grant(coin_amount: int,gem_amount: int=0) -> void:
 add_coins(coin_amount);add_gems(gem_amount)
func stat(key: String) -> int:return int((data.stats as Dictionary).get(key,0))
func bump(key: String,value: int=1) -> void:data.stats[key]=stat(key)+value
func owns(item: String) -> bool:return (data.market.owned as Array).has(item)
func own(item: String) -> void:
 if not owns(item):(data.market.owned as Array).append(item)
func equip(kind: String,id: String) -> void:data.market.equipped[kind]=id
func equipped(kind: String) -> String:return String((data.market.equipped as Dictionary).get(kind,""))
## 캐릭터 해금 상태. 무료 캐릭터는 처음부터 보유한다.
func owns_character(id: String) -> bool:return (data.characters.owned as Array).has(id)
func own_character(id: String) -> void:
 if not owns_character(id):(data.characters.owned as Array).append(id)
