extends Node

func _ready():
	var compositor = Compositor.new()
	
	var updater_script = load("res://final_updater.gd")
	var updater = updater_script.new()
	
	var renderer_script = load("res://final_demo.gd")
	var renderer = renderer_script.new()
	
	updater.set_parent(renderer)
	compositor.compositor_effects = [updater, renderer]
	
	var camera = get_parent().get_node("Camera3D")
	if camera:
		camera.compositor = compositor

