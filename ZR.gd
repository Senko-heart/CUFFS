class_name ZR

var file: FileAccess
var zip64: bool

const COMPRESSION_NONE := 0
const COMPRESSION_DEFLATE := 8

var entry_table: Dictionary[String, int]
var case_sensitive_name: PackedStringArray
var seek_position: PackedInt64Array
var compression: PackedInt32Array
var compressed_size: PackedInt64Array
var uncompressed_size: PackedInt64Array
var crc32: PackedInt32Array

func open(path: String) -> void:
	close()
	file = FileAccess.open(path, FileAccess.READ)
	if _build_file_map():
		file = null

func close() -> void:
	file = null
	entry_table = {}
	case_sensitive_name = []
	seek_position = []
	compression = []
	compressed_size = []
	uncompressed_size = []
	crc32 = []

func file_exists(path: String, case_sensitive: bool = true) -> bool:
	if not file: return false
	var file_id: int = entry_table.get(path.to_upper(), -1)
	if file_id == -1: return false
	if case_sensitive:
		return path == case_sensitive_name[file_id]
	return true

func read_file(path: String, case_sensitive: bool = true) -> PackedByteArray:
	if not file: return PackedByteArray()
	var file_id: int = entry_table.get(path.to_upper(), -1)
	if file_id == -1: return PackedByteArray()
	if case_sensitive and path != case_sensitive_name[file_id]:
		return PackedByteArray()
	file.seek(seek_position[file_id])
	var raw := file.get_buffer(compressed_size[file_id])
	match compression[file_id]:
		COMPRESSION_NONE: return raw
		COMPRESSION_DEFLATE:
			var gz := PackedByteArray([
				0x1f, 0x8b, 0x08, 0x00,
				0x00, 0x00, 0x00, 0x00,
				0x00, 0xff
			])
			gz.append_array(raw)
			var ptr := gz.size()
			var final_size := uncompressed_size[file_id]
			gz.resize(ptr + 8)
			gz.encode_u32(ptr, crc32[file_id])
			gz.encode_u32(ptr + 4, final_size)
			return gz.decompress(final_size, FileAccess.COMPRESSION_GZIP)
		_: return PackedByteArray()

func _build_file_map() -> Error:
	if not file:
		return FAILED
	file.big_endian = false
	if _locate_central_directory():
		return FAILED
	return OK

func _locate_central_directory() -> Error:
	file.seek_end(-22)
	var eocd := file.get_buffer(22)
	eocd.bswap32(0, 1)
	var magic := eocd.decode_u32(0)
	if magic != 0x504b0506:
		printerr("failed to read eocd")
		return FAILED
	var disk_number := eocd.decode_u16(4)
	var disk_start := eocd.decode_u16(6)
	var disk_entries := eocd.decode_u16(8)
	var total_entries := eocd.decode_u16(10)
	var cd_size := eocd.decode_u32(12)
	var cd_offset := eocd.decode_u32(16)
	var comment_len := eocd.decode_u16(20)
	if comment_len != 0:
		return FAILED
	if 0xffff == disk_number \
	or 0xffff == disk_start \
	or 0xffff == disk_entries \
	or 0xffff == total_entries \
	or 0xffffffff == cd_size \
	or 0xffffffff == cd_offset:
		file.seek_end(-42)
		var ecdl := file.get_buffer(20)
		ecdl.bswap32(0, 1)
		magic = ecdl.decode_u32(0)
		if magic != 0x504b0607:
			printerr("failed to read ecdl")
			return FAILED
		var eocd64_offset := ecdl.decode_u64(8)
		file.seek(eocd64_offset)
		var eocd64 := file.get_buffer(56)
		eocd64.bswap32(0, 1)
		magic = eocd64.decode_u32(0)
		if magic != 0x504b0606:
			printerr("failed to read eocd64")
			return FAILED
		total_entries = eocd64.decode_u64(32)
		cd_size = eocd64.decode_u64(40)
		cd_offset = eocd64.decode_u64(48)
		zip64 = true
	else:
		zip64 = false
	file.seek(cd_offset)
	return _cache_central_directory(disk_entries)

func _cache_central_directory(entries: int) -> Error:
	for i in range(entries):
		var cdfh := file.get_buffer(46)
		cdfh.bswap32(0, 1)
		var magic := cdfh.decode_u32(0)
		if magic != 0x504b0102:
			printerr("failed to read cdfh")
			return FAILED
		var _compression := cdfh.decode_u16(10)
		var _crc32 := cdfh.decode_u32(16)
		var _compressed_size := cdfh.decode_u32(20)
		var _uncompressed_size := cdfh.decode_u32(24)
		var filename_len := cdfh.decode_u16(28)
		var extra_len := cdfh.decode_u16(30)
		var file_comment_len := cdfh.decode_u16(32)
		var disk_number := cdfh.decode_u16(34)
		var offset := cdfh.decode_u32(42)
		var filename := file.get_buffer(filename_len).get_string_from_utf8()
		var extra := file.get_buffer(extra_len + file_comment_len)
		if zip64 and extra_len != 0:
			if extra.decode_u16(0) == 0x1:
				var ptr := 4
				if 0xffffffff == _uncompressed_size:
					_uncompressed_size = extra.decode_u64(ptr)
					ptr += 8
				if 0xffffffff == _compressed_size:
					_compressed_size = extra.decode_u64(ptr)
					ptr += 8
				if 0xffffffff == offset:
					offset = extra.decode_u64(ptr)
					ptr += 8
				if 0xffff == disk_number:
					disk_number = extra.decode_u32(ptr)
					ptr += 4
				if ptr != extra.decode_u16(2):
					printerr("failed to read loc")
					return FAILED
		entry_table[filename.to_upper()] = i
		case_sensitive_name.append(filename)
		seek_position.append(offset)
		compression.append(_compression)
		compressed_size.append(_compressed_size)
		uncompressed_size.append(_uncompressed_size)
		crc32.append(_crc32)
	return _inline_seek_positions()

func _inline_seek_positions() -> Error:
	for i in seek_position.size():
		var seek_pos := seek_position[i]
		file.seek(seek_pos)
		var lfh := file.get_buffer(30)
		lfh.bswap32(0, 1)
		var magic := lfh.decode_u32(0)
		if magic != 0x504b0304:
			printerr("failed to read lfh")
			return FAILED
		var filename_len := lfh.decode_u16(26)
		var extra_len := lfh.decode_u16(28)
		seek_position[i] = seek_pos + 30 + filename_len + extra_len
	return OK
