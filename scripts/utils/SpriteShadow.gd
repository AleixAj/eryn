@tool
class_name SpriteShadow
extends Sprite2D


@export var target: Sprite2D:
	set(value):
		target = value
		_refresh()

@export_range(0.05, 1.0, 0.01) var flatten: float = 0.35:
	set(value):
		flatten = value
		_refresh()

@export_range(0.0, 1.0, 0.01) var darkness: float = 0.45:
	set(value):
		darkness = value
		_refresh()

# Fine-tuning offset applied AFTER the shadow is anchored to the bottom edge of
# the target's texture. Expressed in texture-local pixels (as if the sprite were
# at scale 1) so the offset stays consistent when the target is resized.
@export var relative_offset: Vector2 = Vector2.ZERO:
	set(value):
		relative_offset = value
		_refresh()


func _ready() -> void:
	z_index = -1
	z_as_relative = true
	if target == null:
		var sibling := get_parent().get_node_or_null("Sprite")
		if sibling is Sprite2D:
			target = sibling
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if not is_inside_tree():
		return
	if target == null or not is_instance_valid(target):
		return
	texture = target.texture
	scale = Vector2(target.scale.x, -abs(target.scale.y) * flatten)
	modulate = Color(0, 0, 0, darkness)

	# Anchor the shadow to the bottom-center of the target's bounding box and
	# scale the fine-tuning offset with the target so the shadow follows scale
	# changes correctly (smaller sprite -> shadow moves up proportionally).
	var feet_in_parent: Vector2 = target.position
	if target.texture != null:
		var half_height: float = target.texture.get_size().y * 0.5
		var anchor_y: float = half_height if target.centered else float(target.texture.get_size().y)
		feet_in_parent.y += anchor_y * abs(target.scale.y)

	# relative_offset is expressed in TEXTURE-LOCAL pixels (i.e. as if the
	# sprite were at scale 1). It is multiplied by the current scale so the
	# shadow keeps the same visual relationship at any size.
	var scaled_offset := Vector2(
		relative_offset.x * abs(target.scale.x),
		relative_offset.y * abs(target.scale.y)
	)
	position = feet_in_parent + scaled_offset
