class_name AdvScreen
extends Control

const ScreenEffect := ConfigDataBase.ScreenEffect
const GameLogic := Global.GameLogic
const Layer := Global.Layer

enum ToneFilterType {
	NORMAL, NEGATIVE,
	MONOCHROME, MONO_NEGATIVE,
	SEPIA, LOSE
}

var created := false
var msg_frame := MessageFrame.new()
var msg_info := MessageInfo.new()
var req_font := false
var msg_sequence := {}
var adv_base_layer := CanvasLayer.new()
var adv_base := Node2D.new()
var spr_cg := EffectSprite2D.new()
var cg := CgInfo.new()
var bustup_man := BustupManager.new(5)
var hud_layer := CanvasLayer.new()
var update := false
var set_cg := false
var set_cg_rgb := false
var set_bustup := false
var req_zoom := false
var scroll := false
var col_set_cg_rgb := Color.from_rgba8(0, 0, 0, 0)
var scrl_param := MoveParam.new()
var zoom := false
var zoom_param := ZoomParam.new()
var req_tone_filter := false
var type_tone_filter := ToneFilterType.NORMAL
var transition := false
var trans_info := {type = "", time = 0}
var tone_filters: Array[ToneFilter] = create_tone_filter()
var updating := false
var trans_layer := CanvasLayer.new()
var trans_base := TextureRect.new()
var trans_mat := Blender.new()
var dummy_view := SubViewport.new()
var dummy_cg := EffectSprite2D.new()
var dummy_bu: Array[Sprite2D] = []
var dummy_bu_leave: Array[Sprite2D] = []
var select_result := 0
var select := false
var select_item: PackedInt32Array = []
var spr_select: Array[Control] = []
var talk_type := 0
var skip := false
var auto_mode := false
var tone_filter := false
var esc_menu := false
var key_update_flush := false
var capture_viewport: SubViewport

func _init() -> void:
	adv_base_layer.layer = Layer.AdvBase
	add_child(adv_base_layer)
	adv_base_layer.add_child(adv_base)
	spr_cg.centered = false
	spr_cg.use_parent_material = true
	spr_cg.z_index = RenderingServer.CANVAS_ITEM_Z_MIN
	adv_base.add_child(spr_cg)
	adv_base.add_child(bustup_man)
	trans_layer.layer = Layer.Trans
	add_child(trans_layer)
	trans_base.visible = false
	trans_base.texture = dummy_view.get_texture()
	trans_base.size = Global.screen_size
	trans_base.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	trans_base.material = trans_mat
	trans_base.z_index = RenderingServer.CANVAS_ITEM_Z_MIN
	trans_layer.add_child(trans_base)
	dummy_view.size_2d_override = Global.screen_size
	dummy_view.size_2d_override_stretch = true
	dummy_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	trans_layer.add_child(dummy_view)
	dummy_cg.centered = false
	dummy_cg.z_index = spr_cg.z_index
	dummy_cg.set_process(false)
	dummy_view.add_child(dummy_cg)
	for i in range(bustup_man.spr.size()):
		dummy_bu.append(Sprite2D.new())
		dummy_bu[i].centered = false
		dummy_view.add_child(dummy_bu[i])
		dummy_bu_leave.append(Sprite2D.new())
		dummy_bu_leave[i].centered = false
		trans_layer.add_child(dummy_bu_leave[i])
	hud_layer.layer = Layer.Hud
	add_child(hud_layer)
	hud_layer.add_child(msg_frame)
	set_visibility(false)

func _process(delta: float) -> void:
	if Global.cnf_obj.screen_effect == ScreenEffect.Normal:
		for i in range(bustup_man.info.size()):
			if bustup_man.info[i].status == 0:
				continue
			var spr := bustup_man.spr[i]
			var texture := spr.texture
			if texture is AnimTexture:
				if texture.process(delta):
					spr.queue_redraw()

func create() -> void:
	if created: return
	msg_frame.create()
	msg_info.clear()
	msg_sequence = {}
	cg.clear()
	for bu in bustup_man.info:
		bu.clear()
	adv_base.material = tone_filters[ToneFilterType.NORMAL]
	zoom_(Global.screen_size.x / 2, Global.screen_size.y / 2,
		Global.screen_size.x, Global.screen_size.y)
	key_update_flush = true
	update = false
	select = false
	skip = false
	auto_mode = false
	set_visibility(true)
	created = true

func destroy() -> void:
	if not created: return
	flush_update()
	msg_frame.destroy()
	spr_cg.texture = null
	for spr in bustup_man.spr:
		spr.texture = null
	flush_update()
	set_visibility(false)
	created = false

func set_visibility(vis: bool) -> void:
	visible = vis
	adv_base_layer.visible = vis
	trans_layer.visible = vis
	hud_layer.visible = vis

func name_(string: String, voice: String) -> void:
	msg_info.name = string
	msg_info.voice = voice
	if string in [&"", &"心の声", &"語り"]:
		talk_type = 0
	else: talk_type = 1

func mess(id: int) -> void:
	msg_info.message = id

func set_bustup_(filename: String, pos: int, priority: int) -> void:
	print("Char-%s" % filename)
	bustup_man.set_(filename, pos, priority, cg.time_zone)
	set_bustup = true
	update = true

func bustup_move(id: int, pos: int) -> void:
	bustup_man.move(id, pos)
	set_bustup = true
	update = true

func bustup_clear(id: int) -> void:
	print("CharClear-%s" % id)
	bustup_man.clear(id)
	set_bustup = true
	update = true

func bustup_leave(
	id: int, mx: int, my: int,
	fade: bool, time: int, accel: int
) -> void:
	print("CharLeave-%s" % id)
	bustup_man.leave(id, mx, my, fade, time, accel)
	set_bustup = true
	update = true

func bustup_down(id: int, mv: int, time: int, accel: int) -> void:
	bustup_man.down(id, mv, time, accel)
	update = true

func bustup_jump(id: int) -> void:
	bustup_man.jump(id)
	update = true

func bustup_shake(id: int) -> void:
	bustup_man.shake(id)
	update = true

func set_cg_(filename: String, x: int = 0, y: int = 0, _w: int = 0, _h: int = 0) -> void:
	print("CG-%s" % filename)
	Global.check_setup_cg(filename, cg)
	cg.pt = Vector2i(x, y)
	set_cg = true
	set_cg_rgb = false
	update = true

func set_cg_rgb_(r: int, g: int, b: int) -> void:
	print("CGRGB-%s,%s,%s" % [r, g, b])
	cg.pt = Vector2i.ZERO
	col_set_cg_rgb = Color8(r, g, b)
	set_cg = true
	set_cg_rgb = true
	update = true

func is_update() -> bool:
	return update

func update_(flush: bool, wait: bool = false) -> void:
	if not update:
		return
	update = false
	if updating:
		flush_update()
	if trans_info.type == &"NONE":
		flush = true
	elif Global.cnf_obj.screen_effect == ScreenEffect.None:
		flush = true
	var activation_wait := 0.5
	if transition and trans_info.time != 0:
		activation_wait = trans_info.time / 1000.0
	var bustup_size := bustup_man.info.size()
	if not flush:
		dummy_cg.transform = spr_cg.transform
		dummy_cg.texture = spr_cg.texture
		dummy_cg.copy_effect(spr_cg)
		dummy_cg.material = adv_base.material
		for i in range(bustup_size):
			var info := bustup_man.info[i]
			var nonleave := info.status != 128
			var dumbu := dummy_bu[i] if nonleave else dummy_bu_leave[i]
			bustup_man.copy_spr_at(i, dumbu)
			dumbu.material = adv_base.material
		dummy_view.size = get_viewport().size
		dummy_view.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		trans_base.show()
	bustup_man.adjust_position()
	if set_cg:
		Anim.kill(spr_cg)
		if not set_cg_rgb:
			load_cg(spr_cg, cg.filename)
		else:
			create_color_texture(spr_cg, col_set_cg_rgb)
		spr_cg.effect = cg.effect_param
		spr_cg.position = -cg.pt
		wait = true
	if set_bustup:
		for i in range(bustup_size):
			if bustup_man.info[i].status != 2:
				var spr := bustup_man.spr[i]
				Anim.kill(spr)
				spr.modulate.a = 1.0
		for i in range(bustup_size):
			var info := bustup_man.info[i]
			var spr := bustup_man.spr[i]
			Anim.flush(spr)
			if info.status == 2:
				pass
			elif info.status != 0 and info.status != 8:
				load_bustup(spr, info)
				spr.z_index = -info.priority
				spr.show()
			else:
				spr.texture = null
			bustup_man.adjust_spr_position(i)
			if info.status == 1 or info.status == 4:
				info.status = 2
			elif info.status == 8:
				info.clear()
	if Global.cnf_obj.screen_effect == ScreenEffect.None:
		end_animation()
	if req_tone_filter:
		adv_base.material = tone_filters[type_tone_filter]
		tone_filter = type_tone_filter != ToneFilterType.NORMAL
		req_tone_filter = false
	if req_zoom:
		zoom = zoom_param.is_zoom()
		if not zoom:
			adv_base.position = Vector2.ZERO
			adv_base.scale = Vector2.ONE
		else:
			adv_base.position = Vector2(zoom_param.size / 2 - zoom_param.pt)
			adv_base.scale = Vector2(zoom_param.horz_unit(), zoom_param.vert_unit())
			adv_base.position *= adv_base.scale
		req_zoom = false
	if scroll:
		if flush:
			spr_cg.position = scrl_param.pt
		cg.pt = -scrl_param.pt
	var anims := []
	if not flush:
		for i in range(bustup_size):
			var info := bustup_man.info[i]
			var anim := { position = {} }
			if info.status == 16:
				info.local_position += info.down_param.pt
				anim.position.target = info.local_position
				anim.position.accel = Vector2(info.down_param.accel, 0)
			elif info.status == 128:
				info.local_position += info.leave_param.pt
				anim.position.target = info.local_position
				anim.position.accel = Vector2(info.leave_param.accel, 0)
				if info.leave_param.fade:
					anim.alpha = { target = 0.0 }
			anims.append(anim)
	else:
		for i in range(bustup_size):
			var info := bustup_man.info[i]
			var spr := bustup_man.spr[i]
			Anim.kill(spr)
			if info.status == 16:
				info.local_position += info.down_param.pt
				spr.position = info.local_position
			elif info.status == 128:
				info.local_position += info.leave_param.pt
				spr.position = info.local_position
				if info.leave_param.fade:
					spr.modulate.a = 0.0
	if not flush:
		if transition and trans_info.type != &"":
			var alpha_image := FS.load_mask_image(trans_info.type)
			trans_mat.alpha_texture = ImageTexture.create_from_image(alpha_image)
			trans_mat.r = 8.0
		else:
			trans_mat.alpha_texture = Global.create_color_texture(Color.TRANSPARENT)
			trans_mat.r = 1.0
		# Stupid hack
		# All the image loading can take a while.
		# This causes lag frames to not be displayed
		# due to the large delta processing time.
		await RenderingServer.frame_pre_draw
		Anim.property(trans_base, "material:t", activation_wait)
		if scroll:
			Anim.flush(spr_cg)
			Anim.run_single(spr_cg, {
				position = {
					target = Vector2(scrl_param.pt),
					accel = Vector2(scrl_param.accel, 0.0)},
			}, scrl_param.time / 1000.0)
		updating = true
		if wait:
			await wait_update()
		else:
			wait_update()
	for i in range(bustup_size):
		var info := bustup_man.info[i]
		if info.status == 16:
			if not flush:
				var target := bustup_man.spr[i]
				Anim.run_single(target, anims[i], info.down_param.time / 1000.0)
			info.status = 2
		elif info.status == 128:
			if not flush:
				var target := dummy_bu_leave[i]
				Anim.run_single(target, anims[i], info.leave_param.time / 1000.0)
				bustup_man.clear_at(i)
		# It's possible to skip awaiting both actions.
		# The original waits. Doesn't seem to be intended?
		elif info.status == 32:
			if not flush:
				await action_jump(info.id)
			info.status = 2
		elif info.status == 64:
			if not flush:
				await action_shake(info.id)
			info.status = 2
	if Global.is_eye_catch():
		await Global.eye_catch_leave()
	transition = false
	trans_info = {type = "", time = 0}
	set_cg = false
	set_bustup = false
	scroll = false

func wait_update(_flush: bool = false) -> void:
	if updating:
		await Anim.finish(trans_base)
		flush_update()

func flush_update() -> void:
	if updating:
		trans_base.hide()
		Anim.kill(trans_base)
		trans_mat.alpha_texture = null
		trans_mat.t = 0.0
		dummy_cg.texture = null
		for dumbu in dummy_bu:
			dumbu.texture = null
		updating = false
	Anim.flush(adv_base)

func hitret(id: int, voice_wait: int) -> GameLogic:
	var ret := GameLogic.Unaffected
	var flush := is_skip() or Input.is_action_pressed("fast_forward")
	var load_end := false
	if not Global.is_load():
		Global.sc_obj.in_select = false
		Global.sc_obj.hitret_id = id
	if Global.is_load():
		if (Global.sc_obj.in_select
		or Global.sc_obj.hitret_id != id):
			msg_info.clear()
			return GameLogic.Unaffected
		Global.leave_load()
		load_end = true
	elif is_update():
		await update_(flush)
	var voice_plays := false
	var voice_found := FS.exists_voice(msg_info.voice)
	if not load_end:
		msg_frame.clear_page()
		if not msg_frame.is_show:
			await msg_frame._show()
		var names := Global.check_true_name(msg_info.name)
		var true_name: String = names.true_name
		var show_name: String = names.show_name
		if Global.check_play_voice(true_name):
			if msg_info.voice != "" and not flush:
				voice_plays = play_voice(msg_info.voice)
				await RenderingServer.frame_pre_draw
		var message := TranslationTable.mess(msg_info.message)
		msg_frame.apply_sequence(msg_sequence)
		msg_frame.output(show_name, message, flush)
		Global.sc_obj.name_log.add(msg_info.name)
		Global.sc_obj.mess_log.add(str(msg_info.message))
		Global.sc_obj.seq_log.add(JSON.stringify(msg_sequence))
		if req_font:
			msg_sequence = Global.create_message_escape_sequence()
			req_font = false
		if voice_found:
			msg_frame.show_voice()
			Global.sc_obj.voice_log.add(msg_info.voice)
		else:
			msg_frame.hide_voice()
			Global.sc_obj.voice_log.add("")
	if not Global.sys_obj.read_flag.check(id):
		Global.sys_obj.read_flag.set_(id)
		if Global.cnf_obj.read_skip and is_skip():
			skip_(false)
	if is_skip():
		if Input.is_action_just_pressed("hit", true):
			skip_(false)
	var auto_time := float(Global.cnf_obj.automode_speed) + 0.5
	var auto_timer := get_tree().create_timer(auto_time)
	var skip_throttle := get_tree().create_timer(0.033)
	var loop := not is_skip()
	while loop:
		var control := await Global.poll_ui_event()
		var cid: String = control.name if control else ""
		if cid.is_empty() and Input.is_action_just_pressed("hit_confirm", true) \
		or Input.is_action_just_pressed("ui_down"):
			if msg_frame.is_pending():
				msg_frame.flush_()
			else: break
		elif cid == "ID_CLOSE" \
		or Input.is_action_just_pressed("hit_cancel") \
		or Input.is_action_just_pressed("hide_adv"):
			if not is_auto_mode():
				if msg_frame.is_show:
					await msg_frame._hide()
					await Global.test_hitret()
					await msg_frame._show()
				else:
					await Global.test_hitret()
			else:
				auto_mode_(false)
		elif cid == "ID_SKIP" \
		or Input.is_action_just_pressed("skip"):
			await get_tree().process_frame
			skip_(true)
			break
		elif cid == "ID_AUTO" \
		or Input.is_action_just_pressed("auto_mode"):
			if is_auto_mode():
				auto_mode_(false)
			else:
				auto_mode_(true)
				msg_frame.hide_blink()
				auto_timer = get_tree().create_timer(auto_time)
		elif cid == "ID_QLOAD" \
		or Input.is_action_just_pressed("quick_load"):
			if not Global.is_recollect_mode() and Global.sc_obj_qsave:
				msg_frame.enable(false)
				if await Global.confirm(Global.confirm_prompt.qload):
					await Global.quick_load()
					msg_frame.enable(true)
					ret = GameLogic.Load
					break
				msg_frame.enable(true)
		elif cid == "ID_QSAVE" \
		or Input.is_action_just_pressed("quick_save"):
			if not Global.is_recollect_mode():
				msg_frame.enable(false)
				await Global.quick_save()
				msg_frame.enable(true)
				msg_frame.enable_qload(true)
		elif cid == "ID_CONFIG" \
		or Input.is_action_just_pressed("config"):
			ret = await call_config()
			if ret != GameLogic.Unaffected:
				break
		elif cid == "ID_HISTORY" \
		or Input.is_action_just_pressed("history") \
		or Input.is_action_just_pressed("ui_up"):
			await call_history()
		elif cid == "ID_LOAD" \
		or Input.is_action_just_pressed("load", true):
			if not Global.is_recollect_mode():
				ret = await call_load_save(true)
				if ret != GameLogic.Unaffected:
					break
		elif cid == "ID_SAVE" \
		or Input.is_action_just_pressed("save"):
			if not Global.is_recollect_mode():
				ret = await call_load_save(false)
				if ret != GameLogic.Unaffected:
					break
		elif cid == "ID_VOICE":
			SoundSystem.play_voice(Global.sc_obj.voice_log.nth_back(0), true)
		elif Input.is_action_pressed("fast_forward"):
			break
		elif is_auto_mode():
			if msg_frame.is_pending():
				pass
			elif voice_plays and not SoundSystem.is_play_voice():
				loop = false
			elif not(auto_timer.time_left > 0.0):
				loop = false
		elif voice_wait:
			if voice_plays and not SoundSystem.is_play_voice():
				loop = false
		if not msg_frame.is_show_blink() \
		and not msg_frame.is_pending() \
		and not is_auto_mode():
			msg_frame.show_blink()
	if skip_throttle.time_left > 0.0:
		await skip_throttle.timeout
	if ret != GameLogic.Return:
		msg_frame.hide_blink()
	if msg_info.voice != &"" and Global.cnf_obj.voice_stop_on_click:
		SoundSystem.stop_voice()
	msg_info.clear()
	return ret

func font(size_: int, bold: bool, italic: bool, face: String) -> void:
	msg_sequence = Global.create_message_escape_sequence(size_, bold, italic, face)
	req_font = true

func skip_(skipping: bool) -> void:
	skip = skipping
	msg_frame.skip(skipping)

func is_skip() -> bool:
	return skip

func auto_mode_(autoplay: bool) -> void:
	auto_mode = autoplay
	msg_frame.auto_mode(autoplay)

func is_auto_mode() -> bool:
	return auto_mode

func is_show_message() -> bool:
	return msg_frame.is_show

func show_message(flush: bool = false) -> void:
	if is_select():
		transparency_select(1.0)
	await msg_frame._show(flush)

func hide_message(flush: bool = false) -> void:
	if is_select():
		transparency_select(0.0)
	await msg_frame._hide(flush)

func clear_message() -> void:
	msg_frame.clear_page()

func message_view(type: int) -> void:
	msg_frame.view(type)

func get_message_view() -> int:
	return msg_frame.get_view()

func add_select(choice: int, _flag: bool = false) -> void:
	select_item.append(choice)

func start_select() -> GameLogic:
	var ret := GameLogic.Unaffected
	if Global.is_load():
		var selcount := Global.sc_obj.select.size()
		if Global.sc_obj.select_count < selcount:
			msg_info.clear()
			select_result = Global.sc_obj.select[Global.sc_obj.select_count]
			Global.sc_obj.select_count += 1
			return GameLogic.Unaffected
		Global.leave_load()
	Global.sc_obj.in_select = true
	enter_select()
	setup_select_item()
	show_select_item()
	var _select := 0
	while true:
		var control := await Global.poll_ui_event()
		var cid: String = control.name if control else ""
		if cid == "ID_SELECT":
			var parent := control.get_parent()
			_select = spr_select.find(parent) + 1
			if _select != 0:
				break
		elif cid == "ID_CLOSE" \
		or Input.is_action_just_pressed("hit_cancel") \
		or Input.is_action_just_pressed("hide_adv"):
			if is_auto_mode():
				auto_mode_(false)
			elif is_skip():
				skip_(false)
			else:
				hide_select_item()
				if msg_frame.is_show:
					await msg_frame._hide()
					await Global.test_hitret()
					show_select_item()
					await msg_frame._show()
				else:
					await Global.test_hitret()
					show_select_item()
		elif cid == "ID_SKIP" \
		or Input.is_action_just_pressed("skip"):
			skip_(true)
		elif cid == "ID_AUTO" \
		or Input.is_action_just_pressed("auto_mode"):
			if is_auto_mode():
				auto_mode_(false)
			else:
				auto_mode_(true)
				msg_frame.hide_blink()
		elif cid == "ID_QLOAD" \
		or Input.is_action_just_pressed("quick_load"):
			if not Global.is_recollect_mode() and Global.sc_obj_qsave:
				msg_frame.enable(false)
				if await Global.confirm(Global.confirm_prompt.qload):
					await Global.quick_load()
					msg_frame.enable(true)
					ret = GameLogic.Load
					break
				msg_frame.enable(true)
		elif cid == "ID_QSAVE" \
		or Input.is_action_just_pressed("quick_save"):
			if not Global.is_recollect_mode():
				msg_frame.enable(false)
				await Global.quick_save()
				msg_frame.enable(true)
				msg_frame.enable_qload(true)
		elif cid == "ID_CONFIG" \
		or Input.is_action_just_pressed("config"):
			ret = await call_config()
			if ret != GameLogic.Unaffected:
				break
		elif cid == "ID_HISTORY" \
		or Input.is_action_just_pressed("history") \
		or Input.is_action_just_pressed("ui_up"):
			await call_history()
		elif cid == "ID_LOAD" \
		or Input.is_action_just_pressed("load", true):
			if not Global.is_recollect_mode():
				ret = await call_load_save(true)
				if ret != GameLogic.Unaffected:
					break
		elif cid == "ID_SAVE" \
		or Input.is_action_just_pressed("save"):
			if not Global.is_recollect_mode():
				ret = await call_load_save(false)
				if ret != GameLogic.Unaffected:
					break
		elif cid == "ID_VOICE":
			SoundSystem.play_voice(Global.sc_obj.voice_log.nth_back(0), true)
	if _select != 0:
		if Global.cnf_obj.screen_effect == ScreenEffect.Normal:
			var selected := spr_select[_select - 1]
			for item in spr_select:
				if item != selected:
					Anim.kill(item)
					item.modulate.a = 0.0
			await Anim.fade(selected, 0.0, 0.5)
	for item in spr_select:
		Anim.destroy(item)
	spr_select.clear()
	select_item.clear()
	if not Global.is_load():
		select_result = _select
		Global.sc_obj.select.append(_select)
	if is_skip() and not Global.cnf_obj.lock_skip:
		skip_(false)
	leave_select()
	return ret

func enter_select() -> void:
	select = true

func leave_select() -> void:
	select = false

func is_select() -> bool:
	return select

func get_select_result() -> int:
	return select_result

func transparency_select(alpha: float, flush: bool = false) -> void:
	if flush or Global.cnf_obj.screen_effect == ScreenEffect.None:
		for item in spr_select:
			Anim.kill(item)
			item.modulate.a = alpha
	else:
		for item in spr_select:
			Anim.fade(item, alpha, 0.3)

func setup_select_item() -> void:
	for item in spr_select:
		Anim.destroy(item)
	spr_select.clear()
	var y := 264 - 52 * select_item.size() / 2
	for id in select_item:
		var choice := TranslationTable.choice(id)
		var sel := Global.frame_skin.create_form_page(&"ID_PAGE_ADVSELECT")
		sel.pivot_offset = Vector2(375, 24)
		sel.position = Vector2(400, y) - sel.pivot_offset
		sel.modulate.a = 0.0
		sel.name += str(id)
		var sel_text: MessageSprite = sel.get_node("ID_TEXT")
		sel_text.output_message(choice)
		hud_layer.add_child(sel)
		spr_select.append(sel)
		y += 52

func show_select_item() -> void:
	if Global.cnf_obj.screen_effect == ScreenEffect.Normal:
		for item in spr_select:
			Anim.schedule_scale(item, Vector2(0.95, 0.95), Vector2.ONE)
			Anim.schedule_fade(item, 1.0)
		Anim.run(0.3)
	else:
		for item in spr_select:
			Anim.kill(item)
			item.modulate.a = 1.0

func hide_select_item() -> void:
	if Global.cnf_obj.screen_effect == ScreenEffect.Normal:
		for item in spr_select:
			Anim.fade(item, 0.0, 0.3)
	else:
		for item in spr_select:
			Anim.kill(item)
			item.modulate.a = 0.0

func call_history() -> void:
	if Global.sc_obj.name_log.num() <= 1:
		return
	if is_select():
		transparency_select(0.0)
	else:
		msg_frame.hide_blink()
	var win := HistoryWindow.new(hud_layer)
	win._show()
	hide_message()
	await win.run()
	if is_select():
		transparency_select(1.0)
	else:
		msg_frame.show_blink()
	show_message()
	await win._hide()
	win.destroy()

func call_load_save(is_load: bool) -> GameLogic:
	msg_frame.enable(false)
	var win := LoadSaveWindow.new(hud_layer, is_load)
	win._show()
	hide_message()
	var ret := await win.run()
	show_message()
	await win._hide()
	win.destroy()
	msg_frame.enable(true)
	return ret

func call_config() -> GameLogic:
	msg_frame.enable(false)
	var win := ConfigWindow.new(hud_layer, false)
	win._show()
	if is_select():
		transparency_select(0.0)
	var ret := await win.run()
	if is_select():
		transparency_select(1.0)
	await win._hide()
	win.destroy()
	msg_frame.enable(true)
	return ret

func load_cg(spr: Sprite2D, filename: String) -> void:
	var cg_texture := FS.load_texture(filename)
	if cg_texture:
		spr.texture = cg_texture

func load_bustup(spr: Sprite2D, info: BustupInfo) -> void:
	var bu_texture := FS.load_texture(info.filename)
	if bu_texture:
		if bu_texture is AnimTexture:
			if Global.cnf_obj.screen_effect == ScreenEffect.None:
				pass
			elif spr.texture is AnimTexture:
				bu_texture.frame = spr.texture.frame
				bu_texture.frame_progress = spr.texture.frame_progress
			else:
				bu_texture.set_frame(randi_range(0, bu_texture.frame_count))
		spr.texture = bu_texture
		spr.offset = -spr.texture.get_size()
		spr.offset.x = floorf(0.5 * spr.offset.x)
		spr.offset.y += 50
		#spr.modulate.a = 0.0

func create_color_texture(
	spr: Sprite2D,
	color: Color,
	_size: Vector2i = Global.screen_size,
) -> void:
	spr.texture = Global.create_color_texture(color, _size)

func is_zoom() -> bool:
	return zoom

func get_zoom_param() -> ZoomParam:
	return zoom_param

func play_voice(file: String) -> bool:
	return SoundSystem.play_voice(file)

func is_key_update_flush() -> bool:
	return key_update_flush \
		and (is_skip() or Input.is_action_pressed("fast_forward"))

func enable_key_update_flush(enable: bool) -> void:
	key_update_flush = enable

func action_jump(id: int) -> void:
	var spr: Sprite2D = null
	for i in range(bustup_man.info.size()):
		if bustup_man.info[i].id == id:
			spr = bustup_man.spr[i]
			break
	if not spr: return
	var pos := spr.position
	var w := Vector2(0, 25)
	await Anim.move(spr, pos - w, 0.2)
	await Anim.move(spr, pos, 0.2)

func action_shake(id: int) -> void:
	var spr: Sprite2D = null
	for i in range(bustup_man.info.size()):
		if bustup_man.info[i].id == id:
			spr = bustup_man.spr[i]
			break
	if not spr: return
	var pos := spr.position
	var w := Vector2(25, 0)
	await Anim.move(spr, pos - w, 0.03)
	for i in range(1, -1, -1):
		await Anim.move(spr, pos + w, 0.03)
		if i > 0:
			await Anim.move(spr, pos - w, 0.03)
	await Anim.move(spr, pos, 0.03)

func set_transition(type: String, time: int) -> void:
	transition = true
	trans_info.type = type
	trans_info.time = time

func effect_quake(w: int, h: int, whole: bool, count: int, time: int) -> void:
	var target := adv_base
	if not whole:
		target = spr_cg.duplicate()
		target.modulate.a = 0.6171875
		target.z_index += 1
		adv_base.add_child(target)
	var pos := target.position
	var v := Vector2(w, h)
	if time == 0:
		time = 30
	var t := time / 1000.0
	await Anim.move(target, pos - v, t)
	for i in range(count, -1, -1):
		await Anim.move(target, pos + v, 2 * t)
		if i > 0:
			await Anim.move(target, pos - v, 2 * t)
	await Anim.move(target, pos, t)
	if not whole:
		Anim.destroy(target)

func effect_flush(color: String, time: int, _cg_file: String) -> void:
	var spr := Sprite2D.new()
	spr.centered = false
	if color == &"BLACK":
		create_color_texture(spr, Color.BLACK)
	elif color == &"WHITE":
		create_color_texture(spr, Color.WHITE)
	elif color == &"RED":
		create_color_texture(spr, Color.RED)
	elif color == &"GREEN":
		create_color_texture(spr, Color.GREEN)
	elif color == &"BLUE":
		create_color_texture(spr, Color.BLUE)
	else:
		spr.texture = ImageTexture.create_from_image(FS.load_image(color))
	trans_layer.add_child(spr)
	await update_(true)
	await Anim.fade(spr, 0.0, time / 1000.0)
	Anim.destroy(spr)

func scroll_(x: int, y: int, time: int, accel: int) -> void:
	if not set_cg:
		Anim.flush(spr_cg)
		Anim.run_single(spr_cg, {
			position = {
				target = Vector2(-x, -y),
				accel = Vector2(accel, 0.0)},
		}, time / 1000.0)
		if (Global.cnf_obj.screen_effect == ScreenEffect.None
		or is_skip() or Input.is_action_pressed("fast_forward")):
			Anim.flush(spr_cg)
		else:
			await Anim.finish(spr_cg)
		cg.pt = Vector2i(x, y)
	else:
		update = true
		scroll = true
		scrl_param.set_(Vector2i(-x, -y), time, accel, false)

func wait_scroll() -> void:
	if is_skip() or Input.is_action_pressed("fast_forward"):
		Anim.flush(spr_cg)
	else:
		await Anim.finish(spr_cg)

func zoom_(cx: int, cy: int, w: int, h: int, time: int = 0, accel: int = 0) -> void:
	zoom_param.set_(cx, cy, w, h, time, accel)
	if not zoom and not zoom_param.is_zoom(): return
	var anim := { position = {}, scale = {} }
	if update:
		if not zoom_param.is_zoom():
			zoom = false
		req_zoom = true
		return
	if zoom_param.is_zoom():
		var scale_x := zoom_param.horz_unit()
		var scale_y := zoom_param.vert_unit()
		anim.position.target = Vector2(
			-(cx - w / 2) * scale_x,
			-(cy - h / 2) * scale_y
		)
		anim.scale.target = Vector2(scale_x, scale_y)
		zoom = true
	else:
		anim.position.target = Vector2.ZERO
		anim.scale.target = Vector2.ONE
		zoom = false
	anim.position.accel = Vector2(accel, 0.0)
	anim.scale.accel = Vector2(accel, 0.0)
	Anim.run_single(adv_base, anim, time / 1000.0)
	if (Global.cnf_obj.screen_effect == ScreenEffect.None
	or is_skip() or is_key_update_flush()):
		Anim.flush(adv_base)

static func create_tone_filter() -> Array[ToneFilter]:
	return [
		#ToneFilter.new(preload("res://tone/normal.bmp")),
		null,
		ToneFilter.new(preload("res://tone/negative.bmp")),
		ToneFilter.new(preload("res://tone/monochrome.bmp"), true),
		ToneFilter.new(preload("res://tone/mono_negative.bmp"), true),
		ToneFilter.new(preload("res://tone/sepia.bmp"), true),
		ToneFilter.new(preload("res://tone/lose.bmp"), true)
	]

func set_tone_filter(type: String) -> void:
	type = "NORMAL" if type.is_empty() else type.to_upper()
	if type not in ToneFilterType: return
	var kind: ToneFilterType = ToneFilterType[type]
	if kind == type_tone_filter: return
	type_tone_filter = kind
	print("Tone-%s" % kind)
	req_tone_filter = true
	update = true

func is_tone_filter() -> bool:
	return tone_filter

func get_tone_filter() -> String:
	return ToneFilterType.keys()[type_tone_filter]

func begin_animation() -> void:
	if not created:
		return
	spr_cg.effect = cg.effect_param
	for i in range(bustup_man.info.size()):
		if bustup_man.info[i].status == 0:
			continue
		var spr := bustup_man.spr[i]
		var texture := spr.texture
		if texture is AnimTexture:
			texture.set_frame(randi_range(0, texture.frame_count))
			spr.queue_redraw()

func end_animation() -> void:
	if not created:
		return
	spr_cg.effect = EffectParam.new()
	for spr in bustup_man.spr:
		var texture := spr.texture
		if texture is AnimTexture:
			texture.set_frame(0)
			spr.queue_redraw()

func create_capture(hud: bool = true) -> Texture2D:
	capture_viewport = SubViewport.new()
	capture_viewport.size = Global.screen_size
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(capture_viewport)
	capture_viewport.add_child(spr_cg.duplicate())
	for spr in bustup_man.spr:
		capture_viewport.add_child(spr.duplicate())
	if hud:
		var hl := CanvasLayer.new()
		hl.layer = Layer.Hud
		var msg_frm := MessageFrame.new()
		msg_frm.create()
		msg_frm._show(true)
		msg_frm.view(msg_frame.get_view(), true)
		msg_frm.enable(false)
		msg_frm.skip(skip)
		msg_frm.auto_mode(auto_mode)
		msg_frm.apply_sequence(msg_sequence)
		msg_frm.output(
			msg_frame.mspr_name.message,
			msg_frame.mspr_mess.message,
			true)
		if msg_frame.is_show_blink():
			msg_frm.is_shown_blink_hit = true
			msg_frm.spr_blink.position = msg_frame.spr_blink.position
			msg_frm.spr_blink.modulate.a = 1.0
		hl.add_child(msg_frm)
		for spr in spr_select:
			var sel := Global.frame_skin.create_form_page(&"ID_PAGE_ADVSELECT")
			sel.pivot_offset = spr.pivot_offset
			sel.position = spr.position
			sel.name = spr.name
			var sel_text: MessageSprite = sel.get_node("ID_TEXT")
			var choice: MessageSprite = spr.get_node("ID_TEXT")
			sel_text.output_message(choice.message)
			hl.add_child(sel)
		capture_viewport.add_child(hl)
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	return capture_viewport.get_texture()

func destroy_capture() -> void:
	for child in capture_viewport.get_children():
		if child is CanvasLayer:
			var msg_frm: MessageFrame = child.get_child(0)
			msg_frm.destroy()
	capture_viewport.queue_free()
