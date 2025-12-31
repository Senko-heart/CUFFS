class_name HistoryWindow
extends Control

const ScreenEffect := ConfigDataBase.ScreenEffect

var spr_frame: Control
var spr_voice: Array[ModButton]
var mspr_name: Array[MessageSprite]
var mspr_message: Array[MessageSprite]
var index := 0
var index_range := 0
var page_pointer := 0

var ID_SCROLL: ModScroll

func _init(parent: Node) -> void:
	spr_frame = Global.frame_skin.create_form_page(&"ID_PAGE_HISTORY")
	add_child(spr_frame)
	position = 0.5 * (Vector2(Global.screen_size) - spr_frame.size)
	pivot_offset = 0.5 * spr_frame.size
	modulate.a = 0.0
	ID_SCROLL = spr_frame.get_node("ID_SCROLL")
	for i in range(4):
		var hv := Global.frame_skin.create_form_page(&"ID_PAGE_HISTORY_VOICE")
		var voice: ModButton = hv.get_node("ID_VOICE")
		voice.name += str(i + 1)
		voice.hide()
		voice.reparent(self)
		spr_voice.append(voice)
		hv.free()
	for i in range(4):
		var _name := MessageSprite.new()
		_name.create_message(701 - 19, 34)
		_name.position = Vector2(19, 2 + i * 128)
		_name.attach_message_style(Global.frame_skin, &"ID_FONT_NAME")
		add_child(_name)
		mspr_name.append(_name)
		var mess := MessageSprite.new()
		mess.create_message(701 - 14, 78)
		mess.position = Vector2(14, 37 + i * 128)
		mess.attach_message_style(Global.frame_skin, &"ID_FONT_MESSAGE")
		add_child(mess)
		mspr_message.append(mess)
	index_range = Global.sc_obj.name_log.num() - 4
	if index_range <= 0:
		ID_SCROLL.hide()
		index_range = 0
	else:
		ID_SCROLL.max_value = index_range
		ID_SCROLL.value = index_range
	set_page(index)
	parent.add_child(self)

func _ready() -> void:
	ID_SCROLL.enable_container_mode()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up", true):
		Input.action_release("ui_up")
	elif event.is_action_pressed("ui_down", true):
		Input.action_release("ui_down")

func destroy() -> void:
	Anim.destroy(self)

func _show() -> void:
	if Global.cnf_obj.screen_effect == ScreenEffect.Normal:
		Anim.schedule(self, {
			scale = {
				target = Vector2.ONE,
				base = Vector2(1.0, 0.95),
				accel = Vector2(3.0, 0.0) },
			alpha = { target = 1.0 }
		})
		await Anim.run(0.3)
	else:
		Anim.kill(self)
		modulate.a = 1.0

func _hide() -> void:
	if Global.cnf_obj.screen_effect == ScreenEffect.Normal:
		await Anim.fade(self, 0.0, 0.3)
	else:
		Anim.kill(self)
		modulate.a = 0.0

func run() -> void:
	var play_voice := false
	while true:
		var control := await Global.poll_ui_event()
		var cid := control.name if control else &""
		if Input.is_action_just_pressed("hit_cancel"):
			break
		elif cid == "ID_SCROLL":
			if index != index_range - int(ID_SCROLL.value):
				index = index_range - int(ID_SCROLL.value)
				set_page(index)
		elif Input.is_action_just_pressed("ui_up"):
			if index < index_range:
				index += 1
				ID_SCROLL.value = index_range - index
				set_page(index)
		elif Input.is_action_just_pressed("ui_down"):
			if index == 0:
				break
			else:
				index -= 1
				ID_SCROLL.value = index_range - index
				set_page(index)
		elif cid == "ID_VOICE1":
			SoundSystem.play_voice(Global.sc_obj.voice_log.nth_back(page_pointer - 0), true)
			play_voice = true
		elif cid == "ID_VOICE2":
			SoundSystem.play_voice(Global.sc_obj.voice_log.nth_back(page_pointer - 1), true)
			play_voice = true
		elif cid == "ID_VOICE3":
			SoundSystem.play_voice(Global.sc_obj.voice_log.nth_back(page_pointer - 2), true)
			play_voice = true
		elif cid == "ID_VOICE4":
			SoundSystem.play_voice(Global.sc_obj.voice_log.nth_back(page_pointer - 3), true)
			play_voice = true
	if play_voice:
		SoundSystem.stop_voice()

func set_page(_index: int) -> void:
	var num := Global.sc_obj.mess_log.num()
	if index_range == 0:
		page_pointer = num - 1
	else:
		page_pointer = 4 + _index - 1
	for i in range(4):
		mspr_message[i].clear()
		var seq := Global.sc_obj.seq_log.nth_back(page_pointer - i)
		if not seq.is_empty():
			mspr_message[i].apply_sequence(JSON.parse_string(seq))
		var message := Global.sc_obj.mess_log.nth_back(page_pointer - i)
		if not message.is_empty():
			var mess := TranslationTable.mess(message.to_int())
			mspr_message[i].output_message(mess)
	for i in range(4):
		var alias_name := Global.sc_obj.name_log.nth_back(page_pointer - i)
		var show_name: String = Global.check_true_name(alias_name).show_name
		mspr_name[i].output_message(show_name)
		await mspr_name[i].finished
		if Global.sc_obj.voice_log.nth_back(page_pointer - i).is_empty():
			spr_voice[i].hide()
		else:
			spr_voice[i].show()
			spr_voice[i].position = (Vector2(4, 9)
				+ mspr_name[i].position
				+ mspr_name[i].cursor_pos())
