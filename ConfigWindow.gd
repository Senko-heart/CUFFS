class_name ConfigWindow
extends Control

const ScreenType := ConfigDataBase.ScreenType
const ScreenEffect := ConfigDataBase.ScreenEffect
const GameLogic := Global.GameLogic

var spr_base: Control

var ID_WINDOW: ModButton
var ID_FULLSCREEN: ModButton
var ID_CHECK_BGM: ModButton
var ID_CHECK_SE: ModButton
var ID_CHECK_SYSTEM: ModButton
var ID_CHECK_VOICE: ModButton
var ID_NORMAL: ModButton
var ID_NONE: ModButton
var ID_READED: ModButton
var ID_ALL: ModButton
var ID_CLICK_STOP: ModButton
var ID_CLICK_PLAY: ModButton
var ID_STATIC: ModButton
var ID_REMOVE: ModButton
var ID_TITLE: ModButton
var ID_APPRECIATION: ModButton
var ID_END: ModButton

var ID_VOL_BGM: ModScroll
var ID_VOL_SE: ModScroll
var ID_VOL_SYSTEM: ModScroll
var ID_VOL_VOICE: ModScroll
var ID_WINDOW_DEPTH: ModScroll
var ID_MESSAGE_SPEED: ModScroll
var ID_AUTOMODE_SPEED: ModScroll

func _init(parent: Node, from_title: bool) -> void:
	spr_base = Global.frame_skin.create_form_page(&"ID_PAGE_CONFIG")
	spr_base.pivot_offset = 0.5 * spr_base.size
	spr_base.position = 0.5 * (Vector2(Global.screen_size) - spr_base.size)
	spr_base.modulate.a = 0.0
	add_child(spr_base)
	for child in spr_base.get_children():
		set(child.name, child)
		if child is ModScroll:
			child.position.x += 8
	for id_vol: ModScroll in [ID_VOL_BGM, ID_VOL_SE, ID_VOL_SYSTEM, ID_VOL_VOICE]:
		id_vol.max_value = 256
		id_vol.wheel_step = 4
	ID_WINDOW_DEPTH.max_value = 256
	ID_MESSAGE_SPEED.max_value = 45
	ID_AUTOMODE_SPEED.max_value = 8
	apply()
	if from_title:
		ID_TITLE.hide()
		ID_APPRECIATION.hide()
		ID_END.hide()
	elif Global.is_recollect_mode():
		ID_TITLE.hide()
	else:
		ID_APPRECIATION.hide()
	parent.add_child(self)

func destroy() -> void:
	if ID_WINDOW.button_pressed:
		Global.cnf_obj.screen_type = ScreenType.Windowed
	else:
		Global.cnf_obj.screen_type = ScreenType.FullScreen
	Global.cnf_obj.play_bgm = ID_CHECK_BGM.button_pressed
	Global.cnf_obj.vol_bgm = ID_VOL_BGM.ratio
	Global.cnf_obj.play_se = ID_CHECK_SE.button_pressed
	Global.cnf_obj.vol_se = ID_VOL_SE.ratio
	Global.cnf_obj.play_sys_se = ID_CHECK_SYSTEM.button_pressed
	Global.cnf_obj.vol_sys_se = ID_VOL_SYSTEM.ratio
	Global.cnf_obj.play_voice = ID_CHECK_VOICE.button_pressed
	Global.cnf_obj.vol_voice = ID_VOL_VOICE.ratio
	if ID_NORMAL.button_pressed:
		Global.cnf_obj.screen_effect = ScreenEffect.Normal
	else:
		Global.cnf_obj.screen_effect = ScreenEffect.None
	Global.cnf_obj.window_depth = ID_WINDOW_DEPTH.ratio
	Global.cnf_obj.message_speed = int(ID_MESSAGE_SPEED.value)
	Global.cnf_obj.read_skip = ID_READED.button_pressed
	Global.cnf_obj.voice_stop_on_click = ID_CLICK_STOP.button_pressed
	Global.cnf_obj.lock_skip = ID_STATIC.button_pressed
	Global.cnf_obj.automode_speed = int(ID_AUTOMODE_SPEED.value)
	Global.save_config_data()
	Anim.destroy(self)

func apply_to_system() -> void:
	if Global.cnf_obj.play_bgm:
		var bgm := SoundSystem.get_play_bgm_name()
		if bgm != &"":
			SoundSystem.play_bgm(bgm, true)
	else:
		SoundSystem.stop_bgm(true, true)
	SoundSystem.set_bgm_volume(ID_VOL_BGM.ratio)
	if Global.cnf_obj.play_se:
		for env_se in SoundSystem.get_play_env_se_list():
			SoundSystem.play_env_se(env_se)
	else:
		SoundSystem.stop_env_se("", false, true)
	SoundSystem.set_se_volume(ID_VOL_SE.ratio)
	SoundSystem.set_sys_se_volume(ID_VOL_SYSTEM.ratio)
	if not Global.cnf_obj.play_voice:
		SoundSystem.stop_voice()
	SoundSystem.set_voice_volume(ID_VOL_VOICE.ratio)
	if Global.cnf_obj.screen_effect == ScreenEffect.Normal:
		Global.adv.begin_animation()
	else:
		Global.adv.end_animation()

func apply() -> void:
	if Global.cnf_obj.screen_type == ScreenType.Windowed:
		ID_WINDOW.button_pressed = true
	else:
		ID_FULLSCREEN.button_pressed = true
	ID_CHECK_BGM.button_pressed = Global.cnf_obj.play_bgm
	ID_VOL_BGM.ratio = Global.cnf_obj.vol_bgm
	ID_CHECK_SE.button_pressed = Global.cnf_obj.play_se
	ID_VOL_SE.ratio = Global.cnf_obj.vol_se
	ID_CHECK_SYSTEM.button_pressed = Global.cnf_obj.play_sys_se
	ID_VOL_SYSTEM.ratio = Global.cnf_obj.vol_sys_se
	ID_CHECK_VOICE.button_pressed = Global.cnf_obj.play_voice
	ID_VOL_VOICE.ratio = Global.cnf_obj.vol_voice
	if Global.cnf_obj.screen_effect == ScreenEffect.Normal:
		ID_NORMAL.button_pressed = true
	else:
		ID_NONE.button_pressed = true
	ID_WINDOW_DEPTH.ratio = Global.cnf_obj.window_depth
	Global.adv.msg_frame.transparency_base(Global.cnf_obj.window_depth)
	ID_MESSAGE_SPEED.value = Global.cnf_obj.message_speed
	if Global.cnf_obj.read_skip:
		ID_READED.button_pressed = true
	else:
		ID_ALL.button_pressed = true
	if Global.cnf_obj.voice_stop_on_click:
		ID_CLICK_STOP.button_pressed = true
	else:
		ID_CLICK_PLAY.button_pressed = true
	if Global.cnf_obj.lock_skip:
		ID_STATIC.button_pressed = true
	else:
		ID_REMOVE.button_pressed = true
	ID_AUTOMODE_SPEED.value = Global.cnf_obj.automode_speed

func _show() -> void:
	if Global.cnf_obj.screen_effect == ScreenEffect.Normal:
		Anim.schedule_scale(spr_base, Vector2(0.95, 0.95), Vector2.ONE)
		Anim.schedule_fade(spr_base, 1.0)
		await Anim.run(0.3)
	else:
		Anim.kill(spr_base)
		spr_base.modulate.a = 1.0

func _hide() -> void:
	if Global.cnf_obj.screen_effect == ScreenEffect.Normal:
		await Anim.fade(spr_base, 0.0, 0.3)
	else:
		Anim.kill(spr_base)
		spr_base.modulate.a = 1.0

func run() -> GameLogic:
	while true:
		var control := await Global.poll_ui_event()
		var cid: String = control.name if control else ""
		if cid == "ID_WINDOW":
			Global.set_screen_type(ScreenType.Windowed)
		elif cid == "ID_FULLSCREEN":
			Global.set_screen_type(ScreenType.FullScreen)
		elif cid == "ID_CHECK_BGM":
			Global.cnf_obj.play_bgm = ID_CHECK_BGM.button_pressed
			if Global.cnf_obj.play_bgm:
				var bgm := SoundSystem.get_play_bgm_name()
				if bgm != &"":
					SoundSystem.play_bgm(bgm, true)
			else:
				SoundSystem.stop_bgm(true, true)
		elif cid == "ID_VOL_BGM":
			SoundSystem.set_bgm_volume(ID_VOL_BGM.ratio)
		elif cid == "ID_CHECK_SE":
			Global.cnf_obj.play_se = ID_CHECK_SE.button_pressed
			if Global.cnf_obj.play_se:
				for env_se in SoundSystem.get_play_env_se_list():
					SoundSystem.play_env_se(env_se)
			else:
				SoundSystem.stop_env_se("", false, true)
		elif cid == "ID_VOL_SE":
			SoundSystem.set_se_volume(ID_VOL_SE.ratio)
		elif cid == "ID_CHECK_SYSTEM":
			Global.cnf_obj.play_sys_se = ID_CHECK_SYSTEM.button_pressed
		elif cid == "ID_VOL_SYSTEM":
			SoundSystem.set_sys_se_volume(ID_VOL_SYSTEM.ratio)
		elif cid == "ID_CHECK_VOICE":
			Global.cnf_obj.play_voice = ID_CHECK_VOICE.button_pressed
			if not Global.cnf_obj.play_voice:
				SoundSystem.stop_voice()
		elif cid == "ID_VOL_VOICE":
			SoundSystem.set_voice_volume(ID_VOL_VOICE.ratio)
		elif cid == "ID_WINDOW_DEPTH":
			Global.cnf_obj.window_depth = ID_WINDOW_DEPTH.ratio
			Global.adv.msg_frame.transparency_base(Global.cnf_obj.window_depth)
		elif cid == "ID_VOICE_DETAILS":
			await voice_details()
		elif cid == "ID_NORMAL":
			Global.cnf_obj.screen_effect = ScreenEffect.Normal
			Global.adv.begin_animation()
		elif cid == "ID_NONE":
			Global.cnf_obj.screen_effect = ScreenEffect.None
			Global.adv.end_animation()
		elif cid == "ID_DEFAULT":
			if await Global.confirm(Global.confirm_prompt.default):
				var screen_type := Global.cnf_obj.screen_type
				Global.cnf_obj = ConfigDataBase.new()
				Global.cnf_obj.screen_type = screen_type
				apply()
				apply_to_system()
		elif cid == "ID_TITLE":
			if await Global.confirm(Global.confirm_prompt.title):
				return GameLogic.Return
		elif cid == "ID_APPRECIATION":
			if await Global.confirm(Global.confirm_prompt.appreciation):
				return GameLogic.Return
		elif cid == "ID_END":
			await Global.ask_game_exit()
		elif Input.is_action_just_pressed("hit_cancel"):
			break
	return GameLogic.Unaffected

func voice_details() -> void:
	spr_base.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	var spr_details := Global.frame_skin.create_form_page(&"ID_PAGE_VOICE_DETAILS")
	var pos := spr_base.position
	spr_details.pivot_offset = Vector2(spr_details.size.x * 0.5, 0)
	spr_details.position = pos + Vector2(438, 215) - spr_details.pivot_offset
	spr_details.modulate.a = 0.0
	add_child(spr_details)
	var voices := spr_details.get_children()
	for i in range(voices.size()):
		var has_voice := bool((Global.cnf_obj.voice_details >> i) & 1)
		voices[i].button_pressed = has_voice
	if Global.cnf_obj.screen_effect == ScreenEffect.Normal:
		Anim.schedule_scale(spr_details, Vector2(1.0, 0.95), Vector2.ONE)
		Anim.schedule_fade(spr_details, 1.0)
		Anim.schedule_fade(spr_base, 0.5)
		Anim.run(0.3)
	else:
		Anim.kill(spr_details)
		spr_details.modulate.a = 1.0
		Anim.kill(spr_base)
		spr_base.modulate.a = 0.5
	while not Input.is_action_just_pressed("hit_cancel"):
		await get_tree().process_frame
	if Global.cnf_obj.screen_effect == ScreenEffect.Normal:
		Anim.schedule_fade(spr_details, 0.0)
		Anim.schedule_fade(spr_base, 1.0)
		Anim.run(0.3)
	else:
		Anim.kill(spr_details)
		spr_details.modulate.a = 0.0
		Anim.kill(spr_base)
		spr_base.modulate.a = 1.0
	Global.cnf_obj.voice_details = 0
	for i in range(voices.size()):
		if voices[i].button_pressed:
			Global.cnf_obj.voice_details |= 1 << i
	Anim.destroy(spr_details)
	spr_base.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED
