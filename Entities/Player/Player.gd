class_name Player extends CharacterBody2D

@onready var Bullet = preload("res://Entities/Bullet/Bullet.tscn")
@onready var bullet_spawn: Node2D = $BulletSpawn
@export var bullet_speed = 1000;
@export var speed = 300
@export var boost_multiplier = 2.0
@export var shoot_cooldown = 0.3

var max_amplitude = 100.0
var amplitude = 100.0
var shoot_cooldown_timer
var can_shoot = true
var form_index = 0
var FORMS = CONSTANTS.DEFAULT_WAVE_FORMS
var current_form = FORMS.SIN

func _ready() -> void:
	signal_bus.enemy_destroyed.connect(_on_enemy_destroy)
	signal_bus.amplitude_changed.emit(100)
	shoot_cooldown_timer = TimerHelper.make_timer(self, shoot_cooldown, _reset_shoot_cooldown, false, false)
	
func _physics_process(delta: float) -> void:
	spatial_hash.update(self, get_aabb())
	
	if Input.is_action_just_pressed("change_form"):
		change_form()
	elif Input.is_action_pressed("shoot"):
		shoot()

func change_form():
	form_index = (form_index + 1) % FORMS.size()
	current_form = FORMS.values()[form_index]
	set_tint(current_form["color"])

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

func shoot():
	var bullet = Bullet.instantiate()

	if get_parent() && can_shoot:
		get_parent().add_child(bullet)
		bullet.global_position = bullet_spawn.global_position
		bullet.shoot(bullet_speed, current_form)
		can_shoot = false
		amplitude -= 1
		signal_bus.amplitude_changed.emit(amplitude)
		shoot_cooldown_timer.start()

func take_damage(damage, wave_form):
	if wave_form != current_form:
		amplitude = max(amplitude - damage, 0)
		signal_bus.amplitude_changed.emit(amplitude)
	

func enemy_collision(wave_form):
	if wave_form != current_form:
		amplitude = max(amplitude - 30, 0)
		signal_bus.amplitude_changed.emit(amplitude)
	else:
		amplitude = min(amplitude + 10, max_amplitude)
		signal_bus.amplitude_changed.emit(amplitude)

func _on_enemy_destroy():
	amplitude = min(amplitude + 5, max_amplitude)
	signal_bus.amplitude_changed.emit(amplitude)

func _reset_shoot_cooldown():
	can_shoot = true

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
