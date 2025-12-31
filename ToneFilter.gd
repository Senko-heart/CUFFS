class_name ToneFilter
extends ShaderMaterial

func _init(tone_tables: Texture2D, yuv_filter: bool = false) -> void:
	shader = preload("res://tone.gdshader")
	set_shader_parameter(&"tone_tables", tone_tables)
	set_shader_parameter(&"yuv_filter", yuv_filter)
