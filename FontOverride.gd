extends Node

var font_base: Dictionary[String, FontFile] = {
	"MS Gothic": preload("res://msgothic.ttc"),
	"MS Mincho": preload("res://msmincho.ttc"),
}

var font_variations: Dictionary[String, Array] = {
	"MS Gothic" = _produce_variations(_default_bold_italic(font_base["MS Gothic"])),
	"MS Mincho" = _produce_variations(_default_bold_italic(font_base["MS Mincho"])),
}

var font_styles: Dictionary[StringName, String] = {}
var font_styles_remapping: Dictionary[StringName, StringName] = {
	ID_FONT_NAME = &"adv_name",
	ID_FONT_MESSAGE = &"adv_message",
	ID_FONT_SELECT = &"adv_select",
	ID_FONT_CONFIRM = &"sys_confirm",
	ID_FONT_LOADSAVE_NUM = &"loadsave_num",
	ID_FONT_LOADSAVE_INFO = &"loadsave_info",
}

func _init() -> void:
	font_variations[""] = font_variations["MS Gothic"]
	var cfg := ConfigFile.new()
	var cfg_text := FS.get_file_as_bytes("font.cfg").get_string_from_utf8()
	var user_override := true
	if cfg_text.is_empty() or cfg.parse(cfg_text):
		user_override = false
		cfg_text = FS.patch.read_file("font.cfg").get_string_from_utf8()
		if cfg_text.is_empty() or cfg.parse(cfg_text):
			return
	if cfg.has_section("FontBase"):
		for key in cfg.get_section_keys("FontBase"):
			var value: String = cfg.get_value("FontBase", key)
			var font_bytes := PackedByteArray()
			if user_override:
				font_bytes = FS.get_file_as_bytes(value)
			if font_bytes.is_empty():
				font_bytes = FS.patch.read_file(value)
			var font := FontFile.new()
			font.data = font_bytes
			font_base[key] = font
		cfg.erase_section("FontBase")
	if cfg.has_section("FontStyle"):
		for key in cfg.get_section_keys("FontStyle"):
			font_styles[key] = cfg.get_value("FontStyle", key)
		cfg.erase_section("FontStyle")
	for section in cfg.get_sections():
		var fv := FontVariation.new()
		fv.base_font = font_base[cfg.get_value(section, "font_base")]
		fv.baseline_offset = cfg.get_value(section, "baseline_offset", 0.0)
		fv.variation_face_index = cfg.get_value(section, "face_index", 0)
		fv.variation_embolden = cfg.get_value(section, "embolden", 0.4)
		fv.variation_transform.y.x = cfg.get_value(section, "faux_slant", 0.2)
		fv.spacing_bottom = cfg.get_value(section, "spacing_bottom", 0)
		fv.spacing_top = cfg.get_value(section, "spacing_top", 0)
		fv.spacing_glyph = cfg.get_value(section, "spacing_glyph", 0)
		fv.spacing_space = cfg.get_value(section, "spacing_space", 0)
		font_variations[section] = _produce_variations(fv)
	for section in cfg.get_sections():
		var fvs := font_variations[section]
		var fallbacks: PackedStringArray = cfg.get_value(section, "fallbacks", [])
		for i in range(4):
			var fallback_fonts: Array[Font] = []
			fallback_fonts.resize(fallbacks.size())
			for j in range(fallbacks.size()):
				var fallback := fallbacks[j]
				if fallback in font_variations:
					fallback_fonts[j] = font_variations[fallback][i]
				elif fallback in font_base:
					fallback_fonts[j] = font_base[fallback]
			fvs[i].fallbacks = fallback_fonts

static func _default_bold_italic(font: Font) -> FontVariation:
	var fv := FontVariation.new()
	fv.base_font = font
	fv.variation_embolden = 0.4
	fv.variation_transform.y.x = 0.2
	return fv

static func _produce_variations(fv: FontVariation) -> Array:
	var fvs: Array = [fv.duplicate(), fv.duplicate(), fv.duplicate(), fv]
	for i in range(3):
		if not(i & TextServer.FONT_BOLD):
			fvs[i].variation_embolden = 0.0
		if not(i & TextServer.FONT_ITALIC):
			fvs[i].variation_transform.y.x = 0.0
	return fvs

func get_font_variation(
	style: StringName,
	face: String,
	bold: bool,
	italic: bool,
) -> FontVariation:
	var i := ((TextServer.FONT_BOLD if bold else 0)
		| (TextServer.FONT_ITALIC if italic else 0))
	if style in font_styles_remapping:
		style = font_styles_remapping[style]
		if style in font_styles:
			face = font_styles[style]
	if face in font_variations:
		return font_variations[face][i]
	return font_variations[""][i]
