class_name ConfigDataBase

enum ScreenType { Windowed, FullScreen }
enum ScreenEffect { Normal, None }

var screen_type := ScreenType.Windowed
var play_bgm := true
var vol_bgm := 0.5
var play_voice := true
var vol_voice := 1.0
var play_se := true
var vol_se := 1.0
var play_sys_se := true
var vol_sys_se := 1.0
var voice_details := (1 << 9) - 1
var screen_effect := ScreenEffect.Normal
var update_hide_mess := true
var window_depth := 0.5
var message_speed := 15
var read_skip := true
var lock_skip := false
var voice_stop_on_click := false
var automode_speed := 4
var automode_remove := false

const SECTION := "ConfigDataBase"

func _get_prop(cfg: ConfigFile, prop: StringName) -> void:
	cfg.set_value(SECTION, prop, get(prop))

func _set_prop_by_type(cfg: ConfigFile, prop: StringName) -> void:
	if cfg.has_section_key(SECTION, prop):
		set(prop, cfg.get_value(SECTION, prop))

func load_from(cfg: ConfigFile) -> void:
	_set_prop_by_type(cfg, &"screen_type")
	_set_prop_by_type(cfg, &"play_bgm")
	_set_prop_by_type(cfg, &"vol_bgm")
	_set_prop_by_type(cfg, &"play_voice")
	_set_prop_by_type(cfg, &"vol_voice")
	_set_prop_by_type(cfg, &"play_se")
	_set_prop_by_type(cfg, &"vol_se")
	_set_prop_by_type(cfg, &"play_sys_se")
	_set_prop_by_type(cfg, &"vol_sys_se")
	_set_prop_by_type(cfg, &"voice_details")
	_set_prop_by_type(cfg, &"screen_effect")
	_set_prop_by_type(cfg, &"update_hide_mess")
	_set_prop_by_type(cfg, &"window_depth")
	_set_prop_by_type(cfg, &"message_speed")
	_set_prop_by_type(cfg, &"read_skip")
	_set_prop_by_type(cfg, &"lock_skip")
	_set_prop_by_type(cfg, &"voice_stop_on_click")
	_set_prop_by_type(cfg, &"automode_speed")
	_set_prop_by_type(cfg, &"automode_remove")

func dump_into(cfg: ConfigFile) -> void:
	_get_prop(cfg, &"screen_type")
	_get_prop(cfg, &"play_bgm")
	_get_prop(cfg, &"vol_bgm")
	_get_prop(cfg, &"play_voice")
	_get_prop(cfg, &"vol_voice")
	_get_prop(cfg, &"play_se")
	_get_prop(cfg, &"vol_se")
	_get_prop(cfg, &"play_sys_se")
	_get_prop(cfg, &"vol_sys_se")
	_get_prop(cfg, &"voice_details")
	_get_prop(cfg, &"screen_effect")
	_get_prop(cfg, &"update_hide_mess")
	_get_prop(cfg, &"window_depth")
	_get_prop(cfg, &"message_speed")
	_get_prop(cfg, &"read_skip")
	_get_prop(cfg, &"lock_skip")
	_get_prop(cfg, &"voice_stop_on_click")
	_get_prop(cfg, &"automode_speed")
	_get_prop(cfg, &"automode_remove")
