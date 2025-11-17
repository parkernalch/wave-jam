extends CharacterBody2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	spatial_hash.update(self, get_aabb())

func on_hit(wave_form) -> void:
	signal_bus.enemy_hit.emit()

func get_aabb() -> Rect2:
	# If using a CollisionShape2D with RectangleShape2D
	if has_node("CollisionShape2D"):
		var cs = $CollisionShape2D
		var shape = cs.shape
		# rectangle shape
		if shape is RectangleShape2D:
			var ext = shape.extents
			# extents are in local space; we approximate by using global_position (no rotation)
			return Rect2(global_position - ext, ext * 2)
		if shape is CircleShape2D:
			var r = shape.radius
			return Rect2(global_position - Vector2(r, r), Vector2(r*2, r*2))
	# fallback: small box around position
	return Rect2(global_position - Vector2(8,8), Vector2(16,16))
