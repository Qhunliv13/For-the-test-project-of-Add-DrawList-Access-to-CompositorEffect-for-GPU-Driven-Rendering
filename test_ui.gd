extends Control

var fps_label: Label
var info_label: Label
var start_time: float = 0.0

func _ready():
	start_time = Time.get_ticks_msec() / 1000.0
	
	fps_label = Label.new()
	fps_label.position = Vector2(10, 10)
	fps_label.add_theme_font_size_override("font_size", 24)
	add_child(fps_label)
	
	info_label = Label.new()
	info_label.position = Vector2(10, 50)
	info_label.add_theme_font_size_override("font_size", 18)
	info_label.text = """GPU Compute -> Direct Render Demo
Godot 4.5 Custom Build
CompositorEffect Extension

Controls:
• Right Mouse - Rotate Camera
• Mouse Wheel - Zoom
• Arrow Keys - Rotate Camera
• ESC - Quit
"""
	add_child(info_label)
	
	var title = Label.new()
	title.position = Vector2(10, 400)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
	title.text = "GPU Compute -> Direct Render"
	add_child(title)

func _process(_delta):
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
