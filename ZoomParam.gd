class_name ZoomParam
extends LoaderHelper

var pt := Vector2i.ZERO
var size := Vector2i(800, 600)
var time := 0
var accel := 0

func clear() -> void:
	set_(0, 0, Global.screen_size.x, Global.screen_size.y, 0, 0)

func set_(cx: int, cy: int, w: int, h: int, time_: int, accel_: int) -> void:
	pt = Vector2i(cx, cy)
	size = Vector2i(w, h)
	time = time_
	accel = accel_

func is_zoom() -> bool:
	return size != Global.screen_size

func horz_unit() -> float:
	return Global.screen_size.x / float(size.x) + 0.01

func vert_unit() -> float:
	return Global.screen_size.y / float(size.y) + 0.01

func load(dict: Dictionary) -> bool:
	return (
		load_vec2i(dict, &"pt")
	and load_vec2i(dict, &"size", Vector2i(800, 600))
	and load_int(dict, &"time")
	and load_int(dict, &"accel"))

func dump() -> Dictionary:
	return {
		pt = { x = pt.x, y = pt.y },
		size = { x = size.x, y = size.y },
		time = time,
		accel = accel,
	}
