extends Control
class_name Dice3DRoller

# Overlay a pantalla completa con un SubViewport 3D. Lanza el d20 con físicas
# reales y lee qué cara queda hacia arriba al asentarse.

signal rolled(value: int)

const D20_GLB_PATH: String = "res://assets/sprites/dnd_dice_set/dnd_dice_set.glb"
const D20_NODE_NAME: String = "20TieDye_20TieDye_0"

# Modo calibración: cuando es true, tras cada tirada el dado se queda quieto
# en pantalla con un texto enorme indicando el `face_index` detectado. El
# usuario apunta qué número está pintado arriba, dice "face_index N → número M",
# y se actualiza FACE_TO_NUMBER. Una vez calibrado, poner en false.
const CALIBRATION_MODE: bool = false

# face_index (0-19) → número pintado del d20 (1-20).
# Tira el dado en modo calibración, mira qué FACE INDEX detecta el script y qué
# número está pintado arriba del dado, y reemplaza el "?" de la línea
# correspondiente por ese número. Ejemplo: si "FACE INDEX: 7" y arriba ves un 14,
# cambia "7,   # face_index 7" por "14,  # face_index 7".
const FACE_TO_NUMBER: Array[int] = [
	4,   # face_index 0
	11,  # face_index 1
	9,   # face_index 2
	1,   # face_index 3
	5,   # face_index 4
	14,  # face_index 5
	18,  # face_index 6
	15,  # face_index 7
	8,   # face_index 8  (deducido: opuesto a face_index 15, suman 21)
	19,  # face_index 9
	20,  # face_index 10
	12,  # face_index 11
	10,  # face_index 12
	17,  # face_index 13
	16,  # face_index 14
	13,  # face_index 15 (deducido: opuesto a face_index 8, suman 21)
	2,   # face_index 16
	7,   # face_index 17
	3,   # face_index 18
	6,   # face_index 19
]

const VIEWPORT_SIZE: int = 720
const SETTLE_THRESHOLD_LIN: float = 0.06
const SETTLE_THRESHOLD_ANG: float = 0.18
const SETTLE_FRAMES_REQUIRED: int = 14
const MAX_ROLL_TIME_S: float = 5.5

var _subviewport: SubViewport
var _camera: Camera3D
var _dice_body: RigidBody3D
var _dim: ColorRect
var _vp_container: SubViewportContainer
var _face_normals: Array[Vector3] = []
var _calib_label: Label
var _calib_hint: Label
var _calib_continue: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_compute_face_normals()
	_build_overlay()
	_build_3d_world()
	modulate.a = 0.0
	call_deferred("_fit_to_viewport")


func _fit_to_viewport() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_offsets_preset(Control.PRESET_FULL_RECT)


func _build_overlay() -> void:
	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0, 0, 0, 0.55)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)

	_vp_container = SubViewportContainer.new()
	var half: float = VIEWPORT_SIZE * 0.5
	_vp_container.set_anchors_preset(Control.PRESET_CENTER)
	_vp_container.offset_left = -half
	_vp_container.offset_top = -half
	_vp_container.offset_right = half
	_vp_container.offset_bottom = half
	_vp_container.stretch = true
	_vp_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vp_container)

	_subviewport = SubViewport.new()
	_subviewport.size = Vector2i(VIEWPORT_SIZE, VIEWPORT_SIZE)
	_subviewport.transparent_bg = true
	_subviewport.handle_input_locally = false
	_subviewport.own_world_3d = true
	_subviewport.disable_3d = false
	_subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp_container.add_child(_subviewport)

	if CALIBRATION_MODE:
		_calib_label = Label.new()
		_calib_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
		_calib_label.offset_left = -400
		_calib_label.offset_right = 400
		_calib_label.offset_top = 30
		_calib_label.offset_bottom = 130
		_calib_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_calib_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_calib_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
		_calib_label.add_theme_color_override("font_outline_color", Color.BLACK)
		_calib_label.add_theme_constant_override("outline_size", 12)
		_calib_label.add_theme_font_size_override("font_size", 64)
		_calib_label.text = ""
		add_child(_calib_label)

		_calib_hint = Label.new()
		_calib_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		_calib_hint.offset_left = -500
		_calib_hint.offset_right = 500
		_calib_hint.offset_top = -90
		_calib_hint.offset_bottom = -30
		_calib_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_calib_hint.add_theme_color_override("font_color", Color(0.95, 0.92, 0.78))
		_calib_hint.add_theme_color_override("font_outline_color", Color.BLACK)
		_calib_hint.add_theme_constant_override("outline_size", 6)
		_calib_hint.add_theme_font_size_override("font_size", 22)
		_calib_hint.text = ""
		add_child(_calib_hint)


func _build_3d_world() -> void:
	var world: Node3D = Node3D.new()
	_subviewport.add_child(world)

	var env_node: WorldEnvironment = WorldEnvironment.new()
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.04, 0.08, 0.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.72, 0.85)
	env.ambient_light_energy = 1.2
	env_node.environment = env
	world.add_child(env_node)

	_camera = Camera3D.new()
	_camera.fov = 48.0
	_camera.environment = env
	world.add_child(_camera)
	# look_at SOLO funciona bien cuando el nodo ya está en el árbol.
	_camera.position = Vector3(0.0, 7.5, 7.5)
	_camera.look_at(Vector3.ZERO, Vector3.UP)
	_camera.make_current()

	var key_light: DirectionalLight3D = DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-52, -28, 0)
	key_light.light_energy = 1.8
	key_light.light_color = Color(1.0, 0.96, 0.86)
	world.add_child(key_light)

	var fill_light: DirectionalLight3D = DirectionalLight3D.new()
	fill_light.rotation_degrees = Vector3(-20, 120, 0)
	fill_light.light_energy = 0.55
	fill_light.light_color = Color(0.75, 0.88, 1.0)
	world.add_child(fill_light)

	var table: StaticBody3D = StaticBody3D.new()
	var table_collision: CollisionShape3D = CollisionShape3D.new()
	var table_box: BoxShape3D = BoxShape3D.new()
	table_box.size = Vector3(10, 0.4, 8)
	table_collision.shape = table_box
	table_collision.position = Vector3(0, -0.2, 0)
	table.add_child(table_collision)
	var pm_table: PhysicsMaterial = PhysicsMaterial.new()
	pm_table.bounce = 0.22
	pm_table.friction = 0.65
	table.physics_material_override = pm_table
	world.add_child(table)

	var mat_mesh: MeshInstance3D = MeshInstance3D.new()
	var quad: PlaneMesh = PlaneMesh.new()
	quad.size = Vector2(6.5, 4.5)
	mat_mesh.mesh = quad
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.28, 0.18, 0.10)
	mat.roughness = 0.9
	mat_mesh.material_override = mat
	mat_mesh.position = Vector3(0, 0.001, 0)
	world.add_child(mat_mesh)

	_add_wall(world, Vector3(0, 2, -2.8), Vector3.ZERO, Vector3(8, 4, 0.4))
	_add_wall(world, Vector3(0, 2, 2.8), Vector3.ZERO, Vector3(8, 4, 0.4))
	_add_wall(world, Vector3(-3.5, 2, 0), Vector3(0, PI * 0.5, 0), Vector3(8, 4, 0.4))
	_add_wall(world, Vector3(3.5, 2, 0), Vector3(0, PI * 0.5, 0), Vector3(8, 4, 0.4))

	var d20_data: Dictionary = _extract_d20()
	var d20_mesh: Mesh = d20_data.get("mesh", null) as Mesh
	if d20_mesh == null:
		push_warning("Dice3DRoller: no se pudo extraer el mesh del d20.")
		return
	var d20_material_override: Material = d20_data.get("material_override", null) as Material

	_dice_body = RigidBody3D.new()
	_dice_body.mass = 1.4
	_dice_body.gravity_scale = 2.6
	_dice_body.linear_damp = 0.55
	_dice_body.angular_damp = 1.05
	_dice_body.continuous_cd = true
	_dice_body.can_sleep = true
	var pm_dice: PhysicsMaterial = PhysicsMaterial.new()
	pm_dice.bounce = 0.30
	pm_dice.friction = 0.55
	_dice_body.physics_material_override = pm_dice

	var aabb: AABB = d20_mesh.get_aabb()
	var dice_size: float = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
	var dice_scale_factor: float = 1.0 / max(dice_size, 0.0001)
	var mesh_center: Vector3 = aabb.position + aabb.size * 0.5
	var center_offset: Vector3 = -mesh_center * dice_scale_factor

	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = d20_mesh
	mi.scale = Vector3.ONE * dice_scale_factor
	mi.position = center_offset
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if d20_material_override != null:
		mi.material_override = d20_material_override
	elif mi.mesh.surface_get_material(0) == null:
		var fallback_mat: StandardMaterial3D = StandardMaterial3D.new()
		fallback_mat.albedo_color = Color(0.85, 0.15, 0.12)
		fallback_mat.roughness = 0.4
		fallback_mat.metallic = 0.2
		mi.material_override = fallback_mat
	_dice_body.add_child(mi)

	var col: CollisionShape3D = CollisionShape3D.new()
	col.shape = d20_mesh.create_convex_shape()
	col.scale = Vector3.ONE * dice_scale_factor
	col.position = center_offset
	_dice_body.add_child(col)

	_dice_body.freeze = true
	world.add_child(_dice_body)


func _add_wall(parent: Node, pos: Vector3, rot: Vector3, sz: Vector3) -> void:
	var wall: StaticBody3D = StaticBody3D.new()
	wall.position = pos
	wall.rotation = rot
	var c: CollisionShape3D = CollisionShape3D.new()
	var b: BoxShape3D = BoxShape3D.new()
	b.size = sz
	c.shape = b
	wall.add_child(c)
	parent.add_child(wall)


func _extract_d20() -> Dictionary:
	var result: Dictionary = {"mesh": null, "material_override": null}
	var glb_res: Resource = load(D20_GLB_PATH)
	if glb_res == null or not (glb_res is PackedScene):
		return result
	var glb_inst: Node = (glb_res as PackedScene).instantiate()
	if glb_inst == null:
		return result

	var found: MeshInstance3D = null
	var target: Node = glb_inst.find_child(D20_NODE_NAME, true, false)
	if target is MeshInstance3D and (target as MeshInstance3D).mesh != null:
		found = target as MeshInstance3D
	elif target != null:
		found = _find_first_mesh(target)

	if found == null:
		for candidate: MeshInstance3D in _all_meshes(glb_inst):
			if candidate.name.begins_with("20"):
				found = candidate
				break

	if found == null:
		found = _find_first_mesh(glb_inst)

	if found != null and found.mesh != null:
		result["mesh"] = found.mesh
		result["material_override"] = found.material_override
		print("[Dice3DRoller] usando mesh '%s'" % found.name)

	glb_inst.queue_free()
	return result


func _all_meshes(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	_collect_meshes(node, out)
	return out


func _collect_meshes(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		out.append(node as MeshInstance3D)
	for c in node.get_children():
		_collect_meshes(c, out)


func _find_first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return node as MeshInstance3D
	for c in node.get_children():
		var found: MeshInstance3D = _find_first_mesh(c)
		if found != null:
			return found
	return null


func _compute_face_normals() -> void:
	var phi: float = (1.0 + sqrt(5.0)) * 0.5
	var v: Array = [
		Vector3(-1.0,  phi,  0.0), Vector3( 1.0,  phi,  0.0),
		Vector3(-1.0, -phi,  0.0), Vector3( 1.0, -phi,  0.0),
		Vector3( 0.0, -1.0,  phi), Vector3( 0.0,  1.0,  phi),
		Vector3( 0.0, -1.0, -phi), Vector3( 0.0,  1.0, -phi),
		Vector3( phi, 0.0, -1.0), Vector3( phi, 0.0,  1.0),
		Vector3(-phi, 0.0, -1.0), Vector3(-phi, 0.0,  1.0),
	]
	var faces: Array = [
		[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
		[1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
		[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
		[4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]
	]
	_face_normals.clear()
	for f in faces:
		var center: Vector3 = (Vector3(v[f[0]]) + Vector3(v[f[1]]) + Vector3(v[f[2]])) / 3.0
		_face_normals.append(center.normalized())


func roll() -> int:
	if _dice_body == null:
		await get_tree().process_frame
		return randi_range(1, 20)

	_camera.make_current()
	await get_tree().process_frame

	var fade_in: Tween = create_tween()
	fade_in.tween_property(self, "modulate:a", 1.0, 0.18)

	_dice_body.freeze = true
	_dice_body.linear_velocity = Vector3.ZERO
	_dice_body.angular_velocity = Vector3.ZERO
	_dice_body.position = Vector3(1.4, 3.0, randf_range(-0.4, 0.4))
	_dice_body.rotation = Vector3(
		randf_range(-PI, PI),
		randf_range(-PI, PI),
		randf_range(-PI, PI)
	)
	_dice_body.freeze = false

	await get_tree().physics_frame

	var throw_force: Vector3 = Vector3(
		randf_range(-2.2, -1.5),
		randf_range(0.25, 0.6),
		randf_range(-0.4, 0.4)
	)
	_dice_body.apply_central_impulse(throw_force * _dice_body.mass)
	_dice_body.apply_torque_impulse(Vector3(
		randf_range(-2.5, 2.5),
		randf_range(-2.5, 2.5),
		randf_range(-2.5, 2.5)
	))

	await _wait_for_settle()

	var face_index: int = _compute_up_face_index()
	var number: int = FACE_TO_NUMBER[face_index]
	print("[Dice3DRoller] face_index=%d → number=%d" % [face_index, number])

	if CALIBRATION_MODE:
		_calib_label.text = "FACE INDEX: %d" % face_index
		_calib_hint.text = "Mira el número arriba del dado y apúntalo (face_index %d → ?)\nClick o pulsa una tecla para tirar de nuevo" % face_index
		_calib_continue = false
		set_process_input(true)
		while not _calib_continue:
			await get_tree().process_frame
		set_process_input(false)
	else:
		await _showcase_result(number)

	var fade_out: Tween = create_tween()
	fade_out.tween_property(self, "modulate:a", 0.0, 0.30)
	await fade_out.finished

	_dice_body.freeze = true
	rolled.emit(number)
	return number


# Una vez asentado el dado, lo levantamos hacia la cámara, lo giramos
# suavemente sobre el eje Y (no cambia la cara que está arriba) y mostramos
# un cartel grande con el resultado para que se lea sin esfuerzo. Si es
# crítico (20), añadimos un brillo dorado extra.
func _showcase_result(number: int) -> void:
	# Congelamos el cuerpo: a partir de ahora movemos el dado vía tween,
	# sin físicas. La cara ganadora ya apunta a +Y mundial, así que rotar
	# alrededor de Y la mantiene arriba mientras gira para que se vea bien.
	_dice_body.freeze = true
	_dice_body.linear_velocity = Vector3.ZERO
	_dice_body.angular_velocity = Vector3.ZERO

	var start_pos: Vector3 = _dice_body.position
	# Subimos a una zona céntrica/elevada bien expuesta a la cámara.
	var lift_pos: Vector3 = Vector3(0.0, 2.4, 0.5)
	var start_rot: Vector3 = _dice_body.rotation
	var spin_rot: Vector3 = Vector3(start_rot.x, start_rot.y + TAU, start_rot.z)

	var lift: Tween = create_tween()
	lift.set_parallel(true)
	lift.tween_property(_dice_body, "position", lift_pos, 0.55) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	lift.tween_property(_dice_body, "rotation", spin_rot, 1.6) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

	# Cartel del resultado: aparece desde arriba con un punch.
	var crit: bool = number == 20
	var panel: Control = _build_result_panel(number, crit)
	add_child(panel)
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.65, 0.65)
	var pop: Tween = create_tween()
	pop.set_parallel(true)
	pop.tween_property(panel, "modulate:a", 1.0, 0.25).set_delay(0.30)
	pop.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.45) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.30)

	await lift.finished

	# Pequeña pausa para que se aprecie el resultado.
	await get_tree().create_timer(1.20 if crit else 0.85).timeout

	# Salida del cartel.
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
		# Pulso dorado sutil para crítico (modulate del holder entero).
		var glow: Tween = create_tween().set_loops(3)
		glow.tween_property(holder, "modulate", Color(1.4, 1.18, 0.55), 0.18)
		glow.tween_property(holder, "modulate", Color.WHITE, 0.22)

	return holder


func _input(event: InputEvent) -> void:
	if not CALIBRATION_MODE:
		return
	if event is InputEventMouseButton and event.pressed:
		_calib_continue = true
		accept_event()
	elif event is InputEventKey and event.pressed and not event.echo:
		_calib_continue = true
		accept_event()


func _wait_for_settle() -> void:
	var settled: int = 0
	var start_ms: int = Time.get_ticks_msec()
	while settled < SETTLE_FRAMES_REQUIRED:
		await get_tree().physics_frame
		if _dice_body == null:
			break
		if (
			_dice_body.linear_velocity.length() < SETTLE_THRESHOLD_LIN
			and _dice_body.angular_velocity.length() < SETTLE_THRESHOLD_ANG
		):
			settled += 1
		else:
			settled = 0
		if (Time.get_ticks_msec() - start_ms) / 1000.0 > MAX_ROLL_TIME_S:
			break


func _compute_up_face_index() -> int:
	var basis: Basis = _dice_body.global_transform.basis
	var best_idx: int = 0
	var best_y: float = -INF
	for i in _face_normals.size():
		var n: Vector3 = basis * _face_normals[i]
		if n.y > best_y:
			best_y = n.y
			best_idx = i
	return best_idx
