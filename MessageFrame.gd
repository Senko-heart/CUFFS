class_name MessageFrame
extends Control

const ScreenEffect := ConfigDataBase.ScreenEffect

var is_create := false
var is_show := false
var spr_frame: TextureRect
var spr_base_0: TextureRect
var spr_base_1: TextureRect
var spr_menu: Control
var spr_close: Control
var spr_voice: Control
var mspr_name := MessageSprite.new()
var mspr_mess := MessageSprite.new()
var spr_blink: TextureRect
var pre_name := ""
var is_shown_blink_hit := false
var view_0 := true

var ID_CLOSE: ModButton
var ID_VOICE: ModButton
var ID_QSAVE: ModButton
var ID_QLOAD: ModButton
var ID_SAVE: ModButton
var ID_LOAD: ModButton
var ID_CONFIG: ModButton
var ID_AUTO: ModButton
var ID_SKIP: ModButton
var ID_HISTORY: ModButton

func _init() -> void:
	spr_frame = Global.frame_skin.create_texture_rect(&"ID_FRM_0101")
	spr_base_0 = Global.frame_skin.create_texture_rect(&"ID_FRM_0102B")
	spr_base_1 = Global.frame_skin.create_texture_rect(&"ID_FRM_0106B")
	spr_menu = Global.frame_skin.create_form_page(&"ID_PAGE_ADV_MENU")
	spr_menu.position = Vector2(9, 124)
	spr_menu.show()
	spr_close = Global.frame_skin.create_form_page(&"ID_PAGE_ADV_CLOSE")
	spr_close.position = Vector2(727, 7)
	spr_close.show()
	spr_voice = Global.frame_skin.create_form_page(&"ID_PAGE_ADV_VOICE")
	spr_voice.position = Vector2(689, 6)
	spr_voice.modulate.a = 0.0
	spr_voice.show()
	mspr_name.create_message(320, 36)
	mspr_name.attach_message_style(Global.frame_skin, &"ID_FONT_NAME")
	mspr_name.position = Vector2(27, 5)
	mspr_name.add_theme_constant_override(&"outline_size", 4)
	mspr_mess.add_theme_constant_override(&"shadow_outline_size", 2)
	mspr_name.set_default_msg_speed(0, 0, 256)
	mspr_mess.create_message(684, 90)
	mspr_mess.attach_message_style(Global.frame_skin, &"ID_FONT_MESSAGE")
	mspr_mess.position = Vector2(39, 40)
	mspr_mess.add_theme_constant_override(&"outline_size", 2)
	mspr_mess.add_theme_constant_override(&"shadow_outline_size", 1)
	mspr_mess.nvl_effect = true
	mspr_mess.set_default_msg_speed(0, 0, 256)
	spr_blink = Global.frame_skin.create_texture_rect(&"ID_FRM_0103")
	
	pivot_offset = 0.5 * spr_frame.texture.get_size()
	position = Vector2(400, 520) - pivot_offset
	hide()
	
	ID_CLOSE = spr_close.get_node("ID_CLOSE")
	ID_CLOSE.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	ID_VOICE = spr_voice.get_node("ID_VOICE")
	ID_VOICE.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	for child in spr_menu.get_children():
		set(child.name, child)
		if child is ModButton:
			child.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	ID_AUTO.toggle_mode = true
	
	add_child(spr_frame)
	add_child(spr_base_0)
	add_child(spr_base_1)
	add_child(spr_menu)
	add_child(spr_close)
	add_child(spr_voice)
	add_child(mspr_name)
	add_child(mspr_mess)
	add_child(spr_blink)

func create() -> void:
	enable_qload(Global.sc_obj_qsave != null)
	enable(true)
	spr_base_0.modulate.a = Global.cnf_obj.window_depth
	spr_base_1.modulate.a = 0.0
	modulate.a = 0.0
	var disable := Global.is_recollect_mode()
	var alpha := 0.5 if disable else 1.0
	ID_QSAVE.modulate.a = alpha
	ID_QSAVE.disabled = disable
	ID_QLOAD.modulate.a = alpha
	ID_QLOAD.disabled = disable
	ID_SAVE.modulate.a = alpha
	ID_SAVE.disabled = disable
	ID_LOAD.modulate.a = alpha
	ID_LOAD.disabled = disable
	mspr_name.output_message("")
	mspr_mess.apply_sequence({})
	mspr_mess.output_message("")
	hide_voice()
	hide_blink()
	skip(false)
	auto_mode(false)
	view_0 = true
	is_show = false
	is_create = true

func destroy() -> void:
	Anim.kill(self)
	Anim.kill(spr_base_0)
	Anim.kill(spr_base_1)
	Anim.kill(spr_blink)
	Anim.kill(spr_voice)
	hide()
	is_show = false
	is_create = false

func _skip_animation(flush: bool) -> bool:
	return (flush or Global.adv.is_skip()
		or Global.cnf_obj.screen_effect == ScreenEffect.None
		or Input.is_action_pressed("fast_forward"))

func _show(flush: bool = false) -> void:
	Anim.kill(self)
	if modulate.a == 1.0:
		return
	show()
	if _skip_animation(flush):
		modulate.a = 1.0
	else:
		Anim.schedule(self, {
			scale = {
				base = Vector2(0.95, 0.95),
				target = Vector2.ONE,
				accel = Vector2(3.0, 0.0) },
			alpha = { target = 1.0 }
		})
		await Anim.run(0.3)
	if modulate.a == 1.0:
		is_show = true

func _hide(flush: bool = false) -> void:
	Anim.kill(self)
	if modulate.a == 0.0:
		return
	if _skip_animation(flush):
		modulate.a = 0.0
	else:
		await Anim.fade(self, 0.0, 0.3)
	if modulate.a == 0.0:
		hide()
		is_show = false

func view(type: int, flush: bool = false) -> void:
	if not(0 <= type and type <= 1): return
	var old_view := spr_base_0 if view_0 else spr_base_1
	if _skip_animation(flush):
		Anim.kill(old_view)
		old_view.modulate.a = 0.0
	else:
		Anim.fade(old_view, 0.0, 0.3)
	view_0 = type == 0
	var new_view := spr_base_0 if view_0 else spr_base_1
	var alpha := Global.cnf_obj.window_depth
	if _skip_animation(flush):
		Anim.kill(new_view)
		new_view.modulate.a = alpha
	else:
		Anim.fade(new_view, alpha, 0.3)

func get_view() -> int:
	return int(not view_0)

func show_blink() -> void:
	is_shown_blink_hit = true
	var pos := mspr_mess.position + mspr_mess.cursor_pos()
	spr_blink.position = pos
	if Global.cnf_obj.screen_effect == ScreenEffect.Normal:
		await Anim.fade(spr_blink, 1.0, 0.5)
	else:
		Anim.kill(spr_blink)
		spr_blink.modulate.a = 1.0

func hide_blink() -> void:
	Anim.kill(spr_blink)
	spr_blink.modulate.a = 0.0
	is_shown_blink_hit = false

func is_show_blink() -> bool:
	return is_shown_blink_hit

func show_voice() -> void:
	var pos := mspr_name.position + mspr_name.cursor_pos()
	spr_voice.position = pos + Vector2(4, 8)
	if Global.cnf_obj.screen_effect == ScreenEffect.Normal:
		await Anim.fade(spr_voice, 1.0, 0.5)
	else: spr_voice.modulate.a = 1.0

func hide_voice() -> void:
	Anim.kill(spr_voice)
	spr_voice.modulate.a = 0.0

func transparency_base(alpha: float) -> void:
	if not is_create: return
	var base := spr_base_0 if view_0 else spr_base_1
	base.modulate.a = alpha

func apply_sequence(seq: Dictionary) -> void:
	mspr_mess.apply_sequence(seq)

func output(name_: String, mess: String, flush: bool) -> void:
	if flush: mspr_mess.set_default_msg_speed(0, 0)
	else: mspr_mess.set_default_msg_speed(Global.cnf_obj.message_speed, 50)
	if pre_name != name_:
		mspr_name.output_message(name_)
		pre_name = name_
	mspr_mess.output_message(mess)

func clear_page() -> void:
	mspr_mess.message = ""

func is_pending() -> bool:
	return not mspr_mess.message_ended

func flush_() -> void:
	mspr_mess.message_ended = true

func skip(skipping: bool) -> void:
	ID_SKIP.disabled = skipping

func enable(enabled: bool) -> void:
	for pinf in get_property_list():
		var prop: Variant = get(pinf.name)
		if prop is ModButton:
			prop.noninteractive = not enabled

func auto_mode(autoplay: bool) -> void:
	ID_AUTO.button_pressed = autoplay

func enable_qload(enabled: bool) -> void:
	ID_QLOAD.modulate.a = 1.0 if enabled else 0.5
	ID_QLOAD.disabled = not enabled
