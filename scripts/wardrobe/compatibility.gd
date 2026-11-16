class_name WooAppearanceCompatibility
extends RefCounted
## Foot-relative attachment coordinates. Equipment never changes actor scale/collision.
const HEADS={
 "woochi":{"face":Rect2(-9.4,-42,18.8,20),"hair":Vector2(0,0),"hat":Vector2(0,0)},
 "yeonhwa":{"face":Rect2(-9.1,-42.2,18.2,20.2),"hair":Vector2(0,-.2),"hat":Vector2(0,-.3)},
 "muyeong":{"face":Rect2(-9.5,-42,19,20),"hair":Vector2(.1,0),"hat":Vector2(.1,-.1)},
 "hongryeon":{"face":Rect2(-9.2,-42.1,18.4,20.1),"hair":Vector2(-.1,-.1),"hat":Vector2(-.1,-.2)}
}
const HAIR_INDEX={"black":0,"long":1,"tied":2,"silver":3,"short":4,"flower":5}
const HATS={
 "none":{"rect":Rect2(),"seat":-100.0,"mode":"open"},
 "gat":{"rect":Rect2(-20,-49,40,29),"seat":-36.5,"mode":"crown"},
 "bamboo":{"rect":Rect2(-20,-49,40,27),"seat":-36.5,"mode":"crown"},
 "hood":{"rect":Rect2(-14,-49,28,28),"seat":-38.0,"mode":"hood"},
 "crown":{"rect":Rect2(-15,-47,30,28),"seat":-37.0,"mode":"crown"},
 "fox":{"rect":Rect2(-12,-39,24,25),"seat":-100.0,"mode":"mask"},
 "gold":{"rect":Rect2(-17,-48,34,29),"seat":-37.0,"mode":"crown"}
}
const OUTFITS={"basic":Vector2(0,0),"moon":Vector2(0,-.2),"night":Vector2(0,0),"goblin":Vector2(0,.2),"wind":Vector2(0,0),"snow":Vector2(0,-.3),"heaven":Vector2(0,-.2),"dragon":Vector2(0,-.1)}
static func hair_rect(character: String) -> Rect2:
 return Rect2(Vector2(-13,-43)+HEADS[character].hair,Vector2(26,29))
static func hat_rect(character: String,hat: String) -> Rect2:
 var rect: Rect2=HATS[hat].rect;rect.position+=HEADS[character].hat;return rect
static func accessory_rect(id: String) -> Rect2:
 if id=="scroll":return Rect2(-13,-23,12,16)
 if id=="sigil":return Rect2(-5,-23,10,12)
 return Rect2(6,-13,7,10)
static func accessory_behind(id: String) -> bool:return id in ["scroll","sigil"]
