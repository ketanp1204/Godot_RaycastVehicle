extends Node3D

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

@export_category("References")
## Left windshield wiper mesh node
@export var wiper_l_node: NodePath
## Right windshield wiper mesh node
@export var wiper_r_node: NodePath
## Mouse handle node
@export var mouse_handle_node: NodePath

@export_category("Wiper L Rotation Parameters")
## Maximum angle (in degrees) that the wiper rotates from the starting position
@export var wiper_l_max_rotate_angle: float = 80.0
## Whether to use negative rotation value
@export var wiper_l_reverse_direction: bool = true
## Delay after which the wiper starts again in the SINGLE wiper mode
@export var wiper_l_restart_delay: float = 3.0
## Rotation speed of the wiper in the SINGLE and CONTINUOUS states 
@export var wiper_l_low_rotation_speed: float = 1.2
## Rotation speed of the wiper in the RAPID states
@export var wiper_l_high_rotation_speed: float = 2.2

@export_category("Wiper R Rotation Parameters")
## Maximum angle (in degrees) that the wiper rotates from the starting position
@export var wiper_r_max_rotate_angle: float = 60.0
## Whether to use negative rotation value
@export var wiper_r_reverse_direction: bool = true
## Delay after which the wiper starts again in the SINGLE wiper mode
@export var wiper_r_restart_delay: float = 3.0
## Rotation speed of the wiper in the SINGLE and CONTINUOUS states 
@export var wiper_r_low_rotation_speed: float = 1.2
## Rotation speed of the wiper in the RAPID states
@export var wiper_r_high_rotation_speed: float = 2.2

@export_category("Common Rotation Parameters")


# Reference variables
var wiper_l_mesh: MeshInstance3D
var wiper_r_mesh: MeshInstance3D
var mouse_handle: StaticBody3D

# Wiper state variables
var wiper_l_mode: WIPER_MODE = WIPER_MODE.OFF
var wiper_l_move_state: WIPER_MOVE_STATE = WIPER_MOVE_STATE.OFF
var wiper_r_mode: WIPER_MODE = WIPER_MODE.OFF
var wiper_r_move_state: WIPER_MOVE_STATE = WIPER_MOVE_STATE.OFF

# Animation variables
var wiper_l_delay: float = 0.0
var wiper_r_delay: float = 0.0
var wiper_l_loop_rotation: bool = false
var wiper_r_loop_rotation: bool = false
var wiper_l_init_rot_y: float = 0.0
var wiper_r_init_rot_y: float = 0.0
var wiper_l_max_rot_y: float = 0.0
var wiper_r_max_rot_y: float = 0.0
var wiper_l_stop_animation: bool = false
var wiper_r_stop_animation: bool = false

# Wiper move state signals
signal wiper_l_towards_zero_completed
signal wiper_l_towards_zero_from_current_completed 
signal wiper_l_towards_max_completed
signal wiper_l_towards_max_from_current_completed
signal wiper_r_towards_zero_completed
signal wiper_r_towards_zero_from_current_completed 
signal wiper_r_towards_max_completed
signal wiper_r_towards_max_from_current_completed



func _ready():
	# Get nodes from NodePath
	if wiper_l_node:
		wiper_l_mesh = get_node(wiper_l_node) as MeshInstance3D
	if wiper_r_node:
		wiper_r_mesh = get_node(wiper_r_node) as MeshInstance3D
	if mouse_handle_node:
		mouse_handle = get_node(mouse_handle_node) as StaticBody3D
	
	# Connect the mouse handle click signal
	mouse_handle.mouse_clicked.connect(toggle_wiper_l)
	mouse_handle.mouse_clicked.connect(toggle_wiper_r)
	
	# Get initial y rotation of wipers
	wiper_l_init_rot_y = rad_to_deg(wiper_l_mesh.rotation.y)
	wiper_r_init_rot_y = rad_to_deg(wiper_r_mesh.rotation.y)
	wiper_l_max_rot_y = wiper_l_init_rot_y + (
		-wiper_l_max_rotate_angle if wiper_l_reverse_direction
		else wiper_l_max_rotate_angle
	)
	wiper_r_max_rot_y = wiper_r_init_rot_y + (
		-wiper_r_max_rotate_angle if wiper_r_reverse_direction
		else wiper_r_max_rotate_angle
	)


func toggle_wiper_l() -> void:
	if wiper_l_mode == WIPER_MODE.OFF:
		wiper_l_single_state()
	elif wiper_l_mode == WIPER_MODE.SINGLE:
		wiper_l_continuous_state()
	elif wiper_l_mode == WIPER_MODE.CONTINUOUS:
		wiper_l_rapid_state()
	elif wiper_l_mode == WIPER_MODE.RAPID:
		wiper_l_off_state()


func toggle_wiper_r() -> void:
	if wiper_r_mode == WIPER_MODE.OFF:
		wiper_r_single_state()
	elif wiper_r_mode == WIPER_MODE.SINGLE:
		wiper_r_continuous_state()
	elif wiper_r_mode == WIPER_MODE.CONTINUOUS:
		wiper_r_rapid_state()
	elif wiper_r_mode == WIPER_MODE.RAPID:
		wiper_r_off_state()


func wiper_l_move_towards_max(speed: float) -> void:
	wiper_l_move_state = WIPER_MOVE_STATE.TOWARDS_MAX
	var delta: float = get_process_delta_time()
	if wiper_l_reverse_direction:
		while rad_to_deg(wiper_l_mesh.rotation.y) >= wiper_l_max_rot_y:
			if wiper_l_stop_animation:
				wiper_l_stop_animation = false
				return
			wiper_l_mesh.rotate_object_local(Vector3.UP, -deg_to_rad(wiper_l_max_rotate_angle) * delta * speed)
			await get_tree().process_frame
	else:
		while rad_to_deg(wiper_l_mesh.rotation.y) <= wiper_l_max_rot_y:
			if wiper_l_stop_animation:
				wiper_l_stop_animation = false
				return
			wiper_l_mesh.rotate_object_local(Vector3.UP, deg_to_rad(wiper_l_max_rotate_angle) * delta * speed)
			await get_tree().process_frame
	wiper_l_towards_max_completed.emit()


func wiper_r_move_towards_max(speed: float) -> void:
	wiper_r_move_state = WIPER_MOVE_STATE.TOWARDS_MAX
	var delta: float = get_process_delta_time()
	if wiper_r_reverse_direction:
		while rad_to_deg(wiper_r_mesh.rotation.y) >= wiper_r_max_rot_y:
			if wiper_r_stop_animation:
				wiper_r_stop_animation = false
				return
			wiper_r_mesh.rotate_object_local(Vector3.UP, -deg_to_rad(wiper_r_max_rotate_angle) * delta * speed)
			await get_tree().process_frame
	else:
		while rad_to_deg(wiper_r_mesh.rotation.y) <= wiper_r_max_rot_y:
			if wiper_r_stop_animation:
				wiper_r_stop_animation = false
				return
			wiper_r_mesh.rotate_object_local(Vector3.UP, deg_to_rad(wiper_r_max_rotate_angle) * delta * speed)
			await get_tree().process_frame
	wiper_r_towards_max_completed.emit()


func wiper_l_move_towards_max_from_current(speed: float) -> void:
	wiper_l_move_state = WIPER_MOVE_STATE.CURRENT_TOWARDS_MAX
	var delta: float = get_process_delta_time()
	var angle_delta = abs(rad_to_deg(wiper_l_mesh.rotation.y) - wiper_l_max_rot_y)
	if wiper_l_reverse_direction:
		while rad_to_deg(wiper_l_mesh.rotation.y) >= wiper_l_max_rot_y:
			if wiper_l_stop_animation:
				wiper_l_stop_animation = false
				return
			wiper_l_mesh.rotate_object_local(Vector3.UP, -deg_to_rad(angle_delta) * delta * speed)
			await get_tree().process_frame
	else:
		while rad_to_deg(wiper_l_mesh.rotation.y) <= wiper_l_max_rot_y:
			if wiper_l_stop_animation:
				wiper_l_stop_animation = false
				return
			wiper_l_mesh.rotate_object_local(Vector3.UP, deg_to_rad(angle_delta) * delta * speed)
			await get_tree().process_frame
	wiper_l_towards_max_from_current_completed.emit()


func wiper_r_move_towards_max_from_current(speed: float) -> void:
	wiper_r_move_state = WIPER_MOVE_STATE.CURRENT_TOWARDS_MAX
	var delta: float = get_process_delta_time()
	var angle_delta = abs(rad_to_deg(wiper_r_mesh.rotation.y) - wiper_r_max_rot_y)
	if wiper_r_reverse_direction:
		while rad_to_deg(wiper_r_mesh.rotation.y) >= wiper_r_max_rot_y:
			if wiper_r_stop_animation:
				wiper_r_stop_animation = false
				return
			wiper_r_mesh.rotate_object_local(Vector3.UP, -deg_to_rad(angle_delta) * delta * speed)
			await get_tree().process_frame
	else:
		while rad_to_deg(wiper_r_mesh.rotation.y) <= wiper_r_max_rot_y:
			if wiper_r_stop_animation:
				wiper_r_stop_animation = false
				return
			wiper_r_mesh.rotate_object_local(Vector3.UP, deg_to_rad(angle_delta) * delta * speed)
			await get_tree().process_frame
	wiper_r_towards_max_from_current_completed.emit()


func wiper_l_move_towards_zero(speed: float) -> void:
	wiper_l_move_state = WIPER_MOVE_STATE.TOWARDS_ZERO
	var delta: float = get_process_delta_time()
	if wiper_l_reverse_direction:
		while wiper_l_init_rot_y >= rad_to_deg(wiper_l_mesh.rotation.y):
			if wiper_l_stop_animation:
				wiper_l_stop_animation = false
				return
			wiper_l_mesh.rotate_object_local(Vector3.UP, deg_to_rad(wiper_l_max_rotate_angle) * delta * speed)
			await get_tree().process_frame
	else:
		while wiper_l_init_rot_y <= rad_to_deg(wiper_l_mesh.rotation.y):
			if wiper_l_stop_animation:
				wiper_l_stop_animation = false
				return
			wiper_l_mesh.rotate_object_local(Vector3.UP, -deg_to_rad(wiper_l_max_rotate_angle) * delta * speed)
			await get_tree().process_frame
	wiper_l_towards_zero_completed.emit()


func wiper_r_move_towards_zero(speed: float) -> void:
	wiper_r_move_state = WIPER_MOVE_STATE.TOWARDS_ZERO
	var delta: float = get_process_delta_time()
	if wiper_r_reverse_direction:
		while wiper_r_init_rot_y >= rad_to_deg(wiper_r_mesh.rotation.y):
			if wiper_r_stop_animation:
				wiper_r_stop_animation = false
				return
			wiper_r_mesh.rotate_object_local(Vector3.UP, deg_to_rad(wiper_r_max_rotate_angle) * delta * speed)
			await get_tree().process_frame
	else:
		while wiper_r_init_rot_y <= rad_to_deg(wiper_r_mesh.rotation.y):
			if wiper_r_stop_animation:
				wiper_r_stop_animation = false
				return
			wiper_r_mesh.rotate_object_local(Vector3.UP, -deg_to_rad(wiper_r_max_rotate_angle) * delta * speed)
			await get_tree().process_frame
	wiper_r_towards_zero_completed.emit()


func wiper_l_move_towards_zero_from_current(speed: float) -> void:
	wiper_l_move_state = WIPER_MOVE_STATE.CURRENT_TOWARDS_ZERO
	var delta: float = get_process_delta_time()
	var angle_delta = abs(wiper_l_init_rot_y - rad_to_deg(wiper_l_mesh.rotation.y))
	if wiper_l_reverse_direction:
		while wiper_l_init_rot_y >= rad_to_deg(wiper_l_mesh.rotation.y):
			if wiper_l_stop_animation:
				wiper_l_stop_animation = false
				return
			wiper_l_mesh.rotate_object_local(Vector3.UP, deg_to_rad(angle_delta) * delta * speed)
			await get_tree().process_frame
	else:
		while wiper_l_init_rot_y <= rad_to_deg(wiper_l_mesh.rotation.y):
			if wiper_l_stop_animation:
				wiper_l_stop_animation = false
				return
			wiper_l_mesh.rotate_object_local(Vector3.UP, -deg_to_rad(angle_delta) * delta * speed)
			await get_tree().process_frame
	wiper_l_towards_zero_from_current_completed.emit()


func wiper_r_move_towards_zero_from_current(speed: float) -> void:
	wiper_r_move_state = WIPER_MOVE_STATE.CURRENT_TOWARDS_ZERO
	var delta: float = get_process_delta_time()
	var angle_delta = abs(wiper_r_init_rot_y - rad_to_deg(wiper_r_mesh.rotation.y))
	if wiper_r_reverse_direction:
		while wiper_r_init_rot_y >= rad_to_deg(wiper_r_mesh.rotation.y):
			if wiper_r_stop_animation:
				wiper_r_stop_animation = false
				return
			wiper_r_mesh.rotate_object_local(Vector3.UP, deg_to_rad(angle_delta) * delta * speed)
			await get_tree().process_frame
	else:
		while wiper_r_init_rot_y <= rad_to_deg(wiper_r_mesh.rotation.y):
			if wiper_r_stop_animation:
				wiper_r_stop_animation = false
				return
			wiper_r_mesh.rotate_object_local(Vector3.UP, -deg_to_rad(angle_delta) * delta * speed)
			await get_tree().process_frame
	wiper_r_towards_zero_from_current_completed.emit()


func wiper_l_rotation(speed: float) -> void:
	var initial_wiper_mode = wiper_l_mode
	wiper_l_move_towards_max(speed)
	await wiper_l_towards_max_completed
	if wiper_l_mode == initial_wiper_mode:
		wiper_l_move_towards_zero(speed)
		await wiper_l_towards_zero_completed
		if wiper_l_mode == initial_wiper_mode:
			if wiper_l_loop_rotation:
				if wiper_l_mode == WIPER_MODE.SINGLE:
					# Change wiper mode to RESTART_DELAY
					wiper_l_move_state = WIPER_MOVE_STATE.RESTART_DELAY
					await get_tree().create_timer(wiper_l_delay).timeout
					
					# Restart only if mode is still SINGLE
					if wiper_l_delay > 0:
						wiper_l_rotation(speed)
				elif wiper_l_mode == WIPER_MODE.CONTINUOUS:
					wiper_l_rotation(speed)
				elif wiper_l_mode == WIPER_MODE.RAPID:
					wiper_l_rotation(speed)


func wiper_r_rotation(speed: float) -> void:
	var initial_wiper_mode = wiper_r_mode
	wiper_r_move_towards_max(speed)
	await wiper_r_towards_max_completed
	if wiper_r_mode == initial_wiper_mode:
		wiper_r_move_towards_zero(speed)
		await wiper_r_towards_zero_completed
		if wiper_r_mode == initial_wiper_mode:
			if wiper_r_loop_rotation:
				if wiper_r_mode == WIPER_MODE.SINGLE:
					# Change wiper mode to RESTART_DELAY
					wiper_r_move_state = WIPER_MOVE_STATE.RESTART_DELAY
					await get_tree().create_timer(wiper_r_delay).timeout
					
					# Restart only if mode is still SINGLE
					if wiper_r_delay > 0:
						wiper_r_rotation(speed)
				elif wiper_r_mode == WIPER_MODE.CONTINUOUS:
					wiper_r_rotation(speed)
				elif wiper_r_mode == WIPER_MODE.RAPID:
					wiper_r_rotation(speed)


func wiper_l_start_single_state_anim() -> void:
	# Change wiper mode to SINGLE
	wiper_l_mode = WIPER_MODE.SINGLE
	# Set delay to restart delay value
	wiper_l_delay = wiper_l_restart_delay
	# Start wiper rotation
	wiper_l_rotation(wiper_l_low_rotation_speed)


func wiper_l_single_state() -> void:
	# If wiper is off, start SINGLE mode behavior immediately
	if wiper_l_move_state == WIPER_MOVE_STATE.OFF:
		# Set loop rotation to true
		wiper_l_loop_rotation = true
		# Start animation
		wiper_l_start_single_state_anim()
	# If wiper is moving towards zero after RAPID -> OFF state,
	# wait for it to finish and then start SINGLE state behavior
	elif wiper_l_move_state == WIPER_MOVE_STATE.TOWARDS_ZERO:
		# Set loop rotation to false
		wiper_l_loop_rotation = false
		# Wait for wiper animation to zero
		await wiper_l_towards_zero_completed
		# Check if wiper mode has not been changed
		if wiper_l_mode == WIPER_MODE.SINGLE:
			# Set loop rotation to true
			wiper_l_loop_rotation = true
			# Start animation
			wiper_l_start_single_state_anim()


func wiper_r_start_single_state_anim() -> void:
	# Change wiper mode to SINGLE
	wiper_r_mode = WIPER_MODE.SINGLE
	# Set delay to restart delay value
	wiper_r_delay = wiper_r_restart_delay
	# Start wiper rotation
	wiper_r_rotation(wiper_r_low_rotation_speed)


func wiper_r_single_state() -> void:
	# If wiper is off, start SINGLE mode behavior immediately
	if wiper_r_move_state == WIPER_MOVE_STATE.OFF:
		# Set loop rotation to true
		wiper_r_loop_rotation = true
		# Start animation
		wiper_r_start_single_state_anim()
	# If wiper is moving towards zero after RAPID -> OFF state,
	# wait for it to finish and then start SINGLE state behavior
	elif wiper_r_move_state == WIPER_MOVE_STATE.TOWARDS_ZERO:
		# Set loop rotation to false
		wiper_r_loop_rotation = false
		# Wait for wiper animation to zero
		await wiper_r_towards_zero_completed
		# Check if wiper mode has not been changed
		if wiper_r_mode == WIPER_MODE.SINGLE:
			# Set loop rotation to true
			wiper_r_loop_rotation = true
			# Start animation
			wiper_r_start_single_state_anim()


func wiper_l_start_continuous_state_anim() -> void:
	# Change wiper mode to CONTINUOUS
	wiper_l_mode = WIPER_MODE.CONTINUOUS
	# Set delay to 0. This will stop SINGLE mode animation
	wiper_l_delay = 0.0
	# Start wiper rotation
	wiper_l_rotation(wiper_l_low_rotation_speed)


func wiper_l_continuous_state() -> void:
	# If wiper is in the RESTART_DELAY move state, 
	# start CONTINUOUS state behaviour immediately
	if wiper_l_move_state == WIPER_MOVE_STATE.RESTART_DELAY:
		# Start animation
		wiper_l_start_continuous_state_anim()
	# If wiper is in the TOWARDS_ZERO move state,
	# wait for it to finish and then start CONTINUOUS mode behavior
	elif wiper_l_move_state == WIPER_MOVE_STATE.TOWARDS_ZERO:
		# Set loop rotation to false
		wiper_l_loop_rotation = false
		# Wait for wiper animation to zero
		await wiper_l_towards_zero_completed
		# Check if wiper mode has not been changed
		if wiper_l_mode == WIPER_MODE.SINGLE:
			# Set loop rotation to true
			wiper_l_loop_rotation = true
			# Start animation
			wiper_l_start_continuous_state_anim()
	# If wiper is in the TOWARDS_MAX move state, 
	# wait for it to finish and then wait for TOWARDS_ZERO to finish,
	# and then start CONTINUOUS mode behavior
	elif wiper_l_move_state == WIPER_MOVE_STATE.TOWARDS_MAX:
		# Set loop rotation to false
		wiper_l_loop_rotation = false
		# Wait for wiper animation to max
		await wiper_l_towards_max_completed
		# Wait for wiper animation to zero
		await wiper_l_towards_zero_completed
		# Check if wiper mode has not been changed
		if wiper_l_mode == WIPER_MODE.SINGLE:
			# Set loop rotation to true
			wiper_l_loop_rotation = true
			# Start animation
			wiper_l_start_continuous_state_anim()


func wiper_r_start_continuous_state_anim() -> void:
	# Change wiper mode to CONTINUOUS
	wiper_r_mode = WIPER_MODE.CONTINUOUS
	# Set delay to 0. This will stop SINGLE mode animation
	wiper_r_delay = 0.0
	# Start wiper rotation
	wiper_r_rotation(wiper_r_low_rotation_speed)


func wiper_r_continuous_state() -> void:
	# If wiper is in the RESTART_DELAY move state, 
	# start CONTINUOUS state behaviour immediately
	if wiper_r_move_state == WIPER_MOVE_STATE.RESTART_DELAY:
		# Start animation
		wiper_r_start_continuous_state_anim()
	# If wiper is in the TOWARDS_ZERO move state,
	# wait for it to finish and then start CONTINUOUS mode behavior
	elif wiper_r_move_state == WIPER_MOVE_STATE.TOWARDS_ZERO:
		# Set loop rotation to false
		wiper_r_loop_rotation = false
		# Wait for wiper animation to zero
		await wiper_r_towards_zero_completed
		# Check if wiper mode has not been changed
		if wiper_r_mode == WIPER_MODE.SINGLE:
			# Set loop rotation to true
			wiper_r_loop_rotation = true
			# Start animation
			wiper_r_start_continuous_state_anim()
	# If wiper is in the TOWARDS_MAX move state, 
	# wait for it to finish and then wait for TOWARDS_ZERO to finish,
	# and then start CONTINUOUS mode behavior
	elif wiper_r_move_state == WIPER_MOVE_STATE.TOWARDS_MAX:
		# Set loop rotation to false
		wiper_r_loop_rotation = false
		# Wait for wiper animation to max
		await wiper_r_towards_max_completed
		# Wait for wiper animation to zero
		await wiper_r_towards_zero_completed
		# Check if wiper mode has not been changed
		if wiper_r_mode == WIPER_MODE.SINGLE:
			# Set loop rotation to true
			wiper_r_loop_rotation = true
			# Start animation
			wiper_r_start_continuous_state_anim()


func wiper_l_rapid_state() -> void:
	# If wiper is in the TOWARDS_ZERO move state,
	# stop it and then start RAPID mode behavior towards zero
	if wiper_l_move_state == WIPER_MOVE_STATE.TOWARDS_ZERO:
		# Set loop rotation to false
		wiper_l_loop_rotation = false
		# Stop wiper animation immediately
		wiper_l_stop_animation = true
		# Wait for one frame to stop the animation
		await get_tree().process_frame
		# Change wiper mode to RAPID
		wiper_l_mode = WIPER_MODE.RAPID
		# Set delay to 0
		wiper_l_delay = 0.0
		# Finish the TOWARDS_ZERO anim with high speed
		wiper_l_move_towards_zero_from_current(wiper_l_high_rotation_speed)
		await wiper_l_towards_zero_from_current_completed
		# Check if wiper mode has not been changed
		if wiper_l_mode == WIPER_MODE.RAPID:
			# Set loop rotation to true
			wiper_l_loop_rotation = true
			# Restart wiper animation
			wiper_l_rotation(wiper_l_high_rotation_speed)
	# If wiper is in the TOWARDS_MAX move state, 
	# stop it and start RAPID mode behavior to max,
	# and then start RAPID mode behavior towards zero
	elif wiper_l_move_state == WIPER_MOVE_STATE.TOWARDS_MAX:
		# Set loop rotation to false
		wiper_l_loop_rotation = false
		# Stop wiper animation immediately
		wiper_l_stop_animation = true
		# Wait for one frame to stop the animation
		await get_tree().process_frame
		# Change wiper mode to RAPID
		wiper_l_mode = WIPER_MODE.RAPID
		# Set delay to 0
		wiper_l_delay = 0.0
		# Finish the TOWARDS_MAX anim with high speed
		wiper_l_move_towards_max_from_current(wiper_l_high_rotation_speed)
		await wiper_l_towards_max_from_current_completed
		# Check if wiper mode has not been changed
		if wiper_l_mode == WIPER_MODE.RAPID:
			# Finish the TOWARDS_ZERO anim with high speed
			wiper_l_move_towards_zero(wiper_l_high_rotation_speed)
			await wiper_l_towards_zero_completed
			# Check if wiper mode has not been changed
			if wiper_l_mode == WIPER_MODE.RAPID:
				# Set loop rotation to true
				wiper_l_loop_rotation = true
				# Restart wiper animation
				wiper_l_rotation(wiper_l_high_rotation_speed)


func wiper_r_rapid_state() -> void:
	# If wiper is in the TOWARDS_ZERO move state,
	# stop it and then start RAPID mode behavior towards zero
	if wiper_r_move_state == WIPER_MOVE_STATE.TOWARDS_ZERO:
		# Set loop rotation to false
		wiper_r_loop_rotation = false
		# Stop wiper animation immediately
		wiper_r_stop_animation = true
		# Wait for one frame to stop the animation
		await get_tree().process_frame
		# Change wiper mode to RAPID
		wiper_r_mode = WIPER_MODE.RAPID
		# Set delay to 0
		wiper_r_delay = 0.0
		# Finish the TOWARDS_ZERO anim with high speed
		wiper_r_move_towards_zero_from_current(wiper_r_high_rotation_speed)
		await wiper_r_towards_zero_from_current_completed
		# Check if wiper mode has not been changed
		if wiper_r_mode == WIPER_MODE.RAPID:
			# Set loop rotation to true
			wiper_r_loop_rotation = true
			# Restart wiper animation
			wiper_r_rotation(wiper_r_high_rotation_speed)
	# If wiper is in the TOWARDS_MAX move state, 
	# stop it and start RAPID mode behavior to max,
	# and then start RAPID mode behavior towards zero
	elif wiper_r_move_state == WIPER_MOVE_STATE.TOWARDS_MAX:
		# Set loop rotation to false
		wiper_r_loop_rotation = false
		# Stop wiper animation immediately
		wiper_r_stop_animation = true
		# Wait for one frame to stop the animation
		await get_tree().process_frame
		# Change wiper mode to RAPID
		wiper_r_mode = WIPER_MODE.RAPID
		# Set delay to 0
		wiper_r_delay = 0.0
		# Finish the TOWARDS_MAX anim with high speed
		wiper_r_move_towards_max_from_current(wiper_r_high_rotation_speed)
		await wiper_r_towards_max_from_current_completed
		# Check if wiper mode has not been changed
		if wiper_r_mode == WIPER_MODE.RAPID:
			# Finish the TOWARDS_ZERO anim with high speed
			wiper_r_move_towards_zero(wiper_r_high_rotation_speed)
			await wiper_r_towards_zero_completed
			# Check if wiper mode has not been changed
			if wiper_r_mode == WIPER_MODE.RAPID:
				# Set loop rotation to true
				wiper_r_loop_rotation = true
				# Restart wiper animation
				wiper_r_rotation(wiper_r_high_rotation_speed)


func wiper_l_off_state() -> void:
	# If wiper is in the TOWARDS_ZERO move state,
	# stop it and then move the wiper TOWARDS_ZERO with low speed
	if wiper_l_move_state == WIPER_MOVE_STATE.TOWARDS_ZERO:
		# Set loop rotation to false
		wiper_l_loop_rotation = false
		# Stop wiper animation immediately
		wiper_l_stop_animation = true
		# Wait for one frame to stop the animation
		await get_tree().process_frame
		# Change wiper mode to OFF
		wiper_l_mode = WIPER_MODE.OFF
		# Set delay to 0
		wiper_l_delay = 0.0
		# Finish the TOWARDS_ZERO anim with low speed
		wiper_l_move_towards_zero_from_current(wiper_l_low_rotation_speed)
		await wiper_l_towards_zero_from_current_completed
		# Check if wiper mode has not been changed
		if wiper_l_mode == WIPER_MODE.OFF:
			# Change wiper move state to OFF
			wiper_l_move_state = WIPER_MOVE_STATE.OFF
	# If wiper is in the TOWARDS_MAX move state,
	# stop it and move the wiper TOWARDS_MAX with low speed
	# and then move the wiper TOWARDS_ZERO with low speed
	if wiper_l_move_state == WIPER_MOVE_STATE.TOWARDS_MAX:
		# Set loop rotation to false
		wiper_l_loop_rotation = false
		# Stop wiper animation immediately
		wiper_l_stop_animation = true
		# Wait for one frame to stop the animation
		await get_tree().process_frame
		# Change wiper mode to OFF
		wiper_l_mode = WIPER_MODE.OFF
		# Change wiper move state to OFF
		wiper_l_move_state = WIPER_MOVE_STATE.OFF
		# Set delay to 0
		wiper_l_delay = 0.0
		# Finish the TOWARDS_MAX anim with low speed
		wiper_l_move_towards_max_from_current(wiper_l_low_rotation_speed)
		await wiper_l_towards_max_from_current_completed
		# Check if wiper mode has not been changed
		if wiper_l_mode == WIPER_MODE.OFF:
			# Finish the TOWARDS_ZERO anim with low speed
			wiper_l_move_towards_zero(wiper_l_low_rotation_speed)
			await wiper_l_towards_zero_completed
			# Check if wiper mode has not been changed
			if wiper_l_mode == WIPER_MODE.OFF:
				# Change wiper move state to OFF
				wiper_l_move_state = WIPER_MOVE_STATE.OFF


func wiper_r_off_state() -> void:
	# If wiper is in the TOWARDS_ZERO move state,
	# stop it and then move the wiper TOWARDS_ZERO with low speed
	if wiper_r_move_state == WIPER_MOVE_STATE.TOWARDS_ZERO:
		# Set loop rotation to false
		wiper_r_loop_rotation = false
		# Stop wiper animation immediately
		wiper_r_stop_animation = true
		# Wait for one frame to stop the animation
		await get_tree().process_frame
		# Change wiper mode to OFF
		wiper_r_mode = WIPER_MODE.OFF
		# Set delay to 0
		wiper_r_delay = 0.0
		# Finish the TOWARDS_ZERO anim with low speed
		wiper_r_move_towards_zero_from_current(wiper_r_low_rotation_speed)
		await wiper_r_towards_zero_from_current_completed
		# Check if wiper mode has not been changed
		if wiper_r_mode == WIPER_MODE.OFF:
			# Change wiper move state to OFF
			wiper_r_move_state = WIPER_MOVE_STATE.OFF
	# If wiper is in the TOWARDS_MAX move state,
	# stop it and move the wiper TOWARDS_MAX with low speed
	# and then move the wiper TOWARDS_ZERO with low speed
	if wiper_r_move_state == WIPER_MOVE_STATE.TOWARDS_MAX:
		# Set loop rotation to false
		wiper_r_loop_rotation = false
		# Stop wiper animation immediately
		wiper_r_stop_animation = true
		# Wait for one frame to stop the animation
		await get_tree().process_frame
		# Change wiper mode to OFF
		wiper_r_mode = WIPER_MODE.OFF
		# Change wiper move state to OFF
		wiper_r_move_state = WIPER_MOVE_STATE.OFF
		# Set delay to 0
		wiper_r_delay = 0.0
		# Finish the TOWARDS_MAX anim with low speed
		wiper_r_move_towards_max_from_current(wiper_r_low_rotation_speed)
		await wiper_r_towards_max_from_current_completed
		# Check if wiper mode has not been changed
		if wiper_r_mode == WIPER_MODE.OFF:
			# Finish the TOWARDS_ZERO anim with low speed
			wiper_r_move_towards_zero(wiper_r_low_rotation_speed)
			await wiper_r_towards_zero_completed
			# Check if wiper mode has not been changed
			if wiper_r_mode == WIPER_MODE.OFF:
				# Change wiper move state to OFF
				wiper_r_move_state = WIPER_MOVE_STATE.OFF


func _input(event):
	if event.is_action_pressed("WiperToggle"):
		toggle_wiper_l()
		toggle_wiper_r()
