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

var ID_SORA: ModButton
var ID_AKIRA: ModButton
var ID_NAO: ModButton
var ID_KAZUHA: ModButton
var ID_MOTOKA: ModButton
var ID_KOZUE: ModButton
var ID_YAHIRO: ModButton
var ID_RYOUHEI: ModButton
var ID_OTHER: ModButton

func _init(parent: Node, from_title: bool) -> void:
	spr_base = Global.frame_skin.create_form_page(&"ID_PAGE_CONFIG")
	spr_base.pivot_offset = 0.5 * spr_base.size
	spr_base.position = 0.5 * (Vector2(Global.screen_size) - spr_base.size)
	spr_base.modulate.a = 0.0
	add_child(spr_base)
	for child in spr_base.get_children():
		set(child.name, child)
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
	var test_sound := Sound.new(self)
	var play_test_state := 0
	var vol_bgm := Global.cnf_obj.vol_bgm
	var vol_voice := Global.cnf_obj.vol_voice
	var vol_se := Global.cnf_obj.vol_se
	var vol_sys_se := Global.cnf_obj.vol_sys_se
	var window_depth := ID_WINDOW_DEPTH.value
	var message_speed := ID_MESSAGE_SPEED.value
	var automode_speed := ID_AUTOMODE_SPEED.value
	while true:
		var control := await Global.poll_ui_event()
		var cid: String = control.name if control else ""
		if cid == "ID_WINDOW":
			mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
			Global.play_sys_voice("ウィンドウモード")
			await SoundSystem.wait_sys_se()
			Global.set_screen_type(ScreenType.Windowed)
			mouse_behavior_recursive = MOUSE_BEHAVIOR_INHERITED
		elif cid == "ID_FULLSCREEN":
			mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
			Global.play_sys_voice("フルスクリーンモード")
			await SoundSystem.wait_sys_se()
			Global.set_screen_type(ScreenType.FullScreen)
			mouse_behavior_recursive = MOUSE_BEHAVIOR_INHERITED
		elif cid == "ID_CHECK_BGM":
			Global.cnf_obj.play_bgm = ID_CHECK_BGM.button_pressed
			if Global.cnf_obj.play_bgm:
				Global.play_sys_voice("音楽オン")
				var bgm := SoundSystem.get_play_bgm_name()
				if bgm != &"":
					SoundSystem.play_bgm(bgm, true)
			else:
				Global.play_sys_voice("音楽オフ")
				SoundSystem.stop_bgm(true, true)
		elif cid == "ID_VOL_BGM":
			SoundSystem.set_bgm_volume(ID_VOL_BGM.ratio)
		elif cid == "ID_CHECK_SE":
			Global.cnf_obj.play_se = ID_CHECK_SE.button_pressed
			if Global.cnf_obj.play_se:
				Global.play_sys_voice("効果音オン")
				for env_se in SoundSystem.get_play_env_se_list():
					SoundSystem.play_env_se(env_se)
			else:
				Global.play_sys_voice("効果音オフ")
				SoundSystem.stop_env_se("", false, true)
		elif cid == "ID_VOL_SE":
			SoundSystem.set_se_volume(ID_VOL_SE.ratio)
		elif cid == "ID_CHECK_SYSTEM":
			if not ID_CHECK_SYSTEM.button_pressed:
				Global.play_sys_voice("システム音オフ")
			Global.cnf_obj.play_sys_se = ID_CHECK_SYSTEM.button_pressed
			if ID_CHECK_SYSTEM.button_pressed:
				Global.play_sys_voice("システム音オン")
		elif cid == "ID_VOL_SYSTEM":
			SoundSystem.set_sys_se_volume(ID_VOL_SYSTEM.ratio)
		elif cid == "ID_CHECK_VOICE":
			Global.cnf_obj.play_voice = ID_CHECK_VOICE.button_pressed
			if Global.cnf_obj.play_voice:
				Global.play_sys_voice("音声オン")
			else:
				Global.play_sys_voice("音声オフ")
				SoundSystem.stop_voice()
		elif cid == "ID_VOL_VOICE":
			SoundSystem.set_voice_volume(ID_VOL_VOICE.ratio)
		elif cid == "ID_WINDOW_DEPTH":
			Global.cnf_obj.window_depth = ID_WINDOW_DEPTH.ratio
			Global.adv.msg_frame.transparency_base(Global.cnf_obj.window_depth)
		elif cid == "ID_VOICE_DETAILS":
			await voice_details()
		elif cid == "ID_NORMAL":
			Global.play_sys_voice("画面効果オン")
			Global.cnf_obj.screen_effect = ScreenEffect.Normal
			Global.adv.begin_animation()
		elif cid == "ID_NONE":
			Global.play_sys_voice("画面効果オフ")
			Global.cnf_obj.screen_effect = ScreenEffect.None
			Global.adv.end_animation()
		elif cid == "ID_READED":
			Global.play_sys_voice("メッセージスキップ：既読のみ")
		elif cid == "ID_ALL":
			Global.play_sys_voice("メッセージスキップ：全部")
		elif cid == "ID_CLICK_PLAY":
			Global.play_sys_voice("音声制御：抑制なし")
		elif cid == "ID_CLICK_STOP":
			Global.play_sys_voice("音声制御：抑制あり")
		elif cid == "ID_DEFAULT":
			Global.play_sys_voice("初期設定に戻す")
			if await Global.confirm(Global.confirm_prompt.default):
				var screen_type := Global.cnf_obj.screen_type
				Global.cnf_obj = ConfigDataBase.new()
				Global.cnf_obj.screen_type = screen_type
				apply()
				apply_to_system()
		elif cid == "ID_TITLE":
			Global.play_sys_voice("タイトルに戻る")
			if await Global.confirm(Global.confirm_prompt.title):
				return GameLogic.Return
		elif cid == "ID_APPRECIATION":
			if await Global.confirm(Global.confirm_prompt.appreciation):
				return GameLogic.Return
		elif cid == "ID_END":
			await Global.ask_game_exit()
		elif Input.is_action_just_pressed("hit_cancel"):
			break
		if not Global.cnf_obj.play_sys_se:
			pass
		elif cid == "ID_VOL_BGM" and Global.cnf_obj.vol_bgm != vol_bgm:
			test_sound.volume_linear = Global.cnf_obj.vol_bgm
			if play_test_state == 1 and not test_sound.playing:
				test_sound.play()
			elif play_test_state != 1:
				var filename := Global.get_sys_voice_file("音楽ボリューム")
				FS.load_voice(filename, test_sound)
				test_sound.volume_linear = Global.cnf_obj.vol_bgm
				test_sound.play()
				play_test_state = 1
			vol_bgm = Global.cnf_obj.vol_bgm
		elif cid == "ID_VOL_VOICE" and Global.cnf_obj.vol_voice != vol_voice:
			test_sound.volume_linear = Global.cnf_obj.vol_voice
			if play_test_state == 2 and not test_sound.playing:
				test_sound.play()
			elif play_test_state != 2:
				var filename := Global.get_sys_voice_file("音声ボリューム")
				FS.load_voice(filename, test_sound)
				test_sound.volume_linear = Global.cnf_obj.vol_voice
				test_sound.play()
				play_test_state = 2
			vol_voice = Global.cnf_obj.vol_voice
		elif cid == "ID_VOL_SE" and Global.cnf_obj.vol_se != vol_se:
			test_sound.volume_linear = Global.cnf_obj.vol_se
			if play_test_state == 3 and not test_sound.playing:
				test_sound.play()
			elif play_test_state != 3:
				var filename := Global.get_sys_voice_file("効果音ボリューム")
				FS.load_voice(filename, test_sound)
				test_sound.volume_linear = Global.cnf_obj.vol_se
				test_sound.play()
				play_test_state = 3
			vol_se = Global.cnf_obj.vol_se
		elif cid == "ID_VOL_SYSTEM" and Global.cnf_obj.vol_sys_se != vol_sys_se:
			test_sound.volume_linear = Global.cnf_obj.vol_sys_se
			if play_test_state == 4 and not test_sound.playing:
				test_sound.play()
			elif play_test_state != 4:
				var filename := Global.get_sys_voice_file("システム音ボリューム")
				FS.load_voice(filename, test_sound)
				test_sound.volume_linear = Global.cnf_obj.vol_sys_se
				test_sound.play()
				play_test_state = 4
			vol_sys_se = Global.cnf_obj.vol_sys_se
		elif cid == "ID_WINDOW_DEPTH" and ID_WINDOW_DEPTH.value != window_depth:
			test_sound.volume_linear = Global.cnf_obj.vol_sys_se
			if play_test_state == 5 and not test_sound.playing:
				test_sound.play()
			elif play_test_state != 5:
				var filename := Global.get_sys_voice_file("ウィンドウ濃度")
				FS.load_voice(filename, test_sound)
				test_sound.volume_linear = Global.cnf_obj.vol_sys_se
				test_sound.play()
				play_test_state = 5
			window_depth = ID_WINDOW_DEPTH.value
		elif cid == "ID_MESSAGE_SPEED" and ID_MESSAGE_SPEED.value != message_speed:
			test_sound.volume_linear = Global.cnf_obj.vol_sys_se
			if play_test_state == 6 and not test_sound.playing:
				test_sound.play()
			elif play_test_state != 6:
				var filename := Global.get_sys_voice_file("メッセージ表示速度")
				FS.load_voice(filename, test_sound)
				test_sound.volume_linear = Global.cnf_obj.vol_sys_se
				test_sound.play()
				play_test_state = 6
			message_speed = ID_MESSAGE_SPEED.value
		elif cid == "ID_AUTOMODE_SPEED" and ID_AUTOMODE_SPEED.value != automode_speed:
			test_sound.volume_linear = Global.cnf_obj.vol_sys_se
			if play_test_state == 7 and not test_sound.playing:
				test_sound.play()
			elif play_test_state != 7:
				var filename := Global.get_sys_voice_file("オートモードメッセージ送り速度")
				FS.load_voice(filename, test_sound)
				test_sound.volume_linear = Global.cnf_obj.vol_sys_se
				test_sound.play()
				play_test_state = 7
			automode_speed = ID_AUTOMODE_SPEED.value
	test_sound.stop()
	SoundSystem.stop_sys_se()
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
		set(voices[i].name, voices[i])
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
		var control := await Global.poll_ui_event()
		var cid := control.name if control else &""
		if cid == "ID_SORA":
			if ID_SORA.button_pressed:
				Global.play_sys_voice("音声：穹オン")
			else:
				Global.play_sys_voice("音声：穹オフ")
		elif cid == "ID_AKIRA":
			if ID_AKIRA.button_pressed:
				Global.play_sys_voice("音声：瑛オン")
			else:
				Global.play_sys_voice("音声：瑛オフ")
		elif cid == "ID_NAO":
			if ID_NAO.button_pressed:
				Global.play_sys_voice("音声：奈緒オン")
			else:
				Global.play_sys_voice("音声：奈緒オフ")
		elif cid == "ID_KAZUHA":
			if ID_KAZUHA.button_pressed:
				Global.play_sys_voice("音声：一葉オン")
			else:
				Global.play_sys_voice("音声：一葉オフ")
		elif cid == "ID_MOTOKA":
			if ID_MOTOKA.button_pressed:
				Global.play_sys_voice("音声：初佳オン")
			else:
				Global.play_sys_voice("音声：初佳オフ")
		elif cid == "ID_KOZUE":
			if ID_KOZUE.button_pressed:
				Global.play_sys_voice("音声：梢オン")
			else:
				Global.play_sys_voice("音声：梢オフ")
		elif cid == "ID_YAHIRO":
			if ID_YAHIRO.button_pressed:
				Global.play_sys_voice("音声：やひろオン")
			else:
				Global.play_sys_voice("音声：やひろオフ")
		elif cid == "ID_RYOUHEI":
			if ID_RYOUHEI.button_pressed:
				Global.play_sys_voice("音声：亮平オン")
			else:
				Global.play_sys_voice("音声：亮平オフ")
		elif cid == "ID_OTHER":
			if ID_OTHER.button_pressed:
				Global.play_sys_voice("音声：その他オン")
			else:
				Global.play_sys_voice("音声：その他オフ")
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
