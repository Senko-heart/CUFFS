class_name EffectSprite2D
extends Sprite2D

const EffectType := EffectParam.EffectType

var effect := EffectParam.new():
	set(value):
		effect = value
		if is_processing():
			restart_effect()
		else:
			queue_redraw()

var elapsed_time := 0.0

func _init() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

func _process(delta: float) -> void:
	elapsed_time += delta
	if effect.type == EffectType.TileImage:
		var interval := effect.interval / 1000.0
		var change := int(elapsed_time / interval)
		elapsed_time -= change * interval
		region_rect.position -= Vector2(effect.pt_speed * change)
		region_rect.position = region_rect.position.posmodv(region_rect.size)
		if change > 0:
			queue_redraw()

func restart_effect() -> void:
	elapsed_time = 0.0
	region_enabled = false
	if effect.type == EffectType.TileImage:
		region_enabled = true
		region_rect = Rect2(Vector2.ZERO, effect.size_view)
	queue_redraw()

func copy_effect(src: EffectSprite2D) -> void:
	effect = src.effect
	region_enabled = src.region_enabled
	region_rect = src.region_rect
