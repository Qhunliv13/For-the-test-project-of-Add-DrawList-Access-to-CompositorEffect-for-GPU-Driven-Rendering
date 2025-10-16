extends Node3D

const SPHERE_COUNT = 20000
const VERTICES_PER_SPHERE = 96

var spheres: Array[MeshInstance3D] = []
var sphere_mesh: SphereMesh
var material: StandardMaterial3D

var update_time: float = 0.0
var render_time: float = 0.0
var spheres_in_tree: bool = true

func _ready():
	sphere_mesh = SphereMesh.new()
	sphere_mesh.radial_segments = 8
	sphere_mesh.rings = 4
	
	material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	for i in range(SPHERE_COUNT):
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = sphere_mesh
		mesh_instance.material_override = material
		add_child(mesh_instance)
		spheres.append(mesh_instance)

func _process(_delta):
	var start = Time.get_ticks_usec()
	
	for i in range(SPHERE_COUNT):
		var angle = float(i) / SPHERE_COUNT * TAU
		var radius = 10.0
		var height = sin(angle * 5.0) * 3.0
		
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		var y = height
		
		spheres[i].position = Vector3(x, y, z)
		
		var mat = spheres[i].material_override as StandardMaterial3D
		mat.albedo_color = Color(0.0, 0.0, 1.0)
	
	var end = Time.get_ticks_usec()
	update_time = (end - start) / 1000.0

func remove_all_spheres():
	if not spheres_in_tree:
		return
	for sphere in spheres:
		if is_instance_valid(sphere):
			remove_child(sphere)
	spheres_in_tree = false

func add_all_spheres():
	if spheres_in_tree:
		return
	for sphere in spheres:
		if is_instance_valid(sphere):
			add_child(sphere)
	spheres_in_tree = true

func get_stats() -> Dictionary:
	return {
		"update_time": update_time,
		"render_time": render_time,
		"total_time": update_time + render_time,
		"sphere_count": SPHERE_COUNT,
		"vertices": SPHERE_COUNT * VERTICES_PER_SPHERE
	}

