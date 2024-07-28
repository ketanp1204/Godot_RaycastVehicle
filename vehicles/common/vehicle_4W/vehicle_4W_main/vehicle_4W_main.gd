extends RigidBody3D

@export_category("References")
@export var car_body_meshres: Resource
@export var car_body_node: NodePath
@export var door_fl_node: NodePath
@export var door_fr_node: NodePath
@export var door_rl_node: NodePath
@export var door_rr_node: NodePath
@export var wheel_fl_node: NodePath
@export var wheel_fr_node: NodePath
@export var wheel_rl_node: NodePath
@export var wheel_rr_node: NodePath
@export var steering_wheel_mesh_node: NodePath
@export var lights_node: NodePath
@export var cameras_node: NodePath
@export var info_node: NodePath
@export var engine_node: NodePath
@export var gearbox_node: NodePath
@export var differential_node: NodePath
@export var clutch_node: NodePath

var car_body_mesh: MeshInstance3D
var door_fl: Node3D
var door_fr: Node3D
var door_rl: Node3D
var door_rr: Node3D
var wheel_fl: Vehicle_4W_Wheel
var wheel_fr: Vehicle_4W_Wheel
var wheel_rl: Vehicle_4W_Wheel
var wheel_rr: Vehicle_4W_Wheel
var lights: Node3D
var cameras: Node3D
var info: Label
var engine: Vehicle_4W_Engine
var gearbox: Vehicle_4W_Gearbox
var differential: Vehicle_4W_Differential
var clutch: Vehicle_4W_Clutch

var wheels: Array[Vehicle_4W_Wheel]
var wheel_meshes: Array[MeshInstance3D]


########## STEERING ##########
@export_category("Steering")
@export var max_steering_angle: float = 35.0
@export var max_steering_wheel_angle: float = 220.0
var steering_wheel: Node3D
var steer_input: float = 0.0
var steer_angle: float = 0.0
var steer_angle_normalized: float = 0.0


########## LIGHTS ##########
@export_category("Lights")
@export var headlight_mat_index: int


########## ENGINE ##########
var engine_state: GlobalEnums.ENGINE_STATES = GlobalEnums.ENGINE_STATES.OFF


var throttle: float = 0.0
var drive_torque: float = 0.0
var last_pos: Vector3 = Vector3.ZERO
var current_speed_mps: float = 0.0



# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Get nodes from the nodepaths
	car_body_mesh = get_node(car_body_node) as MeshInstance3D
	door_fl = get_node(door_fl_node) as Node3D
	door_fr = get_node(door_fr_node) as Node3D
	door_rl = get_node(door_rl_node) as Node3D
	door_rr = get_node(door_rr_node) as Node3D
	wheel_fl = get_node(wheel_fl_node) as Vehicle_4W_Wheel
	wheel_fr = get_node(wheel_fr_node) as Vehicle_4W_Wheel
	wheel_rl = get_node(wheel_rl_node) as Vehicle_4W_Wheel
	wheel_rr = get_node(wheel_rr_node) as Vehicle_4W_Wheel
	steering_wheel = get_node(steering_wheel_mesh_node) as Node3D
	lights = get_node(lights_node) as Node3D
	cameras = get_node(cameras_node) as Node3D
	info = get_node(info_node) as Label
	engine = get_node(engine_node) as Vehicle_4W_Engine
	gearbox = get_node(gearbox_node) as Vehicle_4W_Gearbox
	differential = get_node(differential_node) as Vehicle_4W_Differential
	clutch = get_node(clutch_node) as Vehicle_4W_Clutch
	
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
	
	# Connect the cameras signal to the doors
	cameras.active_camera_changed.connect(door_fl.set_active_camera_index)
	cameras.active_camera_changed.connect(door_fr.set_active_camera_index)
	cameras.active_camera_changed.connect(door_rl.set_active_camera_index)
	cameras.active_camera_changed.connect(door_rr.set_active_camera_index)


func change_engine_state() -> void:
	if engine_state == GlobalEnums.ENGINE_STATES.OFF:
		engine_state = GlobalEnums.ENGINE_STATES.ELECTRICITY
		SignalManager.engine_state_changed.emit(engine_state)
	elif engine_state == GlobalEnums.ENGINE_STATES.ELECTRICITY:
		engine_state = GlobalEnums.ENGINE_STATES.RUNNING
		SignalManager.engine_state_changed.emit(engine_state)
	elif engine_state == GlobalEnums.ENGINE_STATES.RUNNING:
		engine_state = GlobalEnums.ENGINE_STATES.OFF
		SignalManager.engine_state_changed.emit(engine_state)


func get_speed_kph() -> float:
	return current_speed_mps * 3600.0 / 1000.0


func _process(delta):
	
	var speed = get_speed_kph()
	var engine_rpm = engine.engine_rpm
	var engine_effective_torque = engine.engine_effective_torque
	var gear = gearbox.current_gear
	var gear_ratio = gearbox.current_gear_ratio
	var clutch_torque = clutch.clutch_torque
	var clutch_lock = clutch.clutch_lock
	
	if info:
		var info_text = \
		'Speed: %.0f, 
		Engine RPM: %.0f, 
		Engine Effective Torque: %.0f, 
		Gear: %d, 
		Gear Ratio: %.2f, 
		Clutch Torque: %.1f, 
		Clutch Lock: %.1f)' \
		% [ 
			speed, 
			engine_rpm, 
			engine_effective_torque, 
			gear, 
			gear_ratio, 
			clutch_torque, 
			clutch_lock ]
		
		info.text = info_text


func _physics_process(delta):
	if not (gearbox or clutch or differential or engine):
		return
	
	current_speed_mps = (position - last_pos).length() / delta
	
	if Input.is_action_pressed("Throttle"):
		throttle = 1.0
	if Input.is_action_just_released("Throttle"):
		throttle = 0.0
	
	var gearbox_output_torque = gearbox.get_output_torque(clutch.clutch_torque)
	var differential_output_torques = differential.get_output_torque(gearbox_output_torque)
	wheel_fl.update_physics(delta, 0.0)
	wheel_fr.update_physics(delta, 0.0)
	wheel_rl.update_physics(delta, differential_output_torques[0])
	wheel_rr.update_physics(delta, differential_output_torques[1])
	var differential_input_shaft_vel = differential.get_input_shaft_velocity(
		wheel_rl.wheel_angular_vel,
		wheel_rr.wheel_angular_vel
	)
	var gearbox_input_shaft_vel = gearbox.get_input_shaft_velocity(
		differential_input_shaft_vel
	)
	clutch.update_physics(
		gearbox_input_shaft_vel,
		engine.engine_angular_velocity,
		gearbox.current_gear_ratio
	)
	engine.update_physics(delta, throttle, clutch.clutch_torque)
	
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
	#steering_wheel.rotate_object_local(Vector3.RIGHT, steering_wheel_rotation)
	steering_wheel.rotation_degrees.x = -steering_wheel_rotation
	# z rotation disabled since it doesn't work TODO: Fix this
	#steering_wheel.rotation_degrees.z = -26.0
	
	last_pos = position


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


func _input(event):
	if event.is_action_pressed("EngineStart"):
		change_engine_state()
	
	if event.is_action_pressed("GearShiftUp"):
		gearbox.shift_gear_up()
	
	if event.is_action_pressed("GearShiftDown"):
		gearbox.shift_gear_down()
