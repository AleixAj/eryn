class_name Hero
extends Combatant


func _ready() -> void:
	sprite = $HeroSprite
	hp_bar = $HeroHPBar
	hp_label = $HeroHPBar/HeroHPLabel
	super._ready()
