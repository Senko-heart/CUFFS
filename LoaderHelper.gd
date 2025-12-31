@abstract class_name LoaderHelper

func load_bool(dict: Dictionary, prop: StringName, default: bool = false) -> bool:
	if not dict.has(prop):
		set(prop, default)
		return true
	if not dict[prop] is bool:
		return false
	set(prop, dict[prop])
	return true

func load_int(dict: Dictionary, prop: StringName, default: int = 0) -> bool:
	if not dict.has(prop):
		set(prop, default)
		return true
	if not is_int(dict[prop]):
		return false
	set(prop, int(dict[prop]))
	return true

func is_int(property: Variant) -> bool:
	if property is int:
		return true
	if property is float:
		var val: float = property
		return is_finite(val) and roundf(val) == val
	return false

func load_float(dict: Dictionary, prop: StringName, default: float = 0.0) -> bool:
	if not dict.has(prop):
		set(prop, default)
		return true
	if not dict[prop] is float and not dict[prop] is int:
		return false
	set(prop, float(dict[prop]))
	return true

func load_string(dict: Dictionary, prop: StringName, default: String = "") -> bool:
	if not dict.has(prop):
		set(prop, default)
		return true
	if not dict[prop] is String:
		return false
	set(prop, dict[prop])
	return true

func load_vec2i(
	dict: Dictionary,
	prop: StringName,
	default: Vector2i = Vector2i.ZERO
) -> bool:
	if not dict.has(prop):
		set(prop, default)
		return true
	if dict[prop] is not Dictionary:
		return false
	var value: Dictionary = dict[prop]
	for v: Variant in value.values():
		if v is not int and v is not float:
			return false
	set_indexed(prop + ":x", value.get(&"x", default.x))
	set_indexed(prop + ":y", value.get(&"y", default.y))
	return true

func load_vec3(
	dict: Dictionary,
	prop: StringName,
	default: Vector3 = Vector3.ZERO
) -> bool:
	if not dict.has(prop):
		set(prop, default)
		return true
	if dict[prop] is not Dictionary:
		return false
	var value: Dictionary = dict[prop]
	for v: Variant in value.values():
		if v is not int and v is not float:
			return false
	set_indexed(prop + ":x", value.get(&"x", default.x))
	set_indexed(prop + ":y", value.get(&"y", default.y))
	set_indexed(prop + ":z", value.get(&"z", default.z))
	return true

@abstract func load(dict: Dictionary) -> bool
@abstract func dump() -> Dictionary

func load_sub(dict: Dictionary, prop: StringName) -> bool:
	if not prop in dict:
		return true
	if dict[prop] is not Dictionary:
		return false
	var subprop: LoaderHelper = get(prop)
	return subprop.load(dict[prop])
