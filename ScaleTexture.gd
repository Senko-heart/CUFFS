class_name ScaleTexture
extends Texture2D

var texture: Texture2D
var scale: Vector2

func _init(_texture: Texture2D, _scale: Vector2 = Vector2.ONE) -> void:
	texture = _texture
	scale = _scale

func _draw(
	to_canvas_item: RID,
	pos: Vector2,
	modulate: Color,
	transpose: bool
) -> void:
	var src_rect := Rect2(Vector2.ZERO, texture.get_size())
	var rect := Rect2(pos, src_rect.size / scale)
	var clip_uv := false
	texture.draw_rect_region(to_canvas_item, rect, src_rect, modulate, transpose, clip_uv)

func _draw_rect(
	to_canvas_item: RID,
	rect: Rect2,
	tile: bool,
	modulate: Color,
	transpose: bool
) -> void:
	var src_rect := Rect2(rect.position, rect.size / scale)
	var clip_uv := not tile
	texture.draw_rect_region(to_canvas_item, rect, src_rect, modulate, transpose, clip_uv)

func _draw_rect_region(
	to_canvas_item: RID,
	rect: Rect2,
	src_rect: Rect2,
	modulate: Color,
	transpose: bool,
	clip_uv: bool
) -> void:
	src_rect.size /= scale
	texture.draw_rect_region(to_canvas_item, rect, src_rect, modulate, transpose, clip_uv)

func _get_height() -> int:
	return int(texture.get_height() * scale.y)

func _get_width() -> int:
	return int(texture.get_width() * scale.x)

func _has_alpha() -> bool:
	return texture.has_alpha()
