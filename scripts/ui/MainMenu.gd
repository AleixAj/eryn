extends Control

const CHARACTER_SELECT_SCENE: String = "res://scenes/ui/CharacterSelect.tscn"

@onready var title: Label = $Center/Content/Title
@onready var subtitle: Label = $Center/Content/Subtitle
@onready var play_button: Button = $Center/Content/PlayButton
@onready var options_button: Button = $Center/Content/OptionsButton
@onready var quit_button: Button = $Center/Content/QuitButton
@onready var toast: Label = $Toast


func _ready() -> void:
	if toast:
		toast.modulate.a = 0.0
	_intro_animation()


func _intro_animation() -> void:
	var elements: Array = [title, subtitle, play_button, options_button, quit_button]
	for e in elements:
		if e:
			e.modulate.a = 0.0
			e.scale = Vector2(0.85, 0.85)

	var t: Tween = create_tween()
	t.set_parallel(false)

	for i in elements.size():
		var e = elements[i]
		if not e:
			continue
		var step: Tween = create_tween()
		step.set_parallel(true)
		step.tween_property(e, "modulate:a", 1.0, 0.35)
		step.tween_property(e, "scale", Vector2(1.0, 1.0), 0.45) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await get_tree().create_timer(0.12).timeout


func _on_play_pressed() -> void:
	_set_buttons_disabled(true)
	SceneTransition.change_scene(CHARACTER_SELECT_SCENE)


func _on_options_pressed() -> void:
	_show_toast("Opciones - Próximamente")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _set_buttons_disabled(disabled: bool) -> void:
	if play_button:
		play_button.disabled = disabled
	if options_button:
		options_button.disabled = disabled
	if quit_button:
		quit_button.disabled = disabled


func _show_toast(text: String) -> void:
	if not toast:
		return
	toast.text = text
	var t: Tween = create_tween()
	t.tween_property(toast, "modulate:a", 1.0, 0.18)
	t.tween_interval(1.4)
	t.tween_property(toast, "modulate:a", 0.0, 0.4)
