extends Control

enum BattleState { PLAYER_TURN, ACTING, BOSS_TURN, VICTORY, DEFEAT }

const MENU_SCENE: String = "res://scenes/ui/MainMenu.tscn"

@onready var warrior: Node2D = $Battlefield/Warrior
@onready var wizard: Node2D = $Battlefield/Wizard
@onready var boss: Node2D = $Battlefield/Smaug
@onready var warrior_sprite: Sprite2D = $Battlefield/Warrior/Sprite
@onready var wizard_sprite: Sprite2D = $Battlefield/Wizard/Sprite
@onready var boss_sprite: Sprite2D = $Battlefield/Smaug/Sprite
@onready var effects: Node2D = $Effects

@onready var turn_label: Label = $UI/TurnBanner/TurnLabel
@onready var log_label: Label = $UI/LogPanel/LogLabel
@onready var attack_button: Button = $UI/CommandPanel/AttackButton
@onready var skill_button: Button = $UI/CommandPanel/SkillButton
@onready var menu_button: Button = $UI/CommandPanel/MenuButton
@onready var result_panel: Control = $UI/ResultPanel
@onready var result_label: Label = $UI/ResultPanel/ResultLabel

@onready var warrior_hp_bar: ProgressBar = $UI/PartyPanel/WarriorPanel/HPBar
@onready var warrior_hp_label: Label = $UI/PartyPanel/WarriorPanel/HPLabel
@onready var wizard_hp_bar: ProgressBar = $UI/PartyPanel/WizardPanel/HPBar
@onready var wizard_hp_label: Label = $UI/PartyPanel/WizardPanel/HPLabel
@onready var boss_hp_bar: ProgressBar = $UI/BossPanel/HPBar
@onready var boss_hp_label: Label = $UI/BossPanel/HPLabel

var state: int = BattleState.PLAYER_TURN
var active_index: int = 0
var heroes: Array[Dictionary] = [
	{
		"name": "Guerrero",
		"node": null,
		"sprite": null,
		"hp": 135,
		"max_hp": 135,
		"attack": 22,
		"skill": 34,
		"bar": null,
		"label": null,
		"base": Vector2.ZERO,
		"alive": true
	},
	{
		"name": "Mago",
		"node": null,
		"sprite": null,
		"hp": 92,
		"max_hp": 92,
		"attack": 17,
		"skill": 45,
		"bar": null,
		"label": null,
		"base": Vector2.ZERO,
		"alive": true
	}
]
var boss_stats: Dictionary = {
	"name": "Smaug",
	"hp": 260,
	"max_hp": 260,
	"attack": 26,
	"base": Vector2.ZERO,
	"alive": true
}


func _ready() -> void:
	randomize()
	_setup_refs()
	_style_buttons()
	_style_bars()
	_update_all_hp()
	result_panel.visible = false
	_set_buttons_disabled(false)
	_set_active_hero(0)
	_intro()
	_log("Smaug desciende sobre las ruinas de la montaña.")


func _setup_refs() -> void:
	heroes[0].node = warrior
	heroes[0].sprite = warrior_sprite
	heroes[0].bar = warrior_hp_bar
	heroes[0].label = warrior_hp_label
	heroes[0].base = warrior.position
	heroes[1].node = wizard
	heroes[1].sprite = wizard_sprite
	heroes[1].bar = wizard_hp_bar
	heroes[1].label = wizard_hp_label
	heroes[1].base = wizard.position
	boss_stats.base = boss.position


func _style_buttons() -> void:
	for btn in [attack_button, skill_button, menu_button]:
		_apply_button_style(btn)


func _apply_button_style(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.07, 0.04, 0.82)
	normal.border_color = Color(0.78, 0.60, 0.26)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(8)
	normal.shadow_color = Color(0, 0, 0, 0.45)
	normal.shadow_size = 4
	normal.shadow_offset = Vector2(0, 2)
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(0.22, 0.12, 0.06, 0.92)
	hover.border_color = Color(1.0, 0.82, 0.36)
	hover.set_border_width_all(3)

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color(0.07, 0.04, 0.02, 0.95)
	pressed.border_color = Color(0.62, 0.46, 0.18)

	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color(0.10, 0.07, 0.05, 0.45)
	disabled.border_color = Color(0.45, 0.35, 0.18, 0.7)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.66))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.80))
	btn.add_theme_color_override("font_pressed_color", Color(0.82, 0.70, 0.42))
	btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.50, 0.42))
	btn.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.0, 1.0))
	btn.add_theme_constant_override("outline_size", 4)


func _style_bars() -> void:
	_apply_bar_style(warrior_hp_bar, Color(0.92, 0.22, 0.18), Color(0.55, 0.08, 0.06))
	_apply_bar_style(wizard_hp_bar, Color(0.42, 0.7, 1.0), Color(0.1, 0.18, 0.55))
	_apply_bar_style(boss_hp_bar, Color(1.0, 0.32, 0.1), Color(0.45, 0.06, 0.02))
	_add_bar_shine(warrior_hp_bar)
	_add_bar_shine(wizard_hp_bar)
	_add_bar_shine(boss_hp_bar)


func _apply_bar_style(bar: ProgressBar, fill_top: Color, fill_bottom: Color) -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.07, 0.05, 0.03, 1.0)
	background.border_color = Color(0.85, 0.66, 0.28)
	background.set_border_width_all(3)
	background.set_corner_radius_all(6)
	background.shadow_color = Color(0, 0, 0, 0.55)
	background.shadow_size = 4
	background.shadow_offset = Vector2(0, 2)
	background.content_margin_left = 3
	background.content_margin_right = 3
	background.content_margin_top = 3
	background.content_margin_bottom = 3

	var foreground := StyleBoxFlat.new()
	foreground.bg_color = fill_top
	foreground.set_corner_radius_all(4)
	foreground.border_color = Color(fill_top.r * 1.25, fill_top.g * 1.25, fill_top.b * 1.25, 1.0)
	foreground.set_border_width_all(0)
	foreground.shadow_color = Color(fill_bottom.r, fill_bottom.g, fill_bottom.b, 0.85)
	foreground.shadow_size = 5
	foreground.shadow_offset = Vector2(0, 2)

	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", foreground)


func _add_bar_shine(bar: ProgressBar) -> void:
	if bar.has_node("Shine"):
		return
	var shine := ColorRect.new()
	shine.name = "Shine"
	shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shine.color = Color(1, 1, 1, 0.18)
	shine.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	shine.offset_left = 6
	shine.offset_right = -6
	shine.offset_top = 4
	shine.offset_bottom = 9
	bar.add_child(shine)


func _intro() -> void:
	var actors: Array[Node2D] = [warrior, wizard, boss]
	for actor in actors:
		actor.modulate.a = 0.0
		actor.scale *= 0.88
	for actor in actors:
		var t := create_tween()
		t.set_parallel(true)
		t.tween_property(actor, "modulate:a", 1.0, 0.35)
		t.tween_property(actor, "scale", actor.scale / 0.88, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await get_tree().create_timer(0.12).timeout


func _on_attack_pressed() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	await _hero_action(false)


func _on_skill_pressed() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	await _hero_action(true)


func _hero_action(use_skill: bool) -> void:
	state = BattleState.ACTING
	_set_buttons_disabled(true)
	var hero: Dictionary = heroes[active_index]
	var damage: int = int(hero.skill if use_skill else hero.attack)
	var crit: bool = randf() < (0.22 if use_skill else 0.14)
	if crit:
		damage = int(round(damage * 1.75))

	if use_skill and active_index == 1:
		await _cast_spell(hero, damage, crit)
	elif use_skill:
		await _warrior_heavy_slash(hero, damage, crit)
	else:
		await _basic_attack(hero, damage, crit)

	if not bool(boss_stats.alive):
		_victory()
		return

	_next_living_hero_or_boss()


func _basic_attack(hero: Dictionary, damage: int, crit: bool) -> void:
	var node: Node2D = hero.node
	var base: Vector2 = hero.base
	var dir: float = sign(boss.position.x - node.position.x)
	var t := create_tween()
	t.tween_property(node, "position", base + Vector2(64.0 * dir, -8.0), 0.16).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(node, "position", base + Vector2(122.0 * dir, 0.0), 0.10).set_trans(Tween.TRANS_CUBIC)
	await t.finished
	_damage_boss(damage, crit, "golpea")
	await _hit_flash(boss_sprite, boss)
	var back := create_tween()
	back.tween_property(node, "position", base, 0.25).set_trans(Tween.TRANS_CUBIC)
	await back.finished


func _warrior_heavy_slash(hero: Dictionary, damage: int, crit: bool) -> void:
	var node: Node2D = hero.node
	var base: Vector2 = hero.base
	var sprite: Sprite2D = hero.sprite
	var original_scale: Vector2 = sprite.scale
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(sprite, "scale", original_scale * 1.18, 0.18).set_trans(Tween.TRANS_BACK)
	t.tween_property(sprite, "modulate", Color(1.35, 1.1, 0.75), 0.14)
	t.tween_property(node, "position", base + Vector2(170, -18), 0.22).set_trans(Tween.TRANS_CUBIC)
	await t.finished
	_spawn_slash(boss.position + Vector2(-120, -90))
	_damage_boss(damage, crit, "parte la armadura de")
	await _hit_flash(boss_sprite, boss)
	var back := create_tween()
	back.set_parallel(true)
	back.tween_property(node, "position", base, 0.28)
	back.tween_property(sprite, "modulate", Color.WHITE, 0.22)
	back.tween_property(sprite, "scale", original_scale, 0.22)
	await back.finished


func _cast_spell(hero: Dictionary, damage: int, crit: bool) -> void:
	var node: Node2D = hero.node
	var sprite: Sprite2D = hero.sprite
	var base: Vector2 = hero.base
	var charge := create_tween()
	charge.set_parallel(true)
	charge.tween_property(sprite, "modulate", Color(0.65, 0.9, 1.8), 0.18)
	charge.tween_property(node, "position", base + Vector2(0, -16), 0.18).set_trans(Tween.TRANS_BACK)
	await charge.finished

	var orb := Polygon2D.new()
	orb.polygon = PackedVector2Array([
		Vector2(0, -18), Vector2(15, -8), Vector2(15, 8), Vector2(0, 18), Vector2(-15, 8), Vector2(-15, -8)
	])
	orb.color = Color(0.45, 0.95, 1.0, 0.9)
	orb.position = node.position + Vector2(34, -92)
	effects.add_child(orb)
	var fly := create_tween()
	fly.set_parallel(true)
	fly.tween_property(orb, "position", boss.position + Vector2(-110, -100), 0.42).set_trans(Tween.TRANS_CUBIC)
	fly.tween_property(orb, "rotation", TAU * 2.0, 0.42)
	fly.tween_property(orb, "scale", Vector2(2.2, 2.2), 0.42)
	await fly.finished
	orb.queue_free()
	_spawn_magic_burst(boss.position + Vector2(-110, -100))
	_damage_boss(damage, crit, "lanza un hechizo contra")
	await _hit_flash(boss_sprite, boss)
	var recover := create_tween()
	recover.set_parallel(true)
	recover.tween_property(sprite, "modulate", Color.WHITE, 0.22)
	recover.tween_property(node, "position", base, 0.22)
	await recover.finished


func _damage_boss(amount: int, crit: bool, verb: String) -> void:
	boss_stats.hp = max(0, int(boss_stats.hp) - amount)
	_tween_hp(boss_hp_bar, boss_hp_label, int(boss_stats.hp), int(boss_stats.max_hp))
	_damage_number(boss.position + Vector2(-80, -190), amount, crit)
	_log("%s %s Smaug por %d%s." % [heroes[active_index].name, verb, amount, " CRÍTICO" if crit else ""])
	if int(boss_stats.hp) <= 0:
		boss_stats.alive = false


func _next_living_hero_or_boss() -> void:
	if active_index == 0 and bool(heroes[1].alive):
		active_index = 1
		_set_active_hero(active_index)
		state = BattleState.PLAYER_TURN
		_set_buttons_disabled(false)
	else:
		_boss_turn()


func _boss_turn() -> void:
	state = BattleState.BOSS_TURN
	_set_buttons_disabled(true)
	turn_label.text = "☠  IRA DEL DRAGÓN  ☠"
	turn_label.add_theme_color_override("font_color", Color(1.0, 0.28, 0.16))
	await get_tree().create_timer(0.55).timeout
	var living := heroes.filter(func(h: Dictionary) -> bool: return bool(h.alive))
	if living.is_empty():
		_defeat()
		return
	var target: Dictionary = living.pick_random()
	await _boss_breath(target)
	if heroes.filter(func(h: Dictionary) -> bool: return bool(h.alive)).is_empty():
		_defeat()
		return
	active_index = _first_living_hero_index()
	_set_active_hero(active_index)
	state = BattleState.PLAYER_TURN
	_set_buttons_disabled(false)


func _boss_breath(target: Dictionary) -> void:
	var damage: int = int(boss_stats.attack) + randi_range(-4, 8)
	var crit: bool = randf() < 0.12
	if crit:
		damage = int(round(damage * 1.6))
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(boss, "position", Vector2(boss_stats.base.x - 48, boss_stats.base.y - 12), 0.20)
	t.tween_property(boss_sprite, "modulate", Color(1.6, 0.75, 0.45), 0.16)
	await t.finished
	_spawn_fire(target.node.position + Vector2(40, -80))
	_damage_hero(target, damage, crit)
	await _hit_flash(target.sprite, target.node)
	var back := create_tween()
	back.set_parallel(true)
	back.tween_property(boss, "position", boss_stats.base, 0.24)
	back.tween_property(boss_sprite, "modulate", Color.WHITE, 0.2)
	await back.finished


func _damage_hero(hero: Dictionary, amount: int, crit: bool) -> void:
	hero.hp = max(0, int(hero.hp) - amount)
	_tween_hp(hero.bar, hero.label, int(hero.hp), int(hero.max_hp))
	_damage_number(hero.node.position + Vector2(0, -135), amount, crit)
	_log("Smaug abrasa a %s por %d%s." % [hero.name, amount, " CRÍTICO" if crit else ""])
	if int(hero.hp) <= 0:
		hero.alive = false
		_faint(hero)


func _faint(hero: Dictionary) -> void:
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(hero.sprite, "modulate", Color(0.25, 0.25, 0.3, 0.35), 0.4)
	t.tween_property(hero.node, "rotation", deg_to_rad(-18), 0.4)
	t.tween_property(hero.node, "position", hero.base + Vector2(0, 22), 0.4)


func _set_active_hero(index: int) -> void:
	active_index = index
	var hero: Dictionary = heroes[index]
	turn_label.text = "✦ TURNO DE %s ✦" % String(hero.name).to_upper()
	turn_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.36))
	for i in heroes.size():
		var h: Dictionary = heroes[i]
		if bool(h.alive):
			h.sprite.modulate = Color.WHITE if i == index else Color(0.72, 0.72, 0.78)
	_punch(turn_label)


func _first_living_hero_index() -> int:
	for i in heroes.size():
		if bool(heroes[i].alive):
			return i
	return 0


func _update_all_hp() -> void:
	for h in heroes:
		var bar: ProgressBar = h.bar
		bar.max_value = int(h.max_hp)
		bar.value = int(h.hp)
		h.label.text = "%d / %d" % [int(h.hp), int(h.max_hp)]
	boss_hp_bar.max_value = int(boss_stats.max_hp)
	boss_hp_bar.value = int(boss_stats.hp)
	boss_hp_label.text = "%d / %d" % [int(boss_stats.hp), int(boss_stats.max_hp)]


func _tween_hp(bar: ProgressBar, label: Label, value: int, max_value: int) -> void:
	var start: float = bar.value
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(bar, "value", value, 0.32).set_trans(Tween.TRANS_CUBIC)
	t.tween_method(func(v: float) -> void:
		label.text = "%d / %d" % [int(round(v)), max_value],
		start,
		float(value),
		0.32
	).set_trans(Tween.TRANS_CUBIC)


func _damage_number(pos: Vector2, amount: int, crit: bool) -> void:
	var label := Label.new()
	label.text = "-%d%s" % [amount, "!" if crit else ""]
	label.position = pos
	label.size = Vector2(180, 64)
	label.pivot_offset = Vector2(90, 32)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 44 if crit else 34)
	label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.16) if crit else Color(1.0, 0.25, 0.18))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	effects.add_child(label)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(label, "position", pos + Vector2(randf_range(-36, 36), -95), 0.85).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(label, "modulate:a", 0.0, 0.35).set_delay(0.45)
	t.tween_property(label, "scale", Vector2(1.35, 1.35) if crit else Vector2(0.8, 0.8), 0.75)
	t.finished.connect(label.queue_free)


func _hit_flash(sprite: Sprite2D, node: Node2D) -> void:
	var base := node.position
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(sprite, "modulate", Color(1.7, 0.45, 0.35), 0.07)
	t.tween_property(sprite, "modulate", Color.WHITE, 0.18).set_delay(0.07)
	for i in 5:
		var shake := create_tween()
		shake.tween_property(node, "position", base + Vector2(randf_range(-8, 8), randf_range(-4, 4)), 0.035)
		await shake.finished
	node.position = base


func _spawn_slash(pos: Vector2) -> void:
	var slash := Polygon2D.new()
	slash.polygon = PackedVector2Array([Vector2(-70, -10), Vector2(80, -28), Vector2(92, -2), Vector2(-58, 30)])
	slash.color = Color(1.0, 0.9, 0.55, 0.85)
	slash.position = pos
	slash.rotation = deg_to_rad(-18)
	effects.add_child(slash)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(slash, "modulate:a", 0.0, 0.22)
	t.tween_property(slash, "scale", Vector2(1.4, 1.4), 0.22)
	t.finished.connect(slash.queue_free)


func _spawn_magic_burst(pos: Vector2) -> void:
	for i in 10:
		var shard := Polygon2D.new()
		shard.polygon = PackedVector2Array([Vector2(0, -8), Vector2(6, 0), Vector2(0, 8), Vector2(-6, 0)])
		shard.color = Color(0.42, 0.95, 1.0, 0.9)
		shard.position = pos
		effects.add_child(shard)
		var dir := Vector2.RIGHT.rotated(TAU * float(i) / 10.0)
		var t := create_tween()
		t.set_parallel(true)
		t.tween_property(shard, "position", pos + dir * randf_range(36, 74), 0.35)
		t.tween_property(shard, "modulate:a", 0.0, 0.35)
		t.finished.connect(shard.queue_free)


func _spawn_fire(pos: Vector2) -> void:
	for i in 9:
		var flame := Polygon2D.new()
		flame.polygon = PackedVector2Array([Vector2(0, -22), Vector2(14, 10), Vector2(0, 20), Vector2(-14, 10)])
		flame.color = Color(1.0, randf_range(0.25, 0.72), 0.05, 0.82)
		flame.position = boss.position + Vector2(-110, -120)
		flame.scale = Vector2(randf_range(0.8, 1.4), randf_range(0.8, 1.4))
		effects.add_child(flame)
		var t := create_tween()
		t.set_parallel(true)
		t.tween_property(flame, "position", pos + Vector2(randf_range(-45, 45), randf_range(-30, 30)), 0.28 + i * 0.015)
		t.tween_property(flame, "modulate:a", 0.0, 0.5).set_delay(0.1)
		t.finished.connect(flame.queue_free)


func _punch(label: Label) -> void:
	label.scale = Vector2(0.75, 0.75)
	var t := create_tween()
	t.tween_property(label, "scale", Vector2(1.08, 1.08), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(label, "scale", Vector2(1.0, 1.0), 0.12)


func _set_buttons_disabled(disabled: bool) -> void:
	attack_button.disabled = disabled
	skill_button.disabled = disabled
	menu_button.disabled = disabled


func _log(text: String) -> void:
	log_label.text += text + "\n"
	if log_label.text.length() > 520:
		log_label.text = log_label.text.substr(log_label.text.length() - 430)


func _victory() -> void:
	state = BattleState.VICTORY
	_set_buttons_disabled(true)
	result_label.text = "VICTORIA"
	result_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.28))
	result_panel.visible = true
	_log("Smaug cae entre brasas y humo.")
	_show_result()


func _defeat() -> void:
	state = BattleState.DEFEAT
	_set_buttons_disabled(true)
	result_label.text = "DERROTA"
	result_label.add_theme_color_override("font_color", Color(1.0, 0.22, 0.16))
	result_panel.visible = true
	_log("La montaña guarda silencio.")
	_show_result()


func _show_result() -> void:
	result_panel.modulate.a = 0.0
	result_label.scale = Vector2(0.6, 0.6)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(result_panel, "modulate:a", 1.0, 0.35)
	t.tween_property(result_label, "scale", Vector2(1.1, 1.1), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_restart_button_pressed() -> void:
	SceneTransition.reload_scene()


func _on_menu_button_pressed() -> void:
	SceneTransition.change_scene(MENU_SCENE)


func _on_command_menu_pressed() -> void:
	SceneTransition.change_scene(MENU_SCENE)
