class_name WooPracticeRules
extends "res://scripts/seal/rules.gd"
## Explicitly local sandbox: no connection, account, career, result or persistence writes.
func check_win() -> void:pass

func command(uid: String,data: Dictionary) -> Dictionary:
 if str(data.get("op","")) not in ["move","extract","select_form","cast","rescue","escape","cancel_channel","unmask"]:return {"error":"도술 시험에는 임무·회의·투표 명령이 없습니다"}
 return super.command(uid,data)
