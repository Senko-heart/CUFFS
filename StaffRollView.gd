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
	else: return
	r_task.spr_base.add_child(r_task.spr_pic)
	add_child(r_task.spr_base)

func set1(type: int, start: float, life: float = 0.0,
	res: Variant = null,
	pt_start: Vector2 = Vector2.ZERO,
	pt_end: Vector2 = pt_start,
	pos: int = 0, pt_center: Vector2 = Vector2.ZERO
) -> void:
	set0(type, start, life, res, pt_start, pt_end, pos, pt_center)
	var start_time := task[-1].begin_time
	while elapsed_time() < start_time:
		await get_tree().process_frame
		if Input.is_action_just_pressed("hit"):
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
		FS.load_bgm("BGM02", sound)
		sound.volume_linear = Global.cnf_obj.vol_bgm
		sound.play()
	Global.adv.hide_message(true)
	var adv_screen := await Global.adv.create_capture(false)
	if type == 4:
		await set1(1, 5, 10, "FRM_0612", Vector2(-1, -1))
	elif type == 3:
		await set1(1, 5, 10, "FRM_0612", Vector2(-1, -1))
	elif type == 2:
		await set1(1, 5, 10, "FRM_0612", Vector2(-1, 330))
	elif type == 5:
		await set1(1, 5, 10, "FRM_0612", Vector2(-1, -1))
	elif type == 6:
		await set1(1, 5, 10, "FRM_0612", Vector2(-1, -1))
	set0(2, 14, 9, "FRM_0801", Vector2(131, 0), Vector2(0, 0))
	if type == 4:
		await set1(3, 14, 9, adv_screen, Vector2(131, 0), Vector2(306, 0), 131, Vector2(265, 251))
	elif type == 3:
		await set1(3, 14, 9, adv_screen, Vector2(154, 0), Vector2(306, 0), 154, Vector2(389, 237))
	elif type == 2:
		await set1(3, 14, 9, adv_screen, Vector2(154, 0), Vector2(306, 0), 154, Vector2(398, 310))
	elif type == 5:
		await set1(3, 14, 9, adv_screen, Vector2(169, 0), Vector2(306, 0), 169, Vector2(419, 232))
	elif type == 6:
		await set1(3, 14, 9, adv_screen, Vector2(122, 0), Vector2(306, 0), 122, Vector2(329, 249))
	set0(4, 22, 14, "FRM_0802", Vector2(0, 370 - 100), Vector2(0, 370))
	if type == 4:
		await set1(5, 22, 27, "EA01a", Vector2(0, 100), Vector2(0, 0), 0, Vector2(360, 0))
	elif type == 3:
		await set1(5, 22, 27, "EB01a", Vector2(0, 100), Vector2(0, 0), 0, Vector2(800, 216))
	elif type == 2:
		await set1(5, 22, 27, "EC01a", Vector2(0, 100), Vector2(0, 0), 0, Vector2(364, 197))
	elif type == 5:
		await set1(5, 22, 27, "ED01a", Vector2(0, 100), Vector2(0, 0), 61, Vector2(273, -100))
	elif type == 6:
		await set1(5, 22, 27, "EE01a", Vector2(0, 100), Vector2(0, 0), 0, Vector2(361, 0))
	Global.adv.destroy_capture()
	Global.destroy_adv_screen()
	await set1(4, 35, 14, "FRM_0803", Vector2(0, 370))
	set0(2, 48, 14, "FRM_0804", Vector2(494 - 100, 0), Vector2(494, 0))
	if type == 4:
		await set1(3, 48, 27, "EA06a", Vector2(100, 0), Vector2(0, 0), 485, Vector2(800, 111))
	elif type == 3:
		await set1(3, 48, 27, "EB08a", Vector2(100, 0), Vector2(0, 0), 269, Vector2(800, 0))
	elif type == 2:
		await set1(3, 48, 27, "EC02a", Vector2(100, 0), Vector2(0, 0), 238, Vector2(732, 0))
	elif type == 5:
		await set1(3, 48, 27, "ED06a", Vector2(100, 0), Vector2(0, 0), 138, Vector2(65, 218))
	elif type == 6:
		await set1(3, 48, 27, "EE05a", Vector2(100, 0), Vector2(0, 0), 110, Vector2(0, 0))
	await set1(2, 60, 14, "FRM_0805", Vector2(494, 0))
	set0(4, 73, 14, "FRM_0806", Vector2(0, 100), Vector2(0, 0))
	if type == 4:
		await set1(5, 73, 27, "EA05", Vector2(0, 230 - 100), Vector2(0, 230), 0, Vector2(0, 203))
	elif type == 3:
		await set1(5, 73, 27, "EB07b", Vector2(0, 230 - 100), Vector2(0, 230), 0, Vector2(0, 188))
	elif type == 2:
		await set1(5, 73, 27, "EC05a", Vector2(0, 230 - 100), Vector2(0, 230), 73, Vector2(527, 143))
	elif type == 5:
		await set1(5, 73, 27, "ED02a", Vector2(0, 230 - 100), Vector2(0, 230), 0, Vector2(180, 0))
	elif type == 6:
		await set1(5, 73, 27, "EE02a", Vector2(0, 230 - 100), Vector2(0, 230), 133, Vector2(0, 140))
	await set1(4, 86, 14, "FRM_0807", Vector2(0, 0))
	set0(2, 99, 14, "FRM_0808", Vector2(131, 0), Vector2(0, 0))
	if type == 4:
		await set1(3, 99, 27, "EA07", Vector2(131, 0), Vector2(306, 0), 183, Vector2(361, 295))
	elif type == 3:
		await set1(3, 99, 27, "EB02a", Vector2(131, 0), Vector2(306, 0), 41, Vector2(223, 151))
	elif type == 2:
		await set1(3, 99, 27, "EC03b", Vector2(131, 0), Vector2(306, 0), 280, Vector2(770, 0))
	elif type == 5:
		await set1(3, 99, 27, "ED07a", Vector2(131, 0), Vector2(306, 0), 130, Vector2(611, 40))
	elif type == 6:
		await set1(3, 99, 27, "EE10a", Vector2(131, 0), Vector2(306, 0), 100, Vector2(0, 0))
	await set1(2, 112, 14, "FRM_0809", Vector2(0, 0), Vector2(0, 0))
	set0(4, 125, 14, "FRM_0810", Vector2(0, 370 - 100), Vector2(0, 370))
	if type == 4:
		await set1(5, 125, 27, "EA12a", Vector2(0, 100), Vector2(0, 0), 0, Vector2(140, 69))
	elif type == 3:
		await set1(5, 125, 27, "EB05", Vector2(0, 100), Vector2(0, 0), 0, Vector2(0, 0))
	elif type == 2:
		await set1(5, 125, 27, "EC06a", Vector2(0, 100), Vector2(0, 0), 89, Vector2(444, -100))
	elif type == 5:
		await set1(5, 125, 27, "ED09", Vector2(0, 100), Vector2(0, 0), 0, Vector2(100, 0))
	elif type == 6:
		await set1(5, 125, 27, "EE04c", Vector2(0, 100), Vector2(0, 0), 0, Vector2(673, 0))
	await set1(4, 138, 14, "FRM_0811", Vector2(0, 370))
	set0(2, 151, 14, "FRM_0812", Vector2(494 - 100, 0), Vector2(494, 0))
	if type == 4:
		await set1(3, 151, 27, "EA10a", Vector2(100, 0), Vector2(0, 0), 306, Vector2(700, 0))
	elif type == 3:
		await set1(3, 151, 27, "EB10a", Vector2(100, 0), Vector2(0, 0), 23, Vector2(171, 171))
	elif type == 2:
		await set1(3, 151, 27, "EZ06a", Vector2(100, 0), Vector2(0, 0), 0, Vector2(0, 275))
	elif type == 5:
		await set1(3, 151, 27, "ED10a", Vector2(100, 0), Vector2(0, 0), 150, Vector2(160, 0))
	elif type == 6:
		await set1(3, 151, 27, "EE06a", Vector2(100, 0), Vector2(0, 0), 306, Vector2(50, 0))
	await set1(2, 164, 14, "FRM_0813", Vector2(494, 0))
	set0(4, 177, 14, "FRM_0814", Vector2(0, 100), Vector2(0, 0))
	if type == 4:
		await set1(5, 177, 27, "EA13a", Vector2(0, 230 - 100), Vector2(0, 230), 49, Vector2(100, 50))
	elif type == 3:
		await set1(5, 177, 27, "EB04a", Vector2(0, 230 - 100), Vector2(0, 230), 0, Vector2(0, 10))
	elif type == 2:
		await set1(5, 177, 27, "EC09", Vector2(0, 230 - 100), Vector2(0, 230), 0, Vector2(800, 173))
	elif type == 5:
		await set1(5, 177, 27, "ED04", Vector2(0, 230 - 100), Vector2(0, 230), 148, Vector2(412, 0))
	elif type == 6:
		await set1(5, 177, 27, "EE12a", Vector2(0, 230 - 100), Vector2(0, 230), 45, Vector2(379, 266))
	await set1(4, 190, 14, "FRM_0815", Vector2(0, 0))
	set0(2, 203, 14, "FRM_0816", Vector2(131, 0), Vector2(0, 0))
	if type == 4:
		await set1(3, 203, 27, "EA02", Vector2(131, 0), Vector2(306, 0), 171, Vector2(418, 0))
	elif type == 3:
		await set1(3, 203, 27, "EB03", Vector2(131, 0), Vector2(306, 0), 168, Vector2(413, 229))
	elif type == 2:
		await set1(3, 203, 27, "EC10a", Vector2(131, 0), Vector2(306, 0), 0, Vector2(0, 0))
	elif type == 5:
		await set1(3, 203, 27, "ED05", Vector2(131, 0), Vector2(306, 0), 182, Vector2(800, 0))
	elif type == 6:
		await set1(3, 203, 27, "EE03a", Vector2(131, 0), Vector2(306, 0), 100, Vector2(0, 0))
	await set1(2, 216, 14, "FRM_0817", Vector2(0, 0), Vector2(0, 0))
	set0(4, 229, 14, "FRM_0818", Vector2(0, 370 - 100), Vector2(0, 370))
	if type == 4:
		await set1(5, 229, 27, "EA03a", Vector2(0, 100), Vector2(0, 0), 0, Vector2(278, 195))
	elif type == 3:
		await set1(5, 229, 27, "EB16a", Vector2(0, 100), Vector2(0, 0), 59, Vector2(211, 261))
	elif type == 2:
		await set1(5, 229, 27, "EC13a", Vector2(0, 100), Vector2(0, 0), 0, Vector2(627, 134))
	elif type == 5:
		await set1(5, 229, 27, "ED16a", Vector2(0, 100), Vector2(0, 0), 0, Vector2(568, 0))
	elif type == 6:
		await set1(5, 229, 27, "EE07a", Vector2(0, 100), Vector2(0, 0), 75, Vector2(800, 30))
	await set1(4, 242, 14, "FRM_0819", Vector2(0, 370))
	set0(2, 255, 10, "FRM_0820", Vector2(494 - 100, 0), Vector2(494, 0))
	if type == 4:
		await set1(3, 255, 17, "EA04a", Vector2(100, 0), Vector2(0, 0), 109, Vector2(392, 290))
	elif type == 3:
		await set1(3, 255, 17, "EB06a", Vector2(100, 0), Vector2(0, 0), 110, Vector2(359, 0))
	elif type == 2:
		await set1(3, 255, 17, "EC07a", Vector2(100, 0), Vector2(0, 0), 150, Vector2(442, 302))
	elif type == 5:
		await set1(3, 255, 17, "ED03a", Vector2(100, 0), Vector2(0, 0), 239, Vector2(733, 0))
	elif type == 6:
		await set1(3, 255, 17, "EE08a", Vector2(100, 0), Vector2(0, 0), 132, Vector2(115, 0))
	await set1(2, 265, 7, "FRM_0821", Vector2(494, 0))
	await set1(1, 272, 7, "FRM_0602", Vector2(-1, -1))
	await set1(0, 280)
	destroy_proc(true)
	queue_free()
	Global.setup_adv_screen()
