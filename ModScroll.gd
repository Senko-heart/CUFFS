class_name ModScroll
extends Range

#var scroll: Texture2D
#var up_button := ModButton.new()
#var down_button := ModButton.new()
#var grabber := ModButton.new()
#var vertical := false
#var container_mode := false
#var wheel_step := 1
var scroll: Texture2D
var up_button := ModButton.new()
var down_button := ModButton.new()
var grabber := ModButton.new()
var vertical := false
var container_mode := false
var wheel_step := 1

#var _scroll_box := TextureRect.new()
#var _box: BoxContainer
var _scroll := TextureRect.new()
var _subview := SubViewport.new()
var _subviewc := SubViewportContainer.new()
var _drag_range: Vector2
var _upsize: float
var _scrollsize: float
var _gsize: float

func _init() -> void:
	grabber.keep_pressed_outside = true
	grabber.mouse_filter = MouseFilter.MOUSE_FILTER_PASS
	add_child(up_button)
	add_child(down_button)
	_subview.add_child(_scroll)
	_subview.add_child(grabber)
	_subview.transparent_bg = true
	_subviewc.add_child(_subview)
	_subviewc.stretch = true
	add_child(_subviewc)

func _ready() -> void:
	_scroll.texture = scroll
	_subviewc.size = scroll.get_size() if scroll else Vector2.ZERO
	if vertical:
		_scrollsize = scroll.get_height() if scroll else 0
		_upsize = up_button.size.y
		_gsize = grabber.size.y
		_subviewc.position.y = _upsize
		down_button.position.y = _upsize + _scrollsize
		size.x = max(up_button.size.x, _subviewc.size.x, down_button.size.x)
		size.y = _upsize + _scrollsize + down_button.size.y
	else:
		_scrollsize = scroll.get_width() if scroll else 0
		_upsize = up_button.size.x
		_gsize = grabber.size.x
		_subviewc.position.x = _upsize
		down_button.position.x = _upsize + _scrollsize
		size.x = _upsize + _scrollsize + down_button.size.x
		size.y = max(up_button.size.y, _subviewc.size.y, down_button.size.y)
	_drag_range = Vector2(0.5 * _gsize, _scrollsize - 0.5 * _gsize)
	_value_changed(value)

func _value_changed(_new_value: float) -> void:
	var drag_point := lerpf(_drag_range.x, _drag_range.y, ratio)
	var coord := drag_point - 0.5 * _gsize
	if vertical:
		grabber.position.y = coord
	else:
		grabber.position.x = coord

func _get_minimum_size() -> Vector2:
	return size

func _has_point(point: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).has_point(point)

func _handle_scroll(pos: Vector2) -> void:
	if vertical:
		ratio = inverse_lerp(_drag_range.x, _drag_range.y, pos.y)
	else:
		ratio = inverse_lerp(_drag_range.x, _drag_range.y, pos.x)
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
			_handle_scroll(event.position - _subviewc.position)
	elif event is InputEventMouseButton:
		if grabber.button_pressed:
			Global.scrolled = self
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed \
		and _subviewc.get_rect().has_point(event.position):
			_handle_scroll(event.position - _subviewc.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN \
		and event.pressed:
			_handle_wheel(wheel_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP \
		and event.pressed:
			_handle_wheel(-wheel_step)
