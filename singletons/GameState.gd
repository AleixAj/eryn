extends Node

const HEROES_PATH: String = "res://data/heroes.json"

var heroes: Array = []
var selected_hero: Dictionary = {}


func _ready() -> void:
	_load_heroes()


func _load_heroes() -> void:
	var file := FileAccess.open(HEROES_PATH, FileAccess.READ)
	if file == null:
		push_error("No se pudo abrir heroes.json")
		return
	var raw: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(raw)
	if parsed is Array:
		heroes = parsed
	else:
		push_error("heroes.json no es un array válido")


func get_hero(id: String) -> Dictionary:
	for h in heroes:
		if h is Dictionary and h.get("id", "") == id:
			return h
	return {}


func has_selection() -> bool:
	return not selected_hero.is_empty()
