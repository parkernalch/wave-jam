class_name Player extends CharacterBody2D

@onready var Bullet = preload("res://Entities/Bullet/Bullet.tscn")
@onready var bullet_spawn: Node2D = $BulletSpawn
@export var bullet_speed = 600;
@export var speed = 300


var shoot_cooldown_timer
var shoot_cooldown = 0.2
var can_shoot = true

func _ready() -> void:
	shoot_cooldown_timer = TimerHelper.make_timer(self, shoot_cooldown, _reset_shoot_cooldown, false, false)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("Shoot_Left"):
		shoot(true)
	elif Input.is_action_just_pressed("Shoot_Right"):
		shoot(false)

func shoot(is_left: bool):
	var bullet = Bullet.instantiate()

	if get_parent() && can_shoot:
		get_parent().add_child(bullet)
		bullet.global_position = bullet_spawn.global_position
		bullet.shoot(bullet_speed, is_left)
		can_shoot = false
		shoot_cooldown_timer.start()

func _reset_shoot_cooldown():
	can_shoot = true
