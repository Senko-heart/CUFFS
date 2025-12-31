class_name AnimTexture
extends Texture2D

var frames: Array[Texture2D] = []
var frame := 0
var frame_progress := 0.0
var frame_count: int:
	get(): return frames.size()
var frame_time := 1.0 / 23.976

func _init(_frames: Array[Texture2D]) -> void:
	frames = _frames

func process(delta: float) -> bool:
	frame_progress += delta
	var frame_offset := int(frame_progress / frame_time)
	frame = (frame + frame_offset) % frame_count
	frame_progress -= frame_offset * frame_time
	return frame_offset > 0

func set_frame(i: int) -> void:
	frame = i % frame_count
	frame_progress = 0.0

func set_duration(millis: int) -> void:
	if millis != 0:
		frame_time = millis / 1000.0
		frame_time /= frame_count

func _draw(
	to_canvas_item: RID,
	pos: Vector2,
	modulate: Color,
	transpose: bool
) -> void:
	var texture: Texture2D = frames.get(frame)
	if texture:
		texture.draw(to_canvas_item, pos, modulate, transpose)

func _draw_rect(
	to_canvas_item: RID,
	rect: Rect2,
	tile: bool,
	modulate: Color,
	transpose: bool
) -> void:
	var texture: Texture2D = frames.get(frame)
	if texture:
		texture.draw_rect(to_canvas_item, rect, tile, modulate, transpose)

func _draw_rect_region(
	to_canvas_item: RID,
	rect: Rect2,
	src_rect: Rect2,
	modulate: Color,
	transpose: bool,
	clip_uv: bool
) -> void:
	var texture: Texture2D = frames.get(frame)
	if texture:
		texture.draw_rect_region(to_canvas_item, rect, src_rect, modulate, transpose, clip_uv)

func _get_height() -> int:
	var texture: Texture2D = frames.get(frame)
	if texture:
		return texture.get_height()
	return 0

func _get_width() -> int:
	var texture: Texture2D = frames.get(frame)
	if texture:
		return texture.get_width()
	return 0

func _has_alpha() -> bool:
	var texture: Texture2D = frames.get(frame)
	if texture:
		return texture.has_alpha()
	return false
