class_name Flag

var flag := PackedInt32Array()

func _init(size: int = 0) -> void:
	create(size)

func create(size: int) -> void:
	var flagsize := (size + 31) >> 5
	flag.resize(flagsize)
	flag.fill(0)

func clear() -> void:
	flag.fill(0)

func check(id: int) -> bool:
	var index := id >> 5
	var shift := id & 31
	return (flag[index] >> shift) & 1 != 0

func set_(id: int) -> void:
	var index := id >> 5
	var shift := id & 31
	flag[index] |= 1 << shift

func reset(id: int) -> void:
	var index := id >> 5
	var shift := id & 31
	flag[index] &= ~(1 << shift)

func pack() -> PackedByteArray:
	var size := flag.size() << 5
	assert(size < 1 << 16)
	var packed := PackedInt32Array([])
	var pair := 0
	var i := 0
	while i < size:
		while i < size:
			if check(i): break
			i += 1
			pair += 1
		while i < size:
			if not check(i): break
			i += 1
			pair += 1 << 16
		packed.append(pair)
		pair = 0
	if flag.size() <= packed.size():
		return flag.to_byte_array()
	return packed.to_byte_array()

func pack_base64() -> String:
	return Marshalls.raw_to_base64(pack())

func unpack(p: PackedByteArray) -> void:
	if p.size() & 3 != 0: return
	var packed := p.to_int32_array()
	if flag.size() < packed.size(): return
	if flag.size() == packed.size():
		flag = packed
		return
	flag.fill(0)
	var size := flag.size() << 5
	var i := 0
	for pair in packed:
		i += pair & 0xffff
		pair >>= 16
		for j in range(i, i + pair):
			if j >= size: return
			set_(j)
		i += pair

func unpack_base64(base64: String) -> void:
	unpack(Marshalls.base64_to_raw(base64))
