class_name ScenarioObject
extends LoaderHelper

const ToneFilterType := AdvScreen.ToneFilterType

var loaderr := false
var unix_time := 0.0
var comment := ""
var scenario_call := ""
var scene_title := ""
var flag := Flag.new(512)
var faux_clear := false
var name_log := LogManager.new(50)
var mess_log := LogManager.new(50)
var seq_log := LogManager.new(50)
var voice_log := LogManager.new(50)
var cg := CgInfo.new()
var cg_rgb := false
var col_set_cg_rgb := Color.from_rgba8(0, 0, 0, 0)
var bustup: Array[BustupInfo] = []
var play_bgm := ""
var pause_bgm := false
var play_env_se: PackedStringArray = []
var is_load := false
var hitret_id := 0
var in_select := false
var select: PackedInt32Array = []
var select_count := 0
var view_type := 0
var has_tone_filter := false
var tone_filter := ""
var zoom := false
var zoom_param := ZoomParam.new()

func _load_flag(
	dict: Dictionary,
	prop: StringName,
) -> bool:
	var flg: Flag = get(prop)
	if not prop in dict:
		flg.clear()
		return true
	var value: Variant = dict[prop]
	if typeof(value) != TYPE_STRING:
		return false
	flg.unpack_base64(value)
	return true

func _load_logm(
	dict: Dictionary,
	prop: StringName,
) -> bool:
	var logm: LogManager = get(prop)
	if not prop in dict:
		logm.from_contiguous([])
		return true
	var value := dict[prop] as PackedStringArray
	if value == null: return false
	logm.from_contiguous(value)
	return true

func load(dict: Dictionary) -> bool:
	if (load_float(dict, &"unix_time")
	and load_string(dict, &"comment")
	and load_string(dict, &"scenario_call")
	and load_string(dict, &"scene_title")
	and _load_flag(dict, &"flag")
	and load_bool(dict, &"faux_clear")
	and _load_logm(dict, &"name_log")
	and _load_logm(dict, &"mess_log")
	and _load_logm(dict, &"seq_log")
	and _load_logm(dict, &"voice_log")
	and load_sub(dict, &"cg")
	and load_string(dict, &"play_bgm")
	and load_bool(dict, &"pause_bgm")
	and load_int(dict, &"hitret_id")
	and load_bool(dict, &"in_select")
	and load_int(dict, &"view_type")
	): pass
	else: return false
	
	cg.clear()
	if &"cg" in dict:
		if dict.cg is not Dictionary:
			return false
		if not cg.load(dict.cg):
			return false
	
	bustup.clear()
	if &"bustup" in dict:
		if dict.bustup is not Array:
			return false
		for bu: Variant in dict.bustup:
			if bu is not Dictionary:
				return false
			bustup.append(BustupInfo.new())
			if not bustup[-1].load(bu):
				return false
	
	play_env_se.clear()
	if &"play_env_se" in dict:
		if dict.play_env_se is not PackedStringArray:
			if dict.play_env_se is not Array:
				return false
			for v: Variant in dict.play_env_se:
				if v is not String:
					return false
		play_env_se = dict.play_env_se.duplicate()
	
	select.clear()
	if &"select" in dict:
		if dict.select is not PackedInt32Array:
			if dict.select is not Array:
				return false
			for v: Variant in dict.select:
				if not is_int(v):
					return false
		select = dict.select.duplicate()
	select_count = 0
	
	if &"col_set_cg_rgb" in dict:
		var value: Variant = dict.col_set_cg_rgb
		if value is not String:
			return false
		col_set_cg_rgb = Color.html(value)
		cg_rgb = true
	else: cg_rgb = false
	if &"tone_filter" in dict:
		if not load_string(dict, &"tone_filter"):
			return false
		has_tone_filter = true
	else: has_tone_filter = false
	if &"zoom_param" in dict:
		if not load_sub(dict, &"zoom_param"):
			return false
		zoom = true
	else: zoom = false
	return true

func dump() -> Dictionary:
	var dict := {
		unix_time = unix_time,
		comment = comment,
		scenario_call = scenario_call,
		scene_title = scene_title,
		flag = flag.pack_base64(),
		faux_clear = faux_clear,
		name_log = name_log.contiguous(),
		mess_log = mess_log.contiguous(),
		seq_log = seq_log.contiguous(),
		voice_log = voice_log.contiguous(),
		cg = cg.dump(),
		col_set_cg_rgb = col_set_cg_rgb.to_html(false),
		bustup = bustup.map(func(bu: BustupInfo) -> Dictionary:
			return bu.dump()),
		play_bgm = play_bgm,
		pause_bgm = pause_bgm,
		play_env_se = play_env_se,
		hitret_id = hitret_id,
		in_select = in_select,
		select = select,
		view_type = view_type,
		tone_filter = tone_filter,
		zoom_param = zoom_param.dump(),
	}
	if not cg_rgb: dict.erase(&"col_set_cg_rgb")
	if not has_tone_filter: dict.erase(&"tone_filter")
	if not zoom: dict.erase(&"zoom_param")
	return dict
