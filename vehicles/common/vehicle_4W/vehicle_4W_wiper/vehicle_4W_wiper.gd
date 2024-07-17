extends Node3D


const SINGLE_ANIM_STRING = "wiper_single_mode"
const CONTINUOUS_ANIM_STRING = "wiper_continuous_mode"
const RAPID_ANIM_STRING = "wiper_rapid_mode"
const RAPID_TO_OFF_ANIM_STRING = "wiper_rapid_to_off_mode"

########## REFERENCES ##########
@export_category("References")
@export var anim_player_node: NodePath

var anim_player: AnimationPlayer

########## WIPER STATE ##########
var wiper_mode: GlobalEnums.WIPER_MODES = GlobalEnums.WIPER_MODES.OFF
var wiper_move_state: GlobalEnums.WIPER_MOVE_STATES = GlobalEnums.WIPER_MOVE_STATES.OFF

signal entered_restart_delay
signal rapid_to_off_finished


func _ready():
	# Get nodes from NodePath
	if anim_player_node:
		anim_player = get_node(anim_player_node) as AnimationPlayer
	
	


func wiper_single_state():
	# If wiper is off and not moving, start SINGLE mode animation immediately
	if wiper_mode == GlobalEnums.WIPER_MODES.OFF and wiper_move_state == GlobalEnums.WIPER_MOVE_STATES.OFF:
		# Set SINGLE mode animatio to loop
		anim_player.get_animation(SINGLE_ANIM_STRING).loop_mode = Animation.LOOP_LINEAR
		# Play animation
		anim_player.play(SINGLE_ANIM_STRING)
	# If wiper is in the RAPID_TO_OFF state,
	# play SINGLE mode animation
	elif wiper_mode == GlobalEnums.WIPER_MODES.RAPID_TO_OFF \
	and (wiper_move_state == GlobalEnums.WIPER_MOVE_STATES.TOWARDS_ZERO \
		or wiper_move_state == GlobalEnums.WIPER_MOVE_STATES.TOWARDS_MAX):
		# Wait for RAPID_TO_OFF to finish
		await rapid_to_off_finished
		# Check if wiper mode has not been changed
		if wiper_mode == GlobalEnums.WIPER_MODES.OFF:
			# Set SINGLE mode animation to loop
			anim_player.get_animation(SINGLE_ANIM_STRING).loop_mode = Animation.LOOP_LINEAR
			# Queue SINGLE mode animation
			anim_player.play(SINGLE_ANIM_STRING)


func wiper_continuous_state():
	# If wiper is in the RESTART_DELAY move state, 
	# start CONTINUOUS mode animation immediately
	if wiper_mode == GlobalEnums.WIPER_MODES.SINGLE \
	and wiper_move_state == GlobalEnums.WIPER_MOVE_STATES.RESTART_DELAY:
		# Stop SINGLE mode animation
		anim_player.stop()
		# Set animation to loop
		anim_player.get_animation(CONTINUOUS_ANIM_STRING).loop_mode = Animation.LOOP_LINEAR
		# Play CONTINUOUS mode animation
		anim_player.play(CONTINUOUS_ANIM_STRING)
	# If wiper is in the TOWARDS_ZERO or TOWARDS_MAX move states,
	# wait for it to finish and then start CONTINUOUS mode animation
	elif wiper_mode == GlobalEnums.WIPER_MODES.SINGLE \
	and (wiper_move_state == GlobalEnums.WIPER_MOVE_STATES.TOWARDS_ZERO \
		or wiper_move_state == GlobalEnums.WIPER_MOVE_STATES.TOWARDS_MAX):
		# Stop SINGLE mode animation loop
		anim_player.get_animation(SINGLE_ANIM_STRING).loop_mode = Animation.LOOP_NONE
		# Emit wiper single to continuous signal for
		# changing the position of the wiper switch
		SignalManager.wiper_single_to_continuous.emit()
		# Wait for wiper to enter RESTART_DELAY move state
		await entered_restart_delay
		# Stop SINGLE mode animation
		anim_player.stop()
		# Set CONTINUOUS mode animation to loop
		anim_player.get_animation(CONTINUOUS_ANIM_STRING).loop_mode = Animation.LOOP_LINEAR
		# Play CONTINUOUS mode animation
		anim_player.queue(CONTINUOUS_ANIM_STRING)


func wiper_rapid_state():
	# If wiper is in the CONTINUOUS mode,
	# stop it and then start RAPID mode animation from current position
	if wiper_mode == GlobalEnums.WIPER_MODES.CONTINUOUS:
		if wiper_move_state == GlobalEnums.WIPER_MOVE_STATES.TOWARDS_MAX \
		or wiper_move_state == GlobalEnums.WIPER_MOVE_STATES.TOWARDS_ZERO:
			# Get current animation position
			var current_anim_pos = anim_player.current_animation_position
			# Get current position ratio
			var ratio = current_anim_pos / anim_player.current_animation_length
			# Stop CONTINUOUS mode animation while keeping it's position
			anim_player.stop(true)
			# Set RAPID mode animation to loop
			anim_player.get_animation(RAPID_ANIM_STRING).loop_mode = Animation.LOOP_LINEAR
			# Play RAPID mode animation
			anim_player.play(RAPID_ANIM_STRING)
			# Get the time to seek the RAPID animation to
			var seek_time = anim_player.current_animation_length * ratio
			# Seek the RAPID mode animation to the seek time
			anim_player.seek(seek_time)


func wiper_off_state():
	# If wiper is in the TOWARDS_ZERO move state,
	# stop it and then move the wiper TOWARDS_ZERO with low speed
	if wiper_mode == GlobalEnums.WIPER_MODES.RAPID \
	and (wiper_move_state == GlobalEnums.WIPER_MOVE_STATES.TOWARDS_ZERO \
		or wiper_move_state == GlobalEnums.WIPER_MOVE_STATES.TOWARDS_MAX):
		# Get current animation position
		var current_anim_pos = anim_player.current_animation_position
		# Get current position ratio
		var ratio = current_anim_pos / anim_player.current_animation_length
		# Stop RAPID mode animation while keeping it's position
		anim_player.stop(true)
		# Play RAPID_TO_OFF mode animation
		anim_player.play(RAPID_TO_OFF_ANIM_STRING)
		# Get the time to seek the RAPID animation to
		var seek_time = anim_player.current_animation_length * ratio
		# Seek the RAPID mode animation to the seek time
		anim_player.seek(seek_time)
		# Wait for RAPID_TO_OFF to finish
		await rapid_to_off_finished
		# Check if wiper mode has not been changed
		if wiper_mode == GlobalEnums.WIPER_MODES.RAPID_TO_OFF:
			# Change wiper mode to OFF
			wiper_mode = GlobalEnums.WIPER_MODES.OFF
			# Change wiper move state to OFF
			wiper_move_state = GlobalEnums.WIPER_MOVE_STATES.OFF


func toggle_wiper() -> void:
	if wiper_mode == GlobalEnums.WIPER_MODES.OFF:
		wiper_single_state()
	elif wiper_mode == GlobalEnums.WIPER_MODES.SINGLE:
		wiper_continuous_state()
	elif wiper_mode == GlobalEnums.WIPER_MODES.CONTINUOUS:
		wiper_rapid_state()
	elif wiper_mode == GlobalEnums.WIPER_MODES.RAPID:
		wiper_off_state()


func _input(event):
	if event.is_action_pressed("WiperToggle"):
		toggle_wiper()


func set_wiper_mode(mode: GlobalEnums.WIPER_MODES):
	wiper_mode = mode
	SignalManager.wiper_mode_changed.emit(mode)


func set_wiper_move_state(state: GlobalEnums.WIPER_MOVE_STATES):
	wiper_move_state = state


func wiper_entererd_restart_delay_state():
	entered_restart_delay.emit()


func wiper_rapid_to_off_finished():
	rapid_to_off_finished.emit()
