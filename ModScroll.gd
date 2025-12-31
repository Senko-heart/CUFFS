class_name ModScroll
extends Range

var scroll: Texture2D
var up_button := ModButton.new()
var down_button := ModButton.new()
var grabber := ModButton.new()
var vertical := false
var container_mode := false
var wheel_step := 1

var _scroll_box := TextureRect.new()
var _box: BoxContainer

func _ready() -> void:
	grabber.keep_pressed_outside = true
	grabber.mouse_filter = MouseFilter.MOUSE_FILTER_PASS
	_box = VBoxContainer.new() if vertical else HBoxContainer.new()
	_box.add_child(up_button)
	if scroll:
		_scroll_box.texture = scroll
		_scroll_box.add_child(grabber)
		_box.add_child(_scroll_box)
	_box.add_child(down_button)
	add_child(_box)
	if vertical: _box.position.y = -0.5 * up_button.size.y
	else: _box.position.x = -0.5 * up_button.size.x
	size = _box.size
	_value_changed(value)

func _value_changed(_new_value: float) -> void:
	var gs := -0.5 * grabber.size
	var area := Rect2(Vector2.ZERO, _scroll_box.size)\
		.grow_individual(gs.x, gs.y, gs.x, gs.y)
	var pmin := area.position
	var pmax := area.end
	var pos := pmin.lerp(pmax, ratio) + gs
	if vertical: grabber.position.y = pos.y
	else: grabber.position.x = pos.x

func enable_container_mode() -> void:
	if container_mode: return
	container_mode = true
	_box.position += position
	position = Vector2.ZERO

func _get_minimum_size() -> Vector2:
	return size

func _has_point(point: Vector2) -> bool:
	return container_mode or grabber.button_pressed \
	or _scroll_area().has_point(point)

func _scroll_position() -> Vector2:
	return _box.position + _scroll_box.position

func _scroll_area() -> Rect2:
	return Rect2(_scroll_position(), _scroll_box.size)

func _handle_scroll(pos: Vector2) -> void:
	var gs := -0.5 * grabber.size
	var area := Rect2(Vector2.ZERO, _scroll_box.size)\
		.grow_individual(gs.x, gs.y, gs.x, gs.y)
	var pmin := area.position
	var pmax := area.end
	var r := (pos - pmin) / (pmax - pmin)
	ratio = r.y if vertical else r.x
	Global.scrolled = self
	accept_event()

func _handle_wheel(steps: int) -> void:
	var old_value := value
	value = value + step * steps
	if value != old_value:
		Global.scrolled = self
		accept_event()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if grabber.button_pressed:
			_handle_scroll(event.position - _scroll_position())
	elif event is InputEventMouseButton:
		if grabber.button_pressed:
			Global.scrolled = self
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed \
		and _scroll_area().has_point(event.position):
			_handle_scroll(event.position - _scroll_position())
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN \
		and event.pressed:
			_handle_wheel(wheel_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP \
		and event.pressed:
			_handle_wheel(-wheel_step)
