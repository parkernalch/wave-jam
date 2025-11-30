extends CharacterBody2D

@onready var Bullet = preload("res://Entities/EnemyBullet/EnemyBullet.tscn")
@onready var bullet_spawn: Node2D = $BulletSpawn
@onready var Powerup = preload("res://Entities/Powerup/powerup.tscn")

@export var bullet_speed = 550;
@export var shot_cooldown : float = 0.5
@export var health : int = 1

var current_speed

@export var speed: float = 200.0
@export var amplitude: float = 60.0
@export var freq: float = 3.0
@export var screen_margin: float = 16.0

# Lissajous (figure-8) parameters
@export var figure8_amp_x: float = 60.0
@export var figure8_amp_y: float = 40.0
@export var figure8_freq: float = 1.5

# explicit spawn/movement bounds (use these instead of viewport)
var bounds_left: float = 0.0
var bounds_right: float = 400.0
var bounds_top: float = 0.0
var bounds_bottom: float = 800.0

var hit_box_size

var current_wave_form

var t: float = 0.0
var _base_x: float = 0.0
var _base_y: float = 0.0
var _shot_timer: Timer
var base_speed: float
var base_shot_cooldown: float
@export var max_speed_multiplier: float = 1.5
@export var max_cooldown_reduction: float = 0.5 # reduce cooldown by up to 50%
var _last_applied_wave: int = 0

# Hit flash shaders
var tint_shader = preload("res://Assets/Shaders/TintShader.gdshader")
var flash_shader = preload("res://Assets/Shaders/HitFlashShader.gdshader")
var tint_intensity: float = 0.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	# make this node queryable by group for fast counting
	add_to_group("HoverEnemy")
	current_wave_form = globals.available_wave_forms[randi() % globals.available_wave_forms.size()]
	globals.set_tint(self, current_wave_form["color"], tint_intensity)
	# initialize scaling bases
	base_speed = speed
	base_shot_cooldown = shot_cooldown
	# Timer to handle shooting (store reference so we can update interval)
	_shot_timer = TimerHelper.make_timer(self, shot_cooldown, shoot, false, true)
	# apply current global wave scaling immediately and remember it
	_last_applied_wave = globals.current_wave
	_apply_wave_scaling(_last_applied_wave)
	_base_x = global_position.x
	_base_y = global_position.y
	hit_box_size = $CollisionShape2D.shape.extents * 2

func _physics_process(delta: float) -> void:
	figure8_movement(delta)

	spatial_hash.update(self, get_aabb())

	detect_player_collision()

	if (global_position.y > bounds_bottom + 100):
		destroy(false)

	if (health <= 0):
		destroy(true, 100)

func figure8_movement(delta: float) -> void:
	# Lissajous-style figure-8 movement: x = base_x + A*sin(t), y = base_y + B*sin(2*t)
	# slow global time should reduce the progression of t so the figure-8 slows
	var speed_factor: float = 1.0
	if globals.time_slow_active:
		speed_factor = 0.25

	# advance time scaled by speed_factor so both axes slow
	t += delta * speed_factor

	var target_x := _base_x + figure8_amp_x * sin(t * figure8_freq)
	var target_y := _base_y + figure8_amp_y * sin(2.0 * t * figure8_freq)

	# clamp to configured bounds (left/right/top/bottom) minus margin
	var min_x := bounds_left + screen_margin
	var max_x := bounds_right - screen_margin
	var min_y := bounds_top + screen_margin
	var max_y := bounds_bottom - screen_margin

	target_x = clamp(target_x, min_x, max_x)
	target_y = clamp(target_y, min_y, max_y)

	global_position.x = target_x
	global_position.y = target_y

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
				shader_material.set_shader_parameter("flash_intensity", 1.0)
				shader_material.set_shader_parameter("tint_color", current_wave_form["color"])

		# switch back to tint shader after 0.05 seconds
		TimerHelper.make_timer(self, 0.05, reset_tint, true, true)

func _on_flash_complete() -> void:
	# switch back to tint shader with proper color
	if material and material is ShaderMaterial:
		(material as ShaderMaterial).shader = tint_shader
		(material as ShaderMaterial).set_shader_parameter("tint_color", current_wave_form["color"])
	if has_node("AnimatedSprite2D"):
		var anim := $AnimatedSprite2D
		if anim.material and anim.material is ShaderMaterial:
			(anim.material as ShaderMaterial).shader = tint_shader
			(anim.material as ShaderMaterial).set_shader_parameter("tint_color", current_wave_form["color"])

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

func shoot() -> void:
	var bullet = Bullet.instantiate()

	if get_parent():
		get_parent().add_child(bullet)
		bullet.global_position = bullet_spawn.global_position
		bullet.shoot(bullet_speed, current_wave_form)


func _apply_wave_scaling(wave: int) -> void:
	# scale speed and shot cooldown gently with wave number
	# multiplier grows slowly and is capped by max_speed_multiplier
	var speed_inc: float = float(clamp(wave * 0.02, 0.0, max_speed_multiplier - 1.0))
	var target_speed: float = base_speed * (1.0 + speed_inc)
	# cooldown reduction: up to max_cooldown_reduction fraction
	var cooldown_red: float = float(clamp(wave * 0.01, 0.0, max_cooldown_reduction))
	var target_cooldown: float = max(base_shot_cooldown * (1.0 - cooldown_red), 0.05)

	# apply smoothing so values don't jump too quickly
	speed = lerp(speed, target_speed, 0.25)
	shot_cooldown = lerp(shot_cooldown, target_cooldown, 0.4)
	# update timer interval
	if _shot_timer:
		_shot_timer.wait_time = shot_cooldown

func destroy(spawn_drop, point_increase=0) -> void:
	# Add animation
	spatial_hash.remove(self)
	randomize()

	if point_increase:
		score.add_points(point_increase)
		signal_bus.enemy_destroyed.emit()

	# 33% chance to drop a powerup
	if randi() % 3 == 0 && spawn_drop && globals.powerup_count < constants.MAX_POWERUPS:
		var powerup_instance = Powerup.instantiate()
		if get_parent():
			get_parent().add_child(powerup_instance)
			powerup_instance.global_position = global_position

	queue_free()


func reset_tint() -> void:
	globals.set_tint(self, current_wave_form["color"], tint_intensity)
