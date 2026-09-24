extends Node

var data1 := ZR.new()
var data2 := ZR.new()
var voice := ZR.new()
var sound := ZR.new()
var patch := ZR.new()
var decensor := ZR.new()
var hires := ZR.new()
var soundmod := ZR.new()
var yahiro := ZR.new()

var frame := ZR.new()
var option := ZR.new()
var title := ZR.new()
var scenario := ZR.new()

var root := ""
var save_dir: String
var _arcs_loaded := false

var rc := ResourceCache.new()

var soundmod_cfg: Dictionary[String, Vector2i] = {}

var trash_os := OS.get_name() == "Android"

func _ready() -> void:
	_init_jni()
	if trash_os and not _load_uri():
		var err := DisplayServer.file_dialog_show(
			"%s directory" % ProjectSettings.get_setting("application/config/name"),
			"", "", false,
			DisplayServer.FILE_DIALOG_MODE_OPEN_DIR,
			[],
			_dir_cb
		)
		assert(err == OK, "Failed to open directory dialog.")
	else: _open_archives()

func _open_archives() -> void:
	var start_bytes := get_file_as_bytes(root + "start.cfg")
	var start_text := start_bytes.get_string_from_utf8()
	var cfg := ConfigFile.new()
	if not start_bytes.is_empty() and not cfg.parse(start_text):
		Start.load_from(cfg)
	
	data1.open(root + "data1.zip")
	data2.open(root + "data2.zip")
	voice.open(root + "voice.zip")
	sound.open(root + "sound.zip")
	patch.open(root + "patch.zip")
	if Start.decensor:
		decensor.open(root + "decensor.zip")
		Start.store_decensor = decensor.is_open()
	if Start.hires:
		hires.open(root + "hires.zip")
		Start.store_hires = hires.is_open()
	if Start.soundmod:
		soundmod.open(root + "soundmod.zip")
		Start.store_soundmod = soundmod.is_open()
		var sm_cfg := ConfigFile.new()
		var sm_cfg_text := soundmod.read_file("sound.cfg").get_string_from_utf8()
		if sm_cfg.parse(sm_cfg_text) == OK:
			for filename in sm_cfg.get_sections():
				var a: Variant = sm_cfg.get_value(filename, "a")
				var b: Variant = sm_cfg.get_value(filename, "b")
				soundmod_cfg[filename] = Vector2i(
					a if a is int else 0,
					b if b is int else 0,
				)
	if Start.yahiro:
		yahiro.open(root + "yahiro.zip")
		Start.store_yahiro = yahiro.is_open()
	
	var system := root + "system"
	frame.open(system.path_join("frame.zip"))
	option.open(system.path_join("option.zip"))
	title.open(system.path_join("title.zip"))
	scenario.open(system.path_join("scenario.zip"))
	
	save_dir = root + "save"
	if not trash_os:
		var dir := DirAccess.open(root.trim_suffix("#"))
		dir.make_dir("save")
	
	Start.dump_into(cfg)
	var start_cfg := open_write(root + "start.cfg")
	if start_cfg != null:
		start_cfg.store_string(cfg.encode_to_text())
	
	_arcs_loaded = true

var art: JNISingleton
var context: JavaObject
var resolver: JavaObject

var DocumentsContract: JavaClass
var Document: JavaClass
var Uri: JavaClass

var COLUMN_DOCUMENT_ID: String
var COLUMN_MIME_TYPE: String
var COLUMN_DISPLAY_NAME: String
var MIME_TYPE_DIR: String
var COLUMNS: PackedStringArray

var dir_id: Dictionary[String, String] = {}
var fast_path: Dictionary[String, String] = {}

func _init_jni() -> void:
	if not Engine.has_singleton(&"AndroidRuntime"):
		return
	
	art = Engine.get_singleton(&"AndroidRuntime")
	context = art.getApplicationContext()
	resolver = context.getContentResolver()
	
	DocumentsContract = JavaClassWrapper.wrap("android.provider.DocumentsContract")
	Document = JavaClassWrapper.wrap("android.provider.DocumentsContract$Document")
	Uri = JavaClassWrapper.wrap("android.net.Uri")

	COLUMN_DOCUMENT_ID = Document.COLUMN_DOCUMENT_ID
	COLUMN_MIME_TYPE = Document.COLUMN_MIME_TYPE
	COLUMN_DISPLAY_NAME = Document.COLUMN_DISPLAY_NAME
	MIME_TYPE_DIR = Document.MIME_TYPE_DIR
	COLUMNS = [COLUMN_DOCUMENT_ID, COLUMN_MIME_TYPE, COLUMN_DISPLAY_NAME]

func _init_fast_path(uri: String) -> void:
	if not art:
		return
	var tree_uri: JavaObject = Uri.parse(uri)
	var document_id: String = DocumentsContract.getTreeDocumentId(tree_uri)
	_scan_directory(tree_uri, document_id, uri + "#", fast_path)
	var savepath := uri + "#save"
	if savepath in dir_id:
		_scan_directory(tree_uri, dir_id[savepath], savepath + "/", fast_path)

func _scan_directory(
	tree_uri: JavaObject,
	parent_id: String,
	parent_path: String,
	output: Dictionary[String, String],
) -> void:
	var children_id: JavaObject = DocumentsContract.buildChildDocumentsUriUsingTree(tree_uri, parent_id)
	var cursor: JavaObject = resolver.query(children_id, COLUMNS, null, null)
	if cursor == null:
		return
	while cursor.moveToNext():
		var file_id: String = cursor.getString(0)
		var mime_type: String = cursor.getString(1)
		var display_name: String = cursor.getString(2)
		var path := parent_path + display_name
		if mime_type == MIME_TYPE_DIR:
			dir_id[path] = file_id
		else:
			var file_uri: JavaObject = DocumentsContract.buildDocumentUriUsingTree(tree_uri, file_id)
			var file_path: String = file_uri.toString()
			output[parent_path + display_name] = file_path
	cursor.close()

func _load_uri() -> bool:
	var uri := FileAccess.get_file_as_string("user://uri")
	if not uri.is_empty():
		if art and art.updatePersistableUriPermission(uri, true):
			_init_fast_path(uri)
			root = uri + "#"
			return true
	return false

func _dir_cb(status: bool, paths: PackedStringArray, _ix: int) -> void:
	if not(status and paths.size() > 0):
		printerr("Failed to pick directory.")
		return
	var uri := paths[0]
	if art: art.updatePersistableUriPermission(uri, true)
	var tree_uri := FileAccess.open("user://uri", FileAccess.WRITE)
	tree_uri.store_string(uri)
	_init_fast_path(uri)
	root = uri + "#"
	_open_archives()

func sync() -> void:
	while not _arcs_loaded:
		await get_tree().process_frame

func faster_path(path: String) -> String:
	return fast_path.get(path, path)

func open_read(path: String) -> FileAccess:
	return FileAccess.open(faster_path(path), FileAccess.READ)

func get_file_as_bytes(path: String) -> PackedByteArray:
	return FileAccess.get_file_as_bytes(faster_path(path))

func open_write(path: String) -> FileAccess:
	if not art or not path.begins_with(root):
		return FileAccess.open(path, FileAccess.WRITE)
	if path in fast_path:
		return FileAccess.open(fast_path[path], FileAccess.WRITE)
	var rindex := maxi(path.rfind("/"), root.length() - 1)
	if rindex == path.length() - 1:
		return null
	var path_parent := path.left(rindex)
	var filename := path.right(~rindex)
	var tree_uri: JavaObject = Uri.parse(root.trim_suffix("#"))
	var parent_id: String
	if rindex < root.length():
		parent_id = DocumentsContract.getTreeDocumentId(tree_uri)
	elif path_parent in dir_id:
		parent_id = dir_id[path_parent]
	else:
		return null
	var parent_uri: JavaObject = DocumentsContract.buildDocumentUriUsingTree(
		tree_uri, parent_id)
	var created_uri: JavaObject = DocumentsContract.createDocument(
		resolver, parent_uri, "application/octet-stream", filename)
	if created_uri == null:
		return null
	var uri_string: String = created_uri.toString()
	fast_path[path] = uri_string
	return FileAccess.open(uri_string, FileAccess.WRITE)

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

func measure_webp(bytes: PackedByteArray, begin: int = 0) -> int:
	begin += 8 + bytes.decode_s32(begin + 4)
	return begin

func _try_load_first(
	arcs: Array[ZR],
	path: String,
	case_sensitive: bool = true
) -> PackedByteArray:
	for arc in arcs:
		if Start.full and arc == patch:
			var full_path := "full".path_join(path.get_file())
			if arc.file_exists(full_path, case_sensitive):
				return arc.read_file(full_path, case_sensitive)
		if arc.file_exists(path, case_sensitive):
			return arc.read_file(path, case_sensitive)
	return []

func _lookup_file(
	arcs: Array[ZR],
	basename: String,
	extensions: PackedStringArray,
	case_sensitive: bool = true
) -> Vector2i:
	for x in range(arcs.size()):
		var arc := arcs[x]
		for y in range(extensions.size()):
			var path := basename + extensions[y]
			if arc.file_exists(path, case_sensitive):
				return Vector2i(x, y)
	return Vector2i.MAX

func load_voice(
	filename: String,
	snd: Sound,
	case_sensitive: bool = false
) -> bool:
	filename += ".ogg"
	var bytes := _try_load_first(
		[patch, voice],
		filename,
		case_sensitive
	)
	if bytes.is_empty():
		if not Start.yahiro: return false
		var yahiro_voice := "voice".path_join(filename)
		bytes = yahiro.read_file(yahiro_voice, case_sensitive)
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
	or voice.file_exists(filename, case_sensitive)
	or Start.yahiro and yahiro.file_exists("voice".path_join(filename), case_sensitive))

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
	loop: bool = true,
	case_sensitive: bool = false
) -> bool:
	var hq := filename + ".wav"
	var lq := filename + ".qoa"
	var bytes: PackedByteArray
	var is_qoa := false
	var filename_upper := filename.to_upper()
	if filename_upper in soundmod_cfg:
		if soundmod.file_exists(hq, case_sensitive):
			bytes = soundmod.read_file(hq, case_sensitive)
		elif soundmod.file_exists(lq, case_sensitive):
			bytes = soundmod.read_file(lq, case_sensitive)
			is_qoa = true
		else: return false
		var value := soundmod_cfg[filename_upper]
		bgm.rewind_pos = value.x
		bgm.end_pos = value.y
	elif patch.file_exists(hq, case_sensitive):
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
	if not loop:
		return true
	stream.loop_begin = bgm.rewind_pos
	stream.loop_end = bgm.end_pos
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	if stream.loop_begin == -1:
		stream.loop_begin = 0
	if stream.loop_end == -1:
		if is_qoa:
			var sbytes := bytes.slice(4, 8)
			sbytes.bswap32()
			stream.loop_end = sbytes.decode_u32(0)
		else:
			var byte_per_bloc := bytes.decode_u16(32)
			var data_size := bytes.decode_u32(40)
			stream.loop_end = data_size / byte_per_bloc
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
	var key := filename if case_sensitive else filename.to_upper()
	cache_load_texture(filename, case_sensitive)
	return rc.get_texture(key)

func put_texture_on_load(
	filename: String,
	case_sensitive: bool = false
) -> void:
	var key := filename if case_sensitive else filename.to_upper()
	var arcs: Array[ZR] = [hires, decensor, patch, data1, data2, yahiro]
	var exts: PackedStringArray = [".png", ".jpg", ".webp"]
	var pos := _lookup_file(arcs, filename, exts, case_sensitive)
	if Start.full:
		var full_name := "full".path_join(filename)
		var full_pos := _lookup_file(arcs, full_name, exts, case_sensitive)
		if full_pos.x <= pos.x:
			pos = full_pos
			filename = full_name
	if Start.decensor:
		var decensor_name := "decensor".path_join(filename)
		var decensor_pos := _lookup_file([hires], decensor_name, exts, case_sensitive)
		if decensor_pos.x <= pos.x:
			pos = decensor_pos
			filename = decensor_name
	if pos == Vector2i.MAX:
		return
	var bytes := arcs[pos.x].read_file(filename + exts[pos.y], case_sensitive)
	var is_hires := pos.x == 0
	if bytes.is_empty():
		return
	if pos.y == 0:
		rc.load_png(key, bytes, is_hires)
	elif pos.y == 1:
		rc.load_jpg(key, bytes, is_hires)
	elif pos.y == 2:
		rc.load_webp(key, bytes, is_hires)

func load_mask_texture(
	filename: String,
	case_sensitive: bool = true
) -> Texture2D:
	var mask_image := load_mask_image(filename, case_sensitive)
	return ImageTexture.create_from_image(mask_image)

func load_save_bytes(filename: String) -> PackedByteArray:
	var path := save_dir.path_join(filename)
	if not fast_path.is_empty() and path not in fast_path:
		return PackedByteArray()
	return get_file_as_bytes(path)

func open_save_file(path: String) -> FileAccess:
	if not trash_os:
		var dir := DirAccess.open(save_dir)
		dir.make_dir_recursive(path.get_base_dir())
	path = save_dir.path_join(path)
	return open_write(path)

func cache_reset(hint: String) -> bool:
	return rc.clear(hint)

func cache_load_texture(
	filename: String,
	case_sensitive: bool = false
) -> void:
	var key := filename if case_sensitive else filename.to_upper()
	if not rc.is_put_on_load(key):
		put_texture_on_load(filename, case_sensitive)
