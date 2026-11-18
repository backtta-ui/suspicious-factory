class_name WooPalette
extends RefCounted
## 2.0.23 조선 다크 판타지 팔레트. 모든 UI 화면이 같은 색만 쓴다.
const OBSIDIAN=Color("101323")
const OBSIDIAN_LIGHT=Color("1a2036")
const OBSIDIAN_EDGE=Color("272e4a")
const VIOLET=Color("392947")
const VIOLET_LIGHT=Color("5c4372")
const BRASS=Color("c49b59")
const BRASS_LIGHT=Color("f2d9a6")
const BRASS_DEEP=Color("8a6836")
const HANJI=Color("f1e2c5")
const HANJI_DIM=Color("c3b8a0")
const JADE=Color("74b6a4")
const CRIMSON=Color("c0564f")
const MOON=Color("b9c7ff")

static func alpha(color: Color,value: float) -> Color:
	return Color(color.r,color.g,color.b,value)
