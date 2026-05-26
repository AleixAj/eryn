extends Control
class_name Dice2DRoller

# Versión "clásica" del lanzamiento: un dado 2D que cae desde la esquina
# superior derecha, rebota y rueda por el suelo hasta el centro mientras
# las caras del dado se ciclan rápidamente. Usa los sprites de
# runebit_arcane_d20 (1..20). Ideal para conservar el estilo pixel-art.

signal rolled(value: int)

const DICE_FACES_PATH: String = "res://assets/sprites/runebit_arcane_d20/png_512/d20/"
const DICE_SIZE: float = 240.0

var _dice_faces: Array[Texture2D] = []
var _dim: ColorRect
var _stage: Control
var _shadow: Panel
var _dice: TextureRect


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_preload_dice_faces()
	_build_overlay()
	modulate.a = 0.0
	call_deferred("_fit_to_viewport")


func _fit_to_viewport() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_offsets_preset(Control.PRESET_FULL_RECT)


func _preload_dice_faces() -> void:
	_dice_faces.clear()
	for i in range(1, 21):
		var path: String = "%sd20_%02d.png" % [DICE_FACES_PATH, i]
		var tex: Texture2D = load(path) as Texture2D
		if tex != null:
			_dice_faces.append(tex)


func _build_overlay() -> void:
	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0, 0, 0, 0.55)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)

	# El "stage" usa coordenadas locales: (0,0) es el centro de la pantalla,
	# y negativo es "arriba". Hace de sistema de referencia para las
	# trayectorias y los anclajes del dado y la sombra.
	_stage = Control.new()
	_stage.set_anchors_preset(Control.PRESET_CENTER)
	_stage.size = Vector2.ZERO
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)


func _dice_face(value: int) -> Texture2D:
	if _dice_faces.is_empty():
		return null
	var idx: int = clamp(value - 1, 0, _dice_faces.size() - 1)
	return _dice_faces[idx]


func roll() -> int:
	var result: int = randi_range(1, 20)

	var fade_in: Tween = create_tween()
	fade_in.tween_property(self, "modulate:a", 1.0, 0.18)

	# Sombra elíptica bajo el dado: pequeña/clara cuando el dado vuela alto,
	# grande/oscura cuando golpea el suelo.
	var shadow_w: float = DICE_SIZE * 0.85
	var shadow_h: float = DICE_SIZE * 0.22
	var shadow_offset_x: float = (DICE_SIZE - shadow_w) * 0.5
	_shadow = Panel.new()
	_shadow.size = Vector2(shadow_w, shadow_h)
	_shadow.pivot_offset = Vector2(shadow_w * 0.5, shadow_h * 0.5)
	_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shadow_style: StyleBoxFlat = StyleBoxFlat.new()
	shadow_style.bg_color = Color(0, 0, 0, 0.65)
	shadow_style.set_corner_radius_all(180)
	_shadow.add_theme_stylebox_override("panel", shadow_style)
	_shadow.scale = Vector2(0.40, 0.40)
	_shadow.modulate.a = 0.12
	_stage.add_child(_shadow)

	# Trayectoria: el dado entra desde arriba a la derecha y va cayendo y
	# rodando hacia el centro con rebotes cada vez más bajos.
	var ground_pos: Vector2 = Vector2(-DICE_SIZE * 0.5, -DICE_SIZE * 0.5)
	var throw_pos: Vector2 = ground_pos + Vector2(450.0, -380.0)
	var impact1_pos: Vector2 = ground_pos + Vector2(280.0, 0.0)
	var bounce1_top: Vector2 = ground_pos + Vector2(180.0, -65.0)
	var impact2_pos: Vector2 = ground_pos + Vector2(110.0, 0.0)
	var bounce2_top: Vector2 = ground_pos + Vector2(60.0, -22.0)
	var impact3_pos: Vector2 = ground_pos + Vector2(30.0, 0.0)

	_dice = TextureRect.new()
	_dice.size = Vector2(DICE_SIZE, DICE_SIZE)
	_dice.position = throw_pos
	_dice.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dice.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_dice.pivot_offset = Vector2(DICE_SIZE * 0.5, DICE_SIZE * 0.5)
	_dice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dice.scale = Vector2(1.0, 1.0)
	_dice.modulate.a = 0.0
	_dice.texture = _dice_face(result)
	_stage.add_child(_dice)

	_shadow.position = Vector2(throw_pos.x + shadow_offset_x, DICE_SIZE * 0.42)

	# Spin antihorario: rueda hacia la izquierda. EASE_OUT para "fricción".
	var spin: Tween = create_tween()
	spin.tween_property(_dice, "rotation", deg_to_rad(-720.0), 1.55) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

	# Cycler de caras aleatorias para el efecto de "rodando".
	var cycler: Timer = Timer.new()
	cycler.wait_time = 0.058
	cycler.one_shot = false
	add_child(cycler)
	cycler.timeout.connect(func() -> void:
		_dice.texture = _dice_face(randi_range(1, 20))
	)
	cycler.start()

	# === Fase 1: lanzamiento parabólico hasta el primer impacto ===
	var p1: Tween = create_tween()
	p1.set_parallel(true)
	p1.tween_property(_dice, "modulate:a", 1.0, 0.10)
	p1.tween_property(_dice, "position", impact1_pos, 0.50) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	p1.tween_property(_shadow, "position:x", impact1_pos.x + shadow_offset_x, 0.50) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	p1.tween_property(_shadow, "scale", Vector2(1.0, 1.0), 0.50) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	p1.tween_property(_shadow, "modulate:a", 0.65, 0.50)
	await p1.finished

	# === Fase 2: golpe pesado (sombra se aplasta, dado destella) ===
	var p2: Tween = create_tween()
	p2.set_parallel(true)
	p2.tween_property(_shadow, "scale", Vector2(1.14, 1.14), 0.05)
	p2.tween_property(_shadow, "scale", Vector2(1.0, 1.0), 0.10).set_delay(0.05)
	p2.tween_property(_shadow, "modulate:a", 0.92, 0.05)
	p2.tween_property(_shadow, "modulate:a", 0.65, 0.10).set_delay(0.05)
	p2.tween_property(_dice, "modulate", Color(1.20, 1.14, 1.02), 0.05)
	p2.tween_property(_dice, "modulate", Color.WHITE, 0.10).set_delay(0.05)
	await p2.finished

	# === Fase 3: rebote bajo rodando a la izquierda ===
	var p3: Tween = create_tween()
	p3.set_parallel(true)
	p3.tween_property(_dice, "position", bounce1_top, 0.16) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	p3.tween_property(_shadow, "position:x", bounce1_top.x + shadow_offset_x, 0.16) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	p3.tween_property(_shadow, "scale", Vector2(0.82, 0.82), 0.16)
	p3.tween_property(_shadow, "modulate:a", 0.38, 0.16)
	await p3.finished

	# === Fase 4: cae del rebote ===
	var p4: Tween = create_tween()
	p4.set_parallel(true)
	p4.tween_property(_dice, "position", impact2_pos, 0.14) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	p4.tween_property(_shadow, "position:x", impact2_pos.x + shadow_offset_x, 0.14) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	p4.tween_property(_shadow, "scale", Vector2(1.0, 1.0), 0.14)
	p4.tween_property(_shadow, "modulate:a", 0.62, 0.14)
	await p4.finished

	# === Fase 5: segundo impacto (más débil) ===
	var p5: Tween = create_tween()
	p5.set_parallel(true)
	p5.tween_property(_shadow, "scale", Vector2(1.07, 1.07), 0.04)
	p5.tween_property(_shadow, "scale", Vector2(1.0, 1.0), 0.08).set_delay(0.04)
	p5.tween_property(_shadow, "modulate:a", 0.80, 0.04)
	p5.tween_property(_shadow, "modulate:a", 0.62, 0.08).set_delay(0.04)
	p5.tween_property(_dice, "modulate", Color(1.12, 1.08, 1.0), 0.04)
	p5.tween_property(_dice, "modulate", Color.WHITE, 0.08).set_delay(0.04)
	await p5.finished

	# === Fase 6: micro-rebote rasante ===
	var p6: Tween = create_tween()
	p6.set_parallel(true)
	p6.tween_property(_dice, "position", bounce2_top, 0.10) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	p6.tween_property(_shadow, "position:x", bounce2_top.x + shadow_offset_x, 0.10) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	p6.tween_property(_shadow, "scale", Vector2(0.93, 0.93), 0.10)
	p6.tween_property(_shadow, "modulate:a", 0.50, 0.10)
	await p6.finished

	# === Fase 7: cae del micro-rebote, asentado ===
	var p7: Tween = create_tween()
	p7.set_parallel(true)
	p7.tween_property(_dice, "position", impact3_pos, 0.08) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	p7.tween_property(_shadow, "position:x", impact3_pos.x + shadow_offset_x, 0.08)
	p7.tween_property(_shadow, "scale", Vector2(1.0, 1.0), 0.08)
	p7.tween_property(_shadow, "modulate:a", 0.62, 0.08)
	await p7.finished

	# Antes de la rodadura final, fijamos el resultado: el dado va a
	# deslizar mostrando ya la cara real, como un d20 asentándose.
	cycler.stop()
	_dice.texture = _dice_face(result)

	# === Fase 8: rodadura final por el suelo hasta el centro ===
	var p8: Tween = create_tween()
	p8.set_parallel(true)
	p8.tween_property(_dice, "position", ground_pos, 0.32) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	p8.tween_property(_shadow, "position:x", ground_pos.x + shadow_offset_x, 0.32) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	await p8.finished

	cycler.stop()
	_dice.texture = _dice_face(result)

	# Brillo final cálido. Sin escala (el d20 es de "mármol", no se deforma).
	var emphasis: Tween = create_tween()
	emphasis.tween_property(_dice, "modulate", Color(1.25, 1.18, 1.05), 0.10)
	emphasis.tween_property(_dice, "modulate", Color.WHITE, 0.28)
	if result == 20:
		var glow: Tween = create_tween()
		glow.tween_property(_dice, "modulate", Color(1.6, 1.4, 0.7), 0.16).set_delay(0.30)
		glow.tween_property(_dice, "modulate", Color.WHITE, 0.45)
	await emphasis.finished

	await _showcase_result(result)

	var fade_out: Tween = create_tween()
	fade_out.tween_property(self, "modulate:a", 0.0, 0.30)
	await fade_out.finished

	rolled.emit(result)
	return result


# Cartel grande con el resultado, como el del dado 3D, para que se lea sin
# esfuerzo aunque el sprite sea pequeño/borroso.
func _showcase_result(number: int) -> void:
	var crit: bool = number == 20
	var panel: Control = _build_result_panel(number, crit)
	add_child(panel)
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.65, 0.65)
	var pop: Tween = create_tween()
	pop.set_parallel(true)
	pop.tween_property(panel, "modulate:a", 1.0, 0.25)
	pop.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.45) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await pop.finished
	await get_tree().create_timer(1.10 if crit else 0.75).timeout
	var pop_out: Tween = create_tween()
	pop_out.set_parallel(true)
	pop_out.tween_property(panel, "modulate:a", 0.0, 0.25)
	pop_out.tween_property(panel, "scale", Vector2(0.85, 0.85), 0.25)
	await pop_out.finished
	panel.queue_free()


func _build_result_panel(number: int, crit: bool) -> Control:
	var holder: Control = Control.new()
	holder.set_anchors_preset(Control.PRESET_CENTER_TOP)
	holder.offset_left = -260
	holder.offset_right = 260
	holder.offset_top = 80
	holder.offset_bottom = 240
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var title: Label = Label.new()
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 0
	title.offset_bottom = 36
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override(
		"font_color",
		Color(1.0, 0.78, 0.20) if crit else Color(0.95, 0.92, 0.72)
	)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 6)
	title.text = "✦ ¡CRÍTICO! ✦" if crit else "✦ TIRADA ✦"
	holder.add_child(title)

	var value: Label = Label.new()
	value.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	value.offset_top = 36
	value.offset_bottom = 156
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size", 110)
	value.add_theme_color_override(
		"font_color",
		Color(1.0, 0.86, 0.28) if crit else Color(1.0, 0.95, 0.78)
	)
	value.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.02))
	value.add_theme_constant_override("outline_size", 14)
	value.text = "%d" % number
	holder.add_child(value)

	if crit:
		var glow: Tween = create_tween().set_loops(3)
		glow.tween_property(holder, "modulate", Color(1.4, 1.18, 0.55), 0.18)
		glow.tween_property(holder, "modulate", Color.WHITE, 0.22)

	return holder
