class_name CgInfo
extends LoaderHelper

var time_zone := 0
var filename := ""
var pt := Vector2i.ZERO
var effect_param := EffectParam.new()

func clear() -> void:
	time_zone = 0
	filename = ""
	pt = Vector2i.ZERO
	effect_param.type = EffectParam.EffectType.Nothing

func load(dict: Dictionary) -> bool:
	return (
		load_int(dict, &"time_zone")
	and load_string(dict, &"filename")
	and load_vec2i(dict, &"pt")
	and load_sub(dict, &"effect_param"))

func dump() -> Dictionary:
	return {
		time_zone = time_zone,
		filename = filename,
		pt = { x = pt.x, y = pt.y },
		effect_param = effect_param.dump(),
	}
