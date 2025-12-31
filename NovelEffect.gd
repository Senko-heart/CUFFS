@tool
class_name NovelEffect
extends RichTextEffect

# Syntax: [nvl][/nvl]

var bbcode := "nvl"

var m: MessageSprite
#var visible_chars := 0
#var fully_visible_chars := 0

#var _consumed_time := 0.0
#var _end_fade_ts := PackedFloat32Array()
#var _fade_time := PackedFloat32Array()

func _init(msg_spr: MessageSprite) -> void:
	m = msg_spr

#func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	#var total_chars := m.message.length()
	#if m.message_ended: return true
	#var unprocessed := char_fx.elapsed_time - _consumed_time
	#var _char_show_delta := m.char_show_delta * m.char_show_ratio
	#while unprocessed >= _char_show_delta:
		#if visible_chars >= total_chars: break
		#unprocessed -= _char_show_delta
		#_consumed_time += _char_show_delta
		#_end_fade_ts.push_back(_consumed_time + m.char_fade_delta)
		#_fade_time.push_back(m.char_fade_delta)
		#visible_chars += 1
	#var current_char := char_fx.relative_index
	#if current_char < visible_chars:
		#var ft := _fade_time[current_char]
		#var sft := _end_fade_ts[current_char] - ft
		#char_fx.color.a *= min((char_fx.elapsed_time - sft) / ft, 1.0)
		#if char_fx.elapsed_time >= _end_fade_ts[current_char]:
			#fully_visible_chars = max(fully_visible_chars, current_char + 1)
			#if fully_visible_chars >= total_chars:
				#m.message_ended = true
	#else: char_fx.color.a = 0.0
	#return true

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
