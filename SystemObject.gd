class_name SystemObject

var read_flag := Flag.new(48000)
var cg_flag := Flag.new(4096)
var recollect_flag := Flag.new(32)
var global_sc_flag := Flag.new(128)
var new_bookmark_index := 0
var view_opening_movie := true
var game_clear := false

const SECTION := "SystemObject"

func _get_prop(cfg: ConfigFile, prop: StringName) -> void:
	cfg.set_value(SECTION, prop, get(prop))

func _pack_flag(cfg: ConfigFile, prop: StringName) -> void:
	var flag: Flag = get(prop)
	cfg.set_value(SECTION, prop, flag.pack_base64())

func _set_prop_by_type(cfg: ConfigFile, prop: StringName) -> void:
	if cfg.has_section_key(SECTION, prop):
		set(prop, cfg.get_value(SECTION, prop))

func _unpack_flag(cfg: ConfigFile, prop: StringName) -> void:
	if cfg.has_section_key(SECTION, prop):
		var base64: String = cfg.get_value(SECTION, prop)
		var flag: Flag = get(prop)
		flag.unpack_base64(base64)

func load_from(cfg: ConfigFile) -> void:
	_unpack_flag(cfg, &"read_flag")
	_unpack_flag(cfg, &"cg_flag")
	_unpack_flag(cfg, &"recollect_flag")
	_unpack_flag(cfg, &"global_sc_flag")
	_set_prop_by_type(cfg, &"new_bookmark_index")
	_set_prop_by_type(cfg, &"view_opening_movie")
	_set_prop_by_type(cfg, &"game_clear")

func dump_into(cfg: ConfigFile) -> void:
	_pack_flag(cfg, &"read_flag")
	_pack_flag(cfg, &"cg_flag")
	_pack_flag(cfg, &"recollect_flag")
	_pack_flag(cfg, &"global_sc_flag")
	_get_prop(cfg, &"new_bookmark_index")
	_get_prop(cfg, &"view_opening_movie")
	_get_prop(cfg, &"game_clear")
