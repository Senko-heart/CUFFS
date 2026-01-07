extends Node

var data1 := ZR.new()
var data2 := ZR.new()
var voice := ZR.new()
var sound := ZR.new()
var patch := ZR.new()
var decensor := ZR.new()

var frame := ZR.new()
var option := ZR.new()
var title := ZR.new()
var scenario := ZR.new()

var root := "."
var save_dir: String
var _arcs_loaded := false

func _init() -> void:
	match OS.get_name():
		"Android":
			var err := DisplayServer.file_dialog_show(
				"%s directory" % ProjectSettings.get_setting("application/config/name"),
				"", "", false,
				DisplayServer.FILE_DIALOG_MODE_OPEN_DIR,
				[],
				_dir_cb
			)
			assert(err == OK, "Failed to open directory dialog.")
		_: _open_archives()

func _open_archives() -> void:
	data1.open(root.path_join("data1.zip"))
	data2.open(root.path_join("data2.zip"))
	voice.open(root.path_join("voice.zip"))
	sound.open(root.path_join("sound.zip"))
	patch.open(root.path_join("patch.zip"))
	decensor.open(root.path_join("decensor.zip"))
	
	var system := root.path_join("system")
	frame.open(system.path_join("frame.zip"))
	option.open(system.path_join("option.zip"))
	title.open(system.path_join("title.zip"))
	scenario.open(system.path_join("scenario.zip"))
	
	save_dir = root.path_join("save")
	var dir := DirAccess.open(root)
	dir.make_dir("save")
	
	_arcs_loaded = true

func _dir_cb(status: bool, paths: PackedStringArray, _ix: int) -> void:
	if not(status and paths.size() > 0):
		printerr("Failed to pick directory.")
		return
	root = paths[0]
	_open_archives()

func sync() -> void:
	while not _arcs_loaded:
		await get_tree().process_frame

func measure_png(bytes: PackedByteArray, begin: int = 0) -> int:
	begin += 8
	var type := 0
	var size := bytes.size()
	while type != 0x49454e44 and begin < size:
		var info := bytes.slice(begin, begin + 8)
		info.bswap32()
		begin += 12 + info.decode_u32(0)
		type = info.decode_u32(4)
	return begin

func _try_load_first(
	arcs: Array[ZR],
	path: String,
	case_sensitive: bool = true
) -> PackedByteArray:
	for arc in arcs:
		if arc.file_exists(path, case_sensitive):
			return arc.read_file(path, case_sensitive)
	return []

func load_voice(
	filename: String,
	snd: Sound,
	case_sensitive: bool = false
) -> bool:
	var bytes := _try_load_first(
		[patch, voice],
		filename + ".ogg",
		case_sensitive
	)
	if bytes.is_empty(): return false
	var stream := AudioStreamOggVorbis.load_from_buffer(bytes)
	snd.stream = stream
	snd.filename = filename
	return true

func exists_voice(
	filename: String,
	case_sensitive: bool = false
) -> bool:
	filename += ".ogg"
	return (patch.file_exists(filename, case_sensitive)
	or voice.file_exists(filename, case_sensitive))

func load_sound(
	filename: String,
	snd: Sound,
	looping: bool = false,
	case_sensitive: bool = false
) -> bool:
	var bytes := _try_load_first(
		[patch, sound],
		filename + ".ogg",
		case_sensitive
	)
	if bytes.is_empty(): return false
	var stream := AudioStreamOggVorbis.load_from_buffer(bytes)
	stream.loop = looping
	snd.stream = stream
	snd.filename = filename
	return true

func load_bgm(
	filename: String,
	bgm: Sound,
	case_sensitive: bool = false
) -> bool:
	var hq := filename + ".wav"
	var lq := filename + ".qoa"
	var bytes: PackedByteArray
	var is_qoa := false
	if patch.file_exists(hq, case_sensitive):
		bytes = patch.read_file(hq, case_sensitive)
	elif patch.file_exists(lq, case_sensitive):
		bytes = patch.read_file(lq, case_sensitive)
		is_qoa = true
	elif sound.file_exists(hq, case_sensitive):
		bytes = sound.read_file(hq, case_sensitive)
	elif sound.file_exists(lq, case_sensitive):
		bytes = sound.read_file(lq, case_sensitive)
		is_qoa = true
	else: return false
	var stream: AudioStreamWAV
	if is_qoa:
		stream = AudioStreamWAV.new()
		stream.data = bytes
		stream.format = AudioStreamWAV.FORMAT_QOA
		stream.stereo = true
	else: stream = AudioStreamWAV.load_from_buffer(bytes)
	bgm.stream = stream
	bgm.filename = filename
	stream.loop_begin = bgm.rewind_pos
	stream.loop_end = bgm.end_pos
	if stream.loop_begin != -1:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	return true

func load_image(
	filename: String,
	case_sensitive: bool = false
) -> Image:
	var bytes := _try_load_first(
		[decensor, patch, data1, data2],
		filename + ".png",
		case_sensitive
	)
	var image := Image.new()
	image.load_png_from_buffer(bytes)
	return image

func load_mask_image(
	filename: String,
	case_sensitive: bool = true
) -> Image:
	var mask := load_image(filename, case_sensitive)
	mask.convert(Image.FORMAT_LA8)
	for y in range(0, mask.get_height()):
		for x in range(0, mask.get_width()):
			var color := mask.get_pixel(x, y)
			color.a = color.r
			mask.set_pixel(x, y, color)
	return mask

func load_texture(
	filename: String,
	case_sensitive: bool = false
) -> Texture2D:
	var bytes := _try_load_first(
		[decensor, patch, data1, data2],
		filename + ".png",
		case_sensitive
	)
	if bytes.is_empty():
		return null
	var frames: Array[Texture2D] = []
	var begin := 0
	var size := bytes.size()
	while begin < size - 4:
		var end := measure_png(bytes, begin)
		var image := Image.new()
		image.load_png_from_buffer(bytes.slice(begin, end))
		frames.append(ImageTexture.create_from_image(image))
		begin = end
	if frames.size() != 1:
		var atexture := AnimTexture.new(frames)
		if begin == size - 4:
			var duration := bytes.decode_u32(begin)
			atexture.set_duration(duration)
		return atexture
	else:
		return frames[0]

func load_mask_texture(
	filename: String,
	case_sensitive: bool = true
) -> Texture2D:
	var mask_image := load_mask_image(filename, case_sensitive)
	return ImageTexture.create_from_image(mask_image)

func load_save_bytes(filename: String) -> PackedByteArray:
	var path := save_dir.path_join(filename)
	return FileAccess.get_file_as_bytes(path)

func open_save_file(path: String) -> FileAccess:
	var dir := DirAccess.open(save_dir)
	dir.make_dir_recursive(path.get_base_dir())
	path = save_dir.path_join(path)
	return FileAccess.open(path, FileAccess.WRITE)
