class_name Combatant
extends Node2D

signal died

@export var max_hp: int = 100
@export var attack_damage: int = 25
@export var crit_chance: float = 0.15
@export var crit_multiplier: float = 1.8

var current_hp: int
var is_alive: bool = true

var sprite: Sprite2D
var hp_bar: TextureProgressBar
var hp_label: Label

var _base_position: Vector2
var _base_scale: Vector2
var _base_modulate: Color = Color.WHITE

var _hp_tween: Tween


func _ready() -> void:
	current_hp = max_hp
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp
	_set_hp_label_value(float(current_hp))
	if sprite:
		_base_position = sprite.position
		_base_scale = sprite.scale
		_base_modulate = sprite.modulate


func take_damage(amount: int, is_crit: bool = false) -> void:
	if not is_alive:
		return
	current_hp = max(0, current_hp - amount)
	_tween_hp_bar()
	spawn_damage_number(amount, is_crit)
	_hit_reaction()
	if current_hp <= 0:
		is_alive = false
		_die()


func heal(amount: int) -> void:
	if not is_alive:
		return
	current_hp = min(max_hp, current_hp + amount)
	_tween_hp_bar()


func attack(target: Combatant) -> Dictionary:
	if not is_alive or target == null or not target.is_alive:
		return {"damage": 0, "crit": false}

	var is_crit: bool = randf() < crit_chance
	var damage: int = attack_damage
	if is_crit:
		damage = int(round(damage * crit_multiplier))
	damage = max(1, damage)

	await _attack_anim(target)
	target.take_damage(damage, is_crit)
	return {"damage": damage, "crit": is_crit}


func skill(target: Combatant) -> Dictionary:
	if not is_alive or target == null or not target.is_alive:
		return {"damage": 0, "crit": false}

	await _skill_anim(target)

	var total_damage: int = 0
	var any_crit: bool = false
	for i in 2:
		if not target.is_alive:
			break
		var is_crit: bool = randf() < (crit_chance + 0.05)
		var damage: int = int(round(attack_damage * 0.7))
		if is_crit:
			damage = int(round(damage * crit_multiplier))
			any_crit = true
		damage = max(1, damage)
		target.take_damage(damage, is_crit)
		total_damage += damage
		await get_tree().create_timer(0.22).timeout

	return {"damage": total_damage, "crit": any_crit}


func spawn_damage_number(amount: int, is_crit: bool = false) -> void:
	var holder := Node2D.new()
	holder.position = Vector2(0, -120)
	add_child(holder)

	var label := Label.new()
	label.text = ("-%d!" % amount) if is_crit else ("-%d" % amount)
	var color: Color = Color(1.0, 0.85, 0.18) if is_crit else Color(1.0, 0.32, 0.32)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	label.add_theme_font_size_override("font_size", 40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(220, 64)
	label.position = Vector2(-110, -32)
	label.pivot_offset = Vector2(110, 32)
	label.scale = Vector2(1.5, 1.5) if is_crit else Vector2(1.0, 1.0)
	holder.add_child(label)

	var random_x: float = randf_range(-28.0, 28.0)
	var target_x: float = holder.position.x + random_x
	var target_y: float = holder.position.y - 110.0

	var move: Tween = holder.create_tween()
	move.set_parallel(true)
	move.tween_property(holder, "position:x", target_x, 0.9) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	move.tween_property(holder, "position:y", target_y, 0.9) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	move.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.5)

	if is_crit:
		var pop: Tween = holder.create_tween()
		pop.tween_property(label, "scale", Vector2(2.1, 2.1), 0.12) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop.tween_property(label, "scale", Vector2(1.4, 1.4), 0.18) \
			.set_trans(Tween.TRANS_QUAD)

	move.finished.connect(holder.queue_free)


func _tween_hp_bar() -> void:
	if not hp_bar:
		return
	if _hp_tween and _hp_tween.is_valid():
		_hp_tween.kill()
	_hp_tween = create_tween()
	_hp_tween.set_parallel(true)
	_hp_tween.tween_property(hp_bar, "value", current_hp, 0.35).set_trans(Tween.TRANS_CUBIC)
	if hp_label:
		_hp_tween.tween_method(_set_hp_label_value, float(hp_bar.value), float(current_hp), 0.35) \
			.set_trans(Tween.TRANS_CUBIC)


func _set_hp_label_value(v: float) -> void:
	if hp_label:
		hp_label.text = "%d / %d" % [int(round(v)), max_hp]


func _hit_reaction() -> void:
	if not sprite:
		return

	var flash: Tween = create_tween()
	flash.tween_property(sprite, "modulate", Color(1.6, 0.45, 0.45), 0.06)
	flash.tween_property(sprite, "modulate", _base_modulate, 0.22)

	var shake: Tween = create_tween()
	for i in 6:
		var off: Vector2 = Vector2(randf_range(-7.0, 7.0), randf_range(-3.0, 3.0))
		shake.tween_property(sprite, "position", _base_position + off, 0.04)
	shake.tween_property(sprite, "position", _base_position, 0.05)


func _die() -> void:
	if hp_bar:
		if _hp_tween and _hp_tween.is_valid():
			_hp_tween.kill()
		hp_bar.value = 0
	_set_hp_label_value(0.0)
	emit_signal("died")
	if not sprite:
		return
	var t: Tween = create_tween()
	t.set_parallel(true)
	t.tween_property(sprite, "modulate", Color(0.35, 0.35, 0.4, 0.35), 0.55)
	t.tween_property(sprite, "rotation", deg_to_rad(75.0), 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_property(sprite, "position", _base_position + Vector2(0, 18), 0.55).set_trans(Tween.TRANS_CUBIC)
	if hp_bar:
		t.tween_property(hp_bar, "modulate:a", 0.0, 0.5)


func _attack_anim(target: Combatant) -> void:
	if not sprite:
		return
	var dir: float = sign(target.global_position.x - global_position.x)
	if dir == 0.0:
		dir = 1.0

	var t: Tween = create_tween()
	t.tween_property(sprite, "position", _base_position + Vector2(-22.0 * dir, -6.0), 0.16) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(sprite, "position", _base_position + Vector2(85.0 * dir, 0.0), 0.13) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await t.finished


func _attack_anim_return() -> void:
	if not sprite:
		return
	var t: Tween = create_tween()
	t.tween_property(sprite, "position", _base_position, 0.30) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _skill_anim(target: Combatant) -> void:
	if not sprite:
		return
	var dir: float = sign(target.global_position.x - global_position.x)
	if dir == 0.0:
		dir = 1.0

	var t: Tween = create_tween()
	t.set_parallel(true)
	t.tween_property(sprite, "scale", _base_scale * 1.18, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(sprite, "modulate", Color(1.4, 1.4, 1.9), 0.18)
	t.tween_property(sprite, "position", _base_position + Vector2(-30.0 * dir, -25.0), 0.22)
	await t.finished

	var t2: Tween = create_tween()
	t2.tween_property(sprite, "position", _base_position + Vector2(70.0 * dir, 0.0), 0.14) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await t2.finished


func reset_to_base() -> void:
	if not sprite:
		return
	var t: Tween = create_tween()
	t.set_parallel(true)
	t.tween_property(sprite, "position", _base_position, 0.30).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(sprite, "scale", _base_scale, 0.30)
	t.tween_property(sprite, "modulate", _base_modulate, 0.30)
