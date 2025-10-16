extends Control

var controller: Node
var fps_label: Label
var old_stats_label: Label
var new_stats_label: Label
var comparison_label: Label
var mode_label: Label

func _ready():
	controller = get_parent().get_node("BenchmarkController")
	
	fps_label = Label.new()
	fps_label.position = Vector2(10, 10)
	fps_label.add_theme_font_size_override("font_size", 24)
	add_child(fps_label)
	
	mode_label = Label.new()
	mode_label.position = Vector2(10, 45)
	mode_label.add_theme_font_size_override("font_size", 20)
	mode_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
	add_child(mode_label)
	
	old_stats_label = Label.new()
	old_stats_label.position = Vector2(10, 90)
	old_stats_label.add_theme_font_size_override("font_size", 18)
	old_stats_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	add_child(old_stats_label)
	
	new_stats_label = Label.new()
	new_stats_label.position = Vector2(10, 200)
	new_stats_label.add_theme_font_size_override("font_size", 18)
	new_stats_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	add_child(new_stats_label)
	
	comparison_label = Label.new()
	comparison_label.position = Vector2(10, 310)
	comparison_label.add_theme_font_size_override("font_size", 22)
	comparison_label.add_theme_color_override("font_color", Color(0.3, 1.0, 1.0))
	add_child(comparison_label)
	
	var help_label = Label.new()
	help_label.position = Vector2(10, 400)
	help_label.add_theme_font_size_override("font_size", 16)
	help_label.text = """Controls:
SPACE - Toggle Pipeline Mode
ESC - Quit"""
	add_child(help_label)

func _process(_delta):
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	
	var mode_text = ["OLD PIPELINE", "NEW PIPELINE", "BOTH PIPELINES"]
	mode_label.text = "Mode: %s" % mode_text[controller.current_mode]
	
	var stats = controller.stats_history
	if not stats.is_empty():
		var latest = stats[-1]
		
		if latest.has("old") and not latest.old.is_empty():
			old_stats_label.text = """Old Pipeline (CPU):
  Update: %.2f ms
  Total: %.2f ms
  Spheres: %d
  Vertices: %d""" % [
				latest.old.get("update_time", 0),
				latest.old.get("total_time", 0),
				latest.old.get("sphere_count", 0),
				latest.old.get("vertices", 0)
			]
		
		if latest.has("new") and not latest.new.is_empty():
			new_stats_label.text = """New Pipeline (GPU):
  Compute: %.2f ms
  Render: %.2f ms
  Total: %.2f ms
  Spheres: %d
  Vertices: %d""" % [
				latest.new.get("compute_time", 0),
				latest.new.get("render_time", 0),
				latest.new.get("total_time", 0),
				latest.new.get("sphere_count", 0),
				latest.new.get("vertices", 0)
			]
	
	var avg_stats = controller.get_average_stats()
	if not avg_stats.is_empty():
		comparison_label.text = """Performance Comparison (60 frame avg):
  Old Pipeline: %.2f ms
  New Pipeline: %.2f ms
  Speedup: %.2fx""" % [
			avg_stats.get("old_avg", 0),
			avg_stats.get("new_avg", 0),
			avg_stats.get("speedup", 0)
		]
	
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

