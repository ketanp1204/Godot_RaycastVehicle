extends "res://vehicles/common/vehicle_4W/vehicle_4W_interactable/vehicle_4W_interactable.gd"

@export_category("Audio")
@export var audio_stream_player_node: NodePath
@export var open_anim_play_delay: float = 0.0
@export var close_sound_play_delay: float = 0.0

@export_category("Parameters")
@export var is_driver_door: bool = false


var audio_stream_player: AudioStreamPlayer3D
var active_camera_index: int



func on_ready() -> void:
	audio_stream_player = get_node(audio_stream_player_node) as AudioStreamPlayer3D

func open() -> void:
	# Position the audiostreamplayer3D node to the current handle that called the open function
	if current_handle == HANDLE_LOCATION.EXTERNAL:
		audio_stream_player.position = external_handle.position
	elif current_handle == HANDLE_LOCATION.INTERNAL:
		audio_stream_player.position = internal_handle.position
	
	# Play the door open sound
	SoundManager.play_door_open(audio_stream_player)
	
	# Wait for delay to play sound, if any
	await get_tree().create_timer(open_anim_play_delay).timeout
	
	# Play the door open animation
	open_anim()


func on_close_finished() -> void:
	# Position the audiostreamplayer3D node to the external handle position
	audio_stream_player.position = external_handle.position
	
	# Wait for delay to play sound, if any
	await get_tree().create_timer(close_sound_play_delay).timeout
	
	# Play the door close sound
	SoundManager.play_door_close(audio_stream_player)


func set_active_camera_index(camera_index: int):
	active_camera_index = camera_index


func _input(event):
	if event.is_action_pressed("OpenDriverDoor") and is_driver_door:
		if active_camera_index == GlobalEnums.CAMERAS.CHASING:
			toggle(HANDLE_LOCATION.EXTERNAL)
		elif active_camera_index == GlobalEnums.CAMERAS.INTERNAL:
			toggle(HANDLE_LOCATION.INTERNAL)
