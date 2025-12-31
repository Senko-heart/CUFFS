class_name BustupInfo
extends LoaderHelper

var status := 0
var id := -1
var pos := 0
var pos_fix := false
var base_position := Vector2i.ZERO
var local_position := Vector2i.ZERO
var relation := 0
var priority := 0
var basename := ""
var filename := ""
var down_param := MoveParam.new()
var leave_param := MoveParam.new()

func clear() -> void:
	status = 0
	id = -1
	pos = 0
	pos_fix = false
	base_position = Vector2i.ZERO
	local_position = Vector2i.ZERO
	priority = 0
	filename = ""

func load(dict: Dictionary) -> bool:
	return (
		load_int(dict, &"status")
	and load_int(dict, &"id", -1)
	and load_int(dict, &"pos")
	and load_bool(dict, &"pos_fix")
	and load_vec2i(dict, &"base_position")
	and load_vec2i(dict, &"local_position")
	and load_int(dict, &"relation")
	and load_int(dict, &"priority")
	and load_string(dict, &"basename")
	and load_string(dict, &"filename")
	and load_sub(dict, &"down_param")
	and load_sub(dict, &"leave_param"))

func dump() -> Dictionary:
	return {
		status = status,
		id = id,
		pos = pos,
		pos_fix = pos_fix,
		base_position = {
			x = base_position.x,
			y = base_position.y,
		},
		local_position = {
			x = local_position.x,
			y = local_position.y,
		},
		relation = relation,
		basename = basename,
		filename = filename,
		down_param = down_param.dump(),
		leave_param = leave_param.dump(),
	}
