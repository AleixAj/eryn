class_name Hero
extends Combatant


func _ready() -> void:
	sprite = $HeroSprite
	hp_bar = $HeroHPBar
	hp_label = $HeroHPBar/HeroHPLabel
	_apply_selected_hero()
	super._ready()


func _apply_selected_hero() -> void:
	if not GameState.has_selection():
		return
	var h: Dictionary = GameState.selected_hero
	max_hp = int(h.get("max_hp", max_hp))
	attack_damage = int(h.get("attack_damage", attack_damage))
	crit_chance = float(h.get("crit_chance", crit_chance))
	crit_multiplier = float(h.get("crit_multiplier", crit_multiplier))
	if sprite and h.has("tint") and h.tint is Array and h.tint.size() >= 3:
		sprite.modulate = Color(h.tint[0], h.tint[1], h.tint[2])
