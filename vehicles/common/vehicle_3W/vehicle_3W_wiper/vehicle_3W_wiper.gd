extends Node3D

enum WIPER_MODE { OFF, SINGLE, CONTINUOUS, RAPID}
enum WIPER_MOVE_STATE { OFF, RESTART_DELAY, TOWARDS_MAX, TOWARDS_ZERO }

@export_category("Mesh")
## Mesh resource for the wiper
@export var wiper_meshres: Resource

@export_category("Rotation Params")
## Maximum angle that the wiper rotates from the starting position
@export var max_rotate_angle: float = 82.0
## Delay after which the wiper starts again in the SINGLE wiper mode
@export var restart_delay: float = 3.0
## Rotation speed of the wiper in the SINGLE and CONTINUOUS states (degrees per second)
@export var low_rotation_speed: float = 120
## Rotation speed of the wiper in the RAPID state (degrees per second)
@export var high_rotation_speed: float = 180

@onready var wiper_mesh = $WiperMesh
@onready var mouse_handle = $MouseHandle

var wiper_mode: WIPER_MODE
var wiper_move_state: WIPER_MOVE_STATE

var from_angle: float = 0.0
var anim_length: float
var delay: float = 0.0 
var stop_animation: bool = false
var loop_rotation: bool = false

signal towards_max_completed
signal towards_max_from_current_completed
signal towards_zero_completed
signal towards_zero_from_current_completed


func _ready():
	# Set the mesh of the MeshInstance3D if not set
	if wiper_mesh.mesh == null:
		if wiper_meshres == null:
			print("ERROR @ Node " + name + ": Wiper mesh not set in the inspector")
			return
		else:
			wiper_mesh.mesh = wiper_meshres
	
	# Set the default wiper mode and move state
	wiper_mode = WIPER_MODE.OFF
	wiper_move_state = WIPER_MOVE_STATE.OFF
	
	# Connect the mouse handle click signal
	mouse_handle.mouse_clicked.connect(toggle)


func toggle() -> void:
	if wiper_mode == WIPER_MODE.OFF:
		wiper_single_state()
	elif wiper_mode == WIPER_MODE.SINGLE:
		wiper_continuous_state()
	elif wiper_mode == WIPER_MODE.CONTINUOUS:
		wiper_rapid_state()
	elif wiper_mode == WIPER_MODE.RAPID:
		wiper_off_state()


func wiper_move_towards_max() -> void:
	wiper_move_state = WIPER_MOVE_STATE.TOWARDS_MAX
	var t: float = 0.0
	while (t < anim_length):
		if stop_animation:
			stop_animation = false
			return
		rotation_degrees.y = lerpf(
							0.0, 
							max_rotate_angle, 
							t / anim_length)
		t += get_process_delta_time()
		await get_tree().process_frame
	# Emit the towards max completed signal
	towards_max_completed.emit()


func wiper_move_towards_max_from_current() -> void:
	wiper_move_state = WIPER_MOVE_STATE.TOWARDS_MAX
	var t: float = 0.0
	while (t < anim_length):
		if stop_animation:
			stop_animation = false
			return
		rotation_degrees.y = lerpf(
							from_angle, 
							max_rotate_angle, 
							t / anim_length)
		t += get_process_delta_time()
		await get_tree().process_frame
	# Emit the towards max from current completed signal
	towards_max_from_current_completed.emit()


func wiper_move_towards_zero() -> void:
	wiper_move_state = WIPER_MOVE_STATE.TOWARDS_ZERO
	var t: float = 0.0
	while (t < anim_length):
		if stop_animation:
			stop_animation = false
			return
		rotation_degrees.y = lerpf(
			max_rotate_angle,  
			0.0,
			t / anim_length
		)
		t += get_process_delta_time()
		await get_tree().process_frame
	# Emit the towards zero completed signal
	towards_zero_completed.emit()


func wiper_move_towards_zero_from_current() -> void:
	wiper_move_state = WIPER_MOVE_STATE.TOWARDS_ZERO
	var t: float = 0.0
	while (t < anim_length):
		if stop_animation:
			stop_animation = false
			return
		rotation_degrees.y = lerpf(
			from_angle,
			0.0,
			t / anim_length
		)
		t += get_process_delta_time()
		await get_tree().process_frame
	# Emit the towards zero from current completed signal
	towards_zero_from_current_completed.emit()


func wiper_rotation() -> void:
	wiper_move_towards_max()
	await towards_max_completed
	wiper_move_towards_zero()
	await towards_zero_completed
	if loop_rotation:
		if delay > 0:
			# Change wiper mode to RESTART_DELAY
			wiper_move_state = WIPER_MOVE_STATE.RESTART_DELAY
			await get_tree().create_timer(delay).timeout
			
			# Restart only if mode is still SINGLE
			if delay > 0:
				wiper_rotation()
		else:
			# In CONTINUOUS or RAPID mode -> restart immediately
			wiper_rotation()


func start_single_state_anim() -> void:
	# Change wiper mode to SINGLE
	wiper_mode = WIPER_MODE.SINGLE
	# Set delay to restart delay value
	delay = restart_delay
	# Set from angle to zero
	from_angle = 0.0
	# Set animation length
	anim_length = max_rotate_angle / low_rotation_speed
	# Start wiper rotation
	wiper_rotation()


func wiper_single_state() -> void:
	# If wiper is off, start SINGLE mode behavior immediately
	if wiper_move_state == WIPER_MOVE_STATE.OFF:
		# Set loop rotation to true
		loop_rotation = true
		# Start animation
		start_single_state_anim()
	# If wiper is moving towards zero after RAPID -> OFF state,
	# wait for it to finish and then start SINGLE state behavior
	elif wiper_move_state == WIPER_MOVE_STATE.TOWARDS_ZERO:
		# Set loop rotation to false
		loop_rotation = false
		# Wait for wiper animation to zero
		await towards_zero_completed
		# Set loop rotation to true
		loop_rotation = true
		# Start animation
		start_single_state_anim()


func start_continuous_state_anim() -> void:
	# Change wiper mode to CONTINUOUS
		wiper_mode = WIPER_MODE.CONTINUOUS
		# Set delay to 0. This will stop SINGLE mode animation
		delay = 0.0
		# Set from angle to zero
		from_angle = 0.0
		# Set animation length
		anim_length = abs(max_rotate_angle) / low_rotation_speed
		# Start wiper rotation
		wiper_rotation()


func wiper_continuous_state() -> void:
	# If wiper is in the RESTART_DELAY move state, 
	# start CONTINUOUS state behaviour immediately
	if wiper_move_state == WIPER_MOVE_STATE.RESTART_DELAY:
		# Start animation
		start_continuous_state_anim()
	# If wiper is in the TOWARDS_ZERO move state,
	# wait for it to finish and then start CONTINUOUS mode behavior
	elif wiper_move_state == WIPER_MOVE_STATE.TOWARDS_ZERO:
		# Set loop rotation to false
		loop_rotation = false
		# Wait for wiper animation to zero
		await towards_zero_completed
		# Set loop rotation to true
		loop_rotation = true
		# Start animation
		start_continuous_state_anim()
	# If wiper is in the TOWARDS_MAX move state, 
	# wait for it to finish and then wait for TOWARDS_ZERO to finish,
	# and then start CONTINUOUS mode behavior
	elif wiper_move_state == WIPER_MOVE_STATE.TOWARDS_MAX:
		# Set loop rotation to false
		loop_rotation = false
		# Wait for wiper animation to max
		await towards_max_completed
		# Wait for wiper animation to zero
		await towards_zero_completed
		# Set loop rotation to true
		loop_rotation = true
		# Start animation
		start_continuous_state_anim()


func wiper_rapid_state() -> void:
	# If wiper is in the TOWARDS_ZERO move state,
	# stop it and then start RAPID mode behavior towards zero
	if wiper_move_state == WIPER_MOVE_STATE.TOWARDS_ZERO:
		# Set loop rotation to false
		loop_rotation = false
		# Stop wiper animation immediately
		stop_animation = true
		# Wait for one frame to stop the animation
		await get_tree().process_frame
		# Change wiper mode to RAPID
		wiper_mode = WIPER_MODE.RAPID
		# Set delay to 0
		delay = 0.0
		# Set from angle to current rotation value
		from_angle = rotation_degrees.y
		# Set animation length
		anim_length = from_angle / high_rotation_speed
		# Finish the TOWARDS_ZERO anim with high speed
		wiper_move_towards_zero_from_current()
		await towards_zero_from_current_completed
		# Set loop rotation to true
		loop_rotation = true
		# Reset from_angle back to zero
		from_angle = 0.0
		# Set animation length
		anim_length = max_rotate_angle / high_rotation_speed
		# Restart wiper animation
		wiper_rotation()
	# If wiper is in the TOWARDS_MAX move state, 
	# stop it and start RAPID mode behavior to max,
	# and then start RAPID mode behavior towards zero
	elif wiper_move_state == WIPER_MOVE_STATE.TOWARDS_MAX:
		# Set loop rotation to false
		loop_rotation = false
		# Stop wiper animation immediately
		stop_animation = true
		# Wait for one frame to stop the animation
		await get_tree().process_frame
		# Change wiper mode to RAPID
		wiper_mode = WIPER_MODE.RAPID
		# Set delay to 0
		delay = 0.0
		# Set from angle to current rotation value
		from_angle = rotation_degrees.y
		# Set animation length
		anim_length = (max_rotate_angle - from_angle) / high_rotation_speed
		# Finish the TOWARDS_MAX anim with high speed
		wiper_move_towards_max_from_current()
		await towards_max_from_current_completed
		# Reset from_angle back to zero
		from_angle = 0.0
		# Set animation length
		anim_length = max_rotate_angle / high_rotation_speed
		# Finish the TOWARDS_ZERO anim with high speed
		wiper_move_towards_zero()
		await towards_zero_completed
		# Set loop rotation to true
		loop_rotation = true
		# Restart wiper animation
		wiper_rotation()


func wiper_off_state() -> void:
	# If wiper is in the TOWARDS_ZERO move state,
	# stop it and then move the wiper TOWARDS_ZERO with low speed
	if wiper_move_state == WIPER_MOVE_STATE.TOWARDS_ZERO:
		# Set loop rotation to false
		loop_rotation = false
		# Stop wiper animation immediately
		stop_animation = true
		# Wait for one frame to stop the animation
		await get_tree().process_frame
		# Change wiper mode to OFF
		wiper_mode = WIPER_MODE.OFF
		# Set delay to 0
		delay = 0.0
		# Set from_angle to current rotation value
		from_angle = rotation_degrees.y
		# Set animation length
		anim_length = from_angle / low_rotation_speed
		# Finish the TOWARDS_ZERO anim with low speed
		wiper_move_towards_zero_from_current()
		await towards_zero_from_current_completed
		# Change wiper move state to OFF
		wiper_move_state = WIPER_MOVE_STATE.OFF
	# If wiper is in the TOWARDS_MAX move state,
	# stop it and move the wiper TOWARDS_MAX with low speed
	# and then move the wiper TOWARDS_ZERO with low speed
	if wiper_move_state == WIPER_MOVE_STATE.TOWARDS_MAX:
		# Set loop rotation to false
		loop_rotation = false
		# Stop wiper animation immediately
		stop_animation = true
		# Wait for one frame to stop the animation
		await get_tree().process_frame
		# Change wiper mode to OFF
		wiper_mode = WIPER_MODE.OFF
		# Change wiper move state to OFF
		wiper_move_state = WIPER_MOVE_STATE.OFF
		# Set delay to 0
		delay = 0.0
		# Set from_angle to current rotation value
		from_angle = rotation_degrees.y
		# Set animation length
		anim_length = (max_rotate_angle - from_angle) / low_rotation_speed
		# Finish the TOWARDS_MAX anim with low speed
		wiper_move_towards_max_from_current()
		await towards_max_from_current_completed
		# Reset from_angle back to zero
		from_angle = 0.0
		# Set animation length
		anim_length = max_rotate_angle / low_rotation_speed
		# Finish the TOWARDS_ZERO anim with low speed
		wiper_move_towards_zero()
		await towards_zero_completed
		# Change wiper move state to OFF
		wiper_move_state = WIPER_MOVE_STATE.OFF

func _input(event):
	if event.is_action_pressed("WiperToggle"):
		toggle()
