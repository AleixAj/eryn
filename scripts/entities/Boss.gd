class_name Boss
extends Combatant


func _ready() -> void:
	sprite = $BossSprite
	hp_bar = $BossHPBar
	hp_label = $BossHPBar/BossHPLabel
	super._ready()
