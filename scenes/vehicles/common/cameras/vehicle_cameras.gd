extends Node3D

@export var camera_nodes: Array[NodePath]
@export var spring_arm_default_rotations: Array[Vector3]
@export var default_camera_node: NodePath
@export_range(0, 10, 0.01) var mouse_look_sensitivity : float = 3

var cameras: Array[Camera3D]
var default_camera: Camera3D
var active_spring_arm: SpringArm3D
var cams: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	# Get all camera nodes
	for node in camera_nodes:
		cameras.append(get_node(node) as Camera3D)
	
	# Set default rotations for the spring arms
	for index in cameras.size():
		cameras[index].get_parent().rotation_degrees = spring_arm_default_rotations[index]
		
	
	# Get and enable the default camera
	default_camera = get_node(default_camera_node) as Camera3D
	default_camera.make_current()
	
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
	
	# Disable other cameras
	for camera in cameras:
		if camera != new_camera:
			camera.clear_current()
	
	# Get parent SpringArm3D
	var spring_arm = new_camera.get_parent() as SpringArm3D
	
	# Set parent as the active spring arm
	active_spring_arm = spring_arm
	
	# Set default rotation on the spring arm
	spring_arm.rotation_degrees = spring_arm_default_rotations[index]


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
	
	# Handle mouse clicks
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				if event.pressed:
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				else:
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
