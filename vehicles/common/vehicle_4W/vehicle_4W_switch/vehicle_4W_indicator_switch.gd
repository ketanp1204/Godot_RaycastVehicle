extends Node3D

@export_category("References")
@export var indicator_switch_mesh_node: NodePath
@export var light_switch_mesh_node: NodePath
@export var vehicle_lights_node: NodePath
@export var audio_stream_player_node: NodePath

@export_category("Indicator Switch Parameters")
## Axis of rotation for turn signal
@export var turn_signal_rotation_axis: GlobalEnums.ROTATION_AXIS
## Angle of turn signal rotation
@export var turn_signal_angle_delta: float = 10.0
## Whether to subtract delta rotation angle
@export var turn_signal_left_subtract: bool = false
## Axis of rotation for high beam switch
@export var high_beam_rotation_axis: GlobalEnums.ROTATION_AXIS
## Angle of high beam switch rotation
@export var high_beam_angle_delta: float = 10.0
## Whether to subtract delta rotation angle
@export var high_beam_subtract_rotation: bool = false

@export_category("Light Switch Parameters")
## Axis of rotation for light switch
@export var light_switch_rotation_axis: GlobalEnums.ROTATION_AXIS
## Angle of light switch rotation
@export var light_switch_angle_delta: float = 0.0
## Whether to subtract delta rotation angle
@export var light_switch_subtract_rotation: bool = false


# Node reference variables
var vehicle_lights: Node3D
var audio_stream_player: AudioStreamPlayer3D

# Indicator switch variables
var indicator_switch_mesh: MeshInstance3D
var current_turn_signal_mode: GlobalEnums.INDICATOR_MODE = GlobalEnums.INDICATOR_MODE.OFF
var turn_signal_off_mode_angle: float = 0.0
var turn_signal_left_mode_angle: float = 0.0
var turn_signal_right_mode_angle: float = 0.0
var current_high_beam_mode: bool = false
var high_beam_off_mode_angle: float = 0.0
var high_beam_on_mode_angle: float = 0.0

# Light switch variables
var light_switch_mesh: MeshInstance3D
var current_light_mode: GlobalEnums.LIGHT_MODES = GlobalEnums.LIGHT_MODES.OFF
var light_off_mode_angle: float = 0.0
var light_park_mode_angle: float = 0.0
var light_main_mode_angle: float = 0.0

# Animation variables
var light_from_angle: float = 0.0
var light_to_angle: float = 0.0
var light_anim_length: float = 0.0
var turn_signal_from_angle: float = 0.0
var turn_signal_to_angle: float = 0.0
var turn_signal_anim_length: float = 0.0
var high_beam_from_angle: float = 0.0
var high_beam_to_angle: float = 0.0
var high_beam_anim_length: float = 0.0
@export_category("Animation")
## Degrees per second
@export var anim_speed = 120


func _ready():
	# Get nodes from NodePath
	if indicator_switch_mesh_node:
		indicator_switch_mesh = get_node(indicator_switch_mesh_node) as MeshInstance3D
	if light_switch_mesh_node:
		light_switch_mesh = get_node(light_switch_mesh_node) as MeshInstance3D
	if vehicle_lights_node:
		vehicle_lights = get_node(vehicle_lights_node) as Node3D
	if audio_stream_player_node:
		audio_stream_player = get_node(audio_stream_player_node) as AudioStreamPlayer3D
		
	# Connect light mode changed signal 
	vehicle_lights.light_mode_changed.connect(set_light_mode)
	
	# Get turn indicator angles on selected rotation axis
	turn_signal_off_mode_angle = get_node_selected_axis_rotation(self, turn_signal_rotation_axis)
	turn_signal_left_mode_angle =  turn_signal_off_mode_angle + (
		-turn_signal_angle_delta if turn_signal_left_subtract
		else turn_signal_angle_delta)
	turn_signal_right_mode_angle = turn_signal_off_mode_angle + (
		turn_signal_angle_delta if turn_signal_left_subtract
		else -turn_signal_angle_delta)
	
	# Get high beam switch angles on selected rotation axis
	high_beam_off_mode_angle = get_node_selected_axis_rotation(self, high_beam_rotation_axis)
	high_beam_on_mode_angle = high_beam_off_mode_angle + (
		-high_beam_angle_delta if high_beam_subtract_rotation
		else high_beam_angle_delta)
	
	# Get light switch angles on selected rotation axis
	light_off_mode_angle = get_node_selected_axis_rotation(light_switch_mesh, light_switch_rotation_axis)
	light_park_mode_angle = light_off_mode_angle + (
		-light_switch_angle_delta if light_switch_subtract_rotation 
		else light_switch_angle_delta)
	light_main_mode_angle = light_park_mode_angle + (
		-light_switch_angle_delta if light_switch_subtract_rotation
		else light_switch_angle_delta)


# Get rotation of Node3D on selected rotation axis
func get_node_selected_axis_rotation(node: Node3D, axis: GlobalEnums.ROTATION_AXIS) -> float:
	if axis == GlobalEnums.ROTATION_AXIS.X:
		return node.rotation_degrees.x
	elif axis == GlobalEnums.ROTATION_AXIS.Y:
		return node.rotation_degrees.y
	elif axis == GlobalEnums.ROTATION_AXIS.Z:
		return node.rotation_degrees.z
	else:
		return 0.0


func set_light_mode(mode: GlobalEnums.LIGHT_MODES) -> void:
	current_light_mode = mode
	
	if current_light_mode == GlobalEnums.LIGHT_MODES.OFF:
		start_light_off_mode_anim()
	elif current_light_mode == GlobalEnums.LIGHT_MODES.PARK:
		start_light_park_mode_anim()
	elif current_light_mode == GlobalEnums.LIGHT_MODES.MAIN:
		start_light_main_mode_anim()


func light_switch_anim(from: float, to: float) -> void:
	light_anim_length = abs(from - to) / anim_speed
	var t: float = 0.0
	while (t < light_anim_length):
		if light_switch_rotation_axis == GlobalEnums.ROTATION_AXIS.X:
			light_switch_mesh.rotation_degrees.x = light_anim_lerp(t, from, to)
		elif light_switch_rotation_axis == GlobalEnums.ROTATION_AXIS.Y:
			light_switch_mesh.rotation_degrees.y = light_anim_lerp(t, from, to)
		elif light_switch_rotation_axis == GlobalEnums.ROTATION_AXIS.Z:
			light_switch_mesh.rotation_degrees.z = light_anim_lerp(t, from, to)
		
		t += get_process_delta_time()
		await get_tree().process_frame


func light_anim_lerp(t: float, from: float, to: float) -> float:
	return lerpf(from, to, t / light_anim_length)


func start_light_off_mode_anim() -> void:
	# Change light mode to OFF
	current_light_mode = GlobalEnums.LIGHT_MODES.OFF
	# Set from and to angles
	light_from_angle = get_node_selected_axis_rotation(light_switch_mesh, light_switch_rotation_axis)
	light_to_angle = light_off_mode_angle
	# Start light switch animation
	light_switch_anim(light_from_angle, light_to_angle)


func start_light_park_mode_anim() -> void:
	# Change light mode to PARK
	current_light_mode = GlobalEnums.LIGHT_MODES.PARK
	# Set from and to angles
	light_from_angle = get_node_selected_axis_rotation(light_switch_mesh, light_switch_rotation_axis)
	light_to_angle = light_park_mode_angle
	# Start light switch animation
	light_switch_anim(light_from_angle, light_to_angle)


func start_light_main_mode_anim() -> void:
	# Change light mode to MAIN
	current_light_mode = GlobalEnums.LIGHT_MODES.MAIN
	# Set from and to angles
	light_from_angle = get_node_selected_axis_rotation(light_switch_mesh, light_switch_rotation_axis)
	light_to_angle = light_main_mode_angle
	# Start light switch animation
	light_switch_anim(light_from_angle, light_to_angle)


func set_turn_signal(mode: GlobalEnums.INDICATOR_MODE) -> void:
	current_turn_signal_mode = mode
	
	if current_turn_signal_mode == GlobalEnums.INDICATOR_MODE.OFF:
		start_turn_off_mode_anim()
	elif current_turn_signal_mode == GlobalEnums.INDICATOR_MODE.LEFT:
		start_turn_left_mode_anim()
	elif current_turn_signal_mode == GlobalEnums.INDICATOR_MODE.RIGHT:
		start_turn_right_mode_anim()


func turn_signal_anim(from: float, to: float) -> void:
	turn_signal_anim_length = abs(from - to) / anim_speed
	var t: float = 0.0
	while (t < turn_signal_anim_length):
		if turn_signal_rotation_axis == GlobalEnums.ROTATION_AXIS.X:
			rotation_degrees.x = turn_signal_anim_lerp(t, from, to)
		elif turn_signal_rotation_axis == GlobalEnums.ROTATION_AXIS.Y:
			rotation_degrees.y = turn_signal_anim_lerp(t, from, to)
		elif turn_signal_rotation_axis == GlobalEnums.ROTATION_AXIS.Z:
			rotation_degrees.z = turn_signal_anim_lerp(t, from, to)
		
		t += get_process_delta_time()
		await get_tree().process_frame


func turn_signal_anim_lerp(t: float, from: float, to: float) -> float:
	return lerp(from, to, t / turn_signal_anim_length)


func start_turn_off_mode_anim() -> void:
	# Change turn signal mode to OFF
	current_turn_signal_mode = GlobalEnums.INDICATOR_MODE.OFF
	# Set from and to angles
	turn_signal_from_angle = get_node_selected_axis_rotation(self, turn_signal_rotation_axis)
	turn_signal_to_angle = turn_signal_off_mode_angle
	# Start turn signal animation
	turn_signal_anim(turn_signal_from_angle, turn_signal_to_angle)


func start_turn_left_mode_anim() -> void:
	# Change turn signal mode to OFF
	current_turn_signal_mode = GlobalEnums.INDICATOR_MODE.LEFT
	# Set from and to angles
	turn_signal_from_angle = get_node_selected_axis_rotation(self, turn_signal_rotation_axis)
	turn_signal_to_angle = turn_signal_left_mode_angle
	# Start turn signal animation
	turn_signal_anim(turn_signal_from_angle, turn_signal_to_angle)


func start_turn_right_mode_anim() -> void:
	# Change turn signal mode to OFF
	current_turn_signal_mode = GlobalEnums.INDICATOR_MODE.RIGHT
	# Set from and to angles
	turn_signal_from_angle = get_node_selected_axis_rotation(self, turn_signal_rotation_axis)
	turn_signal_to_angle = turn_signal_right_mode_angle
	# Start turn signal animation
	turn_signal_anim(turn_signal_from_angle, turn_signal_to_angle)


func set_high_beam(mode: bool) -> void:
	current_high_beam_mode = mode
	
	if current_high_beam_mode == true:
		start_high_beam_off_mode_anim()
	else:
		start_high_beam_on_mode_anim()


func high_beam_anim(from: float, to: float) -> void:
	high_beam_anim_length = abs(from - to) / anim_speed
	var t: float = 0.0
	while (t < high_beam_anim_length):
		if high_beam_rotation_axis == GlobalEnums.ROTATION_AXIS.X:
			rotation_degrees.x = high_beam_anim_lerp(t, from, to)
		elif high_beam_rotation_axis == GlobalEnums.ROTATION_AXIS.Y:
			rotation_degrees.y = high_beam_anim_lerp(t, from, to)
		elif high_beam_rotation_axis == GlobalEnums.ROTATION_AXIS.Z:
			rotation_degrees.z = high_beam_anim_lerp(t, from, to)
		
		t += get_process_delta_time()
		await get_tree().process_frame


func high_beam_anim_lerp(t: float, from: float, to: float):
	return lerpf(from, to, t / high_beam_anim_length)


func start_high_beam_off_mode_anim():
	# Change high beam mode to false (OFF)
	current_high_beam_mode = false
	# Set from and to angles
	high_beam_from_angle = get_node_selected_axis_rotation(self, high_beam_rotation_axis)
	high_beam_to_angle = high_beam_off_mode_angle
	# Start high beam switch animation
	high_beam_anim(high_beam_from_angle, high_beam_to_angle)


func start_high_beam_on_mode_anim():
	# Change high beam mode to true (ON)
	current_high_beam_mode = true
	# Set from and to angles
	high_beam_from_angle = get_node_selected_axis_rotation(self, high_beam_rotation_axis)
	high_beam_to_angle = high_beam_on_mode_angle
	# Start high beam switch animation
	high_beam_anim(high_beam_from_angle, high_beam_to_angle)


# TODO: Temporary through inputs, change to signals from respective scripts
func _input(event):
	if event.is_action_pressed("LeftTurnIndicator"):
		SoundManager.play_light_switch_toggle(audio_stream_player)
		if current_turn_signal_mode == GlobalEnums.INDICATOR_MODE.LEFT:
			set_turn_signal(GlobalEnums.INDICATOR_MODE.OFF)
		else:
			set_turn_signal(GlobalEnums.INDICATOR_MODE.LEFT)
	
	if event.is_action_pressed("RightTurnIndicator"):
		SoundManager.play_light_switch_toggle(audio_stream_player)
		if current_turn_signal_mode == GlobalEnums.INDICATOR_MODE.RIGHT:
			set_turn_signal(GlobalEnums.INDICATOR_MODE.OFF)
		else:
			set_turn_signal(GlobalEnums.INDICATOR_MODE.RIGHT)
	
	if event.is_action_pressed("HighBeamToggle"):
		if current_high_beam_mode == true:
			set_high_beam(true)
		else:
			set_high_beam(false)
