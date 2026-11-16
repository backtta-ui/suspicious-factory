class_name SealProgressTicket
extends RefCounted
## Authenticated checkpoints survive free-host disk replacement when the server key is preserved.
var key: PackedByteArray
func _init(secret: String) -> void:key=secret.to_utf8_buffer()
func issue(identity: Dictionary) -> String:
 var payload: String=Marshalls.raw_to_base64(JSON.stringify({"version":1,"uid":identity.uid,"auth":identity.hash,"owned":preload("res://scripts/seal/loadout.gd").known(identity.get("owned_spells",[])),"wins":int(identity.get("wins",0))}).to_utf8_buffer())
 var signature:=Crypto.new().hmac_digest(HashingContext.HASH_SHA256,key,payload.to_utf8_buffer()).hex_encode()
 return payload+"."+signature
func restore(token: Variant,identity: Dictionary) -> bool:
 if not token is String or token.length()>4096 or key.size()<32:return false
 var parts: PackedStringArray=token.split(".")
 if parts.size()!=2:return false
 var expected:=Crypto.new().hmac_digest(HashingContext.HASH_SHA256,key,parts[0].to_utf8_buffer())
 var claimed: String=parts[1]
 if claimed.length()!=64:return false
 for c in claimed:
  if not c in "0123456789abcdef":return false
 if not Crypto.new().constant_time_compare(expected,claimed.hex_decode()):return false
 var value=JSON.parse_string(Marshalls.base64_to_raw(parts[0]).get_string_from_utf8())
 if not value is Dictionary or value.get("version",0)!=1 or value.get("uid","")!=identity.uid or value.get("auth","")!=identity.hash or not preload("res://scripts/seal/catalog.gd").whole(value.get("wins",-1),0,100000):return false
 var owned: Array=preload("res://scripts/seal/loadout.gd").known(identity.get("owned_spells",[]))
 for skill in preload("res://scripts/seal/loadout.gd").known(value.get("owned",[])):
  if not owned.has(skill):owned.append(skill)
 identity.owned_spells=owned;identity.wins=maxi(int(identity.get("wins",0)),int(value.wins))
 return true
