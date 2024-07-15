extends MeshInstance3D

enum WIPER_MODE { 
	OFF, 
	SINGLE, 
	CONTINUOUS, 
	RAPID}
enum WIPER_MOVE_STATE { 
	OFF, 
	RESTART_DELAY, 
	TOWARDS_MAX, 
	TOWARDS_ZERO, 
	CURRENT_TOWARDS_MAX, 
	CURRENT_TOWARDS_ZERO }

## Maximum angle (in degrees) that the wiper rotates from the starting position
@export var max_rotate_angle: float = 80.0
## Whether to use negative rotation value
@export var reverse_direction: bool = true
## Delay after which the wiper starts again in the SINGLE wiper mode
@export var restart_delay: float = 3.0
## Rotation speed of the wiper in the SINGLE and CONTINUOUS states 
@export var low_rotation_speed: float = 1.2
## Rotation speed of the wiper in the RAPID states
@export var high_rotation_speed: float = 2.2

# Wiper state variables
var wiper_mode: WIPER_MODE = WIPER_MODE.OFF
var wiper_move_state: WIPER_MOVE_STATE = WIPER_MOVE_STATE.OFF

# Animation variables
var delay: float = 0.0
var loop_rotation: bool = false
var deg_init_y: float = 0.0
var deg_max_y: float = 0.0
var stop_animation: bool = false

# Wiper move state signals
signal towards_zero_completed
signal towards_zero_from_current_completed 
signal towards_max_completed
signal towards_max_from_current_completed


# Called when the node enters the scene tree for the first time.
func _ready():
	
	deg_init_y = rad_to_deg(rotation.y)
	deg_max_y = deg_init_y + (
		-max_rotate_angle if reverse_direction
		else max_rotate_angle)


func move_towards_max(speed: float) -> void:
	wiper_move_state = WIPER_MOVE_STATE.TOWARDS_MAX
	var delta: float = get_process_delta_time()
	if reverse_direction:
		while rad_to_deg(rotation.y) >= deg_max_y:
			if stop_animation:
				stop_animation = false
				return
			rotate_object_local(Vector3.UP, -deg_to_rad(max_rotate_angle) * delta * speed)
			await get_tree().process_frame
	else:
		while rad_to_deg(rotation.y) <= deg_max_y:
			if stop_animation:
				stop_animation = false
				return
			rotate_object_local(Vector3.UP, deg_to_rad(max_rotate_angle) * delta * speed)
			await get_tree().process_frame
	towards_max_completed.emit()


func move_towards_max_from_current(speed: float) -> void:
	wiper_move_state = WIPER_MOVE_STATE.CURRENT_TOWARDS_MAX
	var delta: float = get_process_delta_time()
	var angle_delta = abs(rad_to_deg(rotation.y) - deg_max_y)
	if reverse_direction:
		while rad_to_deg(rotation.y) >= deg_max_y:
			if stop_animation:
				stop_animation = false
				return
			rotate_object_local(Vector3.UP, -deg_to_rad(angle_delta) * delta * speed)
			await get_tree().process_frame
	else:
		while rad_to_deg(rotation.y) <= deg_max_y:
			if stop_animation:
				stop_animation = false
				return
			rotate_object_local(Vector3.UP, deg_to_rad(angle_delta) * delta * speed)
			await get_tree().process_frame
	towards_max_from_current_completed.emit()


func move_towards_zero(speed: float) -> void:
	wiper_move_state = WIPER_MOVE_STATE.TOWARDS_ZERO
	var delta: float = get_process_delta_time()
	if reverse_direction:
		while deg_init_y >= rad_to_deg(rotation.y):
			if stop_animation:
				stop_animation = false
				return
			rotate_object_local(Vector3.UP, deg_to_rad(max_rotate_angle) * delta * speed)
			await get_tree().process_frame
	else:
		while deg_init_y <= rad_to_deg(rotation.y):
			if stop_animation:
				stop_animation = false
				return
			rotate_object_local(Vector3.UP, -deg_to_rad(max_rotate_angle) * delta * speed)
			await get_tree().process_frame
	towards_zero_completed.emit()


func move_towards_zero_from_current(speed: float) -> void:
	wiper_move_state = WIPER_MOVE_STATE.CURRENT_TOWARDS_ZERO
	var delta: float = get_process_delta_time()
	var angle_delta = abs(deg_init_y - rad_to_deg(rotation.y))
	if reverse_direction:
		while deg_init_y >= rad_to_deg(rotation.y):
			if stop_animation:
				stop_animation = false
				return
			rotate_object_local(Vector3.UP, deg_to_rad(angle_delta) * delta * speed)
			await get_tree().process_frame
	else:
		while deg_init_y <= rad_to_deg(rotation.y):
			if stop_animation:
				stop_animation = false
				return
			rotate_object_local(Vector3.UP, -deg_to_rad(angle_delta) * delta * speed)
			await get_tree().process_frame
	towards_zero_from_current_completed.emit()


func wiper_rotation(speed: float):
	var initial_wiper_mode = wiper_mode
	move_towards_max(speed)
	await towards_max_completed
	if wiper_mode == initial_wiper_mode:
		move_towards_zero(speed)
		await towards_zero_completed
		if wiper_mode == initial_wiper_mode:
			if loop_rotation:
				if wiper_mode == WIPER_MODE.SINGLE:
					# Change wiper mode to RESTART_DELAY
					wiper_move_state = WIPER_MOVE_STATE.RESTART_DELAY
					await get_tree().create_timer(delay).timeout
					
					# Restart only if mode is still SINGLE
					if delay > 0:
						wiper_rotation(speed)
				elif wiper_mode == WIPER_MODE.CONTINUOUS:
					wiper_rotation(speed)
				elif wiper_mode == WIPER_MODE.RAPID:
					wiper_rotation(speed)


func start_single_state_anim():
	# Change wiper mode to SINGLE
	wiper_mode = WIPER_MODE.SINGLE
	# Set delay to restart delay value
	delay = restart_delay
	# Start wiper rotation
	wiper_rotation(low_rotation_speed)


func single_state():
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
		# Check if wiper mode has not been changed
		if wiper_mode == WIPER_MODE.SINGLE:
			# Set loop rotation to true
			loop_rotation = true
			# Start animation
			start_single_state_anim()


func start_continuous_state_anim():
	# Change wiper mode to CONTINUOUS
	wiper_mode = WIPER_MODE.CONTINUOUS
	# Set delay to 0. This will stop SINGLE mode animation
	delay = 0.0
	# Start wiper rotation
	wiper_rotation(low_rotation_speed)


func continuous_state():
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
		# Check if wiper mode has not been changed
		if wiper_mode == WIPER_MODE.SINGLE:
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
		# Check if wiper mode has not been changed
		if wiper_mode == WIPER_MODE.SINGLE:
			# Set loop rotation to true
			loop_rotation = true
			# Start animation
			start_continuous_state_anim()


func rapid_state():
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
		# Finish the TOWARDS_ZERO anim with high speed
		move_towards_zero_from_current(high_rotation_speed)
		await towards_zero_from_current_completed
		# Check if wiper mode has not been changed
		if wiper_mode == WIPER_MODE.RAPID:
			# Set loop rotation to true
			loop_rotation = true
			# Restart wiper animation
			wiper_rotation(high_rotation_speed)
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
		# Finish the TOWARDS_MAX anim with high speed
		move_towards_max_from_current(high_rotation_speed)
		await towards_max_from_current_completed
		# Check if wiper mode has not been changed
		if wiper_mode == WIPER_MODE.RAPID:
			# Finish the TOWARDS_ZERO anim with high speed
			move_towards_zero(high_rotation_speed)
			await towards_zero_completed
			# Check if wiper mode has not been changed
			if wiper_mode == WIPER_MODE.RAPID:
				# Set loop rotation to true
				loop_rotation = true
				# Restart wiper animation
				wiper_rotation(high_rotation_speed)


func off_state():
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
		# Finish the TOWARDS_ZERO anim with low speed
		move_towards_zero_from_current(low_rotation_speed)
		await towards_zero_from_current_completed
		# Check if wiper mode has not been changed
		if wiper_mode == WIPER_MODE.OFF:
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
		# Finish the TOWARDS_MAX anim with low speed
		move_towards_max_from_current(low_rotation_speed)
		await towards_max_from_current_completed
		# Check if wiper mode has not been changed
		if wiper_mode == WIPER_MODE.OFF:
			# Finish the TOWARDS_ZERO anim with low speed
			move_towards_zero(low_rotation_speed)
			await towards_zero_completed
			# Check if wiper mode has not been changed
			if wiper_mode == WIPER_MODE.OFF:
				# Change wiper move state to OFF
				wiper_move_state = WIPER_MOVE_STATE.OFF


func toggle() -> void:
	if wiper_mode == WIPER_MODE.OFF:
		single_state()
	elif wiper_mode == WIPER_MODE.SINGLE:
		continuous_state()
	elif wiper_mode == WIPER_MODE.CONTINUOUS:
		rapid_state()
	elif wiper_mode == WIPER_MODE.RAPID:
		off_state()


func _input(event):
	if event.is_action_pressed("WiperToggle"):
		toggle()
