class_name Player extends CharacterBody2D

@onready var Bullet = preload("res://Entities/Bullet/Bullet.tscn")
@onready var bullet_spawn: Node2D = $BulletSpawn

@export var bullet_speed = 1000;
@export var speed = 250
@export var boost_multiplier = 2.0
@export var shoot_cooldown = .5
@export var damage = 1
@export var max_speed = 600.0
@export var max_bullet_speed = 3000.0

var max_amplitude = 100.0
var amplitude = 100.0
var shoot_cooldown_timer
var can_shoot = true
var form_index = 0
var FORMS = CONSTANTS.DEFAULT_WAVE_FORMS
var current_form = FORMS.SIN
var damage_boost_timer
var all_waves_timer
var all_waves = false
var bullet_spread = false
var bullet_spread_timer
var bullet_spread_angles = [-90, 0, 90]
var bullet_piercing = false
var bullet_piercing_timer
var absorb_all_forms = false
var absorb_all_forms_timer

func _ready() -> void:
	signal_bus.enemy_destroyed.connect(_on_enemy_destroy)
	signal_bus.amplitude_changed.emit(100)
	shoot_cooldown_timer = TimerHelper.make_timer(self, shoot_cooldown, _reset_shoot_cooldown, false, false)
	signal_bus.powerup_collected.connect(_on_powerup_collected)
	get_parent().find_child("DamageBoostTimer").connect("timeout", _on_damage_boost_timeout)
	all_waves_timer = get_parent().find_child("AllWavesTimer")
	all_waves_timer.connect("timeout", _on_all_waves_timeout)
	bullet_spread_timer = get_parent().find_child("BulletSpreadTimer")
	bullet_spread_timer.connect("timeout", _on_bullet_spread_timeout)
	bullet_piercing_timer = get_parent().find_child("BulletPiercingTimer")
	bullet_piercing_timer.connect("timeout", _on_bullet_piercing_timeout)
	globals.available_wave_forms = FORMS.values().slice(0,2)
	absorb_all_forms_timer = get_parent().find_child("AbsorbAllFormsTimer")
	absorb_all_forms_timer.connect("timeout", _on_absorb_all_forms_timeout)

func _physics_process(delta: float) -> void:
	spatial_hash.update(self, get_aabb())
	
	if Input.is_action_pressed("pause"):
		signal_bus.game_paused.emit()
		return

	if Input.is_action_just_pressed("change_form"):
		change_form()
	elif Input.is_action_pressed("shoot"):
		if bullet_spread:
			for angle in bullet_spread_angles:
				shoot(angle)
			can_shoot = false
		else:
			shoot()

	if amplitude <= 0:
		die()
		return

func change_form():
	# form_index = (form_index + 1) % FORMS.size()
	form_index = (form_index + 1) % globals.available_wave_forms.size()
	# current_form = FORMS.values()[form_index]
	current_form = globals.available_wave_forms[form_index]
	set_tint(current_form["color"])
	signal_bus.form_changed.emit(form_index)

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

func shoot(angle=0) -> void:
	var bullet = Bullet.instantiate()

	if get_parent() && can_shoot:
		get_parent().add_child(bullet)
		bullet.global_position = bullet_spawn.global_position
		bullet.shoot(bullet_speed, current_form, damage, all_waves, angle, bullet_piercing)
		
		if not bullet_spread:
			can_shoot = false
		
		signal_bus.amplitude_changed.emit(amplitude)
		$Audio/LaserAudioPlayer.play()
		shoot_cooldown_timer.start()

func take_damage(damage, wave_form):
	if wave_form != current_form && !absorb_all_forms:
		amplitude = amplitude - damage
		signal_bus.amplitude_changed.emit(amplitude)
		$Audio/DamageAudioPlayer.play()
	else:
		amplitude = min(amplitude + damage, max_amplitude)
		signal_bus.amplitude_changed.emit(amplitude)
		$Audio/HealPlayer.play()

func enemy_collision(wave_form):
	if wave_form != current_form && !absorb_all_forms:
		amplitude = amplitude - 30
		signal_bus.amplitude_changed.emit(amplitude)
		score.add_points(-100)
		$Audio/DamageAudioPlayer.play()
	else:
		amplitude = min(amplitude + 10, max_amplitude)
		signal_bus.amplitude_changed.emit(amplitude)
		$Audio/HealPlayer.play()


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

func die() -> void:
	signal_bus.player_died.emit()

func _on_powerup_collected(powerup_type):
	if powerup_type == "DAMAGE":
		damage += 1
	elif powerup_type == "SPEED":
		speed += 50
	elif powerup_type == "FIRE_RATE":
		shoot_cooldown = max(0.0, shoot_cooldown - 0.09)
		shoot_cooldown_timer.wait_time = shoot_cooldown
	elif powerup_type == "MAX_HEALTH":
		amplitude = 100
		signal_bus.amplitude_changed.emit(amplitude)
	elif powerup_type == "ALL_WAVES":
		all_waves = true
		all_waves_timer.start()
	elif powerup_type == "BULLET_SPREAD":
		bullet_spread = true
		bullet_spread_timer.start()
	elif powerup_type == "BULLET_PIERCING":
		bullet_piercing = true
		bullet_piercing_timer.start()
	elif powerup_type == "BULLET_SPEED":
		bullet_speed += 100
	elif powerup_type == "ABSORB_ALL_FORMS":
		absorb_all_forms = true
		absorb_all_forms_timer.start()
	elif powerup_type == "TIME_SLOW":
		globals.time_slow_active = true
		signal_bus.time_slow_started.emit()

func _on_damage_boost_timeout() -> void:
	damage = 1

func _on_bullet_spread_timeout() -> void:
	bullet_spread = false
	
func _on_enemy_destroy():
	amplitude = min(amplitude + 5, max_amplitude)
	signal_bus.amplitude_changed.emit(amplitude)

func _on_all_waves_timeout() -> void:
	all_waves = false

func _on_bullet_piercing_timeout() -> void:
	bullet_piercing = false

func _on_absorb_all_forms_timeout() -> void:
	absorb_all_forms = false