extends Node

var queue: Dictionary[Node, Dictionary] = {}
var active: Dictionary[Node, Dictionary] = {}

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	var to_erase: Array[Node] = []
	for node in active:
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			to_erase.append(node)
			continue
		if not node.is_inside_tree():
			continue
		var dict := active[node]
		dict.elapsed += delta
		var duration: float = dict.duration
		var elapsed: float = dict.elapsed
		var t := minf(elapsed / duration, 1.0)
		var tv := Vector4(
			pow(1.0 - t, 3),
			t * pow(1.0 - t, 2),
			pow(t, 2) * (1.0 - t),
			pow(t, 3)
		)
		if dict.has(&"position_x"):
			var pv: Vector4 = dict.position_x
			node.position.x = tv.dot(pv)
		if dict.has(&"position_y"):
			var pv: Vector4 = dict.position_y
			node.position.y = tv.dot(pv)
		if dict.has(&"rotation"):
			var pv: Vector4 = dict.rotation
			node.rotation = tv.dot(pv)
		if dict.has(&"scale_x"):
			var pv: Vector4 = dict.scale_x
			node.scale.x = tv.dot(pv)
		if dict.has(&"scale_y"):
			var pv: Vector4 = dict.scale_y
			node.scale.y = tv.dot(pv)
		if dict.has(&"alpha"):
			var pv: Vector2 = dict.alpha
			node.modulate.a = Vector2(1.0 - t, t).dot(pv)
		if dict.has(&"volume"):
			var pv: Vector2 = dict.volume
			node.volume_linear = Vector2(1.0 - t, t).dot(pv)
		if dict.has(&"property"):
			var path: NodePath = dict.property
			node.set_indexed(path, t)
		if elapsed >= duration:
			to_erase.append(node)
	for node in to_erase:
		active.erase(node)

func schedule(target: Node, anim: Dictionary) -> void:
	queue.get_or_add(target, {}).merge(anim, true)

func run(time: float, select: Array[Node] = []) -> void:
	if select.is_empty():
		for target in queue:
			var q := queue[target]
			select.append(target)
			run_single(target, q, time)
		queue.clear()
	else:
		for target in select:
			if target in queue:
				var q := queue[target]
				queue.erase(target)
				run_single(target, q, time)
	for target in select:
		await safe_finish(target)

func run_single(node: Node, q: Dictionary, time: float) -> void:
	var anim := {duration = time, elapsed = 0.0}
	for prop: StringName in [&"position", &"scale"]:
		if not prop in q: continue
		var v: Dictionary = q[prop]
		var target: Vector2 = v.target
		var base: Vector2 = v.get(&"base", node[prop])
		var accel: Vector2 = v.get(&"accel", Vector2(1.0, 1.0))
		var curve: Vector2 = v.get(&"curve", Vector2(0.0, 0.0))
		var bctrl := 3.0 * base + (target - base).rotated(deg_to_rad(curve.x)) * accel.x
		var tctrl := 3.0 * target - (target - base).rotated(deg_to_rad(curve.y)) * accel.y
		anim[StringName(prop + &"_x")] = Vector4(base.x, bctrl.x, tctrl.x, target.x)
		anim[StringName(prop + &"_y")] = Vector4(base.y, bctrl.y, tctrl.y, target.y)
	if &"rotation" in q:
		var v: Dictionary = q.rotation
		var target: float = v.target
		var base: float = v.get(&"base", node.rotation)
		var accel: Vector2 = v.get(&"accel", Vector2(1.0, 1.0))
		var bctrl := 3.0 * base + (target - base) * accel.x
		var tctrl := 3.0 * target - (target - base) * accel.y
		anim.rotation = Vector4(base, bctrl, tctrl, target)
	if &"alpha" in q:
		var v: Dictionary = q.alpha
		var target: float = v.target
		var base: float = v.get(&"base", node.modulate.a)
		anim.alpha = Vector2(base, target)
	if &"volume" in q:
		var v: Dictionary = q.volume
		var target: float = v.target
		var base: float = v.get(&"base", node.volume_linear)
		anim.volume = Vector2(base, target)
	if &"property" in q:
		var path: NodePath = q.property
		anim.property = path
	kill(node)
	active[node] = anim
	await safe_finish(node)

func is_animated(target: Node) -> bool:
	return target in active

func safe_finish(target: Node) -> void:
	while is_instance_valid(target) and target in active:
		await get_tree().process_frame

func finish(target: Node) -> void:
	while target in active:
		await get_tree().process_frame

func finish_flushed(target: Node) -> bool:
	while target in active:
		if Input.is_action_just_pressed("hit_confirm", true):
			return true
		await get_tree().process_frame
	return false

func flush(target: Node) -> void:
	var dict: Dictionary = active.get(target, {})
	if dict.is_empty(): return
	active.erase(target)
	if dict.has(&"position_x"):
		var pv: Vector4 = dict.position_x
		target.position.x = pv.w
	if dict.has(&"position_y"):
		var pv: Vector4 = dict.position_y
		target.position.y = pv.w
	if dict.has(&"rotation"):
		var pv: Vector4 = dict.rotation
		target.rotation = pv.w
	if dict.has(&"scale_x"):
		var pv: Vector4 = dict.scale_x
		target.scale.x = pv.w
	if dict.has(&"scale_y"):
		var pv: Vector4 = dict.scale_y
		target.scale.y = pv.w
	if dict.has(&"alpha"):
		var pv: Vector2 = dict.alpha
		target.modulate.a = pv.y
	if dict.has(&"property"):
		var path: NodePath = dict.property
		target.set_indexed(path, 1.0)

func kill(target: Node) -> void:
	var dict: Dictionary = active.get(target, {})
	if dict.is_empty(): return
	active.erase(target)

func destroy(target: Node) -> void:
	kill(target)
	queue.erase(target)
	target.queue_free()

func _move(pos: Vector2, accel: Vector2 = Vector2(3.0, 0.0)) -> Dictionary:
	return { position = { target = pos, accel = accel }}

func schedule_move(target: Node, pos: Vector2) -> void:
	schedule(target, _move(pos))

func move(target: Node, pos: Vector2, time: float) -> void:
	await run_single(target, _move(pos), time)

func _scale(
	to: Vector2,
	from: Vector2,
	accel: Vector2 = Vector2(3.0, 0.0)
) -> Dictionary:
	return { scale = {
		target = to,
		base = from,
		accel = accel,
	}}

func schedule_scale(target: Node, from: Vector2, to: Vector2) -> void:
	schedule(target, _scale(to, from))

func schedule_linear_scale(target: Node, from: Vector2, to: Vector2) -> void:
	schedule(target, _scale(to, from, Vector2.ZERO))

func scale(target: Node, from: Vector2, to: Vector2, time: float) -> void:
	await run_single(target, _scale(from, to), time)

func _fade(alpha: float) -> Dictionary:
	return { alpha = { target = alpha }}

func schedule_fade(target: Node, alpha: float) -> void:
	schedule(target, _fade(alpha))

func fade(target: Node, alpha: float, time: float) -> void:
	await run_single(target, _fade(alpha), time)

func _fade_vol(volume: float) -> Dictionary:
	return { volume = { target = volume }}

func schedule_fade_vol(target: Node, volume: float) -> void:
	schedule(target, _fade_vol(volume))

func fade_vol(target: Node, volume: float, time: float) -> void:
	await run_single(target, _fade_vol(volume), time)

func property(target: Node, path: String, time: float) -> void:
	await run_single(target, { property = path }, time)
