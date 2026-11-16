class_name WooCharacterDirection
extends RefCounted
# Atlas columns: front, back, left, right. Gameplay keeps its original 8-way aim.
const FACING=[2,6,4,0]
static func resolve(facing: int,last: int=0) -> int:
 facing=posmod(facing,8)
 if facing in FACING:return FACING.find(facing)
 var choices: Array={1:[0,3],3:[0,2],5:[1,2],7:[1,3]}[facing]
 return last if choices.has(last) else int(choices[0])
