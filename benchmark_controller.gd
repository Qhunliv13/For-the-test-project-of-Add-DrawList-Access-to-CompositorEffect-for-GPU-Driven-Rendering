extends Node

enum PipelineMode {
	OLD,
	NEW,
	BOTH
}

var current_mode: PipelineMode = PipelineMode.BOTH

var old_pipeline: Node3D
var new_pipeline_effect: CompositorEffect
var camera: Camera3D

var stats_history: Array = []
var history_size: int = 60

var debug_print_timer: float = 0.0
var debug_print_interval: float = 2.0

var hardware_name: String = ""
var result_saved: bool = false

func _ready():
	camera = get_parent().get_node("Camera3D")
	
	Engine.max_fps = 20
	
	detect_hardware()
	ensure_result_directory()
	
	setup_old_pipeline()
	setup_new_pipeline()

func detect_hardware():
	var gpu_name = RenderingServer.get_video_adapter_name()
	gpu_name = gpu_name.replace(" ", "_").replace("(", "").replace(")", "")
	hardware_name = gpu_name

func ensure_result_directory():
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("result"):
		dir.make_dir("result")

func setup_old_pipeline():
	var script = load("res://benchmark_old_pipeline.gd")
	old_pipeline = script.new()
	old_pipeline.name = "OldPipeline"
	get_parent().add_child.call_deferred(old_pipeline)

func setup_new_pipeline():
	var compositor = Compositor.new()
	
	var updater_script = load("res://benchmark_updater.gd")
	var updater = updater_script.new()
	
	var renderer_script = load("res://benchmark_new_pipeline.gd")
	new_pipeline_effect = renderer_script.new()
	
	updater.set_parent(new_pipeline_effect)
	compositor.compositor_effects = [updater, new_pipeline_effect]
	
	camera.compositor = compositor

func _process(delta):
	update_visibility()
	collect_stats()
	
	debug_print_timer += delta
	if debug_print_timer >= debug_print_interval:
		debug_print_timer = 0.0
		print_performance_stats()

func update_visibility():
	if not old_pipeline or not is_instance_valid(old_pipeline):
		return
	
	match current_mode:
		PipelineMode.OLD:
			old_pipeline.visible = true
			old_pipeline.process_mode = Node.PROCESS_MODE_INHERIT
			if old_pipeline.has_method("add_all_spheres"):
				old_pipeline.add_all_spheres()
			new_pipeline_effect.enabled = false
		PipelineMode.NEW:
			old_pipeline.visible = false
			old_pipeline.process_mode = Node.PROCESS_MODE_DISABLED
			if old_pipeline.has_method("remove_all_spheres"):
				old_pipeline.remove_all_spheres()
			new_pipeline_effect.enabled = true
		PipelineMode.BOTH:
			old_pipeline.visible = true
			old_pipeline.process_mode = Node.PROCESS_MODE_INHERIT
			if old_pipeline.has_method("add_all_spheres"):
				old_pipeline.add_all_spheres()
			new_pipeline_effect.enabled = true

func collect_stats():
	var old_stats = {}
	var new_stats = {}
	
	if old_pipeline and is_instance_valid(old_pipeline) and old_pipeline.has_method("get_stats"):
		old_stats = old_pipeline.get_stats()
	
	if new_pipeline_effect and new_pipeline_effect.has_method("get_stats"):
		new_stats = new_pipeline_effect.get_stats()
	
	var frame_stats = {
		"old": old_stats,
		"new": new_stats,
		"fps": Engine.get_frames_per_second()
	}
	
	stats_history.append(frame_stats)
	if stats_history.size() > history_size:
		stats_history.pop_front()

func get_average_stats() -> Dictionary:
	if stats_history.is_empty():
		return {}
	
	var old_total = 0.0
	var new_total = 0.0
	var count = 0
	
	for stats in stats_history:
		if stats.has("old") and stats.old.has("total_time"):
			old_total += stats.old.total_time
		if stats.has("new") and stats.new.has("total_time"):
			new_total += stats.new.total_time
		count += 1
	
	if count == 0:
		return {}
	
	var old_avg = old_total / count
	var new_avg = new_total / count
	var speedup = old_avg / new_avg if new_avg > 0 else 0
	
	return {
		"old_avg": old_avg,
		"new_avg": new_avg,
		"speedup": speedup,
		"samples": count
	}

func toggle_mode():
	current_mode = (current_mode + 1) % 3
	
	var mode_names = ["OLD PIPELINE", "NEW PIPELINE", "BOTH PIPELINES"]
	print("\nMode: %s" % mode_names[current_mode])

func save_test_results():
	if result_saved:
		return
	
	var avg = get_average_stats()
	if avg.is_empty() or avg.samples < 60:
		return
	
	if avg.old_avg <= 0 or avg.new_avg <= 0:
		print("\n Cannot save results: Missing data from one or both pipelines")
		print("   Please run in BOTH PIPELINES mode to collect complete data")
		return
	
	result_saved = true
	
	var datetime = Time.get_datetime_dict_from_system()
	var time_str = "%04d%02d%02d_%02d%02d%02d" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]
	
	var speedup_str = "%.0fx" % avg.speedup
	var filename = "result/%s_%s_%s.txt" % [time_str, hardware_name, speedup_str]
	
	var file = FileAccess.open(filename, FileAccess.WRITE)
	if file:
		file.store_line("GPU-Driven Rendering Benchmark Results")
		file.store_line("=".repeat(70))
		file.store_line("")
		file.store_line("Test Date: %04d-%02d-%02d %02d:%02d:%02d" % [
			datetime.year, datetime.month, datetime.day,
			datetime.hour, datetime.minute, datetime.second
		])
		file.store_line("Hardware: %s" % hardware_name)
		file.store_line("Test Objects: 20,000 spheres (1,920,000 vertices)")
		file.store_line("")
		file.store_line("-".repeat(70))
		file.store_line("Results (Average of %d frames):" % avg.samples)
		file.store_line("-".repeat(70))
		file.store_line("")
		file.store_line("Old Pipeline (CPU-driven):")
		file.store_line("  Time per frame: %.3f ms" % avg.old_avg)
		var old_fps = min(1000.0 / avg.old_avg, 60.0)
		file.store_line("  Actual FPS: %.1f (VSync limited)" % old_fps)
		file.store_line("")
		file.store_line("New Pipeline (GPU-driven):")
		file.store_line("  Time per frame: %.3f ms" % avg.new_avg)
		var new_fps = min(1000.0 / avg.new_avg, 60.0)
		file.store_line("  Actual FPS: %.1f (VSync limited)" % new_fps)
		file.store_line("")
		file.store_line("Performance Improvement:")
		file.store_line("  Speedup: %.2fx" % avg.speedup)
		file.store_line("  Time reduction: %.2f%%" % ((1.0 - avg.new_avg / avg.old_avg) * 100.0))
		file.store_line("")
		file.store_line("=".repeat(70))
		file.close()
		print("\n Results saved to: %s" % filename)

func print_performance_stats():
	if stats_history.is_empty():
		return
	
	var avg = get_average_stats()
	if avg.is_empty():
		return
	
	if not result_saved and avg.samples >= 60:
		save_test_results()
	
	var latest = stats_history[-1]
	
	print("\n" + "-".repeat(70))
	print("Performance Stats (Frame: %d, FPS: %d)" % [Engine.get_frames_drawn(), latest.get("fps", 0)])
	print("-".repeat(70))
	
	if latest.has("old") and not latest.old.is_empty():
		print("Old Pipeline (CPU):")
		print("  Update Time: %.3f ms" % latest.old.get("update_time", 0))
		print("  Total Time:  %.3f ms" % latest.old.get("total_time", 0))
	
	if latest.has("new") and not latest.new.is_empty():
		print("New Pipeline (GPU):")
		print("  Compute Time: %.3f ms" % latest.new.get("compute_time", 0))
		print("  Render Time:  %.3f ms" % latest.new.get("render_time", 0))
		print("  Total Time:   %.3f ms" % latest.new.get("total_time", 0))
	
	print("Average (60 frames):")
	print("  Old Pipeline: %.3f ms" % avg.get("old_avg", 0))
	print("  New Pipeline: %.3f ms" % avg.get("new_avg", 0))
	print("  Speedup:      %.2fx" % avg.get("speedup", 0))
	print("-".repeat(70))

func _input(event):
	if event.is_action_pressed("ui_accept"):
		toggle_mode()
