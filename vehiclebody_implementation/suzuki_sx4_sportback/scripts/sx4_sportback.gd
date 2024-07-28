extends VehicleBody3D


########## REFERENCES ##########
## Set any rear wheel VehicleWheel node here
@export var rear_wheel_node: NodePath
@export var info_label_node: NodePath
@export var steering_wheel_node: NodePath

var rear_wheel: VehicleWheel3D
var info_label: Label
var steering_wheel: Node3D

########## ENGINE ##########
var engine_state: GlobalEnums.ENGINE_STATES = GlobalEnums.ENGINE_STATES.OFF

########## STEERING ##########
@export_category("Steering")
@export var max_steer_angle: float = 30.0
@export var speed_steer_angle: float = 10.0
@export var max_steer_speed: float = 120.0
@export var max_steer_input: float = 90.0
@export var steer_speed: float = 1.0

@onready var max_steer_angle_rad = deg_to_rad(max_steer_angle)
@onready var speed_steer_angle_rad = deg_to_rad(speed_steer_angle)
@onready var max_steer_input_rad = deg_to_rad(max_steer_input)
@export var steer_curve: Curve

var steer_target: float = 0.0
var steer_angle: float = 0.0

########## SPEED AND DRIVE DIRECTION ##########
@export_category("Speed and Drive Direction")
@export var max_engine_force: float = 700.0
@export var max_brake_force: float = 50.0

@export var gear_ratios: Array[float] = [ 3.545, 1.904, 1.310, 0.969, 0.815 ]
@export var reverse_ratio: float = -3.25
@export var final_drive_ratio: float = 4.411
@export var max_engine_rpm: float = 8000.0
@export var power_curve: Curve

var current_gear: int = 0 # -1: reverse, 0: neutral, 1+: gears
var clutch_position: float = 1.0 # 0.0: clutch engaged
var current_speed_mps: float = 0.0
@onready var last_pos: Vector3 = global_transform.origin

var gear_shift_time: float = 0.3
var gear_timer: float = 0.0

func get_speed_kph():
	return current_speed_mps * 3600.0 / 1000.0

# Calculate RPM of engine based on the current speed of the car
func calculate_rpm() -> float:
	# Return 0.0 if wheel not set
	if not rear_wheel:
		return 0.0
	
	# If we are in neutral, no rpm
	if current_gear == 0:
		return 0.0
	
	var wheel_circumference: float = 2.0 * PI * rear_wheel.wheel_radius
	var wheel_rotation_speed: float = 60.0 * current_speed_mps / wheel_circumference
	var drive_shaft_rotation_speed: float = wheel_rotation_speed * final_drive_ratio
	if current_gear == -1:
		return drive_shaft_rotation_speed * -reverse_ratio
	elif current_gear <= gear_ratios.size():
		return drive_shaft_rotation_speed * gear_ratios[current_gear - 1]
	else:
		return 0.0



func _ready():
	if rear_wheel_node:
		rear_wheel = get_node(rear_wheel_node) as VehicleWheel3D
	if info_label_node:
		info_label = get_node(info_label_node) as Label
	if steering_wheel_node:
		steering_wheel = get_node(steering_wheel_node) as Node3D


func process_gear_inputs(delta: float) -> void:
	if gear_timer > 0.0:
		gear_timer = max(0.0, gear_timer - delta)
		clutch_position = 0.0
	else:
		if Input.is_action_pressed("GearShiftDown") and current_gear > -1:
			current_gear -= 1
			gear_timer = gear_shift_time
			clutch_position = 0.0
		elif Input.is_action_pressed("GearShiftUp") and current_gear < gear_ratios.size():
			current_gear += 1
			gear_timer = gear_shift_time
			clutch_position = 0.0
		else:
			clutch_position = 1.0


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


func _process(delta):
	
	if engine_state == GlobalEnums.ENGINE_STATES.RUNNING:
		process_gear_inputs(delta)
	
	if info_label:
		var speed = get_speed_kph()
		var rpm = calculate_rpm()
		var info = 'Speed: %.0f, RPM: %.0f (gear: %d)' % [ speed, rpm, current_gear ]
		info_label.text = info


func _physics_process(delta):
	# Speed in meters per second
	current_speed_mps = (global_transform.origin - last_pos).length() / delta
	
	var steer_val: float = 0.0
	var throttle_val: float = 0.0
	var brake_val: float = 0.0
	
	if Input.is_action_pressed("SteerLeft"):
		steer_val = -1.0
	elif Input.is_action_pressed("SteerRight"):
		steer_val = 1.0
	else:
		steer_val = 0.0
	
	if Input.is_action_pressed("Throttle"):
		throttle_val = 1.0
	else:
		throttle_val = 0.0
	
	if Input.is_action_pressed("Brake"):
		brake_val = 1.0
	else: 
		brake_val = 0.0
	
	var rpm = calculate_rpm()
	var rpm_factor = clamp(rpm / max_engine_rpm, 0.0, 1.0)
	var power_factor = power_curve.sample_baked(rpm_factor)
	
	if current_gear == -1:
		engine_force = \
		clutch_position * \
		throttle_val * \
		power_factor * \
		reverse_ratio * \
		final_drive_ratio * \
		max_engine_force
	elif current_gear > 0 and current_gear <= gear_ratios.size():
		engine_force = \
		clutch_position * \
		throttle_val * \
		power_factor * \
		gear_ratios[current_gear - 1] * \
		final_drive_ratio * \
		max_engine_force
	else:
		engine_force = 0.0
	
	brake = brake_val * max_brake_force
	
	var max_steer_speed_temp = max_steer_speed * 1000.0/3600.0
	var steer_speed_factor = clamp(current_speed_mps / max_steer_speed_temp, 0.0, 1.0)
	
	if abs(steer_val) < 0.05:
		steer_val = 0.0
	elif steer_curve:
		if steer_val < 0.0:
			steer_val = -steer_curve.sample_baked(-steer_val)
		else:
			steer_val =  steer_curve.sample_baked(steer_val)
	
	steer_angle = steer_val * lerp(max_steer_angle_rad, speed_steer_angle_rad, steer_speed_factor)
	steering = -steer_angle
	
	if steering_wheel:
		steering_wheel.rotation.z = steer_val * max_steer_input_rad
	
	last_pos = global_transform.origin


func _input(event):
	if event.is_action_pressed("EngineStart"):
		change_engine_state()
