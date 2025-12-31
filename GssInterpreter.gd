extends Node

const GameLogic := Global.GameLogic

var ws_pat := RegEx.create_from_string(r"[ \t]*")
var kw_pat := RegEx.create_from_string(r"\G#(if|elif|else|fi|enter|leave)\b")
var ident_pat := RegEx.create_from_string(r"\G[A-Za-z][A-Za-z0-9_]*")
var value_pat := RegEx.create_from_string(r'\G"[^"]*"|\G-?\d+(?:\.\d+)?')
var logic_pat := RegEx.create_from_string(r"\G&|\G\|")

enum StepResult {
	Ok,
	OkProgress,
	Finished,
	Change,
	TooMuch,
	BadCommand,
	BadIdent,
	BadValue,
	BadSyntax,
	BadKeyword,
}

var scenario: PackedStringArray = []
var line: int = 0
var open_regions: Dictionary[String, bool] = {}

# The GSS interpreter runs scenario script commands line by line.
# However, we have to introduce special conditional commands.
# if/elif/fi has nesting levels, which is asking for a branching stack.
# Suppose we have two eval modes:
# - one for evaluating commands and special commands,
# - one for evaluating some special commands and keeping track of the stack.
# There is a terminology for code that will never be executed.
# It's called dead code or unreachable code.
# Suppose we are in a second mode on the current level of nesting.
# This means we are in a dead branch that won't be executed in the current run.
# The stack would look like this:
# [m Alive, n Dead]
# However, we want to distinguish between a situation
# where if one of the branches will be taken, the following ones won't.
# For example, if we took the if (Character A loves me),
# we shouldn't consider elif (Character B is asking for a date).
# For this, we would introduce Forward state to the stack.
# With Forward, if the branch condition fails, it ignores only this branch arm.
# The stack now would look like this:
# [m Alive, x Forward, n Dead] (0 <= x <= 1)
# Notice how we don't need the stack of states.
# First, if we assume m = ∞, then we get away with not storing it.
# Second, we can track (n + x) as a nesting level of branches (dead_depth)
# where the topmost branch has failed condition, thus the code is unreachable.
# Third, we distinguish between x = 0 and x = 1 with skip_branch.
# 
# Special thanks to a certain Konata pfp user for suggesting this optimization.
var dead_depth := 0
var skip_branch := false

func load_scenario(sc: String, case_sensitive: bool = false) -> bool:
	var src := sc + ".gss"
	var patch_src := "scenario".path_join(src)
	var bytes: PackedByteArray
	if FS.patch.file_exists(patch_src, case_sensitive):
		bytes = FS.patch.read_file(patch_src, case_sensitive)
	elif FS.scenario.file_exists(src, case_sensitive):
		bytes = FS.scenario.read_file(src, case_sensitive)
	else: return false
	var string := bytes.get_string_from_utf8()
	if string.is_empty(): return false
	scenario = string.split("\n")
	line = 0
	open_regions = { "RecollectMode": false }
	dead_depth = 0
	skip_branch = false
	return true

var l := ""
var li := 0

func step() -> StepResult:
	if line >= scenario.size():
		return StepResult.Finished
	l = scenario[line]
	li = 0
	line += 1
	
	li = ws_pat.search(l, li).get_end()
	if li == l.length():
		return StepResult.Ok
	var kwm := kw_pat.search(l, li)
	if kwm != null:
		li = kwm.get_end()
		var kw := kwm.strings[1]
		if kw == &"enter":
			li = ws_pat.search(l, li).get_end()
			var rim := ident_pat.search(l, li)
			if rim == null:
				return StepResult.BadIdent
			li = rim.get_end()
			var r := rim.strings[0]
			open_regions[r] = true
			return enough()
		elif kw == &"leave":
			li = ws_pat.search(l, li).get_end()
			var rim := ident_pat.search(l, li)
			if rim == null:
				return StepResult.BadIdent
			li = rim.get_end()
			var r := rim.strings[0]
			open_regions[r] = false
			return enough(StepResult.Finished)
		elif not evaluatable():
			return StepResult.Ok
		
		if kw == &"if":
			if dead_depth > 0:
				dead_depth += 1
				return StepResult.Ok
			return step_condition()
		elif kw == &"elif":
			if dead_depth == 1 and not skip_branch:
				return step_condition()
			if dead_depth == 0:
				dead_depth = 1
				skip_branch = true
			return StepResult.Ok
		elif kw == &"else":
			if dead_depth == 1 and not skip_branch:
				dead_depth = 0
				return enough()
			if dead_depth == 0:
				dead_depth = 1
				skip_branch = true
			return StepResult.Ok
		elif kw == &"fi":
			dead_depth = maxi(dead_depth - 1, 0)
			if dead_depth == 0: skip_branch = false
			return enough()
		else: return StepResult.BadKeyword
	
	if l.substr(li).begins_with("ScenarioEnter()"):
		li += "ScenarioEnter()".length()
		Global.scenario_enter()
		return enough()
	
	if not evaluatable() or dead_depth != 0:
		return StepResult.Ok
	
	var cmd: Variant = eat_command()
	if cmd is StepResult:
		return cmd
	var fn: String = cmd.fn
	var args: Array[Variant] = cmd.args
	if fn == &"SceneTitle":
		scene_title.callv(reshape(args, ""))
	elif fn == &"Talk":
		talk.callv(reshape(args, "", ""))
	elif fn == &"Mess":
		mess.callv(reshape(args, 0))
	elif fn == &"Hitret":
		match await hitret.callv(reshape(args, 0, 0)):
			GameLogic.Return:
				change("EXIT_SCENARIO")
				return enough(StepResult.Change)
			GameLogic.Load:
				return enough(StepResult.Change)
		return enough(StepResult.OkProgress)
	elif fn == &"AddSelect":
		add_select.callv(reshape(args, 0, 0))
	elif fn == &"StartSelect":
		match await start_select():
			GameLogic.Return:
				change("EXIT_SCENARIO")
				return enough(StepResult.Change)
			GameLogic.Load:
				return enough(StepResult.Change)
		return enough(StepResult.OkProgress)
	elif fn == &"Font":
		font.callv(reshape(args, 0, ""))
	elif fn == &"Change":
		change.callv(reshape(args, ""))
		return enough(StepResult.Change)
	elif fn == &"SetCg":
		set_cg.callv(reshape(args, "", 0, 0, 0, 0))
	elif fn == &"SetCgRGB":
		set_cg_rgb.callv(reshape(args, 0, 0, 0))
	elif fn == &"SetBustup":
		set_bustup.callv(reshape(args, "", 0, 0))
	elif fn == &"BustupMove":
		bustup_move.callv(reshape(args, 0, 0))
	elif fn == &"BustupClear":
		bustup_clear.callv(reshape(args, 0))
	elif fn == &"BustupLeave":
		bustup_leave.callv(reshape(args, 0, 0, 0, 0, 0, 0))
	elif fn == &"Down":
		down.callv(reshape(args, 0, 0, 0, 0))
	elif fn == &"Jump":
		jump.callv(reshape(args, 0))
	elif fn == &"Shake":
		shake.callv(reshape(args, 0))
	elif fn == &"Update":
		await update.callv(reshape(args, 0))
	elif fn == &"Show":
		await show.callv(reshape(args, 0))
	elif fn == &"Hide":
		await hide.callv(reshape(args, 0))
	elif fn == &"Clear":
		clear()
	elif fn == &"WindowView":
		window_view.callv(reshape(args, 0))
	elif fn == &"ScPlayBgm":
		sc_play_bgm.callv(reshape(args, "", 0))
	elif fn == &"ScStopBgm":
		sc_stop_bgm.callv(reshape(args, 0))
	elif fn == &"ScPauseBgm":
		sc_pause_bgm()
	elif fn == &"ScRestartBgm":
		sc_restart_bgm()
	elif fn == &"ScPlayEnvSe":
		sc_play_env_se.callv(reshape(args, "", 0))
	elif fn == &"ScStopEnvSe":
		sc_stop_env_se.callv(reshape(args, "", 0))
	elif fn == &"ScPlaySe":
		await sc_play_se.callv(reshape(args, "", 0))
	elif fn == &"ScStopSe":
		sc_stop_se()
	elif fn == &"ScPlayVoice":
		sc_play_voice.callv(reshape(args, ""))
	elif fn == &"ScStopVoice":
		sc_stop_voice()
	elif fn == &"ScWaitVoice":
		await sc_wait_voice.callv(reshape(args, 0))
	elif fn == &"Transition":
		transition.callv(reshape(args, "", 0))
	elif fn == &"Quake":
		await quake.callv(reshape(args, 0, 0, 0, 0, 0))
	elif fn == &"Flush":
		await effect_flush.callv(reshape(args, "", 0, ""))
	elif fn == &"ScWait":
		await sc_wait.callv(reshape(args, 0, 0))
	elif fn == &"OpeningMovie":
		await opening_movie()
	elif fn == &"BlackOut":
		await black_out.callv(reshape(args, 0, 0))
	elif fn == &"WhiteOut":
		await white_out.callv(reshape(args, 0, 0))
	elif fn == &"Sepia":
		sepia.callv(reshape(args, 0))
	elif fn == &"Tone":
		tone.callv(reshape(args, ""))
	elif fn == &"Scroll":
		await scroll.callv(reshape(args, 0, 0, 0, 0, 0))
	elif fn == &"WaitScroll":
		await wait_scroll()
	elif fn == &"Zoom":
		zoom.callv(reshape(args, 0, 0, 0, 0, 0, 0, 0))
	elif fn == &"ScPlayMovie":
		await sc_play_movie.callv(reshape(args, ""))
	elif fn == &"OnFlag":
		Global.on_flag.callv(reshape(args, 0))
	elif fn == &"OnGlobalFlag":
		Global.on_global_flag.callv(reshape(args, 0))
	elif fn == &"OnRecollectFlag":
		Global.on_recollect_flag.callv(reshape(args, 0))
	elif fn == &"OnGameClear":
		Global.on_game_clear()
	elif fn == &"EyeCatchEnter":
		await Global.eye_catch_enter.callv(reshape(args, "", 0))
	else:
		return StepResult.BadCommand
	return enough()

func eat_command() -> Variant:
	li = ws_pat.search(l, li).get_end()
	var fnm := ident_pat.search(l, li)
	if fnm == null:
		return StepResult.BadIdent
	li = fnm.get_end()
	var fn := fnm.strings[0]
	var args := []
	li = ws_pat.search(l, li).get_end()
	if not l.substr(li).begins_with("("):
		return StepResult.BadSyntax
	li += 1
	while true:
		li = ws_pat.search(l, li).get_end()
		var more := args.size() == 0
		if l.substr(li).begins_with(","):
			if more:
				return StepResult.BadSyntax
			li = ws_pat.search(l, li + 1).get_end()
			more = true
		if li == l.length():
			return StepResult.BadSyntax
		if l.substr(li).begins_with(")"):
			li += 1
			return { fn = fn, args = args }
		if not more:
			return StepResult.BadSyntax
		var valm := value_pat.search(l, li)
		if valm == null:
			return StepResult.BadValue
		li = valm.get_end()
		var val := valm.strings[0]
		if val.begins_with('"'):
			args.append(val.substr(1, val.length() - 2))
		elif val.contains("."):
			args.append(val.to_float())
		else:
			args.append(val.to_int())
	return StepResult.BadSyntax

func enough(ok: StepResult = StepResult.Ok) -> StepResult:
	li = ws_pat.search(l, li).get_end()
	if li != l.length():
		return StepResult.TooMuch
	return ok

func evaluatable() -> bool:
	return not Global.is_recollect_mode() or open_regions["RecollectMode"]

func reshape(args: Array[Variant], ...default: Array[Variant]) -> Array[Variant]:
	var size := mini(args.size(), default.size())
	for i in range(size):
		if typeof(args[i]) == typeof(default[i]):
			default[i] = args[i]
	return default

func step_condition() -> StepResult:
	var sat := true
	while true:
		var cmd: Variant = eat_command()
		if cmd is StepResult:
			return cmd
		var fn: String = cmd.fn
		var args: Array[Variant] = cmd.args
		if not sat:
			pass
		elif fn == &"ChkSelect":
			sat = chk_select.callv(reshape(args, 0))
		elif fn == &"ChkFlag":
			sat = Global.chk_flag.callv(reshape(args, 0))
		elif fn == &"ChkFlagOn":
			sat = Global.chk_flag_on.callv(reshape(args, 0))
		elif fn == &"ChkFlagOff":
			sat = Global.chk_flag_off.callv(reshape(args, 0))
		elif fn == &"IsGameClear":
			if Global.is_load():
				sat = Global.sc_obj.faux_clear
			else:
				sat = Global.is_game_clear()
				Global.sc_obj.faux_clear = sat
		else:
			dead_depth = 0
			return StepResult.BadCommand
		li = ws_pat.search(l, li).get_end()
		var lm := logic_pat.search(l, li)
		if lm == null:
			break
		var logic_op := lm.strings[0]
		if logic_op == &"|":
			if sat: break
			sat = true
	dead_depth = int(not sat)
	return enough()

func scene_title(title: String) -> void:
	Global.sc_obj.scene_title = title

func talk(string: String, voice: String) -> void:
	Global.adv.name_(string, voice)

func mess(id: int) -> void:
	Global.adv.mess(id)

func hitret(id: int, voice_wait: int) -> GameLogic:
	return await Global.adv.hitret(id, voice_wait)

func add_select(choice: int, flag: int) -> void:
	Global.adv.add_select(choice, flag != 0)

func start_select() -> GameLogic:
	return await Global.adv.start_select()

func chk_select(num: int) -> bool:
	return Global.adv.select_result == num

func font(size: int, face: String) -> void:
	if Global.is_load():
		return
	Global.adv.font(size, false, false, face)

func change(sc: String) -> void:
	Global.sc_obj.scenario_call = sc

func set_cg(cg: String, x: int, y: int, w: int, h: int) -> void:
	if Global.is_load():
		return
	Global.adv.set_cg_(cg, x, y, w, h)
	Global.adv.bustup_clear(0)
	var size := Global.screen_size
	Global.adv.zoom_(size.x / 2, size.y / 2, size.x, size.y, 0, 0)

func set_cg_rgb(r: int, g: int, b: int) -> void:
	if Global.is_load():
		return
	Global.adv.set_cg_rgb_(r, g, b)
	Global.adv.bustup_clear(0)

func set_bustup(bu: String, pos: int, priority: int) -> void:
	if Global.is_load():
		return
	Global.adv.set_bustup_(bu, pos, priority)

func bustup_move(id: int, pos: int) -> void:
	if Global.is_load():
		return
	Global.adv.bustup_move(id, pos)

func bustup_clear(id: int) -> void:
	if Global.is_load():
		return
	Global.adv.bustup_clear(id)

func bustup_leave(id: int, mx: int, my: int, fade: int, time: int, accel: int) -> void:
	if Global.is_load():
		return
	Global.adv.bustup_leave(id, mx, my, fade != 0, time, accel)

func down(id: int, mv: int, time: int, accel: int) -> void:
	if Global.is_load():
		return
	Global.adv.bustup_down(id, mv, time, accel)

func jump(id: int) -> void:
	if Global.is_load():
		return
	Global.adv.bustup_jump(id)

func shake(id: int) -> void:
	if Global.is_load():
		return
	Global.adv.bustup_shake(id)

func update(flush: int) -> void:
	if Global.is_load():
		return
	var _flush := flush != 0 or Global.adv.is_key_update_flush()
	await Global.adv.update_(_flush)
	await Global.adv.wait_update(_flush)

func show(wait: int) -> void:
	if Global.is_load():
		return
	await Global.adv.show_message(wait != 0)

func hide(wait: int) -> void:
	if Global.is_load():
		return
	await Global.adv.hide_message(wait != 0)

func clear() -> void:
	if Global.is_load():
		return
	Global.adv.clear_message()

func window_view(type: int) -> void:
	Global.adv.message_view(type)

func sc_play_bgm(file: String, non_fade: int) -> void:
	if Global.is_load():
		return
	SoundSystem.play_bgm(file, non_fade != 0)

func sc_stop_bgm(non_fade: int) -> void:
	if Global.is_load():
		return
	SoundSystem.stop_bgm(non_fade)

func sc_pause_bgm() -> void:
	if Global.is_load():
		return
	SoundSystem.pause_bgm()

func sc_restart_bgm() -> void:
	if Global.is_load():
		return
	SoundSystem.restart_bgm()

func sc_play_env_se(file: String, fade: int) -> void:
	if Global.is_load():
		return
	SoundSystem.play_env_se(file, fade != 0)

func sc_stop_env_se(file: String, fade: int) -> void:
	if Global.is_load():
		return
	SoundSystem.stop_env_se(file, fade != 0)

func sc_play_se(file: String, wait: int) -> void:
	if Global.is_load():
		return
	if wait != 0 and not Global.adv.is_skip():
		await SoundSystem.play_se(file)
	else:
		SoundSystem.play_se(file)

func sc_stop_se() -> void:
	SoundSystem.stop_se()

func sc_play_voice(file: String) -> void:
	if Global.is_load():
		return
	SoundSystem.play_voice(file)

func sc_stop_voice() -> void:
	SoundSystem.stop_voice()

func sc_wait_voice(key_disable: int) -> void:
	if Global.is_load():
		return
	await SoundSystem.wait_voice(key_disable != 0)

func transition(type: String, time: int) -> void:
	if Global.is_load():
		return
	Global.adv.set_transition(type, time)

func quake(w: int, h: int, whole: int, count: int, time: int) -> void:
	if Global.is_load():
		return
	if Global.adv.is_key_update_flush():
		return
	await Global.adv.effect_quake(w, h, whole != 0, count, time)

func effect_flush(color: String, time: int, cg_file: String) -> void:
	if Global.is_load():
		return
	if Global.adv.is_key_update_flush():
		return
	await Global.adv.effect_flush(color, time, cg_file)

func sc_wait(time: int, key_disable: int) -> void:
	if (Global.is_load()
	or Global.adv.is_key_update_flush()
	or time <= 0):
		return
	var t := time / 1000.0
	if key_disable != 0:
		await get_tree().create_timer(t).timeout
	else:
		await Global.hit_wait(t)

func opening_movie() -> void:
	hide(0)
	set_cg("BLACK", 0, 0, 0, 0)
	transition("", 1000)
	await update(0)
	Global.destroy_adv_screen()
	await Global.play_movie("opening.ogv")
	Global.setup_adv_screen()
	Global.sys_obj.view_opening_movie = true

func black_out(wait: int, _hide: int) -> void:
	if _hide != 0:
		hide(0)
	if wait == 0:
		wait = 1000
	set_cg("black", 0, 0, 0, 0)
	transition("", wait)
	await update(0)

func white_out(wait: int, _hide: int) -> void:
	if _hide != 0:
		hide(0)
	if wait == 0:
		wait = 1000
	set_cg("white", 0, 0, 0, 0)
	transition("", wait)
	await update(0)

func sepia(flag: int) -> void:
	if Global.is_load():
		return
	if flag != 0:
		Global.adv.set_tone_filter("SEPIA")
	else:
		Global.adv.set_tone_filter("NORMAL")

func tone(type: String) -> void:
	if Global.is_load():
		return
	Global.adv.set_tone_filter(type)

func scroll(x: int, y: int, time: int, accel: int, wait: int) -> void:
	if Global.is_load():
		return
	if wait != 0:
		await Global.adv.scroll_(x, y, time, accel)
	else:
		Global.adv.scroll_(x, y, time, accel)

func wait_scroll() -> void:
	await Global.adv.wait_scroll()

func zoom(
	x: int, y: int,
	w: int, h: int,
	time: int, accel: int, _wait: int,
) -> void:
	if Global.is_load():
		return
	Global.adv.zoom_(x, y, w, h, time, accel)

func sc_play_movie(file: String) -> void:
	Global.destroy_adv_screen()
	if Global.cnf_obj.play_bgm:
		Global.set_volume(Global.cnf_obj.vol_bgm * 0.75)
	else:
		Global.set_volume(0.0)
	await Global.play_movie(file + ".ogv")
	Global.set_volume(0.75)
	Global.setup_adv_screen()
