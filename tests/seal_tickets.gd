extends SceneTree
const Ticket=preload("res://scripts/seal/progress_ticket.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if ok:print("PASS: "+label)
 else:failures+=1;push_error("FAIL: "+label)
func _initialize() -> void:
 var signer:=Ticket.new("test-only-key-not-a-production-secret-2026")
 var owner: Dictionary={"uid":"owner","hash":"a".repeat(64),"wins":12,"owned_spells":["transform","blink"]}
 var ticket:=signer.issue(owner)
 var restored: Dictionary={"uid":"owner","hash":"a".repeat(64),"wins":0,"owned_spells":[]}
 check(signer.restore(ticket,restored) and restored.wins==12 and restored.owned_spells==owner.owned_spells,"server-signed progress restores acquired spells and wins after host disk replacement")
 var parts:=ticket.split(".");var data=JSON.parse_string(Marshalls.base64_to_raw(parts[0]).get_string_from_utf8());data.wins=999;data.owned=["mask"]
 var forged: String=Marshalls.raw_to_base64(JSON.stringify(data).to_utf8_buffer())+"."+parts[1]
 check(not signer.restore(forged,restored) and restored.wins==12,"client cannot alter acquired list or win counter in signed receipt")
 var another: Dictionary={"uid":"other","hash":"a".repeat(64),"wins":0}
 check(not signer.restore(ticket,another),"receipt is bound to actual player ID")
 another={"uid":"owner","hash":"b".repeat(64),"wins":0}
 check(not signer.restore(ticket,another),"receipt also requires original anonymous authentication secret proof")
 check(not Ticket.new("different-test-only-server-key-1234567890").restore(ticket,restored),"different server signing key cannot validate another server's rewards")
 restored.wins=30;restored.owned_spells.append("shield");check(signer.restore(ticket,restored) and restored.wins==30 and restored.owned_spells.has("shield"),"older checkpoints cannot erase new wins or acquired spells")
 check(not signer.restore("bad",restored) and not signer.restore(parts[0]+"."+"z".repeat(64),restored),"malformed receipts rejected without engine errors")
 check(not restored.has("tier"),"progress receipt never grants paid or VIP entitlement")
 print("SEAL TICKETS: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
