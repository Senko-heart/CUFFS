class_name BustupManager
extends Node2D

const BUSTUP_XPOS: PackedInt32Array = \
	[0, 0, 80, 160, 240, 320, 400, 480, 560, 640, 720, 800]

var info: Array[BustupInfo]
var spr: Array[Sprite2D]

func _init(size: int) -> void:
	use_parent_material = true
	for i in range(size):
		info.append(BustupInfo.new())
		var _spr := Sprite2D.new()
		_spr.centered = false
		_spr.use_parent_material = true
		spr.append(_spr)
		add_child(_spr)

func copy_spr_at(i: int, copy_to: Sprite2D) -> void:
	copy_to.modulate = spr[i].modulate
	copy_to.texture = spr[i].texture
	copy_to.offset = spr[i].offset
	copy_to.position = spr[i].position
	copy_to.z_index = spr[i].z_index

func clear_at(i: int) -> void:
	info[i].clear()
	spr[i].texture = null
	spr[i].material = null

func set_(filename: String, pos: int, priority: int, timezone: int) -> void:
	var bustup := Global.check_setup_bustup(filename, timezone)
	for bu in info:
		if bu.id != bustup.id: continue
		if bu.status not in [16, 32, 64]:
			bu.status = 4
		bu.basename = bustup.basename
		bu.filename = bustup.filename
		if pos != 0:
			bu.pos = pos
			bu.pos_fix = pos > 0
		bu.relation = bustup.relation
		if priority != 0: bu.priority = priority
		bu.base_position = bustup.base_position
		return
	for bu in info:
		if bu.status != 0: continue
		bu.status = 1
		bu.id = bustup.id
		bu.basename = bustup.basename
		bu.filename = bustup.filename
		if pos != 0:
			bu.pos = pos
			bu.pos_fix = pos > 0
		bu.relation = bustup.relation
		if priority != 0: bu.priority = priority
		else: bu.priority = bustup.priority
		bu.base_position = bustup.base_position
		bu.local_position = bustup.base_position
		return

func move(id: int, pos: int) -> void:
	for bu in info:
		if bu.id != id: continue
		if bu.pos != pos: bu.status = 4
		bu.pos_fix = pos != 0
		bu.pos = pos

func clear(id: int) -> void:
	if id == 0:
		for bu in info:
			if bu.status != 0:
				bu.clear()
	else:
		for bu in info:
			if bu.id == id:
				bu.clear()

func leave(
	id: int, mx: int, my: int,
	fade: bool, time: int, accel: int
) -> void:
	for bu in info:
		if bu.id == id:
			bu.status = 128
			bu.leave_param.set_(Vector2i(mx, my), time, accel, fade)

func move_position(id: int, pos: int) -> void:
	for bu in info:
		if bu.id == id:
			bu.status = 4
			bu.pos = pos

func down(id: int, mv: int, time: int, accel: int) -> void:
	for bu in info:
		if bu.id != id: continue
		bu.status = 16
		var i_mv: int
		var i_time: int
		var i_accel: int
		if mv == 0:
			i_mv = 50
			i_accel = 3
		elif mv == -1:
			i_mv = -(bu.local_position.y - bu.base_position.y)
			i_accel = 3
		else:
			i_mv = mv
			i_accel = accel
		if time == 0: i_time = 1000
		elif time == -1: i_time = 0
		else: i_time = time
		bu.down_param.set_(Vector2i(0, i_mv), i_time, i_accel, false)
		return

func jump(id: int, _mv: int = 0) -> void:
	for bu in info:
		if bu.id == id:
			bu.status = 32
			return

func shake(id: int, _mh: int = 0, _count: int = 0) -> void:
	for bu in info:
		if bu.id == id:
			bu.status = 64
			return

func num_people() -> int:
	var count := 0
	for bu in info:
		if bu.status != 0 and bu.status != 8:
			count += 1
	return count

func sort_priority(descend: bool) -> void:
	if descend:
		info.sort_custom(func(a: BustupInfo, b: BustupInfo) -> bool:
			return a.priority > b.priority)
	else:
		info.sort_custom(func(a: BustupInfo, b: BustupInfo) -> bool:
			return a.priority < b.priority)

func sort_relation() -> void:
	info.sort_custom(func(a: BustupInfo, b: BustupInfo) -> bool:
		return a.relation < b.relation)

func adjust_position() -> void:
	var id_rel: Array[BustupInfo] = []
	for bu in info:
		if bu.id != -1 and bu.status != 8 and not bu.pos_fix:
			var bustup := BustupInfo.new()
			bustup.id = bu.id
			bustup.relation = bu.relation
			id_rel.append(bustup)
	id_rel.sort_custom(func(a: BustupInfo, b: BustupInfo) -> bool:
		return a.relation < b.relation)
	var pos: PackedInt32Array
	match id_rel.size():
		1: pos = [6]
		2: pos = [4, 8]
		3: pos = [3, 6, 9]
		4: pos = [3, 5, 7, 9]
		5: pos = [2, 4, 6, 8, 10]
	for i in range(id_rel.size()):
		for bu in info:
			if bu.id != id_rel[i].id: continue
			if bu.pos < 0: bu.pos = -bu.pos
			else: bu.pos = pos[i]
			break

func adjust_spr_position(id: int) -> void:
	var bu := info[id]
	bu.base_position.x = BUSTUP_XPOS[bu.pos]
	bu.local_position.x = bu.base_position.x
	spr[id].position = bu.local_position
