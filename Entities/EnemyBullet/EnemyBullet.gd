extends RigidBody2D

@export var bullet_speed = 200;
@export var hit_box_size: Vector2 = Vector2(8, 8) # bullet AABB size (tune as needed)

var wave_form

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.

func shoot(bulletSpeed):
    bullet_speed = bulletSpeed

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
    var aabb = Rect2(global_position - hit_box_size * 0.5, hit_box_size)

    var candidates = spatial_hash.query(aabb)

    if (global_position.y > 1000):
        queue_free()
        return

    for obj in candidates:
        # ensure candidate has get_aabb or else skip
        if not obj.has_method("get_aabb"):
            continue
        var obj_rect = obj.get_aabb()
        if aabb.intersects(obj_rect):
            # narrow-phase: call enemy's hit method or do more precise shape checks
            if obj.has_method("take_damage"):
                obj.take_damage(1)
                # destroy bullet after hit (adjust to your logic)
                queue_free()
            return

    linear_velocity = Vector2(0, bullet_speed)	
