class_name SealLoadout
extends RefCounted
const C=preload("res://scripts/seal/catalog.gd")
static func capacity(tier: String) -> int:return 3 if tier=="pass" else 2
static func known(raw: Variant) -> Array:
 var out: Array=[]
 if raw is Array:
  for id in raw:
   if id is String and C.COMMON.has(id) and not out.has(id):out.append(id)
 return out
static func select_spells(owned: Array,tier: String,requested: Variant,reserve: Variant,rng: RandomNumberGenerator) -> Dictionary:
 var available:=known(owned);var main: Array=[]
 if tier=="free":
  for i in range(available.size()-1,0,-1):
   var j:=rng.randi_range(0,i);var swap=available[i];available[i]=available[j];available[j]=swap
  main=available.slice(0,mini(2,available.size()))
 elif tier in ["paid","vip","pass"]:
  if not requested is Array or requested.size()>capacity(tier):return {"error":"서버 권한의 장착 칸을 초과했습니다"}
  for id in requested:
   if not id is String or not available.has(id) or main.has(id):return {"error":"미획득 또는 중복 도술입니다"}
   main.append(id)
 else:return {"error":"서버 이용 등급이 올바르지 않습니다"}
 var extra: String=str(reserve) if tier=="vip" else ""
 if extra!="" and (not available.has(extra) or main.has(extra)):return {"error":"예비 도술은 획득한 별도 도술1개만 가능합니다"}
 while main.size()<capacity(tier):main.append("")
 return {"slots":main,"reserve":extra,"tier":tier}
