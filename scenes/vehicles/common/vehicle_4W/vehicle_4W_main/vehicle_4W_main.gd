extends RigidBody3D

@export_group("References")
@export var car_body_meshres: Resource
@export var car_body_node: NodePath
@export var wheel_fl_node: NodePath
@export var wheel_fr_node: NodePath
@export var wheel_rl_node: NodePath
@export var wheel_rr_node: NodePath

var wheel_fl: Node3D
var wheel_fr: Node3D
var wheel_rl: Node3D
var wheel_rr: Node3D

var car_body_mesh: MeshInstance3D

var wheel_fl_mesh: MeshInstance3D
var wheel_fr_mesh: MeshInstance3D
var wheel_rl_mesh: MeshInstance3D
var wheel_rr_mesh: MeshInstance3D

var wheels: Array[Node3D]
var wheel_meshes: Array[MeshInstance3D]

########## STEERING ##########

@export var steering_wheel_mesh_node: NodePath
@export var max_steering_angle: float = 35.0
@export var max_steering_wheel_angle: float = 220.0
var steering_wheel: Node3D
var steer_input: float = 0.0
var steer_angle: float = 0.0
var steer_angle_normalized: float = 0.0



# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Get nodes from the nodepaths
	car_body_mesh = get_node(car_body_node) as MeshInstance3D
	wheel_fl = get_node(wheel_fl_node) as Node3D
	wheel_fr = get_node(wheel_fr_node) as Node3D
	wheel_rl = get_node(wheel_rl_node) as Node3D
	wheel_rr = get_node(wheel_rr_node) as Node3D
	steering_wheel = get_node(steering_wheel_mesh_node) as Node3D
	
	# Set wheels array
	wheels.append(wheel_fl)
	wheels.append(wheel_fr)
	wheels.append(wheel_rl)
	wheels.append(wheel_rr)
	
	# Pass this rigidbody's reference to the wheel component nodes
	for wheel in wheels:
		wheel.set_car_rigidbody(self)
	
	# Get the wheel meshes
	for wheel in wheels:
		wheel_meshes.append(wheel.wheel_mesh)
	
	# Set the initial position of the wheel meshes
	for i in range(4):
		wheel_meshes[i].position = Vector3(0.0, -wheels[i].rest_length, 0.0)
	
	# Set the mesh of the MeshInstance3D if not set
	if car_body_mesh.mesh == null:
		if car_body_meshres == null:
			print(name + "(Vehicle_4W_Main): vehicle body mesh not set in the inspector")
			# Prevent rigidbody being affected by gravity
			freeze = true
			return
		else:
			car_body_mesh.mesh = car_body_meshres


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if wheel_meshes:
		# Set the current position of the wheel meshes
		for i in range(4):
			wheel_meshes[i].position = Vector3(0.0, -wheels[i].current_length, 0.0)
		
		for i in range(4):
			# Get wheel rotation
			var wheel_rot = wheel_meshes[i].rotation_degrees
			# Get wheel angular velocity
			var wheel_angular_vel = wheels[i].wheel_angular_vel
			# Set new rotation
			wheel_meshes[i].rotation_degrees = Vector3(
				wheel_rot.x,
				wheel_rot.y,
				wheel_rot.z + rad_to_deg(wheel_angular_vel) * delta * -1.0
			)
	
	if Input.is_action_pressed("SteerRight"):
		steer_input = -1.0
	if Input.is_action_pressed("SteerLeft"):
		steer_input = 1.0
	if Input.is_action_just_released("SteerLeft") or Input.is_action_just_released("SteerRight"):
		steer_input = 0.0
	
	var steer_target = steer_input * max_steering_angle
	var steer_interp_speed = (1.0 / delta) * (0.3 if steer_input == 0 else 0.04)
	steer_angle = interp_to(steer_angle, steer_target, delta, steer_interp_speed)
	steer_angle_normalized = steer_angle / max_steering_angle
	
	# Apply steering to wheels
	for wheel in wheels:
		if wheel.use_as_steering:
			var wheel_rot = wheel.rotation_degrees
			wheel.rotation_degrees = Vector3(
				wheel_rot.x,
				steer_angle,
				wheel_rot.z
			)
	
	# Apply steering to steering wheel
	var steering_wheel_rotation = steer_angle_normalized * max_steering_wheel_angle
	steering_wheel.rotation_degrees.x = -steering_wheel_rotation
	# z rotation disabled since it doesn't work TODO: Fix this
	#steering_wheel.rotation_degrees.z = -26.0


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



