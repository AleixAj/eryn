extends Node

enum State { PLAYER_TURN, PLAYER_ACTING, ENEMY_ACTING, VICTORY, DEFEAT }

@onready var hero: Hero = $"../Characters/PlayerParty/Hero"
@onready var boss: Boss = $"../Characters/EnemyParty/Boss"
@onready var log_label: Label = $"../UI/CombatUI/LogLabel"
@onready var turn_label: Label = $"../UI/CombatUI/TurnLabel"
@onready var attack_button: Button = $"../UI/CombatUI/AttackButton"
@onready var skill_button: Button = $"../UI/CombatUI/SkillButton"
@onready var result_panel: Control = $"../UI/CombatUI/ResultPanel"
@onready var result_label: Label = $"../UI/CombatUI/ResultPanel/ResultLabel"

var state: int = State.PLAYER_TURN


func _ready() -> void:
	if log_label:
		log_label.text = ""
	add_log("¡El combate ha comenzado!")

	if hero:
		hero.died.connect(_on_hero_died)
	if boss:
		boss.died.connect(_on_boss_died)

	if result_panel:
		result_panel.visible = false

	_update_turn_label()


func player_attack() -> void:
	if state != State.PLAYER_TURN:
		return
	state = State.PLAYER_ACTING
	_set_buttons_disabled(true)

	var result: Dictionary = await hero.attack(boss)
	if result.crit:
		add_log("★ ¡CRÍTICO! Eryn ataca por %d." % result.damage)
	else:
		add_log("Eryn ataca por %d." % result.damage)

	hero._attack_anim_return()

	if state == State.PLAYER_ACTING and boss.is_alive:
		await get_tree().create_timer(0.45).timeout
		_enemy_turn()


func player_skill() -> void:
	if state != State.PLAYER_TURN:
		return
	state = State.PLAYER_ACTING
	_set_buttons_disabled(true)

	add_log("✦ Eryn lanza Doble Tajo.")
	var result: Dictionary = await hero.skill(boss)
	if result.crit:
		add_log("★ ¡CRÍTICO! Daño total: %d." % result.damage)
	else:
		add_log("Daño total: %d." % result.damage)

	hero.reset_to_base()

	if state == State.PLAYER_ACTING and boss.is_alive:
		await get_tree().create_timer(0.55).timeout
		_enemy_turn()


func _enemy_turn() -> void:
	state = State.ENEMY_ACTING
	_update_turn_label()
	await get_tree().create_timer(0.6).timeout
	if not boss.is_alive or not hero.is_alive:
		return

	var result: Dictionary = await boss.attack(hero)
	if result.crit:
		add_log("★ ¡CRÍTICO! El boss te golpea por %d." % result.damage)
	else:
		add_log("El boss te golpea por %d." % result.damage)

	boss._attack_anim_return()

	if hero.is_alive and boss.is_alive:
		state = State.PLAYER_TURN
		_set_buttons_disabled(false)
		_update_turn_label()


func _on_hero_died() -> void:
	state = State.DEFEAT
	add_log("☠ Eryn ha caído...")
	_show_result("DERROTA", Color(0.95, 0.25, 0.25))
	_set_buttons_disabled(true)


func _on_boss_died() -> void:
	state = State.VICTORY
	add_log("★ ¡Has derrotado al boss!")
	_show_result("VICTORIA", Color(0.98, 0.85, 0.2))
	_set_buttons_disabled(true)


func _show_result(text: String, color: Color) -> void:
	if not result_panel or not result_label:
		return
	result_label.text = text
	result_label.modulate = color
	result_panel.modulate.a = 0.0
	result_panel.visible = true
	result_label.scale = Vector2(0.4, 0.4)

	var t: Tween = create_tween()
	t.set_parallel(true)
	t.tween_property(result_panel, "modulate:a", 1.0, 0.45)
	t.tween_property(result_label, "scale", Vector2(1.15, 1.15), 0.55) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.chain().tween_property(result_label, "scale", Vector2(1.0, 1.0), 0.18)


func restart() -> void:
	SceneTransition.reload_scene()


func back_to_menu() -> void:
	SceneTransition.change_scene("res://scenes/ui/MainMenu.tscn")


func _set_buttons_disabled(disabled: bool) -> void:
	if attack_button:
		attack_button.disabled = disabled
	if skill_button:
		skill_button.disabled = disabled


func _update_turn_label() -> void:
	if not turn_label:
		return
	var text: String = ""
	var color: Color = Color(1.0, 0.86, 0.36)
	match state:
		State.PLAYER_TURN:
			text = "✦  TURNO DEL HÉROE  ✦"
			color = Color(1.0, 0.86, 0.36)
		State.PLAYER_ACTING:
			text = "❖  ATACANDO  ❖"
			color = Color(0.92, 0.94, 1.0)
		State.ENEMY_ACTING:
			text = "☠  TURNO ENEMIGO  ☠"
			color = Color(0.86, 0.22, 0.22)
		_:
			text = ""

	if text == "":
		turn_label.text = ""
		return

	turn_label.text = text
	turn_label.add_theme_color_override("font_color", color)
	_punch_turn_label()


func _punch_turn_label() -> void:
	if not turn_label:
		return
	turn_label.scale = Vector2(0.7, 0.7)
	turn_label.modulate.a = 0.0
	var t: Tween = create_tween()
	t.set_parallel(true)
	t.tween_property(turn_label, "modulate:a", 1.0, 0.22)
	t.tween_property(turn_label, "scale", Vector2(1.08, 1.08), 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.chain().tween_property(turn_label, "scale", Vector2(1.0, 1.0), 0.14) \
		.set_trans(Tween.TRANS_QUAD)


func add_log(text: String) -> void:
	if not log_label:
		return
	log_label.text += text + "\n"
	if log_label.text.length() > 600:
		log_label.text = log_label.text.substr(log_label.text.length() - 500)
