class_name JumpLogManager

var logs: Array[Dictionary] = []
var last := -1
var total := 0

func _init(size: int = 0) -> void:
	assert(size > 0)
	logs.resize(size)

func add(dump: Dictionary) -> void:
	total = min(total + 1, logs.size())
	last = last + 1 if last + 1 < total else 0
	logs[last] = dump

func nth_back(index: int) -> Dictionary:
	if index not in range(total):
		return {}
	return logs[last - index]

func erase_back(count: int) -> void:
	if count - 1 not in range(total):
		return
	total -= count
	last -= count
	if last < 0:
		last += logs.size()

func num() -> int:
	return total

func contiguous() -> Array[Dictionary]:
	var array: Array[Dictionary] = []
	array.resize(total)
	for i in range(total):
		array[~i] = nth_back(i)
	return array

func from_contiguous(array: Array[Dictionary]) -> void:
	last = -1
	total = 0
	for dump in array:
		add(dump)
