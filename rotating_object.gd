extends MeshInstance3D

@export var rotation_speed: Vector3 = Vector3(0, 1.0, 0)

func _process(delta):
	rotate_y(rotation_speed.y * delta)
	rotate_x(rotation_speed.x * delta)
	rotate_z(rotation_speed.z * delta)
