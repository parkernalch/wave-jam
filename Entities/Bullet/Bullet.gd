extends RigidBody2D

@export var bullet_speed = 200;
@export var hit_box_size: Vector2 = Vector2(30, 35) # bullet AABB size (tune as needed)

var wave_form
var damage
var all_waves
var bullet_angle
var bullet_piercing

@onready var rainbow_shader = preload("res://Assets/Shaders/RainbowShader.gdshader")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func shoot(bulletSpeed, waveForm, damage, all_waves, angle, bullet_piercing):
	bullet_speed = bulletSpeed
	wave_form = waveForm
	self.damage = damage
	self.all_waves = all_waves
	var color =  Color.WHITE if all_waves else wave_form["color"]
	globals.set_tint(self,  color, 1)
	bullet_angle = angle
	self.bullet_piercing = bullet_piercing

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var aabb = Rect2(global_position - hit_box_size * 0.5, hit_box_size)

	var candidates = spatial_hash.query(aabb)

	if (global_position.y < -100):
		queue_free()
		return

	for obj in candidates:
		# ensure candidate has get_aabb or else skip
		if not obj.has_method("get_aabb") || obj.has_method("take_damage"):
			continue
		var obj_rect = obj.get_aabb()
		if aabb.intersects(obj_rect):
			# narrow-phase: call enemy's hit method or do more precise shape checks
			if obj.has_method("on_hit"):
				obj.on_hit(wave_form, damage, all_waves)
				# destroy bullet after hit (adjust to your logic)
				if not bullet_piercing:
					queue_free()
			return

	linear_velocity = Vector2(bullet_angle, -bullet_speed)
	pass
