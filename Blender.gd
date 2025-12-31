class_name Blender
extends ShaderMaterial

var alpha_texture: Texture2D:
	set(value):
		alpha_texture = value
		set_shader_parameter(&"alpha_texture", value)

var t: float = 0.0:
	set(value):
		t = value
		set_shader_parameter(&"t", value)

var inv_t: float:
	get():
		return 1.0 - t
	set(value):
		t = 1.0 - value

var r: float = 1.0:
	set(value):
		r = value
		set_shader_parameter(&"r", value)

enum Mode {
	Normal,
	InvertAlpha,
}

func _init(mode: Mode = Mode.Normal) -> void:
	match mode:
		Mode.Normal:
			shader = preload("res://blender.gdshader")
		Mode.InvertAlpha:
			shader = preload("res://blenderinv.gdshader")
	r = 1.0
