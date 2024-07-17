extends Node3D

# Animation name strings
const LIGHT_OFF_TO_PARK_ANIM = "light_off_to_park"
const LIGHT_PARK_TO_MAIN_ANIM = "light_park_to_main"
const LIGHT_MAIN_TO_OFF_ANIM = "light_main_to_off"
const HIGH_BEAM_OFF_TO_ON_ANIM = "high_beam_off_to_on"
const HIGH_BEAM_ON_TO_OFF_ANIM = "high_beam_on_to_off"
const INDICATOR_OFF_TO_LEFT_ANIM = "indicator_off_to_left"
const INDICATOR_OFF_TO_RIGHT_ANIM = "indicator_off_to_right"
const INDICATOR_LEFT_TO_OFF_ANIM = "indicator_left_to_off"
const INDICATOR_LEFT_TO_RIGHT_ANIM = "indicator_left_to_right"
const INDICATOR_RIGHT_TO_OFF_ANIM = "indicator_right_to_off"
const INDICATOR_RIGHT_TO_LEFT_ANIM = "indicator_right_to_left"


@export_category("References")
@export var audio_stream_player_node: NodePath
@export var anim_player_node: NodePath

var audio_stream_player: AudioStreamPlayer3D
var anim_player: AnimationPlayer

var current_light_mode: GlobalEnums.LIGHT_MODES = GlobalEnums.LIGHT_MODES.OFF
var current_turn_signal_mode: GlobalEnums.INDICATOR_MODES = GlobalEnums.INDICATOR_MODES.OFF
var current_high_beam_mode: bool = false



func _ready():
	# Get nodes from NodePath
	if audio_stream_player_node:
		audio_stream_player = get_node(audio_stream_player_node) as AudioStreamPlayer3D
	if anim_player_node:
		anim_player = get_node(anim_player_node) as AnimationPlayer
	
	# Subscribe to signals
	SignalManager.vehicle_light_mode_changed.connect(set_light_mode)
	SignalManager.turn_signal_changed.connect(set_turn_signal)
	SignalManager.high_beam_changed.connect(set_high_beam)


func set_light_mode(mode: GlobalEnums.LIGHT_MODES) -> void:
	# Play switch sound
	SoundManager.play_light_switch_toggle(audio_stream_player)
	# Change light mode
	if current_light_mode == GlobalEnums.LIGHT_MODES.OFF:
		# Change light mode to PARK
		current_light_mode = GlobalEnums.LIGHT_MODES.PARK
		# Start light switch animation
		anim_player.play(LIGHT_OFF_TO_PARK_ANIM)
	elif current_light_mode == GlobalEnums.LIGHT_MODES.PARK:
		# Change light mode to MAIN
		current_light_mode = GlobalEnums.LIGHT_MODES.MAIN
		# Start light switch animation
		anim_player.play(LIGHT_PARK_TO_MAIN_ANIM)
	elif current_light_mode == GlobalEnums.LIGHT_MODES.MAIN:
		# Change light mode to OFF
		current_light_mode = GlobalEnums.LIGHT_MODES.OFF
		# Start light switch animation
		anim_player.play(LIGHT_MAIN_TO_OFF_ANIM)


func set_turn_signal(mode: GlobalEnums.INDICATOR_MODES) -> void:
	# Play switch sound
	SoundManager.play_light_switch_toggle(audio_stream_player)
	# Change turn signal mode
	if current_turn_signal_mode == GlobalEnums.INDICATOR_MODES.OFF:
		if mode == GlobalEnums.INDICATOR_MODES.LEFT:
			current_turn_signal_mode = GlobalEnums.INDICATOR_MODES.LEFT
			anim_player.play(INDICATOR_OFF_TO_LEFT_ANIM)
		elif mode == GlobalEnums.INDICATOR_MODES.RIGHT:
			current_turn_signal_mode = GlobalEnums.INDICATOR_MODES.RIGHT
			anim_player.play(INDICATOR_OFF_TO_RIGHT_ANIM)
	elif current_turn_signal_mode == GlobalEnums.INDICATOR_MODES.LEFT:
		if mode == GlobalEnums.INDICATOR_MODES.LEFT:
			current_turn_signal_mode = GlobalEnums.INDICATOR_MODES.OFF
			anim_player.play(INDICATOR_LEFT_TO_OFF_ANIM)
		elif mode == GlobalEnums.INDICATOR_MODES.RIGHT:
			current_turn_signal_mode = GlobalEnums.INDICATOR_MODES.RIGHT
			anim_player.play(INDICATOR_LEFT_TO_RIGHT_ANIM)
	elif current_turn_signal_mode == GlobalEnums.INDICATOR_MODES.RIGHT:
		if mode == GlobalEnums.INDICATOR_MODES.RIGHT:
			current_turn_signal_mode = GlobalEnums.INDICATOR_MODES.OFF
			anim_player.play(INDICATOR_RIGHT_TO_OFF_ANIM)
		elif mode == GlobalEnums.INDICATOR_MODES.LEFT:
			current_turn_signal_mode = GlobalEnums.INDICATOR_MODES.LEFT
			anim_player.play(INDICATOR_RIGHT_TO_LEFT_ANIM)


func set_high_beam(mode: bool) -> void:
	# Play switch sound
	SoundManager.play_light_switch_toggle(audio_stream_player)
	# Change high beam mode
	if mode == false:
		current_high_beam_mode = false
		anim_player.play(HIGH_BEAM_ON_TO_OFF_ANIM)
	else:
		current_high_beam_mode = true
		anim_player.play(HIGH_BEAM_OFF_TO_ON_ANIM)
