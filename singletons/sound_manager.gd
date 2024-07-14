extends Node


const SOUND_DOOR_OPEN = "door_open"
const SOUND_DOOR_CLOSE = "door_close"


const SOUNDS = {
	SOUND_DOOR_OPEN: preload("res://assets/sounds/car/door/CarDoor_OpenSound.wav"),
	SOUND_DOOR_CLOSE: preload("res://assets/sounds/car/door/CarDoor_CloseSound.wav")
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
