class_name MoveParam
extends LoaderHelper

var pt := Vector2i.ZERO
var time := 0
var accel := 0
var fade := false

func set_(pt_: Vector2i, time_: int, accel_: int, fade_: bool) -> void:
	pt = pt_
	time = time_
	accel = accel_
	fade = fade_

func load(dict: Dictionary) -> bool:
	return (
		load_vec2i(dict, &"pt")
	and load_int(dict, &"time")
	and load_int(dict, &"accel")
	and load_bool(dict, &"fade"))

func dump() -> Dictionary:
	return {
		pt = { x = pt.x, y = pt.y },
		time = time,
		accel = accel,
		fade = fade,
	}
