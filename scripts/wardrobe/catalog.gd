class_name WooWardrobeCatalog
extends RefCounted
const DEFAULT={"character":"woochi","hair":"black","outfit":"basic","hat":"gat","accessory":"none","color":"navy","color_override":false}
const BASE_DEFAULTS={
 "woochi":{"hair":"black","outfit":"basic","hat":"gat","accessory":"none","color":"navy"},
 "yeonhwa":{"hair":"flower","outfit":"basic","hat":"none","accessory":"none","color":"pink"},
 "muyeong":{"hair":"tied","outfit":"basic","hat":"none","accessory":"none","color":"purple"},
 "hongryeon":{"hair":"long","outfit":"basic","hat":"hood","accessory":"ribbon","color":"red"}}
static func base_appearance(id: String) -> Dictionary:
 if not BASE_DEFAULTS.has(id):id="woochi"
 var result: Dictionary=BASE_DEFAULTS[id].duplicate();result.character=id;result.color_override=false;return result
const COLORS={"pink":Color("ce8caa"),"navy":Color("415b96"),"purple":Color("a581cc"),"green":Color("5da682"),"red":Color("bd5863"),"white":Color("dedee7"),"black_gold":Color("383747")}
const COLOR_NAMES={"pink":"분홍색","navy":"남색","purple":"보라색","green":"녹색","red":"붉은색","white":"흰색","black_gold":"검은색·금색"}
const CHARACTERS={
 "woochi":{"name":"전우치","cell":0,"rule":"free","description":"장난기 있는 계월촌의 도사. 기존 전우치 그대로."},
 "yeonhwa":{"name":"연화","cell":1,"rule":"free","description":"갈색 머리와 꽃을 사랑하는 차분한 여성 도사."},
 "muyeong":{"name":"무영","cell":2,"rule":"forest","description":"그림자 속에서 도술을 익힌 신비로운 도사."},
 "hongryeon":{"name":"홍련","cell":3,"rule":"shrine","description":"여우의 숲 사당의 문양을 푼 붉은 도사."}}
const OUTFITS={
 "basic":{"name":"기본 도사복","cell":4,"rule":"free","colors":["navy","pink","purple","green","red","white","black_gold"]},
 "moon":{"name":"백월 도사복","cell":5,"rule":"wins10","colors":["white","purple"]},
 "night":{"name":"흑야 도사복","cell":6,"rule":"forest","colors":["black_gold","navy"]},
 "goblin":{"name":"도깨비 도복","cell":7,"rule":"goblin","colors":["purple","green"]},
 "wind":{"name":"청풍 도포","cell":8,"rule":"wins30","colors":["green","navy"]},
 "snow":{"name":"설화 도포","cell":9,"rule":"event","colors":["white","purple"]},
 "heaven":{"name":"천상 도사복","cell":10,"rule":"master","colors":["white","black_gold"]},
 "dragon":{"name":"황룡 도사복","cell":11,"rule":"shop","colors":["black_gold","red"]}}
const HAIRS={"black":{"name":"기본 검은 머리","cell":12,"rule":"free"},"long":{"name":"긴 검은 머리","cell":13,"rule":"free"},"tied":{"name":"묶은 머리","cell":14,"rule":"free"},"silver":{"name":"은백색 머리","cell":15,"rule":"free"},"short":{"name":"짧은 머리","cell":16,"rule":"free"},"flower":{"name":"꽃 장식 머리","cell":17,"rule":"free"}}
const HATS={"none":{"name":"모자 없음","cell":-1,"rule":"free"},"gat":{"name":"검은 갓","cell":18,"rule":"free"},"bamboo":{"name":"대나무 삿갓","cell":19,"rule":"free"},"hood":{"name":"도사 두건","cell":20,"rule":"free"},"crown":{"name":"장식 관모","cell":21,"rule":"forest"},"fox":{"name":"여우 가면","cell":22,"rule":"shrine"},"gold":{"name":"황금 관모","cell":23,"rule":"master"}}
const ACCESSORIES={"none":{"name":"장신구 없음","cell":-1,"rule":"free"},"talisman":{"name":"부적 장식","cell":24,"rule":"free"},"gourd":{"name":"작은 호리병","cell":25,"rule":"free"},"bell":{"name":"금빛 방울","cell":26,"rule":"free"},"ribbon":{"name":"붉은 허리 장식","cell":27,"rule":"shrine"},"pouch":{"name":"도술 주머니","cell":28,"rule":"free"},"orb":{"name":"달빛 구슬","cell":29,"rule":"forest"},"scroll":{"name":"도술 두루마리","cell":30,"rule":"wins10"},"sigil":{"name":"특별 문양 장식","cell":31,"rule":"master"}}
const RULES={"free":"처음부터 사용 가능","forest":"여우의 숲 임무 완료","shrine":"여우의 숲 사당 문양 퍼즐 완료","wins10":"서버 확정 멀티 누적 10승","wins30":"서버 확정 멀티 누적 30승","goblin":"여우의 숲 도깨비 3마리 처치 임무 완료","event":"특별 이벤트 · 아직 진행 중인 이벤트 없음","master":"마스터 컬렉션 · 성장 시스템 준비 중","shop":"한정 꾸미기 상품 · 결제 미구현, 구매 불가"}
static func table(slot: String) -> Dictionary:
 return {"character":CHARACTERS,"hair":HAIRS,"outfit":OUTFITS,"hat":HATS,"accessory":ACCESSORIES}.get(slot,{})
static func normalize(raw: Variant) -> Dictionary:
 var out: Dictionary=base_appearance(str(raw.get("character","woochi"))) if raw is Dictionary else DEFAULT.duplicate()
 if not raw is Dictionary:return out
 for k in DEFAULT:
  if k=="color_override":
   out[k]=raw.get(k,false)==true;continue
  var values: Dictionary=COLORS if k=="color" else table(k)
  var value=raw.get(k,null)
  if value is String and values.has(value):out[k]=value
 if not out.color_override:out.color=base_appearance(out.character).color
 return out
