class_name LogManager

var logs := PackedStringArray()
var last := -1
var total := 0

func _init(size: int = 0) -> void:
	assert(size > 0)
	logs.resize(size)

func add(string: String) -> void:
	total = min(total + 1, logs.size())
	last = last + 1 if last + 1 < total else 0
	logs[last] = string

func nth_back(index: int) -> String:
	if index not in range(total):
		return ""
	return logs[last - index]

func num() -> int:
	return total

func contiguous() -> PackedStringArray:
	var array := PackedStringArray()
	array.resize(total)
	for i in range(total):
		array[~i] = nth_back(i)
	return array

func from_contiguous(array: PackedStringArray) -> void:
	last = -1
	total = 0
	for string in array:
		add(string)
