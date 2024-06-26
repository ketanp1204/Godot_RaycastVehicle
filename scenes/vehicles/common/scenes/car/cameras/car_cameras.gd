extends Node3D

@export var cameras: Array[Camera3D]
@export var spring_arm_default_rotations: Array[Vector3]
@export var default_camera: Camera3D
@export_range(0, 10, 0.01) var mouse_look_sensitivity : float = 3

var active_spring_arm: SpringArm3D
var cams: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	# Setup camera dictionary
	for index in cameras.size():
		cams[index] = cameras[index]
		
		# Set default rotation on the parent SpringArm3D
		cams[index].get_parent().rotation_degrees = spring_arm_default_rotations[index]
	
	# Enable the default camera
	default_camera.make_current()
	
	# Set it's parent as the active spring arm
	active_spring_arm = default_camera.get_parent() as SpringArm3D
	
	# Set the active spring arm's rotation
	# active_spring_arm.rotation_degrees = spring_arm_default_rotations
	
	# Disable other cameras
	for camera in cameras:
		if camera != default_camera:
			camera.clear_current()


func change_to_camera(index: int) -> void:
	
	var camera = cams[index]
	
	# Make the camera current
	camera.make_current()
	
	# Disable other cameras
	for cam in cameras:
		if cam != camera:
			cam.clear_current()
	
	# Get parent SpringArm3D
	var spring_arm = camera.get_parent() as SpringArm3D
	
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
