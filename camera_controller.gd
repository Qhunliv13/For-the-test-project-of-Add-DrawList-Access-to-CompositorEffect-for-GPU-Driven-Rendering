extends Camera3D

var rotation_speed = 0.5
var zoom_speed = 2.0
var distance = 5.0
var angle_x = 0.0
var angle_y = 0.3

func _ready():
	update_position()

func _process(delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		var mouse_delta = Input.get_last_mouse_velocity() * delta * 0.001
		angle_x -= mouse_delta.x * rotation_speed
		angle_y = clamp(angle_y - mouse_delta.y * rotation_speed, -PI/2 + 0.1, PI/2 - 0.1)
		update_position()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if Input.is_key_pressed(KEY_LEFT):
		angle_x += rotation_speed * delta
		update_position()
	if Input.is_key_pressed(KEY_RIGHT):
		angle_x -= rotation_speed * delta
		update_position()
	if Input.is_key_pressed(KEY_UP):
		angle_y = clamp(angle_y + rotation_speed * delta, -PI/2 + 0.1, PI/2 - 0.1)
		update_position()
	if Input.is_key_pressed(KEY_DOWN):
		angle_y = clamp(angle_y - rotation_speed * delta, -PI/2 + 0.1, PI/2 - 0.1)
		update_position()
	
	if Input.is_action_just_released("ui_page_up"):
		distance = max(2.0, distance - zoom_speed)
		update_position()
	if Input.is_action_just_released("ui_page_down"):
		distance = min(20.0, distance + zoom_speed)
		update_position()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = max(2.0, distance - zoom_speed * 0.5)
			update_position()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = min(20.0, distance + zoom_speed * 0.5)
			update_position()

func update_position():
	var x = distance * cos(angle_y) * cos(angle_x)
	var y = distance * sin(angle_y)
	var z = distance * cos(angle_y) * sin(angle_x)
	
	position = Vector3(x, y, z)
	look_at(Vector3.ZERO, Vector3.UP)
