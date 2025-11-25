extends CharacterBody2D

@onready var Bullet = preload("res://Entities/EnemyBullet/EnemyBullet.tscn")
@onready var bullet_spawn: Node2D = $BulletSpawn
@onready var Powerup = preload("res://Entities/Powerup/powerup.tscn")

@export var health : int = 2

@export var speed: float = 150.0
@export var amplitude: float = 60.0
@export var freq: float = 3.0
@export var screen_margin: float = 16.0

# explicit spawn/movement bounds (use these instead of viewport)
var bounds_left: float = 0.0
var bounds_right: float = 400.0
var bounds_top: float = 0.0
var bounds_bottom: float = 800.0

var hit_box_size

var current_wave_form

var t: float = 0.0
var _base_x: float = 0.0
var player: Player
var vector_to_player: Vector2
var move_vector: Vector2

func set_tint(color: Vector4) -> void:
	# Root node material
	if material and material is ShaderMaterial:
		var mat := (material as ShaderMaterial).duplicate(true) as ShaderMaterial
		material = mat
		mat.set_shader_parameter("tint_color", color)
	
	# AnimatedSprite2D material
	if has_node("AnimatedSprite2D"):
		var anim := $AnimatedSprite2D
		if anim.material and anim.material is ShaderMaterial:
			var amat := (anim.material as ShaderMaterial).duplicate(true) as ShaderMaterial
			anim.material = amat
			amat.set_shader_parameter("tint_color", color)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	current_wave_form = globals.available_wave_forms[randi() % globals.available_wave_forms.size()]
	set_tint(current_wave_form["color"])
	# Timer to handle shooting
	_base_x = global_position.x
	hit_box_size = $CollisionShape2D.shape.extents * 2
	player = get_parent().get_node("Player") as Player

func _physics_process(delta: float) -> void:
	spatial_hash.update(self, get_aabb())

	detect_player_collision()

	vector_to_player = (player.global_position - global_position).normalized()
	if global_position.y > player.global_position.y:
		move_vector = Vector2(0, 1).normalized()
	else:
		move_vector = Vector2(vector_to_player.x, 1).normalized()

	global_position += move_vector * speed * delta
	
	if (global_position.y > bounds_bottom + 100):
		destroy(false, false)

	if (health <= 0):
		destroy(true, true)


func on_hit(wave_form, damage, all_waves) -> void:
	if (wave_form == current_wave_form || all_waves):
		health -= damage

func detect_player_collision() -> void:
	var aabb = Rect2(global_position - hit_box_size * 0.5, hit_box_size)

	var candidates = spatial_hash.query(aabb)

	for obj in candidates:
		# ensure candidate has get_aabb or else skip
		if not obj.has_method("get_aabb"):
			continue
		var obj_rect = obj.get_aabb()
		if aabb.intersects(obj_rect):
			# narrow-phase: call enemy's hit method or do more precise shape checks
			if obj.has_method("enemy_collision"):
				obj.enemy_collision(current_wave_form)
				destroy(false, true)
			return


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

func destroy(spawn_drop, give_points) -> void:
	# Add animation
	spatial_hash.remove(self)

	if give_points:
		score.add_points(100)
		signal_bus.enemy_destroyed.emit()


	randomize()
	if randi() % 5 == 0 && spawn_drop:
		var powerup_instance = Powerup.instantiate()
		if get_parent():
			get_parent().add_child(powerup_instance)
			powerup_instance.global_position = global_position
				
	spatial_hash.remove(self)
	queue_free()
