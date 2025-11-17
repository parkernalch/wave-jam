class_name Player extends CharacterBody2D

@onready var Bullet = preload("res://Entities/Bullet/Bullet.tscn")
@onready var bullet_spawn: Node2D = $BulletSpawn
@export var bullet_speed = 600;
@export var speed = 300
@export var boost_multiplier = 2.0

var max_amplitude = 100.0
var amplitude = 100.0
var shoot_cooldown_timer
var shoot_cooldown = 0.00001
var can_shoot = true
var form_index = 0
var FORMS = CONSTANTS.DEFAULT_WAVE_FORMS
var current_form = FORMS.SIN

func _ready() -> void:
	signal_bus.enemy_hit.connect(_on_enemy_hit)
	signal_bus.amplitude_changed.emit(100)
	shoot_cooldown_timer = TimerHelper.make_timer(self, shoot_cooldown, _reset_shoot_cooldown, false, false)
	
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("change_form"):
		change_form()
	elif Input.is_action_pressed("shoot"):
		amplitude -= 10 * delta
		signal_bus.amplitude_changed.emit(amplitude)
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
		shoot_cooldown_timer.start()

func _on_enemy_hit():
	amplitude = min(amplitude + 1, max_amplitude)
	signal_bus.amplitude_changed.emit(amplitude)

func _reset_shoot_cooldown():
	can_shoot = true
