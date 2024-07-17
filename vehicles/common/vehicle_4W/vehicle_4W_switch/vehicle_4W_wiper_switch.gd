extends Node

const WIPER_OFF_TO_SINGLE_ANIM = "wiper_off_to_single"
const WIPER_SINGLE_TO_CONTINUOUS_ANIM = "wiper_single_to_continuous"
const WIPER_CONTINUOUS_TO_RAPID_ANIM = "wiper_continuous_to_rapid"
const WIPER_RAPID_TO_OFF_ANIM = "wiper_rapid_to_off"

@export_category("References")
@export var audio_stream_player_node: NodePath
@export var anim_player_node: NodePath

var audio_stream_player: AudioStreamPlayer3D
var anim_player: AnimationPlayer

var wiper_mode: GlobalEnums.WIPER_MODES = GlobalEnums.WIPER_MODES.OFF



# Called when the node enters the scene tree for the first time.
func _ready():
	# Get nodes from NodePath
	if audio_stream_player_node:
		audio_stream_player = get_node(audio_stream_player_node) as AudioStreamPlayer3D
	if anim_player_node:
		anim_player = get_node(anim_player_node) as AnimationPlayer
	
	# Connect wiper mode changed signal
	SignalManager.wiper_mode_changed.connect(set_wiper_mode)
	# Connect wiper single to continuous signal to
	# immediately play the animation
	SignalManager.wiper_single_to_continuous.connect(wiper_single_to_continuous)


func set_wiper_mode(mode: GlobalEnums.WIPER_MODES):
	# Stop if wiper is already in received mode
	if wiper_mode == mode:
		return
	
	SoundManager.play_light_switch_toggle(audio_stream_player)
	if wiper_mode == GlobalEnums.WIPER_MODES.OFF \
	and mode == GlobalEnums.WIPER_MODES.SINGLE:
		anim_player.play(WIPER_OFF_TO_SINGLE_ANIM)
		wiper_mode = GlobalEnums.WIPER_MODES.SINGLE
	elif wiper_mode == GlobalEnums.WIPER_MODES.SINGLE \
	and mode == GlobalEnums.WIPER_MODES.CONTINUOUS:
		anim_player.play(WIPER_SINGLE_TO_CONTINUOUS_ANIM)
		wiper_mode = GlobalEnums.WIPER_MODES.CONTINUOUS
	elif wiper_mode == GlobalEnums.WIPER_MODES.CONTINUOUS \
	and mode == GlobalEnums.WIPER_MODES.RAPID:
		anim_player.play(WIPER_CONTINUOUS_TO_RAPID_ANIM)
		wiper_mode = GlobalEnums.WIPER_MODES.RAPID
	elif wiper_mode == GlobalEnums.WIPER_MODES.RAPID \
	and mode == GlobalEnums.WIPER_MODES.RAPID_TO_OFF:
		anim_player.play(WIPER_RAPID_TO_OFF_ANIM)
		wiper_mode = GlobalEnums.WIPER_MODES.OFF


func wiper_single_to_continuous() -> void:
	SoundManager.play_light_switch_toggle(audio_stream_player)
	anim_player.play(WIPER_SINGLE_TO_CONTINUOUS_ANIM)
	wiper_mode = GlobalEnums.WIPER_MODES.CONTINUOUS
