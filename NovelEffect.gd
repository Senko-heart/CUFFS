@tool
class_name NovelEffect
extends RichTextEffect

# Syntax: [nvl][/nvl]

var bbcode := "nvl"

var m: MessageSprite

func _init(msg_spr: MessageSprite) -> void:
	m = msg_spr

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	if m.message_ended: return true
	var char_show_delta := m.char_show_delta * m.char_show_ratio
	var char_fade_delta := m.char_fade_delta
	var current_char := char_fx.relative_index
	var elapsed_time := char_fx.elapsed_time
	var time := char_show_delta * (current_char + 1)
	if elapsed_time >= time:
		var fade := elapsed_time - time
		if fade >= char_fade_delta:
			if current_char == m.message.length() - 1:
				m.message_ended = true
		else:
			char_fx.color.a *= fade / char_fade_delta
	else:
		char_fx.color.a = 0.0
	return true
