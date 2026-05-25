extends Control

const COMBAT_SCENE: String = "res://scenes/game/CombatScene.tscn"
const MENU_SCENE: String = "res://scenes/ui/MainMenu.tscn"

const HERO_PORTRAIT: Texture2D = preload("res://assets/sprites/hero.png")

@onready var cards_container: HBoxContainer = $Center/Cards
@onready var description_label: Label = $Bottom/Description
@onready var confirm_button: Button = $Bottom/Buttons/ConfirmButton
@onready var back_button: Button = $Bottom/Buttons/BackButton

var selected_id: String = ""
var card_buttons: Dictionary = {}


func _ready() -> void:
	confirm_button.disabled = true
	description_label.text = "Selecciona un héroe para conocer su historia."
	_build_cards()
	_intro_animation()


func _build_cards() -> void:
	for hero in GameState.heroes:
		if hero is Dictionary:
			var card := _create_card(hero)
			cards_container.add_child(card)
			card_buttons[hero.get("id", "")] = card


func _create_card(hero: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(240, 400)
	btn.flat = false
	btn.text = ""
	btn.focus_mode = Control.FOCUS_NONE

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 12.0
	vbox.offset_top = 14.0
	vbox.offset_right = -12.0
	vbox.offset_bottom = -14.0
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 6)
	btn.add_child(vbox)

	var portrait := TextureRect.new()
	portrait.texture = HERO_PORTRAIT
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(0, 200)
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if hero.has("tint") and hero.tint is Array and hero.tint.size() >= 3:
		portrait.modulate = Color(hero.tint[0], hero.tint[1], hero.tint[2])
	vbox.add_child(portrait)

	var name_label := Label.new()
	name_label.text = String(hero.get("name", "?"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 30)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.36))
	name_label.add_theme_color_override("font_outline_color", Color(0.18, 0.08, 0.02))
	name_label.add_theme_constant_override("outline_size", 7)
	vbox.add_child(name_label)

	var class_label := Label.new()
	class_label.text = "✦ " + String(hero.get("class", "")) + " ✦"
	class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	class_label.add_theme_font_size_override("font_size", 16)
	class_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.62))
	class_label.add_theme_color_override("font_outline_color", Color(0.12, 0.06, 0.02))
	class_label.add_theme_constant_override("outline_size", 3)
	vbox.add_child(class_label)

	var sep := HSeparator.new()
	sep.modulate = Color(1, 0.86, 0.36, 0.4)
	vbox.add_child(sep)

	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 2)
	stats.add_child(_make_stat_line("HP", str(hero.get("max_hp", 0))))
	stats.add_child(_make_stat_line("ATK", str(hero.get("attack_damage", 0))))
	var cc: float = float(hero.get("crit_chance", 0.0)) * 100.0
	stats.add_child(_make_stat_line("CRIT", "%d%%" % int(round(cc))))
	vbox.add_child(stats)

	var hero_id: String = String(hero.get("id", ""))
	btn.pressed.connect(_on_card_pressed.bind(hero_id))
	return btn


func _make_stat_line(label_text: String, value_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = label_text
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color(0.85, 0.78, 0.6))
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var v := Label.new()
	v.text = value_text
	v.add_theme_font_size_override("font_size", 16)
	v.add_theme_color_override("font_color", Color(1, 0.94, 0.78))
	v.add_theme_color_override("font_outline_color", Color(0.12, 0.06, 0.02))
	v.add_theme_constant_override("outline_size", 3)
	row.add_child(v)
	return row


func _on_card_pressed(id: String) -> void:
	selected_id = id
	confirm_button.disabled = false
	var hero: Dictionary = GameState.get_hero(id)
	description_label.text = String(hero.get("description", ""))

	for cid in card_buttons.keys():
		var card: Button = card_buttons[cid]
		if cid == id:
			_animate_select(card)
		else:
			_animate_deselect(card)


func _animate_select(card: Button) -> void:
	var t: Tween = card.create_tween()
	t.set_parallel(true)
	t.tween_property(card, "modulate", Color(1, 1, 1, 1), 0.18)
	t.tween_property(card, "scale", Vector2(1.06, 1.06), 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _animate_deselect(card: Button) -> void:
	var t: Tween = card.create_tween()
	t.set_parallel(true)
	t.tween_property(card, "modulate", Color(0.55, 0.55, 0.6, 1), 0.18)
	t.tween_property(card, "scale", Vector2(0.96, 0.96), 0.18)


func _intro_animation() -> void:
	for card in card_buttons.values():
		card.modulate.a = 0.0
		card.scale = Vector2(0.85, 0.85)

	var i: int = 0
	for card in card_buttons.values():
		var t: Tween = card.create_tween()
		t.set_parallel(true)
		t.tween_property(card, "modulate:a", 1.0, 0.35).set_delay(i * 0.1)
		t.tween_property(card, "scale", Vector2(1.0, 1.0), 0.45) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(i * 0.1)
		i += 1


func _on_confirm_pressed() -> void:
	if selected_id == "":
		return
	GameState.selected_hero = GameState.get_hero(selected_id)
	SceneTransition.change_scene(COMBAT_SCENE)


func _on_back_pressed() -> void:
	SceneTransition.change_scene(MENU_SCENE)
