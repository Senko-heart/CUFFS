class_name ToneMixFilter
extends ShaderMaterial

var tone_tables: Texture2D:
	set(value):
		tone_tables = value
		set_shader_parameter(&"tone_tables", value)

var yuv_filter: bool:
	set(value):
		yuv_filter = value
		set_shader_parameter(&"yuv_filter", value)

var t: float:
	set(value):
		t = value
		set_shader_parameter(&"t", value)

func _init(tone_filter: Dictionary) -> void:
	shader = preload("res://tonemix.gdshader")
	_set_tone_filter(tone_filter)
	_retire_tone_filter()
	t = 1.0

func _retire_tone_filter() -> void:
	set_shader_parameter(&"old_tone_tables", tone_tables)
	set_shader_parameter(&"old_yuv_filter", yuv_filter)

func _set_tone_filter(tone_filter: Dictionary) -> void:
	tone_tables = tone_filter.tone_tables
	yuv_filter = tone_filter.get(&"yuv_filter", false)

func set_tone_filter(tone_filter: Dictionary) -> void:
	_retire_tone_filter()
	_set_tone_filter(tone_filter)
	t = 0.0
