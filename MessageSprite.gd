class_name MessageSprite
extends RichTextLabel

@export var message := "":
	set(msg):
		message = msg
		reset_tag_stack()
@export var nvl_effect := false
@export var char_show_delta := 0.0
@export var char_fade_delta := 0.0
@export var char_show_ratio := 1.0

@export var use_bold := false
@export var use_italics := false
@export var face := ""
@export var font_size := 0

var message_ended := false

func _init() -> void:
	scroll_active = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func apply_sequence(seq: Dictionary) -> void:
	set(&"font_size", seq.get(&"size", 0))
	set(&"use_bold", seq.get(&"bold", false))
	set(&"use_italics", seq.get(&"italic", false))
	set(&"face", seq.get(&"face", ""))

func reset_tag_stack() -> void:
	clear()
	message_ended = false
	if nvl_effect:
		push_customfx(NovelEffect.new(self), {})
	var font_not_pushed := true
	if not face.is_empty():
		var fv := Global.get_font_variation(face, use_bold, use_italics)
		if fv:
			push_font(fv)
			font_not_pushed = false
	if font_not_pushed:
		if use_bold:
			push_bold()
		if use_italics:
			push_italics()
	if font_size != 0:
		push_font_size(font_size)
	add_text(message.replace(".", "․"))
	pop_all()

func create_message(width: int, height: int) -> void:
	size = Vector2(width, height)

func attach_message_style(skin: ControlPack, style_id: StringName) -> void:
	skin.attach_text_style(self, style_id)

func output_message(msg: String) -> void:
	message = msg

func set_default_msg_speed(
	char_speed: int,
	fade_speed: int,
	speed_ratio: int = 0x100
) -> void:
	char_show_delta = float(char_speed) / 1000.0
	char_fade_delta = float(fade_speed) / 1000.0
	char_show_ratio = float(speed_ratio) / 256.0

func cursor_pos() -> Vector2:
	var line := get_line_count() - 1
	if line < 0: return Vector2()
	var x := get_line_width(line)
	var y := get_line_offset(line)
	return Vector2(x, y)
