extends CanvasLayer

const FADE_DURATION: float = 0.35

@onready var rect: ColorRect = $Rect

var _is_transitioning: bool = false


func _ready() -> void:
	layer = 100
	rect.color = Color(0, 0, 0, 1)
	rect.modulate.a = 0.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func change_scene(path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var fade_out: Tween = create_tween()
	fade_out.tween_property(rect, "modulate:a", 1.0, FADE_DURATION) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await fade_out.finished

	var err: int = get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Error al cambiar de escena: %s (code %d)" % [path, err])

	await get_tree().process_frame
	await get_tree().process_frame

	var fade_in: Tween = create_tween()
	fade_in.tween_property(rect, "modulate:a", 0.0, FADE_DURATION) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await fade_in.finished

	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning = false


func reload_scene() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var fade_out: Tween = create_tween()
	fade_out.tween_property(rect, "modulate:a", 1.0, FADE_DURATION) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await fade_out.finished

	get_tree().reload_current_scene()
	await get_tree().process_frame

	var fade_in: Tween = create_tween()
	fade_in.tween_property(rect, "modulate:a", 0.0, FADE_DURATION) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await fade_in.finished

	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning = false
