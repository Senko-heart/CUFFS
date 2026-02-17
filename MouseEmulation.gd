extends Node

var was_last_emulated := false

func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		was_last_emulated = event.device == InputEvent.DEVICE_ID_EMULATION
	elif event is InputEventScreenTouch:
		if event.index == 1:
			var ev := InputEventMouseButton.new()
			ev.device = InputEvent.DEVICE_ID_EMULATION
			ev.button_index = MOUSE_BUTTON_RIGHT
			ev.position = event.position
			ev.pressed = event.pressed
			Input.parse_input_event(ev)
