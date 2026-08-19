extends Node

var unlock_sora := true
var day_night_cycle := true
var jump_log := true
var translated := true
var full := true
var decensor := true
var hires := true
var yahiro := true

var store_decensor := false
var store_hires := false
var store_yahiro := false

const SECTION := "Start"

func _get_prop(cfg: ConfigFile, prop: StringName) -> void:
	cfg.set_value(SECTION, prop, get(prop))

func _set_prop_by_type(cfg: ConfigFile, prop: StringName) -> void:
	if cfg.has_section_key(SECTION, prop):
		set(prop, cfg.get_value(SECTION, prop))

func load_from(cfg: ConfigFile) -> void:
	_set_prop_by_type(cfg, &"unlock_sora")
	_set_prop_by_type(cfg, &"day_night_cycle")
	_set_prop_by_type(cfg, &"jump_log")
	_set_prop_by_type(cfg, &"translated")
	_set_prop_by_type(cfg, &"full")
	_set_prop_by_type(cfg, &"decensor")
	_set_prop_by_type(cfg, &"hires")
	_set_prop_by_type(cfg, &"yahiro")

func dump_into(cfg: ConfigFile) -> void:
	_get_prop(cfg, &"unlock_sora")
	_get_prop(cfg, &"day_night_cycle")
	_get_prop(cfg, &"jump_log")
	_get_prop(cfg, &"translated")
	_get_prop(cfg, &"full")
	if store_decensor or not decensor:
		_get_prop(cfg, &"decensor")
	if store_hires or not hires:
		_get_prop(cfg, &"hires")
	if store_yahiro or not yahiro:
		_get_prop(cfg, &"yahiro")
