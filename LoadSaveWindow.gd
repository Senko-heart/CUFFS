class_name LoadSaveWindow
extends Control

const ScreenEffect := ConfigDataBase.ScreenEffect
const GameLogic := Global.GameLogic

var spr_frame: Control
var spr_thumb: Array[Sprite2D]
var spr_thumb_base: Array[Sprite2D]
var thumb_mask: Texture2D
var is_load: bool

var ID_QSAVE: BaseButton
var ID_SCROLL: ModScroll
var ID_SELECT: Array[BaseButton] = []
var ID_NEW: Array[TextureRect] = []
var ID_NUMBER: Array[MessageSprite] = []
var ID_DATE: Array[MessageSprite] = []
var ID_COMMENT: Array[MessageSprite] = []

func _init(parent: Node, load_: bool) -> void:
	is_load = load_
	if is_load:
		spr_frame = Global.frame_skin.create_form_page("ID_PAGE_LOAD")
		ID_QSAVE = spr_frame.get_node("ID_QSAVE")
		if not Global.sc_obj_qsave:
			ID_QSAVE.hide()
			ID_QSAVE.modulate.a = 0.0
	else:
		spr_frame = Global.frame_skin.create_form_page("ID_PAGE_SAVE")
	spr_frame.modulate.a = 0.0
	spr_frame.hide()
	ID_SCROLL = spr_frame.get_node("ID_SCROLL")
	ID_SCROLL.max_value = (Global.SAVE_NUM - 9) / 3
	for i in range(1, 10):
		var id_select: Control = spr_frame.get_node("ID_SELECT%02d" % i)
		ID_SELECT.append(id_select.get_node("ID_SELECT"))
		ID_NEW.append(id_select.get_node("ID_NEW"))
		ID_NUMBER.append(id_select.get_node("ID_NUMBER"))
		ID_DATE.append(id_select.get_node("ID_DATE"))
		ID_COMMENT.append(id_select.get_node("ID_COMMENT"))
	var thumb_mask_img := FS.load_mask_image("FRM_0510_")
	thumb_mask = ImageTexture.create_from_image(thumb_mask_img)
	for i in range(9):
		var thumb := Sprite2D.new()
		thumb.centered = false
		var thumb_base := Sprite2D.new()
		thumb_base.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
		thumb_base.position = Vector2(i % 3 * 224 + 95, i / 3 * 174 + 34)
		thumb_base.texture = thumb_mask
		thumb_base.centered = false
		thumb_base.add_child(thumb)
		spr_thumb.append(thumb)
		spr_thumb_base.append(thumb_base)
	for child in spr_frame.get_children():
		if child != ID_SCROLL: child.reparent(ID_SCROLL)
	add_child(spr_frame)
	for thumb_base in spr_thumb_base: spr_frame.add_child(thumb_base)
	spr_frame.pivot_offset = 0.5 * spr_frame.size
	spr_frame.position = 0.5 * (Vector2(Global.screen_size) - spr_frame.size)
	set_page((Global.sys_obj.new_bookmark_index - 1) / 3 - 1)
	parent.add_child(self)

func _ready() -> void:
	ID_SCROLL.enable_container_mode()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up", true):
		Input.action_release("ui_up")
	elif event.is_action_pressed("ui_down", true):
		Input.action_release("ui_down")

func destroy() -> void:
	Anim.destroy(spr_frame)
	Anim.destroy(self)

func _show() -> void:
	spr_frame.show()
	if Global.cnf_obj.screen_effect == ScreenEffect.Normal:
		Anim.schedule_scale(spr_frame, Vector2(0.95, 0.95), Vector2.ONE)
		Anim.schedule_fade(spr_frame, 1.0)
		await Anim.run(0.3)
	else:
		Anim.kill(spr_frame)
		spr_frame.modulate.a = 1.0

func _hide() -> void:
	if Global.cnf_obj.screen_effect == ScreenEffect.Normal:
		Anim.schedule_scale(spr_frame, Vector2.ONE, Vector2(0.95, 0.95))
		Anim.schedule_fade(spr_frame, 0.0)
		await Anim.run(0.3)
	else:
		Anim.kill(spr_frame)
		spr_frame.modulate.a = 0.0
	spr_frame.hide()

func set_page(index: int) -> void:
	ID_SCROLL.value = index
	index = int(ID_SCROLL.value)
	var start_save_index := index * 3 + 1
	for i in range(9):
		ID_NUMBER[i].output_message(Global.create_num_string(
			start_save_index + i, 2, true, true
		))
		var save_index := start_save_index + i - 1
		if Global.sc_objects[save_index]:
			spr_thumb[i].texture = Global.sc_obj_thumb_textures[save_index];
			spr_thumb[i].scale = Vector2(120, 90) / spr_thumb[i].texture.get_size()
			spr_thumb_base[i].show()
			var sc_obj := Global.sc_objects[save_index]
			ID_DATE[i].output_message(
				Global.create_time_string(sc_obj.unix_time))
			var comment := sc_obj.comment.replace("\n", "").replace("  ", "　")
			if comment.length() > 20:
				comment = comment.left(19) + "…"
			comment = Global.adjust_string(comment, 10)
			ID_COMMENT[i].output_message(comment)
			if start_save_index + i == Global.sys_obj.new_bookmark_index:
				ID_NEW[i].show()
			else:
				ID_NEW[i].hide()
			ID_SELECT[i].disabled = false
		else:
			spr_thumb_base[i].hide()
			ID_DATE[i].output_message("")
			ID_COMMENT[i].output_message("")
			ID_NEW[i].hide()
			ID_SELECT[i].disabled = is_load

func loadsave(save_index: int) -> GameLogic:
	if is_load:
		if await Global.confirm(Global.confirm_prompt.load % (save_index + 1)):
			await Global.normal_load(save_index)
			return GameLogic.Load
	elif Global.sc_objects[save_index]:
		if await Global.confirm(Global.confirm_prompt.save % (save_index + 1)):
			await Global.normal_save(save_index)
			set_page(int(ID_SCROLL.value))
	else:
		await Global.normal_save(save_index)
		set_page(int(ID_SCROLL.value))
	return GameLogic.Unaffected

func run() -> GameLogic:
	while true:
		var control := await Global.poll_ui_event()
		var cid: String = control.name if control else ""
		if cid == "ID_SELECT":
			var index := int(ID_SCROLL.value)
			var save_index := 3 * index + ID_SELECT.find(control)
			var ret := await loadsave(save_index)
			if ret != GameLogic.Unaffected:
				return ret
		elif control == ID_SCROLL:
			set_page(int(ID_SCROLL.value))
		elif Input.is_action_just_pressed("ui_up"):
			var index := int(ID_SCROLL.value)
			set_page(index - 1)
		elif Input.is_action_just_pressed("ui_down"):
			var index := int(ID_SCROLL.value)
			set_page(index + 1)
		elif cid == "ID_QSAVE" or Input.is_action_pressed("quick_load"):
			if Global.sc_obj_qsave:
				if await Global.confirm(Global.confirm_prompt.qload):
					await Global.quick_load()
					return GameLogic.Load
		elif Input.is_action_pressed("hit_cancel"):
			break
	return GameLogic.Unaffected
