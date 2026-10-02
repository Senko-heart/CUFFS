extends Node

const ScreenType := ConfigDataBase.ScreenType
const ScreenEffect := ConfigDataBase.ScreenEffect
const StepResult := GssInterpreter.StepResult
const TimeZone := CgInfo.TimeZone
const SAVE_NUM := 99
const GAS := 10000

enum GameLogic {
	Unaffected = 0,
	Return = 30,
	Load = 40,
}

enum GameAction {
	Return = 0,
	Start = 1,
	Continue = 2,
	Appreciation = 3,
	Logo = 5,
	Title = 6,
	TitleTop = 6,
	TitleShortScenario = 7,
	TitleWeb = 8,
	Sora = 11,
	Yahiro = 12,
	Kozue = 13,
	Karaoke = 14,
	Web01 = 15,
	Web02 = 16,
	Web03 = 17,
	Web04 = 18,
	Web05 = 19,
	Web06 = 20,
	Countdown = 21,
	Wallpaper = 22,
}

enum Menu {
	Top,
	ShortScenario,
	Web,
}

enum Layer {
	Default,
	AdvBase,
	Trans,
	Hud,
	Appreciation,
	Movie,
	EyeCatch,
	LoadEffect,
	Confirm,
}

var screen_size := Vector2i(800, 600)
var recollect_mode := false
var sc_obj := ScenarioObject.new()
var cnf_obj := ConfigDataBase.new()
var sys_obj := SystemObject.new()
var adv: AdvScreen
var in_movie := false
var in_confirm := false
var in_eye_catch := false
var eye_catch_type := ""
var in_ask_game_exit := false
var load_effect := CanvasLayer.new()
var load_effect_alpha: Texture2D
var eye_catch := CanvasLayer.new()
var eye_catch_alpha_t: Texture2D
var eye_catch_alpha_b: Texture2D
var eye_catch_logo: Texture2D
var frame_skin: ControlPack
var title_skin: ControlPack
var option_skin: ControlPack

var sc_objects: Array[ScenarioObject] = []
var sc_history: Array[Dictionary] = []
var sc_history_diff: Array[Dictionary] = []
var sc_history_end := 49
var sc_obj_thumb_textures: Array[Texture2D] = []
var sc_obj_qsave: ScenarioObject = null
var confirm_prompt: Dictionary[StringName, String] = {
	quit = "ゲームを終了します",
	qload = "クイックロードします",
	qsave = "クイックセーブしました",
	loaderr = "セーブデータに異常があり、ゲームを終了します。",
	load = "%02d番をロードします",
	save = "%02d番にセーブします",
	default = "初期設定に戻します",
	title = "タイトルに戻ります",
	appreciation = "鑑賞に戻ります",
}

var FRM_0414: Texture2D
var MESS_X := 684
var BLINK_WIDTH := 0.0

func _init() -> void:
	sc_objects.resize(SAVE_NUM)
	sc_history.resize(50)
	sc_history_diff.resize(50)
	sc_obj_thumb_textures.resize(SAVE_NUM)

func _ready() -> void:
	await FS.sync()
	if not FS.patch.is_open():
		MESS_X = 696
		BLINK_WIDTH = 24.0
	TranslationTable.initialize()
	load_system_data()
	load_config_data()
	load_scobjs_data()
	set_screen_type(cnf_obj.screen_type)
	frame_skin = ControlPack.new(&"frame")
	title_skin = ControlPack.new(&"title")
	option_skin = ControlPack.new(&"option")
	var bytes := Global.frame_skin._try_load("FRM_0414.png")
	if not bytes.is_empty():
		var image := Image.new()
		image.load_png_from_buffer(bytes)
		FRM_0414 = ImageTexture.create_from_image(image)
	else: FRM_0414 = preload("res://FRM_0414.png")
	var master := AudioServer.get_bus_index(&"Master")
	AudioServer.set_bus_volume_linear(master, 0.75)
	eye_catch.layer = Layer.EyeCatch
	add_child(eye_catch)
	eye_catch_alpha_t = FS.load_mask_texture("EyeCatchT")
	eye_catch_alpha_b = FS.load_mask_texture("EyeCatchB")
	eye_catch_logo = FS.load_texture("title")
	load_effect.layer = Layer.LoadEffect
	add_child(load_effect)
	load_effect_alpha = FS.load_mask_texture("WIP_TLBR")
	adv = AdvScreen.new()
	add_child(adv)
	await starting()
	save_and_quit()

func _process(_delta: float) -> void:
	check_shortcut_key()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if in_movie:
			Input.action_press("hit_cancel")
			Input.action_release("hit_cancel")
		else:
			await ask_game_exit()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Input.action_press("hit_cancel")
		await get_tree().process_frame
		Input.action_release("hit_cancel")

func wait(action: StringName, time: float) -> bool:
	if Input.is_action_just_pressed(action):
		await get_tree().process_frame
	var deadline := get_tree().create_timer(time)
	while deadline.time_left > 0.0:
		if Input.is_action_just_pressed(action):
			return true
		await get_tree().process_frame
	return false

var pressed_button: ModButton:
	set(value):
		pressed_button = value
		if value:
			ui_event_control = value
			pressed_button_signal.emit()
signal pressed_button_signal

func next_pressed_button() -> ModButton:
	await pressed_button_signal
	return pressed_button

func poll_pressed_button() -> ModButton:
	pressed_button = null
	await get_tree().process_frame
	return pressed_button

var scrolled: ModScroll:
	set(value):
		scrolled = value
		if value:
			ui_event_control = value
			scrolled_signal.emit()
signal scrolled_signal

var ui_event_control: Control

func poll_ui_event() -> Control:
	while get_tree().paused:
		await get_tree().process_frame
	ui_event_control = null
	pressed_button = null
	scrolled = null
	await get_tree().process_frame
	return ui_event_control

func set_volume(vol: float) -> void:
	var master := AudioServer.get_bus_index(&"Master")
	AudioServer.set_bus_volume_linear(master, vol)

#region file-2.cos
func create_num_string(
	num: int,
	figure: int = 0,
	pad_zeros: bool = false,
	fullwidth: bool = false,
) -> String:
	var strnum := (
		str(num).pad_zeros(figure) if pad_zeros else
		"-" + str(-num).lpad(figure) if num < 0 else
		str(num).lpad(figure))
	if fullwidth: return make_fullwidth(strnum)
	return strnum

func make_fullwidth(strnum: String) -> String:
	var ascii := strnum.to_ascii_buffer()
	var fwnum := ""
	for n in ascii:
		if n == ord("-"): fwnum += "－"
		elif n == ord(" "): fwnum += "　"
		elif ord("0") <= n and n <= ord("9"):
			fwnum += String.chr(n + 0xfee0)
		else: fwnum += String.chr(n)
	return fwnum

func create_time_string(unix_time: float) -> String:
	var bias: int = Time.get_time_zone_from_system().bias
	var local_time := int(unix_time) + 60 * bias
	return Time.get_datetime_string_from_unix_time(local_time, true)\
		.replace("-", "/")

func adjust_string(src: String, num: int) -> String:
	var size := src.length()
	var split := range(0, size, num).map(func(n: int) -> String:
		return src.substr(n, mini(num, size - n))
	)
	return "\n".join(split)

func adjust_message(mess: String) -> PackedStringArray:
	var lines := mess.split("\n")
	var size := lines.size()
	return range(0, size, 3).map(func(n: int) -> String:
		return "\n".join(lines.slice(n, min(n + 3, size)))
	)

func rgb(r: int, g: int, b: int) -> int:
	return (r << 16) | (g << 8) | b

func rgba(r: int, g: int, b: int, a: int) -> int:
	return (a << 24) | (r << 16) | (g << 8) | b

func play_movie(filename: String, vol: float = cnf_obj.vol_bgm if cnf_obj.play_bgm else 0.0) -> void:
	var master := AudioServer.get_bus_index(&"Master")
	AudioServer.set_bus_volume_linear(master, 0.75 * vol)
	in_movie = true
	var movie_layer := CanvasLayer.new()
	var player := VideoStreamPlayer.new()
	var stream := VideoStreamTheora.new()
	stream.file = FS.root + filename
	player.stream = stream
	movie_layer.layer = Layer.Movie
	add_child(movie_layer)
	movie_layer.add_child(player)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	await get_tree().process_frame
	player.play()
	while player.is_playing():
		if Input.is_action_just_pressed("hit_cancel", true):
			break
		await get_tree().process_frame
	player.stop()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	movie_layer.queue_free()
	in_movie = false
	AudioServer.set_bus_volume_linear(master, 0.75)

func create_color_texture(
	color: Color,
	size: Vector2i = screen_size,
) -> GradientTexture2D:
	var texture := GradientTexture2D.new()
	texture.width = size.x
	texture.height = size.y
	var gradient := Gradient.new()
	gradient.set_color(0, color)
	gradient.set_color(1, color)
	texture.gradient = gradient
	return texture

func create_message_escape_sequence(
	size: int = 0,
	bold: bool = false,
	italic: bool = false,
	face: String = "",
) -> Dictionary:
	var seq := {}
	if size > 0: seq.size = size
	if bold: seq.bold = true
	if italic: seq.italic = true
	if not face.is_empty(): seq.face = face
	return seq
#endregion

#region file-3.cos
func load_system_data() -> void:
	var bytes := FS.load_save_bytes("system.cfg")
	var text := bytes.get_string_from_utf8()
	var cfg := ConfigFile.new()
	if text.is_empty() or cfg.parse(text):
		save_system_data()
		return
	sys_obj.load_from(cfg)

func save_system_data() -> void:
	var file := FS.open_save_file("system.cfg")
	if file != null:
		var cfg := ConfigFile.new()
		sys_obj.dump_into(cfg)
		var text := cfg.encode_to_text()
		file.store_string(text)

func load_config_data() -> void:
	var bytes := FS.load_save_bytes("config.cfg")
	var text := bytes.get_string_from_utf8()
	var cfg := ConfigFile.new()
	if text.is_empty() or cfg.parse(text):
		save_config_data()
		return
	cnf_obj.load_from(cfg)

func save_config_data() -> void:
	var file := FS.open_save_file("config.cfg")
	if file != null:
		var cfg := ConfigFile.new()
		cnf_obj.dump_into(cfg)
		var text := cfg.encode_to_text()
		file.store_string(text)

func load_scobjs_data() -> void:
	for i in range(SAVE_NUM + 1):
		var filename := "Save%02d.png" % (i + 1) if i < SAVE_NUM else "QSave.sav"
		var bytes := FS.load_save_bytes(filename)
		if bytes.is_empty():
			continue
		var unc_size: int
		if i < SAVE_NUM:
			var pngsize := FS.measure_png(bytes)
			var png := bytes.slice(0, pngsize)
			var thm := Image.new()
			thm.load_png_from_buffer(png)
			var dims := thm.get_size()
			if dims.x > 400 or dims.y > 300:
				dims = Vector2(400, 300).min(dims)
				thm.resize(dims.x, dims.y)
			var texture := ImageTexture.create_from_image(thm)
			sc_obj_thumb_textures[i] = texture
			unc_size = bytes.decode_u32(pngsize)
			bytes = bytes.slice(pngsize + 4)
		else:
			unc_size = bytes.decode_u32(0)
			bytes = bytes.slice(4)
		bytes = bytes.decompress(unc_size, FileAccess.COMPRESSION_ZSTD)
		var loadobj := ScenarioObject.new()
		var json := JSON.new()
		if json.parse(bytes.get_string_from_utf8()):
			loadobj.loaderr = true
		elif json.data is not Dictionary:
			loadobj.loaderr = true
		elif not loadobj.load(json.data):
			loadobj.loaderr = true
		if i < SAVE_NUM:
			sc_objects[i] = loadobj
		else:
			sc_obj_qsave = loadobj

func check_shortcut_key() -> void:
	if Input.is_action_just_pressed("toggle_screen_mode"):
		match cnf_obj.screen_type:
			ScreenType.Windowed: set_screen_type(ScreenType.FullScreen)
			ScreenType.FullScreen: set_screen_type(ScreenType.Windowed)

func set_screen_type(screen_type: ScreenType) -> void:
	match screen_type:
		ScreenType.Windowed:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(
				DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		ScreenType.FullScreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	if screen_type != cnf_obj.screen_type:
		cnf_obj.screen_type = screen_type
		save_config_data()

func setup_adv_screen() -> void:
	print("+-SetupAdvScreen-+")
	Global.adv.create()

func destroy_adv_screen() -> void:
	print("+-DestroyAdvScreen-+")
	Global.adv.destroy()

func scenario_loop(sc: String) -> GameAction:
	SoundSystem.stop_bgm()
	setup_adv_screen()
	GssInterpreter.change(sc)
	adv.set_tone_filter("NORMAL")
	adv.set_cg_("BLACK")
	var gas := GAS
	var ret := GameAction.TitleShortScenario \
			if &"00_" in sc_obj.scenario_call \
			or &"KARAOKE" in sc_obj.scenario_call \
			else GameAction.TitleWeb
	while sc_obj.scenario_call != &"EXIT_SCENARIO" \
	and sc_obj.scenario_call != &"EXIT_SCENARIO_LOGO":
		print_rich("[color=#88ffff]Jump-%s[/color]" % sc_obj.scenario_call)
		sc = "sc" + sc_obj.scenario_call
		if not GssInterpreter.load_scenario(sc):
			printerr("Failed to load %s" % sc)
			get_tree().quit(1)
		var has_finished := false
		while gas > 0:
			match await GssInterpreter.step():
				StepResult.Ok:
					pass
				StepResult.OkProgress:
					gas = GAS + 1
				StepResult.Change:
					gas -= 1
					break
				StepResult.Finished:
					has_finished = true
					break
				StepResult.TooMuch:
					printsteperr("Line contains more than a single command", sc)
				StepResult.BadCommand:
					printsteperr("Unknown command", sc)
				StepResult.BadIdent:
					printsteperr("Expected identifier", sc)
				StepResult.BadValue:
					printsteperr("Expected literal value", sc)
				StepResult.BadSyntax:
					printsteperr("Syntax error", sc)
				StepResult.BadKeyword:
					printsteperr("Unrecognized keyword", sc)
			gas -= 1
		assert(gas > 0, "out of gas")
		if gas <= 0: get_tree().quit(1)
		if has_finished: break
	adv.set_tone_filter("NORMAL")
	adv.hide_message()
	adv.set_cg_("BLACK")
	adv.bustup_clear(0)
	await adv.update_(false, true)
	SoundSystem.stop_voice()
	SoundSystem.stop_se()
	SoundSystem.stop_env_se()
	SoundSystem.stop_bgm()
	destroy_adv_screen()
	if sc_obj.scenario_call == &"EXIT_SCENARIO_LOGO":
		return GameAction.Logo
	return ret

func scenario_enter() -> void:
	if is_load():
		return
	sc_obj.hitret_id = -1
	sc_obj.select.clear()
	sc_obj.select_count = 0

func printsteperr(message: String, sc: String) -> void:
	printerr("%s (%s.gss, line %d)" % [message, sc, GssInterpreter.line])
	printerr("in: %s" % GssInterpreter.l)

func ask_game_exit() -> void:
	if in_ask_game_exit: return
	in_ask_game_exit = true
	play_sys_voice("ゲーム終了")
	if await confirm(confirm_prompt.quit):
		save_and_quit()
	in_ask_game_exit = false

func save_and_quit() -> void:
	save_system_data()
	save_config_data()
	ResourceCache.free_all()
	get_tree().quit()

func on_flag(i: int) -> void:
	if 0 < i and i < 512:
		print_rich("[color=#aaffaa]Flag%s-ON[/color]" % i)
		sc_obj.flag.set_(i)

func off_flag(i: int) -> void:
	if 0 < i and i < 512:
		print_rich("[color=#aaffaa]Flag%s-OFF[/color]" % i)
		sc_obj.flag.reset(i)

func chk_flag(i: int) -> bool:
	return chk_flag_on(i)

func chk_flag_on(i: int) -> bool:
	if 0 < i and i < 512:
		return sc_obj.flag.check(i)
	return false

func chk_flag_off(i: int) -> bool:
	if 0 < i and i < 512:
		return not sc_obj.flag.check(i)
	return false

func on_global_flag(i: int) -> void:
	if 0 < i and i < 128:
		print("GlobalFlag%s-ON" % i)
		sys_obj.global_sc_flag.set_(i)
		save_system_data()

func off_global_flag(i: int) -> void:
	if 0 < i and i < 128:
		print("GlobalFlag%s-OFF" % i)
		sys_obj.global_sc_flag.reset(i)
		save_system_data()

func chk_global_flag_on(i: int) -> bool:
	if 0 < i and i < 128:
		return sys_obj.global_sc_flag.check(i)
	return false

func is_recollect_mode() -> bool:
	return recollect_mode

func is_saveable() -> bool:
	return not recollect_mode

func enter_recollect_mode() -> void:
	recollect_mode = true

func leave_recollect_mode() -> void:
	recollect_mode = false

func on_recollect_flag(i: int) -> void:
	if 0 < i and i < 32:
		print("Recollect%s-ON" % i)
	sys_obj.recollect_flag.set_(i)
	save_system_data()

func chk_recollect_flag(i: int) -> bool:
	if 0 < i and i < 32:
		return sys_obj.recollect_flag.check(i)
	return false

func check_cg_flag(id: int) -> bool:
	if 0 < id and id < 4096:
		return sys_obj.cg_flag.check(id)
	return false

func set_cg_flag(id: int) -> void:
	if 0 < id and id < 4096: sys_obj.cg_flag.set_(id)

func reset_cg_flag(id: int) -> void:
	if 0 < id and id < 4096: sys_obj.cg_flag.reset(id)

func check_bu(
	src: String,
	filename: StringName,
	base_flag: int = 0,
	flag: int = 0
) -> bool:
	if filename in src:
		if base_flag != 0:
			set_cg_flag(base_flag)
			set_cg_flag(flag)
		return true
	return false

func check_cg(
	src: String,
	filename: StringName,
	base_flag: int = 0,
	flag: int = 0
) -> bool:
	if filename == src:
		if base_flag != 0:
			set_cg_flag(base_flag)
			set_cg_flag(flag)
		return true
	return false

func is_game_clear() -> bool:
	return sys_obj.game_clear

func on_game_clear() -> void:
	sys_obj.game_clear = true
	save_system_data()

func off_game_clear() -> void:
	sys_obj.game_clear = false
	save_system_data()

func hit_wait(time: float) -> bool:
	return await wait(&"hit", time)

func test_hitret(msg: String = "") -> void:
	if not msg.is_empty(): print(msg)
	while not Input.is_action_just_pressed("hit", true):
		await get_tree().process_frame
#endregion

#region file-6.cos
func starting() -> void:
	var action := GameAction.Logo
	while true:
		match action:
			GameAction.Logo:
				await logo()
				await attention()
				await play_movie("opening.ogv")
				action = GameAction.Title
			GameAction.Title:
				action = await title(Menu.Top)
			GameAction.TitleShortScenario:
				action = await title(Menu.ShortScenario)
			GameAction.TitleWeb:
				action = await title(Menu.Web)
			GameAction.Start:
				await scenario_loop("sampleSC")
				action = GameAction.Logo
			GameAction.Appreciation:
				await appreciation()
				action = GameAction.Title
			GameAction.Wallpaper:
				await wallpaper()
				action = GameAction.Title
			GameAction.Continue:
				action = await scenario_loop(sc_obj.scenario_call)
			GameAction.Sora:
				action = await scenario_loop("00_A001")
			GameAction.Yahiro:
				action = await scenario_loop("00_G001")
			GameAction.Kozue:
				action = await scenario_loop("00_H001")
			GameAction.Karaoke:
				action = await scenario_loop("KARAOKE")
			GameAction.Web01:
				action = await scenario_loop("WEB01")
			GameAction.Web02:
				action = await scenario_loop("WEB02")
			GameAction.Web03:
				action = await scenario_loop("WEB03")
			GameAction.Web04:
				action = await scenario_loop("WEB04")
			GameAction.Web05:
				action = await scenario_loop("WEB05")
			GameAction.Web06:
				action = await scenario_loop("WEB06")
			GameAction.Countdown:
				action = await scenario_loop("COUNTDOWN")
			_: break

func logo() -> void:
	var spr_base := title_skin.create_texture_rect("ID_FRM_0601")
	spr_base.modulate.a = 0.0
	add_child(spr_base)
	Anim.fade(spr_base, 1.0, 1.0)
	var spr_logo: TextureRect
	var cancel := await hit_wait(1.0)
	if not cancel:
		play_sys_voice("ブランドコール")
		spr_logo = title_skin.create_texture_rect("ID_FRM_0602")
		spr_logo.modulate.a = 0.0
		add_child(spr_logo)
		spr_logo.position = (screen_size - Vector2i(spr_logo.size)) / 2
		Anim.fade(spr_logo, 1.0, 1.0)
		cancel = await hit_wait(5.0)
	if not cancel:
		Anim.schedule_fade(spr_base, 0.0)
		Anim.schedule_fade(spr_logo, 0.0)
		await Anim.run(1.0)
	if spr_logo: Anim.destroy(spr_logo)
	Anim.destroy(spr_base)

func title(state: Menu) -> GameAction:
	sc_obj = ScenarioObject.new()
	SoundSystem.play_bgm("BGM07")
	var spr_base := title_skin.create_texture_rect(&"ID_FRM_0611")
	spr_base.modulate.a = 0.0
	add_child(spr_base)
	var spr_logo: Control = title_skin.create_texture_rect(&"ID_FRM_0612")
	spr_logo.modulate.a = 0.0
	spr_logo.position = Vector2(223, 95)
	add_child(spr_logo)
	var menu_center := Vector2(screen_size.x / 2, 400.0)
	var spr_top_menu := title_skin.create_form_page(&"ID_PAGE_MENU_FULL")
	spr_top_menu.modulate.a = 0.0
	spr_top_menu.position = menu_center - 0.5 * spr_top_menu.size
	add_child(spr_top_menu)
	var spr_ss_menu := title_skin.create_form_page(&"ID_PAGE_SHORTSCENARIO")
	spr_ss_menu.modulate.a = 0.0
	spr_ss_menu.position = menu_center - 0.5 * spr_ss_menu.size
	add_child(spr_ss_menu)
	var spr_web_menu := title_skin.create_form_page(&"ID_PAGE_WEB")
	spr_web_menu.modulate.a = 0.0
	spr_web_menu.position = menu_center - 0.5 * spr_web_menu.size
	add_child(spr_web_menu)
	var mspr_version := MessageSprite.new()
	mspr_version.create_message(70, 20)
	mspr_version.attach_message_style(title_skin, &"ID_FONT_VERSION")
	mspr_version.set_default_msg_speed(0, 0, 0)
	mspr_version.position = Vector2(screen_size) - mspr_version.size
	mspr_version.output_message("Ver 1.00")
	mspr_version.modulate.a = 0.0
	add_child(mspr_version)
	Anim.fade(mspr_version, 1.0, 0.5)
	play_sys_voice("タイトルコール")
	spr_top_menu.hide()
	spr_ss_menu.hide()
	spr_web_menu.hide()
	match state:
		Menu.Top:
			spr_top_menu.show()
			Anim.fade(spr_top_menu, 1.0, 0.3)
		Menu.ShortScenario:
			spr_ss_menu.show()
			Anim.fade(spr_ss_menu, 1.0, 0.3)
		Menu.Web:
			spr_web_menu.show()
			Anim.fade(spr_web_menu, 1.0, 0.3)
	Anim.fade(spr_logo, 1.0, 0.5)
	await Anim.fade(spr_base, 1.0, 0.5)
	var ret := GameAction.Return
	while true:
		var control := await poll_ui_event()
		var cid := control.name if control else &""
		if cid == &"ID_SHORTSCENARIO":
			state = Menu.ShortScenario
			play_sys_voice("ショートストーリー")
			spr_ss_menu.show()
			Anim.fade(spr_top_menu, 0.0, 0.5)
			await Anim.fade(spr_ss_menu, 1.0, 0.5)
			spr_top_menu.hide()
		elif cid == &"ID_SORA":
			play_sys_voice("ショートストーリー：穹")
			ret = GameAction.Sora
			break
		elif cid == &"ID_YAHIRO":
			play_sys_voice("ショートストーリー：やひろ")
			ret = GameAction.Yahiro
			break
		elif cid == &"ID_KOZUE":
			play_sys_voice("ショートストーリー：梢")
			ret = GameAction.Kozue
			break
		elif cid == &"ID_KARAOKE":
			play_sys_voice("ショートストーリー：初佳")
			ret = GameAction.Karaoke
			break
		elif cid == &"ID_WEB":
			state = Menu.Web
			play_sys_voice("WEBコンテンツ：選択")
			spr_web_menu.show()
			Anim.fade(spr_top_menu, 0.0, 0.5)
			await Anim.fade(spr_web_menu, 1.0, 0.5)
			spr_top_menu.hide()
		elif cid == &"ID_WEB01":
			play_sys_voice("コズエノソラ：１")
			ret = GameAction.Web01
			break
		elif cid == &"ID_WEB02":
			play_sys_voice("コズエノソラ：２")
			ret = GameAction.Web02
			break
		elif cid == &"ID_WEB03":
			play_sys_voice("コズエノソラ：３")
			ret = GameAction.Web03
			break
		elif cid == &"ID_WEB04":
			play_sys_voice("コズエノソラ：４")
			ret = GameAction.Web04
			break
		elif cid == &"ID_WEB05":
			play_sys_voice("コズエノソラ：５")
			ret = GameAction.Web05
			break
		elif cid == &"ID_WEB06":
			play_sys_voice("コズエノソラ：６")
			ret = GameAction.Web06
			break
		elif cid == &"ID_COUNTDOWN":
			play_sys_voice("カウントダウ")
			ret = GameAction.Countdown
			break
		elif cid == &"ID_WALLPAPER":
			play_sys_voice("壁紙")
			ret = GameAction.Wallpaper
			break
		elif cid == &"ID_CONTINUE":
			Anim.fade(spr_top_menu, 0.0, 0.3)
			var win := LoadSaveWindow.new(self, true)
			win._show()
			var _ret := await win.run()
			if _ret != GameLogic.Load:
				Anim.fade(spr_top_menu, 1.0, 0.3)
			await win._hide()
			win.destroy()
			if _ret == GameLogic.Load:
				ret = GameAction.Continue
				break
		elif cid == &"ID_CONFIG":
			play_sys_voice("コンフィグ")
			Anim.fade(spr_top_menu, 0.0, 0.3)
			var win := ConfigWindow.new(self, true)
			win._show()
			await win.run()
			Anim.fade(spr_top_menu, 1.0, 0.3)
			await win._hide()
			win.destroy()
		elif cid == &"ID_APPRECIATION":
			play_sys_voice("鑑賞モード")
			ret = GameAction.Appreciation
			break
		elif cid == &"ID_EXITGAME":
			await ask_game_exit()
		elif Input.is_action_just_pressed(&"quick_load"):
			if sc_obj_qsave:
				play_sys_voice(&"クイックロード確認")
				if await confirm(confirm_prompt.qload):
					await quick_load()
					ret = GameAction.Continue
					break
		elif Input.is_action_just_pressed(&"hit_cancel"):
			if state == Menu.ShortScenario:
				spr_top_menu.show()
				Anim.fade(spr_top_menu, 1.0, 0.5)
				await Anim.fade(spr_ss_menu, 0.0, 0.5)
				spr_ss_menu.hide()
				SoundSystem.stop_sys_se()
				state = Menu.Top
			elif state == Menu.Web:
				spr_top_menu.show()
				Anim.fade(spr_top_menu, 1.0, 0.5)
				await Anim.fade(spr_web_menu, 0.0, 0.5)
				spr_web_menu.hide()
				SoundSystem.stop_sys_se()
				state = Menu.Top
	SoundSystem.stop_bgm()
	var time := 3.0 if ret == GameAction.Start else 0.5
	var spr_ss_title := TextureRect.new()
	if state == Menu.ShortScenario:
		if ret == GameAction.Sora:
			spr_ss_title.texture = FS.load_texture("SS_SORA")
		elif ret == GameAction.Yahiro:
			spr_ss_title.texture = FS.load_texture("SS_YAHIRO")
		elif ret == GameAction.Kozue:
			spr_ss_title.texture = FS.load_texture("SS_KOZUE")
		elif ret == GameAction.Karaoke:
			spr_ss_title.texture = FS.load_texture("SS_KARAOKE")
		spr_ss_title.modulate.a = 0.0
		add_child(spr_ss_title)
		await Anim.fade(spr_ss_title, 1.0, 2.0)
		Anim.fade(spr_ss_menu, 0.0, 0.5)
	elif state == Menu.Web:
		Anim.fade(spr_web_menu, 0.0, 0.5)
		Anim.schedule_fade(mspr_version, 0.0)
		Anim.schedule_fade(spr_logo, 0.0)
		Anim.schedule_fade(spr_base, 0.0)
		await Anim.run(time)
	else:
		Anim.fade(spr_top_menu, 0.0, 0.5)
		Anim.schedule_fade(mspr_version, 0.0)
		Anim.schedule_fade(spr_logo, 0.0)
		Anim.schedule_fade(spr_base, 0.0)
		await Anim.run(time)
	Anim.destroy(spr_base)
	Anim.destroy(spr_logo)
	Anim.destroy(spr_top_menu)
	Anim.destroy(spr_ss_menu)
	Anim.destroy(spr_web_menu)
	Anim.destroy(mspr_version)
	if state == Menu.ShortScenario:
		var cancel := await SoundSystem.wait_sys_se()
		if not cancel:
			cancel = await hit_wait(3.0)
		if not cancel:
			await Anim.fade(spr_ss_title, 0.0, 2.0)
		SoundSystem.stop_sys_se()
	elif state == Menu.Web:
		await SoundSystem.wait_sys_se()
		SoundSystem.stop_sys_se()
	Anim.destroy(spr_ss_title)
	return ret

var attention_given := false

func attention() -> void:
	if attention_given:
		return
	await get_tree().process_frame
	var spr_attention := TextureRect.new()
	spr_attention.texture = FS.load_texture("attention")
	add_child(spr_attention)
	var cancel := false
	for file: String in ["AK200004", "SR200004",
			"AK200005", "SR200005", "AK200007", "SR200006"]:
		SoundSystem.play_voice(file)
		cancel = await SoundSystem.wait_voice()
		if cancel: break
	SoundSystem.stop_voice()
	if not cancel:
		cancel = await hit_wait(3.0)
	if not cancel:
		await Anim.fade(spr_attention, 0.0, 3.0)
	Anim.destroy(spr_attention)
	attention_given = true

var VOICE_CALLS: Dictionary[String, PackedStringArray] = {
	"ブランドコール": ["AK200001", "KA200001", "KO200001", "MT200001", "NO200001", "RH200001", "SR200001", "YH200001"],
	"タイトルコール": ["AK200002", "KA200002", "KO200002", "MT200002", "NO200002", "RH200002", "SR200002", "YH200002"],
	"アイキャッチ": ["AK200003", "KA200003", "KO200003", "MT200003", "SR200003"],
	"ワーニング": ["warning"],
	"セーブしました": ["AK200008", "KA200004", "KO200003", "MT200004", "NO200003", "SR200007", "YH200003"],
	"セーブ上書き確認": ["AK200009", "KA200005", "KO200004", "MT200005", "NO200004", "SR200008", "YH200004"],
	"ロード確認": ["AK200010", "KA200006", "KO200005", "MT200006", "NO200005", "SR200009", "YH200005"],
	"クイックセーブしました": ["AK200011", "KA200007", "KO200006", "MT200007", "NO200006", "SR200010", "YH200006"],
	"クイックロード確認": ["AK200012", "KA200008", "KO200007", "MT200008", "NO200007", "SR200011", "YH200007"],
	"スクリーンモード": ["AK200013", "KA200009", "KO200008", "MT200009", "NO200008", "SR200012", "YH200008"],
	"ウィンドウモード": ["AK200014", "KA200010", "KO200009", "MT200010", "NO200009", "SR200013", "YH200009"],
	"フルスクリーンモード": ["AK200015", "KA200011", "KO200010", "MT200011", "NO200010", "SR200014", "YH200010"],
	"音楽オン": ["AK200016", "KA200012", "KO200011", "MT200012", "NO200011", "SR200015", "YH200011"],
	"音楽オフ": ["AK200017", "KA200013", "KO200012", "MT200013", "NO200012", "SR200016", "YH200012"],
	"音楽ボリューム": ["AK200018", "KA200014", "KO200013", "MT200014", "NO200013", "SR200017", "YH200013"],
	"効果音オン": ["AK200019", "KA200015", "KO200014", "MT200015", "NO200014", "SR200018", "YH200014"],
	"効果音オフ": ["AK200020", "KA200016", "KO200015", "MT200016", "NO200015", "SR200019", "YH200015"],
	"効果音ボリューム": ["AK200021", "KA200017", "KO200016", "MT200017", "NO200016", "SR200020", "YH200016"],
	"システム音オン": ["AK200022", "KA200018", "KO200017", "MT200018", "NO200017", "SR200021", "YH200017"],
	"システム音オフ": ["AK200023", "KA200019", "KO200018", "MT200019", "NO200018", "SR200022", "YH200018"],
	"システム音ボリューム": ["AK200024", "KA200020", "KO200019", "MT200020", "NO200019", "SR200023", "YH200019"],
	"音声オン": ["AK200025", "KA200021", "KO200020", "MT200021", "NO200020", "SR200024", "YH200020"],
	"音声オフ": ["AK200026", "KA200022", "KO200021", "MT200022", "NO200021", "SR200025", "YH200021"],
	"音声ボリューム": ["AK200027", "KA200023", "KO200022", "MT200023", "NO200022", "SR200026", "YH200022"],
	"音声：穹オン": ["SR200027"],
	"音声：穹オフ": ["SR200029"],
	"音声：奈緒オン": ["NO200023"],
	"音声：奈緒オフ": ["NO200024"],
	"音声：瑛オン": ["AK200028"],
	"音声：瑛オフ": ["AK200029"],
	"音声：一葉オン": ["KA200024"],
	"音声：一葉オフ": ["KA200025"],
	"音声：初佳オン": ["MT200024"],
	"音声：初佳オフ": ["MT200025"],
	"音声：やひろオン": ["YH200023"],
	"音声：やひろオフ": ["YH200024"],
	"音声：梢オン": ["KO200023"],
	"音声：梢オフ": ["KO200024"],
	"音声：亮平オン": ["RH200003"],
	"音声：亮平オフ": ["RH200004"],
	"音声：その他オン": ["SR200028"],
	"音声：その他オフ": ["AK200030"],
	"画面効果オン": ["AK200031", "KA200026", "KO200025", "MT200026", "NO200025", "SR200030", "YH200025"],
	"画面効果オフ": ["AK200032", "KA200027", "KO200026", "MT200027", "NO200026", "SR200031", "YH200026"],
	"ウィンドウ濃度": ["AK200033", "KA200028", "KO200027", "MT200028", "NO200027", "SR200032", "YH200027"],
	"メッセージ表示速度": ["AK200034", "KA200029", "KO200028", "MT200029", "NO200028", "SR200033", "YH200028"],
	"メッセージスキップ：既読のみ": ["AK200035", "KA200030", "KO200029", "MT200030", "SR200034", "YH200029"],
	"メッセージスキップ：全部": ["AK200036", "KA200031", "KO200030", "MT200031", "NO200030", "SR200035", "YH200030"],
	"音声制御：抑制なし": ["AK200037", "KA200032", "KO200031", "MT200032", "NO200031", "SR200036", "YH200031"],
	"音声制御：抑制あり": ["AK200038", "KO200032", "MT200033", "NO200032", "YH200032"],
	"オートモードメッセージ送り速度": ["AK200039", "KA200034", "KO200033", "MT200034", "NO200033", "SR200038", "YH200033"],
	"初期設定に戻す": ["AK200040", "KA200035", "KO200034", "MT200035", "NO200034", "SR200039", "YH200034"],
	"ゲーム終了": ["AK200041", "KA200036", "KO200035", "MT200036", "NO200035", "SR200040", "YH200035"],
	"タイトルに戻る": ["AK200042", "KA200037", "KO200036", "MT200037", "NO200036", "SR200041", "YH200036"],
	"終了ボイス": ["AK200043", "KA200038", "KO200037", "MT200038", "NO200037", "SR200042", "YH200037"],
	"ショートストーリー": ["AK200044", "KO200038", "SR200043", "YH200038"],
	"ショートストーリー：穹": ["SR200045"],
	"ショートストーリー：やひろ": ["YH200039"],
	"ショートストーリー：梢": ["KO200041"],
	"ショートストーリー：初佳": ["MT200041"],
	"カウントダウン": ["AK200046"],
	"WEBコンテンツ：選択": ["KA200039", "MT200039"],
	"コズエノソラ：選択": ["KO200043"],
	"コズエノソラ：１": ["AK200047"],
	"コズエノソラ：２": ["NO200039"],
	"コズエノソラ：３": ["SR200046"],
	"コズエノソラ：４": ["KA200041"],
	"コズエノソラ：５": ["MT200042"],
	"コズエノソラ：６": ["KO200042"],
	"壁紙": ["SR200044", "NO200038"],
	"鑑賞モード": ["AK200045", "KO200040"],
	"コンフィグ": ["KA200040", "MT200040"],
	"ショートストーリー終了：穹": ["SR200047"],
	"ショートストーリー終了：やひろ": ["YH200040"],
	"ショートストーリー終了：梢": ["KO200044"],
	"ショートストーリー終了：全員": []
}

func play_sys_voice(type: String) -> void:
	var file := get_sys_voice_file(type)
	if not file.is_empty():
		SoundSystem.play_sys_se(file)

func get_sys_voice_file(type: String) -> String:
	if type not in VOICE_CALLS: return ""
	var voice := VOICE_CALLS[type]
	if voice.is_empty(): return ""
	return voice[randi_range(0, voice.size() - 1)]
#endregion

#region file-9.cos
@warning_ignore("shadowed_variable")
func load(save: ScenarioObject) -> void:
	SoundSystem.stop_bgm()
	SoundSystem.stop_env_se()
	SoundSystem.stop_se()
	SoundSystem.stop_voice()
	if save.loaderr:
		await confirm(confirm_prompt.loaderr, false, 5.0)
		save_and_quit()
	sc_obj.load(save.dump())
	await show_load_effect()
	enter_load()

func save(filename: String, thumb: bool, id: int = -1) -> void:
	var file := FS.open_save_file(filename)
	if thumb:
		var thm: Image
		if is_h_scene(filename):
			thm = FS.load_image(filename.left(4) + "thm")
		else:
			thm = (await adv.create_capture()).get_image()
			thm.convert(Image.FORMAT_RGB8)
			adv.destroy_capture()
		var png := thm.save_png_to_buffer()
		var end := FS.measure_png(png)
		if end < png.size():
			png.resize(end)
		file.store_buffer(png)
		if id in range(SAVE_NUM):
			var dims := thm.get_size()
			if dims.x > 400 or dims.y > 300:
				dims = Vector2i(400, 300).min(dims)
				thm.resize(dims.x, dims.y)
			var texture := ImageTexture.create_from_image(thm)
			sc_obj_thumb_textures[id] = texture
	var data := sc_obj.savedump()
	if id in range(SAVE_NUM):
		if not sc_objects[id]:
			sc_objects[id] = ScenarioObject.new()
		sc_objects[id].load(data)
		sc_objects[id].loaderr = false
	else:
		if not sc_obj_qsave:
			sc_obj_qsave = ScenarioObject.new()
		sc_obj_qsave.load(data)
		sc_obj_qsave.loaderr = false
	var bytes := JSON.stringify(data).to_utf8_buffer()
	var unc_size := bytes.size()
	bytes = bytes.compress(FileAccess.COMPRESSION_ZSTD)
	file.store_32(unc_size)
	file.store_buffer(bytes)

func normal_load(id: int) -> void:
	if id in range(SAVE_NUM):
		print("Load:Save%02d" % (id + 1))
		await self.load(sc_objects[id])

func normal_save(id: int) -> void:
	if id in range(SAVE_NUM):
		print("Save:Save%02d" % (id + 1))
		var mess_id := int(sc_obj.mess_log.nth_back(0))
		sc_obj.unix_time = Time.get_unix_time_from_system()
		sc_obj.comment = TranslationTable.mess(mess_id)
		await save("Save%02d.png" % (id + 1), true, id)
		sys_obj.new_bookmark_index = id + 1
		save_system_data()

func quick_load() -> void:
	print("Load:QSave")
	await self.load(sc_obj_qsave)

func quick_save() -> void:
	print("Save:QSave")
	await save("QSave.sav", false)
	await confirm(confirm_prompt.qsave, false)

func is_load() -> bool:
	return sc_obj.is_load

func enter_load() -> void:
	sc_obj.is_load = true
	sc_obj.select_count = 0
	adv.select_item.clear()
	for spr in adv.spr_select:
		Anim.destroy(spr)
	adv.spr_select.clear()
	adv.msg_info.clear()

func leave_load() -> void:
	sc_obj.is_load = false
	adv.flush_update()
	if sc_obj.play_bgm != &"":
		SoundSystem.play_bgm(sc_obj.play_bgm)
		if sc_obj.pause_bgm:
			SoundSystem.pause_bgm()
	for env_se in sc_obj.play_env_se:
		SoundSystem.play_env_se(env_se)
	adv.message_view(sc_obj.view_type)
	adv.msg_frame.clear_page()
	var names := check_true_name(sc_obj.name_log.nth_back(0))
	var mess := TranslationTable.mess(int(sc_obj.mess_log.nth_back(0)))
	var seq: Dictionary = JSON.parse_string(sc_obj.seq_log.nth_back(0))
	adv.msg_frame.apply_sequence(seq)
	adv.msg_frame.output(names.show_name, adjust_message(mess)[0], true)
	if sc_obj.voice_log.nth_back(0) != &"":
		adv.msg_frame.show_voice()
	else:
		adv.msg_frame.hide_voice()
	adv.msg_frame._show(true)
	adv.skip_(false)
	adv.auto_mode_(false)
	if sc_obj.has_tone_filter:
		adv.set_tone_filter(sc_obj.tone_filter)
	else:
		adv.set_tone_filter("NORMAL")
	if not sc_obj.cg_rgb:
		adv.set_cg_(sc_obj.cg.filename, sc_obj.cg.pt.x, sc_obj.cg.pt.y)
	else:
		var col := sc_obj.col_set_cg_rgb
		adv.set_cg_rgb_(col.r8, col.g8, col.b8)
	adv.bustup_clear(0)
	for bu in sc_obj.bustup:
		if bu.status != 0:
			var pos := bu.pos if bu.pos_fix else -bu.pos
			adv.set_bustup_(bu.filename, pos, bu.priority)
			var mv := bu.local_position.y - bu.base_position.y
			if mv != 0:
				adv.bustup_down(bu.id, mv, 0, 0)
	if sc_obj.zoom:
		var param := sc_obj.zoom_param
		adv.zoom_(param.pt.x, param.pt.y, param.size.x, param.size.y)
	else:
		adv.zoom_(0, 0, screen_size.x, screen_size.y)
	await adv.update_(true)
	await hide_load_effect()
	if sc_obj.voice_log.nth_back(0) != &"":
		if check_play_voice(names.true_name):
			SoundSystem.play_voice(sc_obj.voice_log.nth_back(0))

func show_load_effect() -> void:
	var blender := Blender.new(Blender.Mode.InvertAlpha)
	blender.alpha_texture = load_effect_alpha
	blender.r = 8.0
	blender.inv_t = 0.0
	var load_effect_base := TextureRect.new()
	load_effect_base.texture = create_color_texture(Color.BLACK)
	load_effect_base.material = blender
	load_effect.add_child(load_effect_base)
	await Anim.property(load_effect_base, "material:inv_t", 0.3)

func hide_load_effect() -> void:
	var load_effect_base := load_effect.get_child(0)
	await Anim.property(load_effect_base, "material:t", 0.3)
	Anim.destroy(load_effect_base)
#endregion

#region file-10.cos
func is_confirm() -> bool:
	return in_confirm or in_movie

func confirm(msg: String, yes_no: bool = true, time: float = 0.0) -> bool:
	if is_confirm(): return false
	in_confirm = true
	var ret := false
	var confirm_layer := CanvasLayer.new()
	confirm_layer.layer = Layer.Confirm
	confirm_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var spr_black := ColorRect.new()
	spr_black.size = screen_size
	spr_black.color = Color.BLACK
	spr_black.modulate.a = 0.0
	confirm_layer.add_child(spr_black)
	var spr_frame := frame_skin.create_form_page(&"ID_PAGE_CONFIRM")
	spr_frame.pivot_offset = 0.5 * spr_frame.size
	spr_frame.position = 0.5 * (Vector2(screen_size) - spr_frame.size)
	spr_frame.modulate.a = 0.0
	confirm_layer.add_child(spr_frame)
	var mspr_message := MessageSprite.new()
	mspr_message.create_message(screen_size.x, 24)
	mspr_message.attach_message_style(frame_skin, &"ID_FONT_CONFIRM")
	if yes_no:
		mspr_message.position.y = 30
	else:
		spr_frame.get_node("ID_YES").modulate.a = 0.0
		spr_frame.get_node("ID_NO").modulate.a = 0.0
		mspr_message.position.y = (spr_frame.size.y - 24) / 2
	mspr_message.output_message(msg)
	spr_frame.add_child(mspr_message)
	add_child(confirm_layer)
	get_tree().paused = true
	
	if cnf_obj.screen_effect == ScreenEffect.Normal:
		Anim.schedule_scale(spr_frame, Vector2(1.0, 0.0), Vector2.ONE)
		Anim.schedule_fade(spr_frame, 1.0)
		Anim.schedule_fade(spr_black, 0.5)
		Anim.run(0.3)
	else:
		spr_frame.modulate.a = 1.0
		spr_black.modulate.a = 0.5
	
	if yes_no:
		while true:
			if Input.is_action_pressed("hit_cancel"):
				spr_frame.get_node("ID_NO").disabled = true
				break
			var button := await poll_pressed_button()
			if not button: pass
			elif button.name == "ID_YES":
				button.disabled = true
				ret = true
				break
			elif button.name == "ID_NO":
				button.disabled = true
				break
	else:
		if time == 0.0:
			time = 1.0
		await hit_wait(time)
	if cnf_obj.screen_effect == ScreenEffect.Normal:
		Anim.schedule_fade(spr_frame, 0.0)
		Anim.schedule_fade(spr_black, 0.0)
		await Anim.run(0.3)
	Anim.destroy(spr_frame)
	Anim.destroy(spr_black)
	confirm_layer.queue_free()
	get_tree().paused = false
	in_confirm = false
	return ret
#endregion

#region file-11.cos
func eye_catch_enter(type: String, sound_keep: int) -> void:
	if is_load():
		return
	type = type.to_upper()
	SoundSystem.stop_voice()
	if sound_keep == 0:
		SoundSystem.stop_env_se()
		SoundSystem.stop_bgm()
	await adv.hide_message()
	if Global.adv.is_key_update_flush():
		return
	if type == &"" or type == &"NORMAL":
		await eye_catch01(true)
		type = "NORMAL"
	elif type == "DATE":
		await eye_catch03(true)
	elif type == "BLACKOUT":
		await eye_catch03(true)
	eye_catch_type = type
	in_eye_catch = true

func eye_catch_leave() -> void:
	if eye_catch_type == &"NORMAL":
		await eye_catch01(false)
	elif eye_catch_type == &"DATE":
		await eye_catch03(false)
	elif eye_catch_type == &"BLACKOUT":
		await eye_catch03(false)
	in_eye_catch = false

func is_eye_catch() -> bool:
	return in_eye_catch

@warning_ignore_start("shadowed_variable")
func eye_catch01(enter: bool) -> void:
	if enter:
		var t := Blender.new()
		t.alpha_texture = eye_catch_alpha_t
		t.inv_t = 0.0
		var b := Blender.new()
		b.alpha_texture = eye_catch_alpha_b
		b.inv_t = 0.0
		var logo := TextureRect.new()
		logo.texture = eye_catch_logo
		logo.position = Vector2(430, 10)
		logo.modulate.a = 0.0
		logo.use_parent_material = true
		var black := create_color_texture(Color.BLACK, Vector2i(screen_size.x, 100))
		var black_t := TextureRect.new()
		black_t.texture = black
		black_t.material = t
		eye_catch.add_child(black_t)
		var black_b := TextureRect.new()
		black_b.texture = black
		black_b.material = b
		black_b.position.y = screen_size.y - 100
		eye_catch.add_child(black_b)
		black_b.add_child(logo)
		Anim.property(black_t, "material:inv_t", 1.5)
		Anim.property(black_b, "material:inv_t", 1.5)
		adv.bustup_clear(0)
		var flush := adv.is_key_update_flush()
		await adv.update_(flush)
		await adv.wait_update(flush)
		if not adv.is_key_update_flush():
			await Anim.finish(black_b)
		Anim.fade(logo, 1.0, 1.0)
		if not adv.is_key_update_flush():
			await hit_wait(2.5)
	else:
		var black_t := eye_catch.get_child(0)
		Anim.property(black_t, "material:t", 1.0)
		var black_b := eye_catch.get_child(1)
		Anim.property(black_b, "material:t", 1.0)
		if not adv.is_key_update_flush():
			await hit_wait(1.5)
		var logo := black_b.get_child(0)
		Anim.destroy(logo)
		Anim.destroy(black_b)
		Anim.destroy(black_t)

func eye_catch03(enter: bool) -> void:
	if enter:
		var black := TextureRect.new()
		black.texture = create_color_texture(Color.BLACK)
		black.modulate.a = 0.0
		eye_catch.add_child(black)
		var logo := TextureRect.new()
		logo.texture = eye_catch_logo
		logo.position = Vector2(430, 510)
		logo.modulate.a = 0.0
		eye_catch.add_child(logo)
		Anim.fade(black, 1.0, 1.5)
		if not adv.is_key_update_flush():
			await hit_wait(2.0)
		Anim.flush(black)
		Anim.fade(logo, 1.0, 1.5)
		if not adv.is_key_update_flush():
			await hit_wait(2.5)
	else:
		var black := eye_catch.get_child(0)
		Anim.fade(black, 0.0, 1.5)
		var logo := eye_catch.get_child(1)
		Anim.fade(logo, 0.0, 3.0)
		if not adv.is_key_update_flush():
			await hit_wait(3.5)
		Anim.destroy(logo)
		Anim.destroy(black)
@warning_ignore_restore("shadowed_variable")
#endregion

#region file-12.cos
func appreciation() -> void:
	SoundSystem.stop_bgm()
	enter_recollect_mode()
	var _view := AppreciationView.new(self)
	await _view.run()
	_view.destroy()
	leave_recollect_mode()
#endregion

#region file-13.cos
func check_setup_cg(filename: String, cg_info: CgInfo) -> void:
	var s := filename.to_upper()
	cg_info.effect_param = EffectParam.new()
	cg_info.time_zone = TimeZone.Daytime
	if s.is_empty(): pass
	elif s == &"BLACK": pass
	elif s == &"WHITE": pass
	elif s == &"B01B": cg_info.time_zone = TimeZone.Evening
	elif s == &"B01C": cg_info.time_zone = TimeZone.NightL
	elif s == &"B05C": cg_info.time_zone = TimeZone.NightL
	elif s == &"B07B": cg_info.time_zone = TimeZone.Evening
	elif s == &"B07C": cg_info.time_zone = TimeZone.Night
	elif s == &"B09B": cg_info.time_zone = TimeZone.Evening
	elif s == &"B09C": cg_info.time_zone = TimeZone.Night
	elif s == &"B12B": cg_info.time_zone = TimeZone.Evening
	elif s == &"B12C": cg_info.time_zone = TimeZone.Night
	elif s == &"B13C": cg_info.time_zone = TimeZone.Night
	elif s == &"B14B": cg_info.time_zone = TimeZone.Evening
	elif s == &"B15B": cg_info.time_zone = TimeZone.Evening
	elif s == &"B15C": cg_info.time_zone = TimeZone.Night
	elif s == &"B17B": cg_info.time_zone = TimeZone.Evening
	elif s == &"B18B": cg_info.time_zone = TimeZone.Evening
	elif s == &"B19B": cg_info.time_zone = TimeZone.Evening
	elif s == &"B20B": cg_info.time_zone = TimeZone.Evening
	elif s == &"B21B": cg_info.time_zone = TimeZone.Evening
	elif s == &"B21E": cg_info.time_zone = TimeZone.Evening
	elif s == &"B22B": cg_info.time_zone = TimeZone.Evening
	elif s == &"B23B": cg_info.time_zone = TimeZone.Evening
	elif s == &"B25C": cg_info.time_zone = TimeZone.Night
	elif s == &"B26C": cg_info.time_zone = TimeZone.Night
	elif s == &"B29B": cg_info.time_zone = TimeZone.Evening
	elif s == &"B33B": cg_info.time_zone = TimeZone.Evening
	elif s == &"B33C": cg_info.time_zone = TimeZone.NightL
	elif s == &"B34B": cg_info.time_zone = TimeZone.Evening
	elif s == &"B34C": cg_info.time_zone = TimeZone.Night
	elif s == &"B35B": cg_info.time_zone = TimeZone.Evening
	elif s == &"B35C": cg_info.time_zone = TimeZone.NightL
	elif s == &"B36B": cg_info.time_zone = TimeZone.Evening
	elif s == &"B38B": cg_info.time_zone = TimeZone.Evening
	elif s == &"B39B": cg_info.time_zone = TimeZone.Evening
	elif check_cg(s, &"EA05", 90, 91): pass
	elif check_cg(s, &"EA07", 95, 96): pass
	elif check_cg(s, &"EA08A", 100, 101): pass
	elif check_cg(s, &"EA08B", 100, 102): pass
	elif check_cg(s, &"EA08C", 100, 103): pass
	elif check_cg(s, &"EA18A", 105, 106): pass
	elif check_cg(s, &"EA18B", 105, 107): pass
	elif check_cg(s, &"EA19A", 110, 111): pass
	elif check_cg(s, &"EA19B", 110, 112): pass
	elif check_cg(s, &"EA19C", 110, 113): pass
	elif check_cg(s, &"EA20A", 120, 121): pass
	elif check_cg(s, &"EA20B", 120, 122): pass
	elif check_cg(s, &"EA21A", 130, 131): pass
	elif check_cg(s, &"EA21B", 130, 132): pass
	elif check_cg(s, &"EA21C", 130, 133): pass
	elif check_cg(s, &"EA22A", 140, 141): pass
	elif check_cg(s, &"EA22B", 140, 142): pass
	elif check_cg(s, &"EA22C", 140, 143): pass
	elif check_cg(s, &"EA22D", 140, 144): pass
	elif check_cg(s, &"EA23A", 150, 151): pass
	elif check_cg(s, &"EA23B", 150, 152): pass
	elif check_cg(s, &"EA24A", 160, 161): pass
	elif check_cg(s, &"EA24B", 160, 162): pass
	elif check_cg(s, &"EA24C", 160, 163): pass
	elif check_cg(s, &"EA25A", 170, 171): pass
	elif check_cg(s, &"EA25B", 170, 172): pass
	elif check_cg(s, &"EA25C", 170, 173): pass
	elif check_cg(s, &"EA25D", 170, 174): pass
	elif check_cg(s, &"EA26A", 180, 181): pass
	elif check_cg(s, &"EA26B", 180, 182): pass
	elif check_cg(s, &"EA26C", 180, 183): pass
	elif check_cg(s, &"EA26D", 180, 184): pass
	elif check_cg(s, &"EA26E", 180, 185): pass
	elif check_cg(s, &"EA26F", 180, 186): pass
	elif check_cg(s, &"EA26G", 180, 187): pass
	elif check_cg(s, &"EA26H", 180, 188): pass
	elif check_cg(s, &"EA27A", 190, 191): pass
	elif check_cg(s, &"EA27B", 190, 192): pass
	elif check_cg(s, &"EA27C", 190, 193): pass
	elif check_cg(s, &"EA27D", 190, 194): pass
	elif check_cg(s, &"EA27E", 190, 195): pass
	elif check_cg(s, &"EA27F", 190, 196): pass
	elif check_cg(s, &"EA27G", 190, 197): pass
	elif check_cg(s, &"EA27H", 190, 198): pass
	elif check_cg(s, &"EA28A", 200, 201): pass
	elif check_cg(s, &"EA28B", 200, 202): pass
	elif check_cg(s, &"EA28C", 200, 203): pass
	elif check_cg(s, &"EA28D", 200, 204): pass
	elif check_cg(s, &"EA29A", 210, 211): pass
	elif check_cg(s, &"EA29B", 210, 212): pass
	elif check_cg(s, &"EA29C", 210, 213): pass
	elif check_cg(s, &"EC02A", 220, 221): pass
	elif check_cg(s, &"EC02B", 220, 222): pass
	elif check_cg(s, &"EC02C", 220, 223): pass
	elif check_cg(s, &"ED02A", 230, 231): pass
	elif check_cg(s, &"ED02B", 230, 232): pass
	elif check_cg(s, &"EE01A", 240, 241): pass
	elif check_cg(s, &"EE01B", 240, 242): pass
	elif check_cg(s, &"EE01C", 240, 243): pass
	elif check_cg(s, &"EE01D", 240, 244): pass
	elif check_cg(s, &"EE02A", 250, 251): pass
	elif check_cg(s, &"EE02B", 250, 252): pass
	elif check_cg(s, &"EE02C", 250, 253): pass
	elif check_cg(s, &"EE02D", 250, 254): pass
	elif check_cg(s, &"EZ04A", 260, 261): pass
	elif check_cg(s, &"EZ04B", 260, 262): pass
	elif check_cg(s, &"EZ07A", 270, 271): pass
	elif check_cg(s, &"EZ07B", 270, 272): pass
	elif check_cg(s, &"EZ08A", 280, 281): pass
	elif check_cg(s, &"EZ08B", 280, 282): pass
	elif check_cg(s, &"EZ08C", 280, 283): pass
	elif check_cg(s, &"EZ09A", 290, 291): pass
	elif check_cg(s, &"EZ09B", 290, 292): pass
	elif check_cg(s, &"EZ09C", 290, 293): pass
	elif check_cg(s, &"EZ09D", 290, 294): pass
	elif check_cg(s, &"EZ10", 300, 301): pass
	elif check_cg(s, &"EZ11", 310, 311): pass
	elif check_cg(s, &"EZ12A", 320, 321): pass
	elif check_cg(s, &"EZ12B", 320, 322): pass
	elif check_cg(s, &"EZ12C", 320, 323): pass
	elif check_cg(s, &"EZ12D", 320, 324): pass
	elif check_cg(s, &"EZ12E", 320, 325): pass
	elif check_cg(s, &"EZ12F", 320, 326): pass
	elif check_cg(s, &"EZ13A", 330, 331): pass
	elif check_cg(s, &"EZ13B", 330, 332): pass
	elif check_cg(s, &"EZ13C", 330, 333): pass
	elif check_cg(s, &"EZ13D", 330, 334): pass
	elif check_cg(s, &"EZ14A", 340, 341): pass
	elif check_cg(s, &"EZ14B", 340, 342): pass
	elif check_cg(s, &"EZ14C", 340, 343): pass
	elif check_cg(s, &"EZ15A", 350, 351): pass
	elif check_cg(s, &"EZ15B", 350, 352): pass
	elif check_cg(s, &"EZ15C", 350, 353): pass
	elif check_cg(s, &"EZ15D", 350, 354): pass
	elif check_cg(s, &"EZ16A", 360, 361): pass
	elif check_cg(s, &"EZ16B", 360, 362): pass
	elif check_cg(s, &"EZ16C", 360, 363): pass
	elif check_cg(s, &"EZ16D", 360, 364): pass
	elif check_cg(s, &"EZ16E", 360, 365): pass
	elif check_cg(s, &"EZ17A", 370, 371): pass
	elif check_cg(s, &"EZ17B", 370, 372): pass
	elif check_cg(s, &"EZ17C", 370, 373): pass
	elif check_cg(s, &"EZ17D", 370, 374): pass
	elif check_cg(s, &"EZ17E", 370, 375): pass
	elif check_cg(s, &"EZ20", 380, 381): pass
	elif check_cg(s, &"EZ21A", 390, 391): pass
	elif check_cg(s, &"EZ21B", 390, 392): pass
	elif check_cg(s, &"EZ21C", 390, 393): pass
	elif check_cg(s, &"EZ21D", 390, 394): pass
	elif check_cg(s, &"EZ21E", 390, 395): pass
	elif check_cg(s, &"EZ22A", 400, 401): pass
	elif check_cg(s, &"EZ22B", 400, 402): pass
	elif check_cg(s, &"EZ22C", 400, 403): pass
	elif check_cg(s, &"EZ23A", 410, 411): pass
	elif check_cg(s, &"EZ23B", 410, 412): pass
	elif check_cg(s, &"EZ24A", 420, 421): pass
	elif check_cg(s, &"EZ24B", 420, 422): pass
	elif check_cg(s, &"EZ25A", 430, 431): pass
	elif check_cg(s, &"EZ25B", 430, 432): pass
	elif check_cg(s, &"EZ25C", 430, 433): pass
	elif check_cg(s, &"EZ25D", 430, 434): pass
	elif check_cg(s, &"EZ25E", 430, 435): pass
	elif check_cg(s, &"EZ25F", 430, 436): pass
	elif check_cg(s, &"EZ25G", 430, 437): pass
	elif check_cg(s, &"EZ25H", 430, 438): pass
	elif check_cg(s, &"EZ25I", 430, 439): pass
	elif check_cg(s, &"EZ25J", 430, 440): pass
	elif check_cg(s, &"EZ25K", 430, 441): pass
	elif check_cg(s, &"EZ25L", 430, 442): pass
	elif check_cg(s, &"EZ26A", 450, 451): pass
	elif check_cg(s, &"EZ26B", 450, 452): pass
	elif check_cg(s, &"EZ26C", 450, 453): pass
	elif check_cg(s, &"EZ26D", 450, 454): pass
	elif check_cg(s, &"EZ27A", 460, 461): pass
	elif check_cg(s, &"EZ27B", 460, 462): pass
	elif check_cg(s, &"EZ27C", 460, 463): pass
	elif check_cg(s, &"EZ28A", 470, 471): pass
	elif check_cg(s, &"EZ28B", 470, 472): pass
	elif check_cg(s, &"EZ28C", 470, 473): pass
	elif check_cg(s, &"EZ28D", 470, 474): pass
	cg_info.filename = s

func check_setup_bustup(filename: String, _timezone: int) -> BustupInfo:
	var id := -1
	var info := BustupInfo.new()
	var s := filename.to_upper()
	info.basename = s
	var file_not_found := false
	if s.is_empty(): pass
	elif &"CA" in s:
		id = 4
		if   check_bu(s, &"01_", 1): pass
		elif check_bu(s, &"02_", 2): pass
		elif check_bu(s, &"03_", 3): pass
		elif check_bu(s, &"04_", 4): pass
		elif check_bu(s, &"05_", 5): pass
		elif check_bu(s, &"06_", 6): pass
		elif check_bu(s, &"07_", 7): pass
		else: file_not_found = true
	elif &"CB" in s:
		id = 3
		if   check_bu(s, &"01_", 11): pass
		elif check_bu(s, &"02_", 12): pass
		elif check_bu(s, &"03_", 13): pass
		elif check_bu(s, &"04_", 14): pass
		elif check_bu(s, &"05_", 15): pass
		elif check_bu(s, &"06_", 16): pass
		elif check_bu(s, &"07_", 17): pass
		else: file_not_found = true
	elif &"CC" in s:
		id = 2
		if   check_bu(s, &"01_", 21): pass
		elif check_bu(s, &"02_", 22): pass
		elif check_bu(s, &"03_", 23): pass
		elif check_bu(s, &"04_", 24): pass
		elif check_bu(s, &"05_", 25): pass
		elif check_bu(s, &"06_", 26): pass
		elif check_bu(s, &"07_", 27): pass
		elif check_bu(s, &"08_", 28): pass
		else: file_not_found = true
	elif &"CD" in s:
		id = 5
		if   check_bu(s, &"01_", 31): pass
		elif check_bu(s, &"02_", 32): pass
		elif check_bu(s, &"03_", 33): pass
		elif check_bu(s, &"04_", 34): pass
		elif check_bu(s, &"05_", 35): pass
		elif check_bu(s, &"06_", 36): pass
		elif check_bu(s, &"07_", 37): pass
		else: file_not_found = true
	elif &"CE" in s:
		id = 6
		if   check_bu(s, &"01_", 41): pass
		elif check_bu(s, &"02_", 42): pass
		elif check_bu(s, &"03_", 43): pass
		elif check_bu(s, &"04_", 44): pass
		else: file_not_found = true
	elif &"CF" in s:
		id = 7
		if   check_bu(s, &"01_", 51): pass
		elif check_bu(s, &"02_", 52): pass
		elif check_bu(s, &"03_", 53): pass
		elif check_bu(s, &"04_", 54): pass
		elif check_bu(s, &"05_", 55): pass
		elif check_bu(s, &"06_", 56): pass
		else: file_not_found = true
	elif &"CG" in s:
		id = 8
		if   check_bu(s, &"01_", 61): pass
		elif check_bu(s, &"02_", 62): pass
		elif check_bu(s, &"03_", 63): pass
		elif check_bu(s, &"04_", 64): pass
		elif check_bu(s, &"05_", 65): pass
		else: file_not_found = true
	elif &"CH" in s:
		id = 9
		if   check_bu(s, &"01_", 71): pass
		elif check_bu(s, &"02_", 72): pass
		elif check_bu(s, &"03_", 73): pass
		elif check_bu(s, &"04_", 74): pass
		elif check_bu(s, &"05_", 75): pass
		elif check_bu(s, &"06_", 76): pass
		elif check_bu(s, &"07_", 77): pass
		elif check_bu(s, &"08_", 78): pass
		elif check_bu(s, &"09_", 79): pass
		else: file_not_found = true
	elif &"CI" in s:
		id = 12
	elif &"CJ" in s:
		id = 10
		if   check_bu(s, &"01_", 81): pass
		else: file_not_found = true
	elif &"CK" in s:
		id = 11
	elif &"CL" in s:
		id = 99
	else: file_not_found = true
	if file_not_found:
		var sc := sc_obj.scenario_call.trim_prefix("sc")
		printerr("Invalid BUSTUP specification - %s:[%s]" % [sc, s])
	info.base_position.y = screen_size.y
	info.id = id
	info.filename = s
	match id:
		2:
			info.relation = 10
			info.priority = 52
		3:
			info.relation = 50
			info.priority = 55
		4:
			info.relation = 70
			info.priority = 51
		5:
			info.relation = 20
			info.priority = 56
		6:
			info.relation = 60
			info.priority = 54
		7:
			info.relation = 40
			info.priority = 58
		8:
			info.relation = 80
			info.priority = 57
		9:
			info.relation = 30
			info.priority = 53
		10:
			info.relation = 90
			info.priority = 60
		11:
			info.relation = 15
			info.priority = 59
	if &"S" in s:
		info.priority += 20
	elif &"L" in s:
		info.priority -= 20
	return info

func check_true_name(alias_name: String) -> Dictionary:
	var names := {}
	var index := alias_name.find("《")
	if index != -1:
		names.show_name = alias_name.substr(0, index)
		var right := alias_name.rfind("》")
		names.true_name = alias_name.substr(index + 1, right - index - 1)
	else: names = { show_name = alias_name, true_name = alias_name }
	if alias_name.is_empty(): pass
	elif names.show_name == &"語り":
		names.show_name = ""
	elif names.show_name == &"心の声":
		names.show_name = ""
	elif names.show_name == &"モノローグ":
		names.show_name = ""
	names.show_name = TranslationTable.name_(names.show_name)
	return names

func is_h_scene(filename: String) -> bool:
	if   &"EA24" in filename: return true
	elif &"EA25" in filename: return true
	elif &"EA26" in filename: return true
	elif &"EA27" in filename: return true
	elif &"EA28" in filename: return true
	elif &"EA29" in filename: return true
	elif &"EZ12" in filename: return true
	elif &"EZ13" in filename: return true
	elif &"EZ14" in filename: return true
	elif &"EZ15" in filename: return true
	elif &"EZ16" in filename: return true
	elif &"EZ17" in filename: return true
	elif &"EZ25" in filename: return true
	elif &"EZ26" in filename: return true
	elif &"EZ27" in filename: return true
	elif &"EZ28" in filename: return true
	else: return false

func check_play_voice(true_name: String) -> bool:
	true_name = true_name.replace("悠", "").replace("＆", "")
	var cnf_id := cnf_obj.voice_details
	for voice: String in ["穹","瑛","奈緒","一葉","初佳","委員長","やひろ","亮平"]:
		if voice in true_name:
			if cnf_id & 1 == 0: return false
			true_name = true_name.replace(voice, "")
		cnf_id >>= 1
	if not true_name.is_empty():
		return cnf_id & 1 != 0
	return true
#endregion

#region file-14.cos
func staff_roll(type: int) -> void:
	if is_load():
		return
	SoundSystem.stop_bgm()
	var view := StaffRollView.new(self)
	await view.run(type)
#endregion

#region file-15.cos
func wallpaper() -> void:
	var view := WallPaperViewer.new(self)
	await view.run()
#endregion
