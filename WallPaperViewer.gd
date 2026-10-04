class_name WallPaperViewer
extends Control

const ScreenEffect = ConfigDataBase.ScreenEffect

var page := 0
var spr_board: TextureRect
var spr_tag: Control
var spr_tags: Array[ModButton]
var spr_thumb: Array[Control]
var spr_cg := TextureRect.new()
static var pt_thumb: PackedVector2Array = [Vector2(409, 172), Vector2(176, 201),
		Vector2(628, 267), Vector2(199, 424), Vector2(430, 422)]
var option_skin := Global.option_skin

func _init(parent: Node) -> void:
	modulate.a = 0.0
	parent.add_child(self)
	spr_board = option_skin.create_texture_rect(&"ID_FRM_0801")
	add_child(spr_board)
	spr_tag = option_skin.create_form_page(&"ID_PAGE_WALLTAG")
	spr_tag.position = Vector2(534, 504)
	add_child(spr_tag)
	for child_name: String in ["ID_TAG1", "ID_TAG2", "ID_TAG3", "ID_TAG4"]:
		spr_tags.append(spr_tag.get_node(child_name))
	spr_thumb.append(option_skin.create_form_page(&"ID_PAGE_WALLTHUMB1"))
	spr_thumb.append(option_skin.create_form_page(&"ID_PAGE_WALLTHUMB2"))
	spr_thumb.append(option_skin.create_form_page(&"ID_PAGE_WALLTHUMB3"))
	spr_thumb.append(option_skin.create_form_page(&"ID_PAGE_WALLTHUMB4"))
	spr_thumb.append(option_skin.create_form_page(&"ID_PAGE_WALLTHUMB5"))
	for thumb in spr_thumb:
		thumb.pivot_offset_ratio = Vector2(0.5, 0.5)
		add_child(thumb)
	spr_cg.pivot_offset_ratio = Vector2(0.5, 0.5)
	add_child(spr_cg)
	FS.cache_reset(&"wallpaper")
	for i in range(1, 21):
		FS.cache_load_texture("WALL%02d" % i)

func set_page(page_num: int) -> void:
	page = page_num
	for tag in spr_tags:
		tag.disabled = false
	spr_tags[page].disabled = true
	var thm0 := page * 5 + 1
	for i in range(5):
		var thumb := spr_thumb[i]
		var texture := option_skin.get_texture("ID_WALL%02d" % (thm0 + i))
		thumb.get_node("ID_THUMB").texture = texture
		thumb.position = pt_thumb[i] + Vector2(randi() & 15, randi() & 15) - 0.5 * thumb.size
		var _scale := randi_range(90, 100) / 100.0
		thumb.rotation_degrees = randi_range(-10, 10)
		thumb.scale = Vector2(_scale, _scale)
		Anim.kill(thumb)
		thumb.modulate.a = 0.0
		Anim.schedule_fade(thumb, 1.0)
	Anim.run(0.0 if Global.cnf_obj.screen_effect != ScreenEffect.Normal else 0.5)

func show_cg(id: int) -> void:
	var thumb := spr_thumb[id]
	spr_cg.texture = FS.load_texture("WALL%02d" % (page * 5 + id + 1))
	spr_cg.size = spr_cg.texture.get_size()
	spr_cg.position = thumb.position - 0.5 * (spr_cg.size - thumb.size)
	spr_cg.rotation = thumb.rotation
	spr_cg.scale = thumb.scale * thumb.size / spr_cg.size
	spr_cg.modulate.a = 0.5
	spr_cg.show()
	var target_scale := Vector2(Global.screen_size) / spr_cg.size
	Anim.schedule_move(spr_cg, 0.5 * (Vector2(Global.screen_size) - spr_cg.size))
	Anim.schedule_rotate(spr_cg, 0.0)
	Anim.schedule_scale(spr_cg, spr_cg.scale, target_scale)
	Anim.schedule_fade(spr_cg, 1.0)
	Anim.run(0.0 if Global.cnf_obj.screen_effect != ScreenEffect.Normal else 0.5)
	await Global.test_hitret()
	Anim.kill(spr_cg)
	spr_cg.hide()

func run() -> void:
	SoundSystem.play_bgm("BGM15")
	set_page(0)
	if Global.cnf_obj.screen_effect != ScreenEffect.Normal:
		modulate.a = 1.0
	else:
		Anim.fade(self, 1.0, 0.5)
	while true:
		var control := await Global.poll_ui_event()
		var cid := control.name if control != null else &""
		if Input.is_action_just_pressed(&"hit_cancel"):
			break
		elif Input.is_action_just_pressed(&"ui_up"):
			page -= 1
			set_page(3 if page < 0 else page)
		elif Input.is_action_just_pressed(&"ui_down"):
			page += 1
			set_page(0 if page > 3 else page)
		elif cid == &"ID_TAG1":
			if page != 0: set_page(0)
		elif cid == &"ID_TAG2":
			if page != 1: set_page(1)
		elif cid == &"ID_TAG3":
			if page != 2: set_page(2)
		elif cid == &"ID_TAG4":
			if page != 3: set_page(3)
		elif cid == &"ID_BUTTON":
			var num := control.get_parent().name.trim_prefix("ID_PAGE_WALLTHUMB")
			await show_cg(int(num) - 1)
	if Global.cnf_obj.screen_effect != ScreenEffect.Normal:
		modulate.a = 0.0
	else:
		Anim.fade(self, 0.0, 0.5)
		await Anim.finish_flushed(self)
	SoundSystem.stop_bgm()
	FS.cache_reset(&"")
	queue_free()
