class_name CgInfo
extends LoaderHelper

enum TimeZone {
	Unspecified,
	Daytime,
	DaytimeRain,
	Evening,
	EveningRain,
	Night,
	NightL,
	Midnight,
}

var time_zone := TimeZone.Unspecified
var filename := ""
var pt := Vector2i.ZERO
var effect_param := EffectParam.new()

func clear() -> void:
	time_zone = TimeZone.Unspecified
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

static func gamma_shader(gamma: Vector3, wmin: Vector3, wmax: Vector3) -> Material:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://gamma.gdshader")
	mat.set_shader_parameter(&"gamma", gamma)
	mat.set_shader_parameter(&"wmin", wmin)
	mat.set_shader_parameter(&"wmax", wmax)
	return mat

static var gamma_shaders := [
	null,
	null,
	gamma_shader(Vector3.ONE, Vector3.ZERO, Vector3(210, 210, 220) / 255),
	gamma_shader(Vector3(1.2, 0.8, 0.8), Vector3.ZERO, Vector3.ONE),
	null,
	gamma_shader(Vector3(0.9, 0.9, 1.2), Vector3.ZERO, Vector3(180, 180, 230) / 255),
	gamma_shader(Vector3(0.9, 0.9, 1.0), Vector3.ZERO, Vector3(220, 220, 250) / 255),
	gamma_shader(Vector3.ONE, Vector3.ZERO, Vector3(150, 150, 180) / 255),
]

func sunlight_material() -> Material:
	if Start.day_night_cycle:
		return gamma_shaders[time_zone]
	return null
