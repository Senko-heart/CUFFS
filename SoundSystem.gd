extends Node

var bgm: Array[Sound] = [Sound.new(self), Sound.new(self)]
var bgm_index := 0
var env_se: Dictionary[String, Sound] = {}
var se := Sound.new(self)
var sys_se := Sound.new(self)
var voice := Sound.new(self)

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _stop_signal(snd: Sound, key_disable: bool = false) -> void:
	if key_disable:
		if snd.playing:
			await snd.finished
		return
	while snd.playing:
		if Input.is_action_just_pressed("hit", true): break
		await get_tree().process_frame

func play_bgm(file: String, non_fade: bool = false) -> void:
	file = file.to_upper()
	if is_play_bgm():
		if bgm[bgm_index].filename == file: return
		stop_bgm(non_fade)
	print("BGM-%s" % file)
	bgm_index = 1 - bgm_index
	bgm[bgm_index].filename = file
	set_bgm_info(bgm[bgm_index])
	if not Global.cnf_obj.play_bgm: return
	Anim.flush(bgm[bgm_index])
	FS.load_bgm(file, bgm[bgm_index])
	if not non_fade:
		bgm[bgm_index].volume_linear = 0.0
		bgm[bgm_index].is_play = true
		bgm[bgm_index].play()
		Anim.fade_vol(bgm[bgm_index], Global.cnf_obj.vol_bgm, 2.0)
	else:
		bgm[bgm_index].volume_linear = Global.cnf_obj.vol_bgm
		bgm[bgm_index].is_play = true
		bgm[bgm_index].play()

func stop_bgm(non_fade: bool = false, config_stop: bool = false) -> void:
	print("BGM-STOP")
	var _bgm := bgm[bgm_index]
	_bgm.is_play = false
	if not config_stop:
		_bgm.filename = ""
	if not non_fade:
		await Anim.fade_vol(_bgm, 0.0, 3.0)
	if not _bgm.is_play:
		_bgm.stop()

func is_pause_bgm() -> bool:
	return bgm[bgm_index].stream_paused

func pause_bgm() -> void:
	bgm[bgm_index].stream_paused = true

func restart_bgm() -> void:
	bgm[bgm_index].play()

func set_bgm_volume(vol: float) -> void:
	bgm[0].volume_linear = vol
	bgm[1].volume_linear = vol
	Global.cnf_obj.vol_bgm = vol

func is_play_bgm() -> bool:
	return bgm[bgm_index].is_play
	
func get_play_bgm_name() -> String:
	return bgm[bgm_index].filename

func set_bgm_info(info: Sound) -> void:
	if info.filename == "BGM01":
		info.end_pos = -1
		info.rewind_pos = -1
	elif info.filename == "BGM02":
		info.end_pos = -1
		info.rewind_pos = -1
	elif info.filename == "BGM02_S":
		info.end_pos = -1
		info.rewind_pos = -1
	elif info.filename == "BGM03":
		info.end_pos = 3453154
		info.rewind_pos = 235043
	elif info.filename == "BGM04":
		info.end_pos = 6625443
		info.rewind_pos = 403958
	elif info.filename == "BGM05":
		info.end_pos = 4658801
		info.rewind_pos = 524416
	elif info.filename == "BGM06":
		info.end_pos = 5516339
		info.rewind_pos = 243508
	elif info.filename == "BGM07":
		info.end_pos = 4973038
		info.rewind_pos = 161922
	elif info.filename == "BGM08":
		info.end_pos = 6405448
		info.rewind_pos = 179568
	elif info.filename == "BGM09":
		info.end_pos = 4664696
		info.rewind_pos = 399603
	elif info.filename == "BGM10":
		info.end_pos = 7202878
		info.rewind_pos = 734884
	elif info.filename == "BGM11":
		info.end_pos = 3830880
		info.rewind_pos = 1394331
	elif info.filename == "BGM12":
		info.end_pos = 3888551
		info.rewind_pos = 943395
	elif info.filename == "BGM13":
		info.end_pos = 3915822
		info.rewind_pos = 22837
	elif info.filename == "BGM14":
		info.end_pos = 2955738
		info.rewind_pos = 22821
	elif info.filename == "BGM15":
		info.end_pos = 3487364
		info.rewind_pos = 120386
	elif info.filename == "BGM16":
		info.end_pos = 8693598
		info.rewind_pos = 226400
	elif info.filename == "BGM17":
		info.end_pos = 9330057
		info.rewind_pos = 211613
	elif info.filename == "BGM18":
		info.end_pos = 7477617
		info.rewind_pos = 22772
	elif info.filename == "BGM19":
		info.end_pos = 4934151
		info.rewind_pos = 530871
	elif info.filename == "BGM20":
		info.end_pos = 9068182
		info.rewind_pos = 364347
	elif info.filename == "BGM21":
		info.end_pos = 6787583
		info.rewind_pos = 22075

func bgm_release() -> void:
	bgm[0].stream = null
	bgm[1].stream = null

func play_env_se(file: String, fade: bool = false) -> void:
	file = file.to_upper()
	print("EnvSe-%s" % file)
	if file in env_se:
		env_se[file].stop()
		Anim.destroy(env_se[file])
	var snd := Sound.new(self)
	env_se[file] = snd
	snd.filename = file
	if not Global.cnf_obj.play_se: return
	FS.load_sound(file, snd, true)
	if fade:
		snd.volume_linear = 0.0
		snd.play()
		Anim.fade_vol(snd, Global.cnf_obj.vol_se, 2.0)
	else:
		snd.volume_linear = Global.cnf_obj.vol_se
		snd.play()

func stop_env_se(
	file: String = "",
	fade: bool = false,
	config_stop: bool = false
) -> void:
	file = file.to_upper()
	if file.is_empty():
		print("StopEnvSe-All")
		for key in env_se:
			var snd := env_se[key]
			if fade:
				Anim.schedule_fade_vol(snd, 0.0)
			else:
				snd.stream = null
		if fade or not config_stop:
			var se_list: Array[Sound] = env_se.values()
			env_se.clear()
			if fade:
				await Anim.run(3.0)
			for snd in se_list:
				Anim.destroy(snd)
	else:
		if not file in env_se: return
		var snd := env_se[file]
		print("StopEnvSe-%s" % file)
		if fade:
			env_se.erase(file)
			await Anim.fade_vol(snd, 0.0, 3.0)
		else:
			snd.stream = null
		if fade or not config_stop:
			env_se.erase(file)
			Anim.destroy(snd)

func env_se_release() -> void:
	for file in env_se:
		var snd := env_se[file]
		snd.stream = null
		Anim.destroy(snd)
	env_se.clear()

func get_play_env_se_list() -> Array[String]:
	return env_se.keys()

func set_se_volume(vol: float) -> void:
	for file in env_se:
		env_se[file].volume_linear = vol
	Global.cnf_obj.vol_se = vol

func play_se(file: String) -> void:
	print("Se-%s" % file)
	if not Global.cnf_obj.play_se: return
	FS.load_sound(file, se)
	se.volume_linear = Global.cnf_obj.vol_se
	se.play()
	await _stop_signal(se)

func stop_se() -> void:
	se.stream = null

func play_sys_se(file: String) -> void:
	print("SysSe-%s" % file)
	if not Global.cnf_obj.play_sys_se: return
	FS.load_voice(file, sys_se)
	sys_se.volume_linear = Global.cnf_obj.vol_sys_se
	sys_se.play()
	await _stop_signal(sys_se)

func stop_sys_se() -> void:
	sys_se.stream = null

func set_sys_se_volume(vol: float) -> void:
	Global.cnf_obj.vol_sys_se = vol

func play_voice(file: String, force: bool = false) -> bool:
	if not Global.cnf_obj.play_voice and not force:
		return false
	if FS.load_voice(file, voice):
		voice.volume_linear = Global.cnf_obj.vol_voice
		voice.play()
		return true
	else:
		printerr("NotFound-%s" % file)
		return false

func stop_voice() -> void:
	voice.stream = null

func wait_voice(key_disable: bool = false) -> void:
	await _stop_signal(voice, key_disable)

func is_play_voice() -> bool:
	return voice.playing

func set_voice_volume(vol: float) -> void:
	voice.volume_linear = vol
	Global.cnf_obj.vol_voice = vol
