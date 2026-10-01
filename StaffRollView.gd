class_name StaffRollView
extends CanvasLayer

class StaffRollSpriteTask:
	var type: int
	var spr_base := TextureRect.new()
	var spr_pic := Sprite2D.new()
	var begin_time: float
	var life_time: float
	var status: int
	var file := ""
	var pt_start := Vector2.ZERO
	var pt_end := Vector2.ZERO
	
	func _init() -> void:
		spr_base.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
		spr_pic.centered = false

var exit := false
var begin_time := Time.get_ticks_usec()
var sound := Sound.new(self)
var task: Array[StaffRollSpriteTask] = []

func _init(parent: Node) -> void:
	parent.add_child(self)

func elapsed_time() -> float:
	return (Time.get_ticks_usec() - begin_time) * 1e-6

func black(x: int, y: int) -> Texture2D:
	return Global.create_color_texture(Color.BLACK, Vector2i(x, y))

func set0(
	type: int, start: float, life: float = 0.0,
	res: Variant = null,
	pt_start: Vector2 = Vector2.ZERO,
	pt_end: Vector2 = pt_start,
	pos: int = 0, pt_center: Vector2 = Vector2.ZERO
) -> void:
	if exit:
		return
	var r_task := StaffRollSpriteTask.new()
	task.append(r_task)
	r_task.type = type
	r_task.begin_time = start
	r_task.life_time = start + life
	r_task.status = 1
	if res is String:
		r_task.file = res
		r_task.spr_pic.texture = FS.load_texture(res)
	elif res is Texture2D:
		r_task.spr_pic.texture = res
	var pic_texture := r_task.spr_pic.texture
	var pic_size := pic_texture.get_size() if pic_texture else Vector2.ZERO
	r_task.pt_start = pt_start
	r_task.pt_end = pt_end
	if type == 1:
		if pt_start.x == -1:
			pt_start.x = Global.screen_size.x / 2
		if pt_start.y == -1:
			pt_start.y = Global.screen_size.y / 2
		r_task.spr_base.position = pt_start - 0.5 * pic_size
		r_task.spr_base.modulate.a = 0.0
		Anim.schedule_fade(r_task.spr_base, 1.0)
	elif type == 2:
		r_task.spr_pic.position = 0.5 * (Vector2(306, 600) - pic_size)
		r_task.spr_base.texture = black(306, 600)
		r_task.spr_base.position = pt_start
		r_task.spr_base.modulate.a = 0.0
		Anim.schedule_fade(r_task.spr_base, 1.0)
		Anim.schedule_move(r_task.spr_base, pt_end)
	elif type == 3:
		r_task.spr_pic.position = pt_center - Vector2(pos, 0)
		r_task.spr_pic.offset = -pt_center
		Anim.schedule_linear_scale(r_task.spr_pic, Vector2.ONE, Vector2(1.5, 1.5))
		r_task.spr_base.texture = black(494, 600)
		r_task.spr_base.position = pt_start
		r_task.spr_base.modulate.a = 0.0
		Anim.schedule_fade(r_task.spr_base, 1.0)
		Anim.schedule_move(r_task.spr_base, pt_end)
	elif type == 4:
		r_task.spr_base.texture = black(800, 230)
		r_task.spr_pic.position = 0.5 * (Vector2(800, 230) - pic_size)
		r_task.spr_base.position = pt_start
		r_task.spr_base.modulate.a = 0.0
		Anim.schedule_fade(r_task.spr_base, 1.0)
		Anim.schedule_move(r_task.spr_base, pt_end)
	elif type == 5:
		r_task.spr_pic.position = pt_center - Vector2(0, pos)
		r_task.spr_pic.offset = -pt_center
		Anim.schedule_linear_scale(r_task.spr_pic, Vector2.ONE, Vector2(1.5, 1.5))
		r_task.spr_base.texture = black(800, 370)
		r_task.spr_base.position = pt_start
		r_task.spr_base.modulate.a = 0.0
		Anim.schedule_fade(r_task.spr_base, 1.0)
		Anim.schedule_move(r_task.spr_base, pt_end)
	elif type == 6:
		r_task.spr_pic.position = pt_center - Vector2(0, pos)
		r_task.spr_pic.offset = -pt_center
		Anim.schedule_linear_scale(r_task.spr_pic, Vector2.ONE, Vector2(1.5, 1.5))
		r_task.spr_base.texture = black(int(pic_size.x), int(pic_size.y))
		r_task.spr_base.position = pt_start
		r_task.spr_base.modulate.a = 0.0
		Anim.schedule_fade(r_task.spr_base, 1.0)
	else: return
	r_task.spr_base.add_child(r_task.spr_pic)
	add_child(r_task.spr_base)

func set1(type: int, start: float, life: float = 0.0,
	res: Variant = null,
	pt_start: Vector2 = Vector2.ZERO,
	pt_end: Vector2 = pt_start,
	pos: int = 0, pt_center: Vector2 = Vector2.ZERO
) -> void:
	if exit:
		return
	set0(type, start, life, res, pt_start, pt_end, pos, pt_center)
	var start_time := task[-1].begin_time
	while elapsed_time() < start_time:
		await get_tree().process_frame
		if Input.is_action_just_pressed("hit_cancel"):
			exit = true
			return
		loop_proc()
		destroy_proc()
	loop_proc()
	destroy_proc()

func loop_proc(elapsed: float = elapsed_time()) -> void:
	for r_task in task:
		if elapsed >= r_task.life_time:
			if r_task.status == 2:
				Anim.kill(r_task.spr_base)
				Anim.fade(r_task.spr_base, 0.0, 0.5)
				r_task.status = 3
			elif r_task.status == 3:
				if not Anim.is_animated(r_task.spr_base):
					r_task.status = 4
		elif elapsed >= r_task.begin_time:
			if r_task.status == 1:
				if r_task.type == 1:
					Anim.run(0.5, [r_task.spr_base])
				elif r_task.type == 2:
					Anim.run(0.5, [r_task.spr_base])
				elif r_task.type == 3:
					Anim.run(0.5, [r_task.spr_base])
					Anim.run(50, [r_task.spr_pic])
				elif r_task.type == 4:
					Anim.run(0.5, [r_task.spr_base])
				elif r_task.type == 5:
					Anim.run(0.5, [r_task.spr_base])
					Anim.run(50, [r_task.spr_pic])
				elif r_task.type == 6:
					Anim.run(0.5, [r_task.spr_base])
					Anim.run(50, [r_task.spr_pic])
				r_task.status = 2

func destroy_proc(force: bool = false) -> void:
	var i := 0
	while i < task.size():
		if task[i].status == 4 or force:
			Anim.destroy(task[i].spr_pic)
			Anim.destroy(task[i].spr_base)
			task[i] = task.back()
			task.pop_back()
		else: i += 1

func run(type: int) -> void:
	exit = false
	layer = Global.Layer.Movie
	if Global.cnf_obj.play_bgm:
		FS.load_bgm("BGM02", sound, false)
		sound.volume_linear = Global.cnf_obj.vol_bgm
		sound.play()
	Global.adv.hide_message(true)
	var adv_screen := await Global.adv.create_capture(false)
	if type == 4:
		await set1(1, 5, 10, "title", Vector2(-1, -1))
	elif type == 8:
		await set1(1, 5, 10, "title", Vector2(-1, -1))
	elif type == 9:
		await set1(1, 5, 10, "title", Vector2(-1, 330))
	set0(2, 14, 12, "FRM_0901", Vector2(131, 0), Vector2(0, 0))
	if type == 4:
		await set1(3, 14, 12, adv_screen, Vector2(131, 0), Vector2(306, 0), 140, Vector2(202, 256))
	elif type == 8:
		await set1(3, 14, 12, adv_screen, Vector2(154, 0), Vector2(306, 0), 174, Vector2(372, 51))
	elif type == 9:
		await set1(3, 14, 12, adv_screen, Vector2(154, 0), Vector2(306, 0), 64, Vector2(166, 66))
	set0(4, 24, 14, "FRM_0902", Vector2(0, 370 - 100), Vector2(0, 370))
	if type == 4:
		await set1(5, 24, 23, "B07a", Vector2(0, 100), Vector2(0, 0), 101, Vector2(195, 154))
	elif type == 8:
		await set1(5, 24, 23, "B15a", Vector2(0, 100), Vector2(0, 0), 94, Vector2(138, 167))
	elif type == 9:
		await set1(5, 24, 23, "B19a", Vector2(0, 100), Vector2(0, 0), 63, Vector2(226, 122))
	Global.adv.destroy_capture()
	Global.destroy_adv_screen()
	await set1(4, 34, 14, "FRM_0903", Vector2(0, 370))
	set0(2, 44, 14, "FRM_0904", Vector2(494 - 100, 0), Vector2(494, 0))
	if type == 4:
		await set1(3, 44, 33, "EA19a", Vector2(100, 0), Vector2(0, 0), 233, Vector2(236, 159))
	elif type == 8:
		await set1(3, 44, 33, "EZ07a", Vector2(100, 0), Vector2(0, 0), 22, Vector2(223, 26))
	elif type == 9:
		await set1(3, 44, 33, "EZ20", Vector2(100, 0), Vector2(0, 0), 69, Vector2(177, 63))
	await set1(2, 54, 14, "FRM_0905", Vector2(494, 0))
	await set1(2, 64, 14, "FRM_0906", Vector2(494, 0))
	set0(4, 74, 14, "FRM_0907", Vector2(0, 100), Vector2(0, 0))
	if type == 4:
		await set1(5, 74, 23, "B12a", Vector2(0, 230 - 100), Vector2(0, 230), 141, Vector2(569, 175))
	elif type == 8:
		await set1(5, 74, 23, "B39a", Vector2(0, 230 - 100), Vector2(0, 230), 110, Vector2(611, 140))
	elif type == 9:
		await set1(5, 74, 23, "B17a", Vector2(0, 230 - 100), Vector2(0, 230), 137, Vector2(588, 104))
	await set1(4, 84, 14, "FRM_0908", Vector2(0, 0))
	set0(2, 94, 14, "FRM_0909", Vector2(131, 0), Vector2(0, 0))
	if type == 4:
		await set1(3, 94, 33, "EA20a", Vector2(131, 0), Vector2(306, 0), 157, Vector2(227, 280))
	elif type == 8:
		await set1(3, 94, 33, "EZ08a", Vector2(131, 0), Vector2(306, 0), 0, Vector2(0, 60))
	elif type == 9:
		await set1(3, 94, 33, "EZ22a", Vector2(131, 0), Vector2(306, 0), 0, Vector2(119, 98))
	await set1(2, 104, 14, "FRM_0910", Vector2(0, 0), Vector2(0, 0))
	await set1(2, 114, 14, "FRM_0911", Vector2(0, 0), Vector2(0, 0))
	set0(4, 124, 14, "FRM_0912", Vector2(0, 370 - 100), Vector2(0, 370))
	if type == 4:
		await set1(5, 124, 23, "B01a", Vector2(0, 100), Vector2(0, 0), 60, Vector2(313, 235))
	elif type == 8:
		await set1(5, 124, 23, "B35b", Vector2(0, 100), Vector2(0, 0), 143, Vector2(20, 180))
	elif type == 9:
		await set1(5, 124, 23, "B48a", Vector2(0, 100), Vector2(0, 0), 201, Vector2(681, 83))
	await set1(4, 134, 14, "FRM_0913", Vector2(0, 370))
	set0(2, 144, 14, "FRM_0914", Vector2(494 - 100, 0), Vector2(494, 0))
	if type == 4:
		await set1(3, 144, 33, "EA21a", Vector2(100, 0), Vector2(0, 0), 0, Vector2(196, 166))
	elif type == 8:
		await set1(3, 144, 33, "EZ09a", Vector2(100, 0), Vector2(0, 0), 0, Vector2(414, 30))
	elif type == 9:
		await set1(3, 144, 33, "EZ23a", Vector2(100, 0), Vector2(0, 0), 221, Vector2(474, 14))
	await set1(2, 154, 14, "FRM_0915", Vector2(494, 0))
	await set1(2, 164, 14, "FRM_0916", Vector2(494, 0))
	set0(4, 174, 14, "FRM_0917", Vector2(0, 100), Vector2(0, 0))
	if type == 4:
		await set1(5, 174, 23, "B44a", Vector2(0, 230 - 100), Vector2(0, 230), 184, Vector2(206, 109))
	elif type == 8:
		await set1(5, 174, 23, "B41c", Vector2(0, 230 - 100), Vector2(0, 230), 156, Vector2(396, 180))
	elif type == 9:
		await set1(5, 174, 23, "B43a", Vector2(0, 230 - 100), Vector2(0, 230), 22, Vector2(400, 0))
	await set1(4, 184, 14, "FRM_0918", Vector2(0, 0))
	set0(2, 194, 14, "FRM_0919", Vector2(131, 0), Vector2(0, 0))
	if type == 4:
		await set1(3, 194, 33, "EA22a", Vector2(131, 0), Vector2(306, 0), 163, Vector2(353, 194))
	elif type == 8:
		await set1(3, 194, 33, "EZ10", Vector2(131, 0), Vector2(306, 0), 194, Vector2(260, 0))
	elif type == 9:
		await set1(3, 194, 33, "EZ21d", Vector2(131, 0), Vector2(306, 0), 0, Vector2(0, 0))
	await set1(2, 204, 14, "FRM_0920", Vector2(0, 0), Vector2(0, 0))
	await set1(2, 214, 14, "FRM_0921", Vector2(0, 0), Vector2(0, 0))
	set0(4, 224, 14, "FRM_0922", Vector2(0, 370 - 100), Vector2(0, 370))
	if type == 4:
		await set1(5, 224, 23, "B46a", Vector2(0, 100), Vector2(0, 0), 183, Vector2(416, 135))
	elif type == 8:
		await set1(5, 224, 23, "B47a", Vector2(0, 100), Vector2(0, 0), 128, Vector2(407, 166))
	elif type == 9:
		await set1(5, 224, 23, "B23a", Vector2(0, 100), Vector2(0, 0), 150, Vector2(83, 169))
	await set1(4, 234, 14, "FRM_0923", Vector2(0, 370))
	if type == 4:
		await set1(6, 244, 27, "EA23a", Vector2(0, 0), Vector2(0, 0), 0, Vector2(400, 0))
	elif type == 8:
		await set1(6, 244, 27, "EZ11", Vector2(0, 0), Vector2(0, 0), 0, Vector2(538, 77))
	elif type == 9:
		await set1(6, 244, 27, "EZ24a", Vector2(0, 0), Vector2(0, 0), 0, Vector2(190, 0))
	await set1(1, 244, 10, "FRM_0924", Vector2(-1, -1))
	await set1(1, 254, 7, "FRM_0925", Vector2(-1, -1))
	await set1(1, 264, 7, "FRM_0926", Vector2(-1, -1))
	await set1(1, 272, 7, "FRM_0602", Vector2(-1, -1))
	await set1(0, 280)
	destroy_proc(true)
	queue_free()
	Global.setup_adv_screen()
