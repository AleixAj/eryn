extends Control

const CHARACTER_SELECT_SCENE: String = "res://scenes/ui/CharacterSelect.tscn"
const TEST_BATTLE_SCENE: String = "res://scenes/game/TestBattle.tscn"

@onready var title: Label = $Center/Content/Title
@onready var subtitle: Label = $Center/Content/Subtitle
@onready var play_button: Button = $Center/Content/PlayButton
@onready var test_button: Button = $Center/Content/TestButton
@onready var options_button: Button = $Center/Content/OptionsButton
@onready var quit_button: Button = $Center/Content/QuitButton
@onready var toast: Label = $Toast


func _ready() -> void:
	if toast:
		toast.modulate.a = 0.0
	_intro_animation()


func _intro_animation() -> void:
	var elements: Array = [title, subtitle, play_button, test_button, options_button, quit_button]
	for e in elements:
		if e:
			e.modulate.a = 0.0
			e.scale = Vector2(0.9, 0.9)

	var stagger: float = 0.05
	for i in elements.size():
		var e: Control = elements[i]
		if not e:
			continue
		var delay: float = i * stagger
		var t: Tween = create_tween()
		t.set_parallel(true)
		t.tween_property(e, "modulate:a", 1.0, 0.22).set_delay(delay)
		t.tween_property(e, "scale", Vector2(1.0, 1.0), 0.30) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT) \
			.set_delay(delay)


func _on_play_pressed() -> void:
	_set_buttons_disabled(true)
	SceneTransition.change_scene(CHARACTER_SELECT_SCENE)


func _on_test_pressed() -> void:
	_set_buttons_disabled(true)
	SceneTransition.change_scene(TEST_BATTLE_SCENE)


func _on_options_pressed() -> void:
	_show_toast("Opciones - Próximamente")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _set_buttons_disabled(disabled: bool) -> void:
	if play_button:
		play_button.disabled = disabled
	if test_button:
		test_button.disabled = disabled
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
