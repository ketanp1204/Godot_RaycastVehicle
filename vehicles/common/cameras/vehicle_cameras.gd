extends Node3D
signal active_camera_changed(camera: String)


@export var spring_arm_nodes: Array[NodePath]
@export var spring_arms_data: Array[SpringArmData]
@export var default_camera_node: NodePath
@export_range(0, 10, 0.01) var mouse_look_sensitivity : float = 3

var spring_arms: Array[SpringArm3D]
var cameras: Array[Camera3D]
var default_camera: Camera3D
var active_camera_index: int
var active_spring_arm: SpringArm3D
var target_arm_length: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if spring_arm_nodes.size() == 0:
		return
	
	# Get all spring arm and camera nodes
	for index in spring_arm_nodes.size():
		var spring_arm = get_node(spring_arm_nodes[index]) as SpringArm3D
		spring_arms.append(spring_arm)
		cameras.append(spring_arm.get_child(0) as Camera3D)
		
		# Set spring arm data
		spring_arm.position = spring_arms_data[index].initial_position
		spring_arm.rotation_degrees = spring_arms_data[index].default_rotation
		spring_arm.spring_length = spring_arms_data[index].spring_length
		target_arm_length = spring_arm.spring_length
	
	# Get and enable the default camera
	default_camera = get_node(default_camera_node) as Camera3D
	default_camera.make_current()
	
	# Get default camera index
	var default_camera_index: int = 0
	for index in cameras.size():
		if cameras[index] == default_camera:
			default_camera_index = index
	
	# Set the active camera value
	active_camera_index = default_camera_index
	active_camera_changed.emit(active_camera_index)
	
	# Set it's parent as the active spring arm
	active_spring_arm = default_camera.get_parent() as SpringArm3D
	
	# Disable other cameras
	for camera in cameras:
		if camera != default_camera:
			camera.clear_current()


func change_to_camera(index: int) -> void:
	
	var new_camera = cameras[index]
	
	# Make the camera current
	new_camera.make_current()
	
	# Set active camera enum
	active_camera_index = index
	active_camera_changed.emit(active_camera_index)
	
	# Disable other cameras
	for camera in cameras:
		if camera != new_camera:
			camera.clear_current()
	
	# Get parent SpringArm3D
	var spring_arm = spring_arms[index]
	
	# Set parent as the active spring arm
	active_spring_arm = spring_arm
	
	# Set default rotation on the spring arm
	spring_arm.rotation_degrees = spring_arms_data[index].default_rotation


func _process(delta):
	spring_arm_zoom(delta)


func spring_arm_zoom(delta: float) -> void:
	
	var active_spring_length = active_spring_arm.spring_length
	if target_arm_length != active_spring_length:
		var spring_length_interp = interp_to(
			active_spring_length,
			target_arm_length,
			delta,
			spring_arms_data[active_camera_index].zoom_interp_speed
		)
		
		spring_length_interp = clampf(
			spring_length_interp, 
			spring_arms_data[active_camera_index].zoom_min,
			spring_arms_data[active_camera_index].zoom_max)
		
		active_spring_arm.spring_length = spring_length_interp


func _input(event) -> void:
	
	# Change to internal camera (index = 0)
	if event.is_action_pressed("InternalCamera"):
		change_to_camera(0)
	
	# Change to chasing camera (index = 1)
	if event.is_action_pressed("ChasingCamera"):
		change_to_camera(1)
	
	# Handle mouse movement
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			active_spring_arm.rotation.y -= event.relative.x / 1000 * mouse_look_sensitivity
			active_spring_arm.rotation.x -= event.relative.y / 1000 * mouse_look_sensitivity
			active_spring_arm.rotation.x = clamp(active_spring_arm.rotation.x, PI/-2.5, PI/2.5)
		
		if event is InputEventMouseButton:
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					if event.pressed:
						# Zoom in 
						var zoom_delta = spring_arms_data[active_camera_index].zoom_delta
						target_arm_length = active_spring_arm.spring_length - zoom_delta
				MOUSE_BUTTON_WHEEL_DOWN:
					if event.pressed:
						# Zoom out
						var zoom_delta = spring_arms_data[active_camera_index].zoom_delta
						target_arm_length = active_spring_arm.spring_length + zoom_delta
	
	# Handle mouse buttons
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				if event.pressed:
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				else:
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func interp_to(current: float, target: float, delta: float, interp_speed: float) -> float:
	# If no interp speed is given, or delta time is zero, return target directly
	if interp_speed <= 0.0 or delta <= 0.0:
		return target
	
	# Calculate distance to interpolate
	var distance: float = target - current
	
	# If the distance is very small, just return the target
	if distance**2 < 0.0001:
		return target
	
	var delta_move = distance * clampf(delta * interp_speed, 0.0, 1.0)
	
	return current + delta_move
