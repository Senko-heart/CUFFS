extends Node

var unlock_sora := true
var translated := true
var full := true
var decensor := true
var hires := true

var store_decensor := false
var store_hires := false

const SECTION := "Start"

func _get_prop(cfg: ConfigFile, prop: StringName) -> void:
	cfg.set_value(SECTION, prop, get(prop))

func _set_prop_by_type(cfg: ConfigFile, prop: StringName) -> void:
	if cfg.has_section_key(SECTION, prop):
		set(prop, cfg.get_value(SECTION, prop))

func load_from(cfg: ConfigFile) -> void:
	_set_prop_by_type(cfg, &"unlock_sora")
	_set_prop_by_type(cfg, &"translated")
	_set_prop_by_type(cfg, &"full")
	_set_prop_by_type(cfg, &"decensor")
	_set_prop_by_type(cfg, &"hires")

func dump_into(cfg: ConfigFile) -> void:
	_get_prop(cfg, &"unlock_sora")
	_get_prop(cfg, &"translated")
	_get_prop(cfg, &"full")
	if store_decensor or not decensor:
		_get_prop(cfg, &"decensor")
	if store_hires or not hires:
		_get_prop(cfg, &"hires")
