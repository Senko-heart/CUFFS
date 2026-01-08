class_name ModButton
extends BaseButton

@export var tex_normal: Texture2D = null
@export var tex_pushed: Texture2D = null
@export var tex_focus: Texture2D = null
@export var tex_pushed_focus: Texture2D = null
@export var tex_disabled: Texture2D = null
@export var tex_push_disabled: Texture2D = null

var noninteractive: bool:
	set(value):
		if noninteractive != value:
			noninteractive = value
			if noninteractive:
				disabled_copy = disabled
				disabled = true
			else:
				disabled = disabled_copy

var disabled_copy := false

func _init() -> void:
	focus_mode = Control.FOCUS_ACCESSIBILITY
	pressed.connect(func() -> void: Global.pressed_button = self)

func _ready() -> void:
	if tex_normal:
		size = tex_normal.get_size()

func _get_minimum_size() -> Vector2:
	return size

func _apply_texture(tex: Texture2D) -> void:
	size = tex.get_size()
	draw_texture(tex, Vector2.ZERO)

func _draw() -> void:
	var _pressed := button_pressed and (not noninteractive or toggle_mode)
	var _hovered := is_hovered() and not noninteractive
	var _disabled := disabled_copy if noninteractive else disabled
	if _disabled:
		if _pressed and tex_push_disabled:
			_apply_texture(tex_push_disabled)
			return
		if tex_disabled:
			_apply_texture(tex_disabled)
			return
	elif _pressed:
		if _hovered and tex_pushed_focus:
			_apply_texture(tex_pushed_focus)
			return
		if tex_pushed:
			_apply_texture(tex_pushed)
			return
		if tex_focus:
			_apply_texture(tex_focus)
			return
	elif _hovered and tex_focus:
		_apply_texture(tex_focus)
		return
	if tex_normal:
		_apply_texture(tex_normal)
