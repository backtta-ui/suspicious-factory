class_name SealArena
extends RefCounted
## Map data + collision queries. No rendering dependency or per-match global map state.
const Village=preload("res://scripts/woo/village_layout.gd")
const Forest=preload("res://scripts/woo/forest_layout.gd")
const REGISTRY={
 "village":{"name":"달빛 계월촌","size":Vector2(3400,1900),"spawn":Vector2(900,690),"altar":Vector2(1140,670),"jail":Vector2(2380,1210),"stations":[Vector2(900,700),Vector2(1180,950),Vector2(1840,650),Vector2(2260,900),Vector2(2640,560),Vector2(1440,1300),Vector2(2200,1120),Vector2(780,980)],"layout":"res://scripts/woo/village_layout.gd","scene":"res://scripts/woo/village.gd"},
 "forest":{"name":"안개 속 여우의 숲","size":Vector2(3000,2160),"spawn":Vector2(320,780),"altar":Vector2(1150,690),"jail":Vector2(2520,1400),"stations":[Vector2(490,690),Vector2(980,580),Vector2(1320,1080),Vector2(1800,1100),Vector2(2180,1080),Vector2(2460,700),Vector2(2600,1300),Vector2(2650,1690)],"layout":"res://scripts/woo/forest_layout.gd","scene":"res://scripts/woo/forest.gd"}}
const KINDS={
 "jar":{"name":"항아리","type":"object","radius":6.0,"size":Vector2(19,24),"trackable":true},
 "crate":{"name":"나무 상자","type":"object","radius":9.0,"size":Vector2(24,22),"trackable":true},
 "basket":{"name":"바구니","type":"object","radius":7.0,"size":Vector2(23,18),"trackable":true},
 "lantern":{"name":"등불","type":"object","radius":6.0,"size":Vector2(19,29),"trackable":true},
 "straw":{"name":"짚단","type":"object","radius":8.0,"size":Vector2(24,25),"trackable":true},
 "door":{"name":"문짝","type":"object","radius":8.0,"size":Vector2(18,35),"trackable":true},
 "dummy":{"name":"허수아비","type":"object","radius":7.0,"size":Vector2(27,35),"trackable":true},
 "cat":{"name":"고양이","type":"animal","radius":0.0,"size":Vector2(22,23),"trackable":true},
 "dog":{"name":"강아지","type":"animal","radius":0.0,"size":Vector2(24,25),"trackable":true},
 "chicken":{"name":"닭","type":"animal","radius":0.0,"size":Vector2(18,22),"trackable":true}}
var id: String
var data: Dictionary
var layout: Script
var altar: Vector2
var jail: Vector2
var assets: Array[Dictionary]=[]
var cache: Dictionary={}
var sight_cache: Dictionary={}
var spawn_points: Array[Vector2]=[]
func _init(map_id: String="village") -> void:
 id=map_id if REGISTRY.has(map_id) else "village";data=REGISTRY[id];layout=load(data.layout);altar=data.altar;jail=data.jail
 var centers: Array=data.stations
 for i in range(20):
  var kind: String=KINDS.keys()[i%KINDS.size()]
  var p: Vector2=centers[i%centers.size()]+Vector2(75+(i/8)*38,55 if i%2==0 else -55)
  if not base_stand(p,12):p=centers[i%centers.size()]+Vector2(-50,40)
  if base_stand(p,12):assets.append({"id":"%s_%d"%[id,i],"kind":kind,"origin":p,"extractable":true,"interactable":true,"transformable":true,"reacts":["transform","track"],"radius":KINDS[kind].radius,"resource":kind})
 for i in range(8):spawn_points.append(safe(data.spawn+Vector2((i%4)*56,(i/4)*60)))
func base_stand(p: Vector2,margin: float=9) -> bool:return layout.can_stand(p,margin)
func can_stand(p: Vector2) -> bool:
 if not is_finite(p.x) or not is_finite(p.y):return false
 var cell:=Vector2i(floori(p.x/3),floori(p.y/3))
 if not cache.has(cell):
  var q:=Vector2(cell)*3+Vector2(1.5,1.5);var valid:=base_stand(q,9)
  if valid:
   for asset in assets:
    if asset.radius>0 and q.distance_to(asset.origin)<asset.radius+7:valid=false;break
  cache[cell]=valid
 return cache[cell]
func safe(p: Vector2) -> Vector2:
 if can_stand(p):return p
 for r in range(12,145,12):
  for i in range(16):
   var q:=p+Vector2.from_angle(i*TAU/16)*r
   if can_stand(q):return q
 return data.spawn
func sight(p: Vector2) -> bool:
 var cell:=Vector2i(floori(p.x/4),floori(p.y/4))
 if not sight_cache.has(cell):sight_cache[cell]=base_stand(Vector2(cell)*4+Vector2(2,2),3)
 return sight_cache[cell]
func line(a: Vector2,b: Vector2) -> bool:
 var n:=maxi(1,ceili(a.distance_to(b)/8))
 for i in range(1,n):
  if not sight(a.lerp(b,float(i)/n)):return false
 return true
func move(from: Vector2,to: Vector2) -> Vector2:
 var n:=maxi(1,ceili(from.distance_to(to)/3));var current:=from
 var step: Vector2=(to-from)/n
 for i in range(n):
  var next:=current+step
  if can_stand(next):current=next
  elif can_stand(Vector2(next.x,current.y)):current.x=next.x
  elif can_stand(Vector2(current.x,next.y)):current.y=next.y
  else:break
 return current
func asset_position(asset: Dictionary,time: float) -> Vector2:
 if KINDS[asset.kind].type!="animal":return asset.origin
 return move(asset.origin,asset.origin+Vector2(sin(time*.5+assets.find(asset)),cos(time*.35+assets.find(asset)))*16)
func public_assets(time: float) -> Array:
 var out: Array=[]
 for asset in assets:
  var p:=asset_position(asset,time);out.append({"id":asset.id,"kind":asset.kind,"position":[p.x,p.y],"extractable":asset.extractable,"interactable":asset.interactable,"transformable":asset.transformable,"type":KINDS[asset.kind].type,"resource":asset.resource,"trackable":KINDS[asset.kind].trackable})
 return out
func find_asset(asset_id: String) -> Dictionary:
 for asset in assets:
  if asset.id==asset_id:return asset
 return {}
