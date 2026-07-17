class_name ResourceCache
extends RefCounted

var cache_hint: String = ""
var cache: Dictionary[String, Resource] = {}
var tasks: Dictionary[String, int] = {}
var mutex: Mutex = Mutex.new()

func clear(hint: String) -> bool:
	if cache_hint != hint:
		wait_all()
		cache.clear()
		cache_hint = hint
		return true
	return false

func _write(key: String, value: Resource) -> void:
	mutex.lock()
	cache[key] = value
	mutex.unlock()

func is_put_on_load(key: String) -> bool:
	if key in tasks: return true
	mutex.lock()
	var ret := key in cache
	mutex.unlock()
	return ret

func load_simple_png(key: String, bytes: PackedByteArray) -> void:
	var task := func() -> void:
		var image := Image.new()
		image.load_png_from_buffer(bytes)
		var texture: Texture2D = ImageTexture.create_from_image(image)
		_write(key, texture)
	tasks[key] = WorkerThreadPool.add_task(task, false, key)

func load_png(key: String, bytes: PackedByteArray, is_hires: bool) -> void:
	var task := func() -> void:
		var frames: Array[Texture2D] = []
		var begin := 0
		var size := bytes.size()
		while begin < size - 4:
			var end := FS.measure_png(bytes, begin)
			var image := Image.new()
			image.load_png_from_buffer(bytes.slice(begin, end))
			var texture: Texture2D = ImageTexture.create_from_image(image)
			if is_hires:
				texture = ScaleTexture.new(texture, Vector2(0.5, 0.5))
			frames.append(texture)
			begin = end
		if frames.size() != 1:
			var atexture := AnimTexture.new(frames)
			if begin == size - 4:
				var duration := bytes.decode_u32(begin)
				atexture.set_duration(duration)
			_write(key, atexture)
		else:
			_write(key, frames[0])
	tasks[key] = WorkerThreadPool.add_task(task, false, key)

func load_jpg(key: String, bytes: PackedByteArray, is_hires: bool) -> void:
	var task := func() -> void:
		var image := Image.new()
		image.load_jpg_from_buffer(bytes)
		var texture: Texture2D = ImageTexture.create_from_image(image)
		if is_hires:
			texture = ScaleTexture.new(texture, Vector2(0.5, 0.5))
		_write(key, texture)
	tasks[key] = WorkerThreadPool.add_task(task, false, key)

func load_webp(key: String, bytes: PackedByteArray, is_hires: bool) -> void:
	var task := func() -> void:
		var frames: Array[Texture2D] = []
		var begin := 0
		var size := bytes.size()
		while begin < size - 4:
			var end := FS.measure_webp(bytes, begin)
			var image := Image.new()
			image.load_webp_from_buffer(bytes.slice(begin, end))
			var texture: Texture2D = ImageTexture.create_from_image(image)
			if is_hires:
				texture = ScaleTexture.new(texture, Vector2(0.5, 0.5))
			frames.append(texture)
			begin = end
		if frames.size() != 1:
			var atexture := AnimTexture.new(frames)
			if begin == size - 4:
				var duration := bytes.decode_u32(begin)
				atexture.set_duration(duration)
			_write(key, atexture)
		else:
			_write(key, frames[0])
	tasks[key] = WorkerThreadPool.add_task(task, false, key)

func get_texture(key: String) -> Texture2D:
	return wait(key)

func wait(key: String) -> Resource:
	if key in tasks:
		var task := tasks[key]
		WorkerThreadPool.wait_for_task_completion(task)
		tasks.erase(key)
	mutex.lock()
	var value: Resource = cache.get(key)
	mutex.unlock()
	return value

func wait_all() -> void:
	for task: int in tasks.values():
		WorkerThreadPool.wait_for_task_completion(task)
	tasks.clear()
