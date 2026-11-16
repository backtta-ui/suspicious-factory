class_name WooCharacterDirection
extends RefCounted
# Existing cardinal columns preserved; new authored diagonal companion columns.
const FACING=[2,6,4,0,1,3,5,7]
static func resolve(facing: int,_last: int=0) -> int:return FACING.find(posmod(facing,8))
static func quantize(input: Vector2,last: int) -> int:
 if input.length()<.18:return posmod(last,8)
 var angle:=input.angle();var previous:=posmod(last,8)*PI/4
 if absf(angle_difference(previous,angle))<PI/8+.065:return posmod(last,8)
 return posmod(roundi(angle/(PI/4)),8)
