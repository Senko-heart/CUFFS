extends Node

const ScreenType := ConfigDataBase.ScreenType
const ScreenEffect := ConfigDataBase.ScreenEffect
const StepResult := GssInterpreter.StepResult
var TRIAL := false
var TECHGIAN := false
const SAVE_NUM := 60
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
	TechGian = 101,
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

func _init() -> void:
	sc_objects.resize(SAVE_NUM)
	sc_obj_thumb_textures.resize(SAVE_NUM)

func _ready() -> void:
	await FS.sync()
	TranslationTable.initialize()
	load_system_data()
	load_config_data()
	load_scobjs_data()
	set_screen_type(cnf_obj.screen_type)
	frame_skin = ControlPack.new(&"frame")
	title_skin = ControlPack.new(&"title")
	option_skin = ControlPack.new(&"option")
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
		await ask_game_exit()

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

var font_base: Dictionary[String, Dictionary] = {
	"MS Mincho": {
		font = preload("res://msmincho.ttc"),
		normal_face_index = 0,
		mono_face_index = 1,
		embolden = 0.4,
		faux_slant = 0.2
	}
}

var font_variations: Dictionary[StringName, Array] = {}

func get_font_variation(
	face: String,
	bold: bool,
	italic: bool
) -> FontVariation:
	if face not in font_base: return null
	if face not in font_variations:
		font_variations[face] = []
		font_variations[face].resize(8)
	var fontvars := font_variations[face]
	var varidx := int(bold) + (int(italic) << 1)
	if fontvars[varidx]: return fontvars[varidx]
	var fontbase := font_base[face]
	var fv := FontVariation.new()
	fv.base_font = fontbase.font
	if bold: fv.variation_embolden = fontbase.get(&"embolden", 0)
	if italic: fv.variation_transform.y.x = fontbase.get(&"faux_slant", 0)
	fv.variation_face_index = fontbase.get(&"face_index", 0)
	fontvars[varidx] = fv
	return fv

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

func rgb(r: int, g: int, b: int) -> int:
	return (r << 16) | (g << 8) | b

func rgba(r: int, g: int, b: int, a: int) -> int:
	return (a << 24) | (r << 16) | (g << 8) | b

func play_movie(filename: String) -> void:
	in_movie = true
	var movie_layer := CanvasLayer.new()
	var player := VideoStreamPlayer.new()
	var stream := VideoStreamTheora.new()
	stream.file = FS.root.path_join(filename)
	player.stream = stream
	movie_layer.layer = Layer.Movie
	add_child(movie_layer)
	movie_layer.add_child(player)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	await get_tree().process_frame
	player.play()
	while player.is_playing():
		if Input.is_action_just_pressed("hit", true):
			break
		await get_tree().process_frame
	player.stop()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	movie_layer.queue_free()
	in_movie = false

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

func scenario_loop(sc: String) -> void:
	SoundSystem.stop_bgm()
	setup_adv_screen()
	GssInterpreter.change(sc)
	adv.set_tone_filter("NORMAL")
	adv.set_cg_("BLACK")
	var gas := GAS
	while sc_obj.scenario_call != &"EXIT_SCENARIO":
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
	if await confirm(confirm_prompt.quit):
		save_and_quit()

func save_and_quit() -> void:
	save_system_data()
	save_config_data()
	get_tree().quit()

func on_flag(i: int) -> void:
	if 0 < i and i < 512:
		print("Flag%s-ON" % i)
		sc_obj.flag.set_(i)

func off_flag(i: int) -> void:
	if 0 < i and i < 512:
		print("Flag%s-OFF" % i)
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
				action = GameAction.Title
			GameAction.Title:
				action = await title()
			GameAction.Start:
				await scenario_loop("00_Z000")
				action = GameAction.Logo
			GameAction.Continue:
				await scenario_loop(sc_obj.scenario_call)
				action = GameAction.Logo
			GameAction.Appreciation:
				await appreciation()
				action = GameAction.Title
			GameAction.TechGian:
				await scenario_loop("tg01")
				action = GameAction.Logo
			_: break

func logo() -> void:
	var spr_base := title_skin.create_texture_rect("ID_FRM_0601")
	spr_base.modulate.a = 0.0
	add_child(spr_base)
	Anim.fade(spr_base, 1.0, 1.0)
	var spr_logo: TextureRect
	var cancel := await hit_wait(1.0)
	if not cancel:
		var brand_call := [
			"AK080001", "KA080001", "KO080001", "MT080001",
			"NO080001", "RH080001", "SR080001", "YH080001",
		]
		SoundSystem.play_sys_se(brand_call.pick_random())
		spr_logo = title_skin.create_texture_rect("ID_FRM_0602")
		spr_logo.modulate.a = 0.0
		add_child(spr_logo)
		spr_logo.position = (screen_size - Vector2i(spr_logo.size)) / 2
		Anim.fade(spr_logo, 1.0, 1.0)
		cancel = await hit_wait(5.0)
	if not cancel:
		Anim.schedule(spr_base, { alpha = { target = 0.0 }})
		Anim.schedule(spr_logo, { alpha = { target = 0.0 }})
		await Anim.run(1.0)
	if spr_logo: Anim.destroy(spr_logo)
	Anim.destroy(spr_base)

func title() -> GameAction:
	SoundSystem.play_bgm("BGM07")
	var spr_base := title_skin.create_texture_rect("ID_FRM_0611")
	spr_base.modulate.a = 0.0
	add_child(spr_base)
	var spr_logo := title_skin.create_texture_rect("ID_FRM_0612")
	spr_logo.modulate.a = 0.0
	spr_logo.position = Vector2(223, 95)
	add_child(spr_logo)
	var spr_sub_logo: TextureRect
	if TECHGIAN:
		spr_sub_logo = title_skin.create_texture_rect("ID_FRM_0614")
		spr_sub_logo.modulate.a = 0.0
		spr_sub_logo.position = Vector2(369, 171)
		add_child(spr_sub_logo)
	elif TRIAL:
		spr_sub_logo = title_skin.create_texture_rect("ID_FRM_0613")
		spr_sub_logo.modulate.a = 0.0
		spr_sub_logo.position = Vector2(511, 171)
		add_child(spr_sub_logo)
	var spr_menu: TextureRect
	if TECHGIAN:
		spr_menu = title_skin.create_form_page("ID_PAGE_MENU_TG")
	elif not TRIAL and is_game_clear():
		spr_menu = title_skin.create_form_page("ID_PAGE_MENU_FULL")
	else:
		spr_menu = title_skin.create_form_page("ID_PAGE_MENU")
	spr_menu.modulate.a = 0.0
	spr_menu.position = Vector2(313, 324)
	add_child(spr_menu)
	var mspr_version := MessageSprite.new()
	mspr_version.create_message(70 + 12, 20)
	mspr_version.attach_message_style(title_skin, "ID_FONT_VERSION")
	mspr_version.position = Vector2(screen_size) - mspr_version.size
	mspr_version.output_message("Ver 1.00β")
	mspr_version.modulate.a = 0.0
	add_child(mspr_version)
	Anim.fade(mspr_version, 1.0, 0.5)
	var brand_call := [
		"AK080002", "KA080002", "KO080002", "MT080002",
		"NO080002", "RH080002", "SR080002", "YH080002",
	]
	SoundSystem.play_sys_se(brand_call.pick_random())
	Anim.fade(spr_menu, 1.0, 0.3)
	Anim.fade(spr_logo, 1.0, 0.5)
	if spr_sub_logo:
		Anim.fade(spr_sub_logo, 1.0, 0.5)
	await Anim.fade(spr_base, 1.0, 0.5)
	var ret := GameAction.Return
	while true:
		var control := await poll_ui_event()
		var cid := control.name if control else &""
		if cid == "ID_START":
			ret = GameAction.Start
			break
		elif cid == "ID_CONTINUE":
			Anim.fade(spr_menu, 0.0, 0.3)
			var win := LoadSaveWindow.new(self, true)
			win._show()
			var _ret := await win.run()
			if _ret != GameLogic.Load:
				Anim.fade(spr_menu, 1.0, 0.3)
			await win._hide()
			win.destroy()
			if _ret == GameLogic.Load:
				ret = GameAction.Continue
				break
		elif cid == "ID_TG":
			ret = GameAction.TechGian
			break
		elif cid == "ID_CONFIG":
			Anim.fade(spr_menu, 0.0, 0.3)
			var win := ConfigWindow.new(self, true)
			win._show()
			await win.run()
			Anim.fade(spr_menu, 1.0, 0.3)
			await win._hide()
			win.destroy()
		elif cid == "ID_APPRECIATION":
			ret = GameAction.Appreciation
			break
		elif cid == "ID_EXITGAME":
			await ask_game_exit()
		elif Input.is_action_just_pressed("quick_load") \
		and sc_obj_qsave \
		and await confirm(confirm_prompt.qload):
			await quick_load()
			ret = GameAction.Continue
			break
	SoundSystem.stop_bgm()
	Anim.schedule_fade(mspr_version, 0.0)
	Anim.schedule_fade(spr_logo, 0.0)
	if spr_sub_logo: Anim.schedule_fade(spr_sub_logo, 0.0)
	Anim.schedule_fade(spr_base, 0.0)
	Anim.schedule_fade(spr_menu, 0.0)
	var time := 3.0 if ret == GameAction.Start else 0.5
	await Anim.run(time)
	Anim.destroy(mspr_version)
	Anim.destroy(spr_menu)                              
	if spr_sub_logo: Anim.destroy(spr_sub_logo)
	Anim.destroy(spr_logo)
	Anim.destroy(spr_base)
	return ret
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
	sc_obj.cg = adv.cg
	sc_obj.cg_rgb = adv.set_cg_rgb
	sc_obj.col_set_cg_rgb = adv.col_set_cg_rgb
	sc_obj.bustup.clear()
	for bu in adv.bustup_man.info:
		var info := BustupInfo.new()
		info.load(bu.dump())
		sc_obj.bustup.append(info)
	sc_obj.has_tone_filter = adv.is_tone_filter()
	sc_obj.tone_filter = adv.get_tone_filter()
	sc_obj.view_type = adv.get_message_view()
	sc_obj.zoom = adv.is_zoom()
	sc_obj.zoom_param = adv.get_zoom_param()
	sc_obj.play_bgm = SoundSystem.get_play_bgm_name()
	sc_obj.pause_bgm = SoundSystem.is_pause_bgm()
	sc_obj.play_env_se = SoundSystem.get_play_env_se_list()
	var data := sc_obj.dump()
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
	adv.msg_frame.output(names.show_name, mess, true)
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
		Anim.schedule(spr_frame, {
			scale = {
				base = Vector2(1.0, 0.0),
				target = Vector2.ONE,
				accel = Vector2(3.0, 0.0)},
			alpha = { target = 1.0 }
		})
		Anim.schedule(spr_black, { alpha = { target = 0.5 }})
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
		Anim.schedule(spr_frame, { alpha = { target = 0.0 }})
		Anim.schedule(spr_black, { alpha = { target = 0.0 }})
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
	if sound_keep != 0:
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
	if s.is_empty(): pass
	elif s == &"BLACK": pass
	elif s == &"WHITE": pass
	elif check_cg(s, &"EA01A", 100, 101): pass
	elif check_cg(s, &"EA01B", 100, 102): pass
	elif check_cg(s, &"EA01C", 100, 103): pass
	elif check_cg(s, &"EA01D", 100, 104): pass
	elif check_cg(s, &"EA01E", 100, 105): pass
	elif check_cg(s, &"EA01F", 100, 106): pass
	elif check_cg(s, &"EA01G", 100, 107): pass
	elif check_cg(s, &"EA01H", 100, 108): pass
	elif check_cg(s, &"EA02", 110, 111): pass
	elif check_cg(s, &"EA03A", 120, 121): pass
	elif check_cg(s, &"EA03B", 120, 122): pass
	elif check_cg(s, &"EA04A", 130, 131): pass
	elif check_cg(s, &"EA04B", 130, 132): pass
	elif check_cg(s, &"EA04C", 130, 133): pass
	elif check_cg(s, &"EA05", 140, 141): pass
	elif check_cg(s, &"EA06A", 150, 151): pass
	elif check_cg(s, &"EA06B", 150, 152): pass
	elif check_cg(s, &"EA06C", 150, 153): pass
	elif check_cg(s, &"EA06D", 150, 154): pass
	elif check_cg(s, &"EA06E", 150, 155): pass
	elif check_cg(s, &"EA07", 160, 161): pass
	elif check_cg(s, &"EA08A", 170, 171): pass
	elif check_cg(s, &"EA08B", 170, 172): pass
	elif check_cg(s, &"EA08C", 170, 173): pass
	elif check_cg(s, &"EA09A", 180, 181): pass
	elif check_cg(s, &"EA09B", 180, 182): pass
	elif check_cg(s, &"EA09C", 180, 183): pass
	elif check_cg(s, &"EA09D", 180, 184): pass
	elif check_cg(s, &"EA10A", 190, 191): pass
	elif check_cg(s, &"EA10B", 190, 192): pass
	elif check_cg(s, &"EA10C", 190, 193): pass
	elif check_cg(s, &"EA10D", 190, 194): pass
	elif check_cg(s, &"EA11A", 200, 201): pass
	elif check_cg(s, &"EA11B", 200, 202): pass
	elif check_cg(s, &"EA11C", 200, 203): pass
	elif check_cg(s, &"EA11D", 200, 204): pass
	elif check_cg(s, &"EA12A", 210, 211): pass
	elif check_cg(s, &"EA12B", 210, 212): pass
	elif check_cg(s, &"EA12C", 210, 213): pass
	elif check_cg(s, &"EA13A", 220, 221): pass
	elif check_cg(s, &"EA13B", 220, 222): pass
	elif check_cg(s, &"EA13C", 220, 223): pass
	elif check_cg(s, &"EA14", 230, 231): pass
	elif check_cg(s, &"EA15", 240, 241): pass
	elif check_cg(s, &"EA16A", 250, 251): pass
	elif check_cg(s, &"EA16B", 250, 252): pass
	elif check_cg(s, &"EA17A", 260, 261): pass
	elif check_cg(s, &"EA17B", 260, 262): pass
	elif check_cg(s, &"EA17C", 260, 263): pass
	elif check_cg(s, &"EA18A", 270, 271): pass
	elif check_cg(s, &"EA18B", 270, 272): pass
	elif check_cg(s, &"EB01A", 280, 281): pass
	elif check_cg(s, &"EB01B", 280, 282): pass
	elif check_cg(s, &"EB02A", 290, 291): pass
	elif check_cg(s, &"EB02B", 290, 292): pass
	elif check_cg(s, &"EB03", 300, 301): pass
	elif check_cg(s, &"EB04A", 310, 311): pass
	elif check_cg(s, &"EB04B", 310, 312): pass
	elif check_cg(s, &"EB04A_", 310, 313): pass
	elif check_cg(s, &"EB05", 320, 321): pass
	elif check_cg(s, &"EB06A", 330, 331): pass
	elif check_cg(s, &"EB06B", 330, 332): pass
	elif check_cg(s, &"EB07A", 340, 341): pass
	elif check_cg(s, &"EB07B", 340, 342): pass
	elif check_cg(s, &"EB08A", 350, 351): pass
	elif check_cg(s, &"EB08B", 350, 352): pass
	elif check_cg(s, &"EB08C", 350, 353): pass
	elif check_cg(s, &"EB08A_", 350, 354): pass
	elif check_cg(s, &"EB08B_", 350, 355): pass
	elif check_cg(s, &"EB09", 360, 361): pass
	elif check_cg(s, &"EB10A", 370, 371): pass
	elif check_cg(s, &"EB10B", 370, 372): pass
	elif check_cg(s, &"EB11A", 380, 381): pass
	elif check_cg(s, &"EB11B", 380, 382): pass
	elif check_cg(s, &"EB12A", 390, 391): pass
	elif check_cg(s, &"EB12B", 390, 392): pass
	elif check_cg(s, &"EB12C", 390, 393): pass
	elif check_cg(s, &"EB13A", 400, 401): pass
	elif check_cg(s, &"EB13B", 400, 402): pass
	elif check_cg(s, &"EB14", 410, 411): pass
	elif check_cg(s, &"EB15", 420, 421): pass
	elif check_cg(s, &"EB16A", 430, 431): pass
	elif check_cg(s, &"EB16B", 430, 432): pass
	elif check_cg(s, &"EB16C", 430, 433): pass
	elif check_cg(s, &"EB17A", 440, 441): pass
	elif check_cg(s, &"EB17B", 440, 442): pass
	elif check_cg(s, &"EB17C", 440, 443): pass
	elif check_cg(s, &"EB18", 450, 451): pass
	elif check_cg(s, &"EC01A", 460, 461): pass
	elif check_cg(s, &"EC01B", 460, 462): pass
	elif check_cg(s, &"EC02A", 470, 471): pass
	elif check_cg(s, &"EC02B", 470, 472): pass
	elif check_cg(s, &"EC02C", 470, 473): pass
	elif check_cg(s, &"EC03A", 480, 481): pass
	elif check_cg(s, &"EC03B", 480, 482): pass
	elif check_cg(s, &"EC03C", 480, 483): pass
	elif check_cg(s, &"EC03D", 480, 484): pass
	elif check_cg(s, &"EC04A", 490, 491): pass
	elif check_cg(s, &"EC04B", 490, 492): pass
	elif check_cg(s, &"EC05A", 500, 501): pass
	elif check_cg(s, &"EC05B", 500, 502): pass
	elif check_cg(s, &"EC06A", 510, 511): pass
	elif check_cg(s, &"EC06B", 510, 512): pass
	elif check_cg(s, &"EC07A", 520, 521): pass
	elif check_cg(s, &"EC07B", 520, 522): pass
	elif check_cg(s, &"EC07C", 520, 523): pass
	elif check_cg(s, &"EC08", 530, 531): pass
	elif check_cg(s, &"EC09", 540, 541): pass
	elif check_cg(s, &"EC10A", 550, 551): pass
	elif check_cg(s, &"EC10B", 550, 552): pass
	elif check_cg(s, &"EC10C", 550, 553): pass
	elif check_cg(s, &"EC10D", 550, 554): pass
	elif check_cg(s, &"EC10E", 550, 555): pass
	elif check_cg(s, &"EC10F", 550, 556): pass
	elif check_cg(s, &"EC11A", 560, 561): pass
	elif check_cg(s, &"EC11B", 560, 562): pass
	elif check_cg(s, &"EC11C", 560, 563): pass
	elif check_cg(s, &"EC12A", 570, 571): pass
	elif check_cg(s, &"EC12B", 570, 572): pass
	elif check_cg(s, &"EC12C", 570, 573): pass
	elif check_cg(s, &"EC13A", 580, 581): pass
	elif check_cg(s, &"EC13B", 580, 582): pass
	elif check_cg(s, &"EC13C", 580, 583): pass
	elif check_cg(s, &"EC13D", 580, 584): pass
	elif check_cg(s, &"EC13E", 580, 584): pass
	elif check_cg(s, &"EC14", 590, 591): pass
	elif check_cg(s, &"EC15", 600, 601): pass
	elif check_cg(s, &"EC16A", 610, 611): pass
	elif check_cg(s, &"EC16B", 610, 612): pass
	elif check_cg(s, &"EC16C", 610, 613): pass
	elif check_cg(s, &"EC16D", 610, 614): pass
	elif check_cg(s, &"EC17A", 620, 621): pass
	elif check_cg(s, &"EC17B", 620, 622): pass
	elif check_cg(s, &"EC17C", 620, 623): pass
	elif check_cg(s, &"EC18", 630, 631): pass
	elif check_cg(s, &"ED01A", 640, 641): pass
	elif check_cg(s, &"ED01B", 640, 642): pass
	elif check_cg(s, &"ED01C", 640, 643): pass
	elif check_cg(s, &"ED02A", 650, 651): pass
	elif check_cg(s, &"ED02B", 650, 652): pass
	elif check_cg(s, &"ED03A", 660, 661): pass
	elif check_cg(s, &"ED03B", 660, 662): pass
	elif check_cg(s, &"ED03C", 660, 663): pass
	elif check_cg(s, &"ED04", 670, 671): pass
	elif check_cg(s, &"ED05", 680, 681): pass
	elif check_cg(s, &"ED06A", 690, 691): pass
	elif check_cg(s, &"ED06B", 690, 692): pass
	elif check_cg(s, &"ED06C", 690, 693): pass
	elif check_cg(s, &"ED07A", 700, 701): pass
	elif check_cg(s, &"ED07B", 700, 702): pass
	elif check_cg(s, &"ED08", 710, 711): pass
	elif check_cg(s, &"ED09", 720, 721): pass
	elif check_cg(s, &"ED10A", 730, 731): pass
	elif check_cg(s, &"ED10B", 730, 732): pass
	elif check_cg(s, &"ED10C", 730, 733): pass
	elif check_cg(s, &"ED11A", 740, 741): pass
	elif check_cg(s, &"ED11B", 740, 742): pass
	elif check_cg(s, &"ED11C", 740, 743): pass
	elif check_cg(s, &"ED11D", 740, 744): pass
	elif check_cg(s, &"ED12A", 750, 751): pass
	elif check_cg(s, &"ED12B", 750, 752): pass
	elif check_cg(s, &"ED12C", 750, 753): pass
	elif check_cg(s, &"ED13A", 760, 761): pass
	elif check_cg(s, &"ED13B", 760, 762): pass
	elif check_cg(s, &"ED14", 770, 771): pass
	elif check_cg(s, &"ED15", 780, 781): pass
	elif check_cg(s, &"ED16A", 790, 791): pass
	elif check_cg(s, &"ED16B", 790, 792): pass
	elif check_cg(s, &"ED16C", 790, 793): pass
	elif check_cg(s, &"ED17A", 800, 801): pass
	elif check_cg(s, &"ED17B", 800, 802): pass
	elif check_cg(s, &"ED17C", 800, 803): pass
	elif check_cg(s, &"ED18A", 810, 811): pass
	elif check_cg(s, &"ED18B", 810, 812): pass
	elif check_cg(s, &"ED18C", 810, 813): pass
	elif check_cg(s, &"EE01A", 820, 821): pass
	elif check_cg(s, &"EE01B", 820, 822): pass
	elif check_cg(s, &"EE01C", 820, 823): pass
	elif check_cg(s, &"EE01D", 820, 824): pass
	elif check_cg(s, &"EE02A", 830, 831): pass
	elif check_cg(s, &"EE02B", 830, 832): pass
	elif check_cg(s, &"EE02C", 830, 833): pass
	elif check_cg(s, &"EE02D", 830, 834): pass
	elif check_cg(s, &"EE03A", 840, 841): pass
	elif check_cg(s, &"EE03B", 840, 842): pass
	elif check_cg(s, &"EE04A", 850, 851): pass
	elif check_cg(s, &"EE04B", 850, 852): pass
	elif check_cg(s, &"EE04C", 850, 853): pass
	elif check_cg(s, &"EE05A", 860, 861): pass
	elif check_cg(s, &"EE05B", 860, 862): pass
	elif check_cg(s, &"EE06A", 870, 871): pass
	elif check_cg(s, &"EE06B", 870, 872): pass
	elif check_cg(s, &"EE07A", 880, 881): pass
	elif check_cg(s, &"EE07B", 880, 882): pass
	elif check_cg(s, &"EE08A", 890, 891): pass
	elif check_cg(s, &"EE08B", 890, 892): pass
	elif check_cg(s, &"EE09", 900, 901): pass
	elif check_cg(s, &"EE10A", 910, 911): pass
	elif check_cg(s, &"EE10B", 910, 912): pass
	elif check_cg(s, &"EE10C", 910, 913): pass
	elif check_cg(s, &"EE10D", 910, 914): pass
	elif check_cg(s, &"EE11A", 920, 921): pass
	elif check_cg(s, &"EE11B", 920, 922): pass
	elif check_cg(s, &"EE11C", 920, 923): pass
	elif check_cg(s, &"EE12A", 930, 931): pass
	elif check_cg(s, &"EE12B", 930, 932): pass
	elif check_cg(s, &"EE12C", 930, 933): pass
	elif check_cg(s, &"EE12D", 930, 934): pass
	elif check_cg(s, &"EE13A", 940, 941): pass
	elif check_cg(s, &"EE13B", 940, 942): pass
	elif check_cg(s, &"EE13C", 940, 943): pass
	elif check_cg(s, &"EE14", 950, 951): pass
	elif check_cg(s, &"EE15", 960, 961): pass
	elif check_cg(s, &"EE16A", 970, 971): pass
	elif check_cg(s, &"EE16B", 970, 972): pass
	elif check_cg(s, &"EE17A", 980, 981): pass
	elif check_cg(s, &"EE17B", 980, 982): pass
	elif check_cg(s, &"EE18", 990, 991): pass
	elif check_cg(s, &"EZ01A", 1000, 1001):
		cg_info.effect_param.type = EffectParam.EffectType.TileImage
		cg_info.effect_param.interval = 100
		cg_info.effect_param.degree_step = 0
		cg_info.effect_param.size_view = Vector2i(800, 600)
		cg_info.effect_param.pt_speed = Vector2i(1, 0)
	elif check_cg(s, &"EZ01B", 1000, 1002):
		cg_info.effect_param.type = EffectParam.EffectType.TileImage
		cg_info.effect_param.interval = 100
		cg_info.effect_param.degree_step = 0
		cg_info.effect_param.size_view = Vector2i(800, 600)
		cg_info.effect_param.pt_speed = Vector2i(1, 0)
	elif check_cg(s, &"EZ02", 1010, 1011): pass
	elif check_cg(s, &"EZ03", 1020, 1021): pass
	elif check_cg(s, &"EZ04A", 1030, 1031): pass
	elif check_cg(s, &"EZ04B", 1030, 1032): pass
	elif check_cg(s, &"EZ05A", 1040, 1041): pass
	elif check_cg(s, &"EZ05B", 1040, 1042): pass
	elif check_cg(s, &"EZ05C", 1040, 1043): pass
	elif check_cg(s, &"EZ05D", 1040, 1044): pass
	elif check_cg(s, &"EZ06A", 1050, 1051): pass
	elif check_cg(s, &"EZ06B", 1050, 1052): pass
	elif check_cg(s, &"EZ06C", 1050, 1053): pass
	elif check_cg(s, &"EZ06D", 1050, 1054): pass
	elif check_cg(s, &"EZ06E", 1050, 1055): pass
	elif check_cg(s, &"EZ06F", 1050, 1056): pass
	elif check_cg(s, &"EZ07", 1060, 1061): pass
	elif check_cg(s, &"EZ08", 1070, 1071): pass
	elif check_cg(s, &"SP"): pass
	cg_info.time_zone = 1
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
		elif check_bu(s, &"EZ01CA"): pass
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
		elif check_bu(s, &"EZ01CB"): pass
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
		elif check_bu(s, &"EZ01CC"): pass
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
		elif check_bu(s, &"EZ01CD"): pass
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
		elif check_bu(s, &"EZ01CF"): pass
		else: file_not_found = true
	elif &"CG" in s:
		id = 8
		if   check_bu(s, &"01_", 61): pass
		elif check_bu(s, &"02_", 62): pass
		elif check_bu(s, &"03_", 63): pass
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
		else: file_not_found = true
	elif &"CI" in s:
		id = 12
	elif &"CJ" in s:
		id = 10
		if   check_bu(s, &"01_", 81): pass
		else: file_not_found = true
	elif &"CK" in s:
		id = 11
		if   check_bu(s, &"01_", 91): pass
		else: file_not_found = true
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
	if   &"EA10" in filename: return true
	elif &"EA11" in filename: return true
	elif &"EA12" in filename: return true
	elif &"EA13" in filename: return true
	elif &"EA16" in filename: return true
	elif &"EA17" in filename: return true
	elif &"EB01" in filename: return true
	elif &"EB10" in filename: return true
	elif &"EB11" in filename: return true
	elif &"EB12" in filename: return true
	elif &"EB13" in filename: return true
	elif &"EB16" in filename: return true
	elif &"EB17" in filename: return true
	elif &"EC10" in filename: return true
	elif &"EC11" in filename: return true
	elif &"EC12" in filename: return true
	elif &"EC13" in filename: return true
	elif &"EC16" in filename: return true
	elif &"EC17" in filename: return true
	elif &"ED10" in filename: return true
	elif &"ED11" in filename: return true
	elif &"ED12" in filename: return true
	elif &"ED13" in filename: return true
	elif &"ED16" in filename: return true
	elif &"ED17" in filename: return true
	elif &"EE10" in filename: return true
	elif &"EE11" in filename: return true
	elif &"EE12" in filename: return true
	elif &"EE13" in filename: return true
	elif &"EE16" in filename: return true
	elif &"EE17" in filename: return true
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
