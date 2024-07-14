extends Node


const SOUND_DOOR_OPEN = "door_open"
const SOUND_DOOR_CLOSE = "door_close"
const SOUND_LIGHTSWITCH_TOGGLE = "lightswitch_toggle"


const SOUNDS = {
	SOUND_DOOR_OPEN: preload("res://assets/sounds/car/door/Car_DoorOpen.wav"),
	SOUND_DOOR_CLOSE: preload("res://assets/sounds/car/door/Car_DoorClose.wav"),
	SOUND_LIGHTSWITCH_TOGGLE: preload("res://assets/sounds/car/light_switch/Car_LightSwitchToggle.wav")
}


func play_sound(player: AudioStreamPlayer3D, key: String) -> void:
	if not SOUNDS.has(key):
		return
	
	player.stop()
	player.stream = SOUNDS[key]
	player.play()


func play_door_open(player: AudioStreamPlayer3D) -> void:
	play_sound(player, SOUND_DOOR_OPEN)

func play_door_close(player: AudioStreamPlayer3D) -> void:
	play_sound(player, SOUND_DOOR_CLOSE)

func play_light_switch_toggle(player: AudioStreamPlayer3D) -> void:
	play_sound(player, SOUND_LIGHTSWITCH_TOGGLE)
