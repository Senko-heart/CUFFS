class_name Sound
extends AudioStreamPlayer

var filename: String
var end_pos := -1
var rewind_pos := -1
var is_play := false

func _init(parent: Node) -> void:
	parent.add_child(self)
