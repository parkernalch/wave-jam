extends CharacterBody2D

@onready var Bullet = preload("res://Entities/EnemyBullet/EnemyBullet.tscn")
@onready var bullet_spawn: Node2D = $BulletSpawn
@onready var Powerup = preload("res://Entities/Powerup/powerup.tscn")

@export var health : int = 3

@export var speed: float = 150.0
@export var amplitude: float = 60.0
@export var freq: float = 3.0
@export var screen_margin: float = 16.0
var current_speed

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

var time_slow_timer
var base_speed: float
@export var max_speed_multiplier: float = 1.5
var _last_applied_wave: int = 0

# Hit flash shaders
var tint_shader = preload("res://Assets/Shaders/TintShader.gdshader")
var flash_shader = preload("res://Assets/Shaders/HitFlashShader.gdshader")

func set_tint() -> void:
	# Root node material
	if material and material is ShaderMaterial:
		var mat := (material as ShaderMaterial).duplicate(true) as ShaderMaterial
		mat.shader = tint_shader
		material = mat
		mat.set_shader_parameter("tint_color", current_wave_form["color"])

	# AnimatedSprite2D material
	if has_node("AnimatedSprite2D"):
		var anim := $AnimatedSprite2D
		if anim.material and anim.material is ShaderMaterial:
			var amat := (anim.material as ShaderMaterial).duplicate(true) as ShaderMaterial
			amat.shader = tint_shader
			anim.material = amat
			amat.set_shader_parameter("tint_color", current_wave_form["color"])

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	current_wave_form = globals.available_wave_forms[randi() % globals.available_wave_forms.size()]
	set_tint()
	# Timer to handle shooting
	# initialize base speed for wave-scaling
	base_speed = speed
	# apply current global wave scaling immediately and remember it
	_last_applied_wave = globals.current_wave
	_apply_wave_scaling(_last_applied_wave)

	_base_x = global_position.x
	hit_box_size = $CollisionShape2D.shape.extents * 2
	player = get_parent().get_node("Player") as Player
	time_slow_timer = get_parent().get_node("TimeSlowTimer") as Timer
	current_speed = speed

func _physics_process(delta: float) -> void:
	spatial_hash.update(self, get_aabb())

	detect_player_collision()

	vector_to_player = (player.global_position - global_position).normalized()
	if global_position.y > player.global_position.y:
		move_vector = Vector2(0, 1).normalized()
	else:
		move_vector = Vector2(vector_to_player.x, 1).normalized()

	if globals.time_slow_active:
		current_speed = speed * 0.25
	else:
		current_speed = speed

	global_position += move_vector * current_speed * delta

	if (global_position.y > bounds_bottom + 100):
		destroy(false)

	if (health <= 0):
		destroy(true, 100)


func on_hit(wave_form, damage, all_waves) -> void:
	if (wave_form == current_wave_form || all_waves):
		health -= damage
		# trigger hit flash by switching to flash shader for 0.3 seconds
		if material and material is ShaderMaterial:
			(material as ShaderMaterial).shader = flash_shader
		if has_node("AnimatedSprite2D"):
			var anim := $AnimatedSprite2D
			if anim.material and anim.material is ShaderMaterial:
				var shader_material = anim.material as ShaderMaterial
				shader_material.shader = flash_shader
				shader_material.set_shader_parameter("flash_intensity", 1)
				shader_material.set_shader_parameter("tint_color", current_wave_form["color"])

		# switch back to tint shader after 0.06 seconds
		TimerHelper.make_timer(self, 0.05, set_tint, true, true)


func _apply_wave_scaling(wave: int) -> void:
	# scale movement speed gently with wave number, capped by max_speed_multiplier
	var speed_inc: float = float(clamp(wave * 0.02, 0.0, max_speed_multiplier - 1.0))
	var target_speed: float = base_speed * (1.0 + speed_inc)
	# smooth the change so enemies don't jump suddenly
	speed = lerp(speed, target_speed, 0.25)


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
				destroy(false, 50)
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

func destroy(spawn_drop, point_increase=0) -> void:
	# Add animation
	spatial_hash.remove(self)

	if point_increase:
		score.add_points(point_increase)
		signal_bus.enemy_destroyed.emit()


	randomize()

	if randi() % 5 == 0 && spawn_drop:
		var powerup_instance = Powerup.instantiate()
		if get_parent():
			get_parent().add_child(powerup_instance)
			powerup_instance.global_position = global_position

	spatial_hash.remove(self)
	queue_free()
