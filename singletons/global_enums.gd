extends Node

########## INTERACTABLE ##########
enum ROTATION_AXIS { 
	X, 
	Y, 
	Z}


########## CAMERA ##########
enum CAMERAS { 
	INTERNAL, 
	CHASING }


########## INDICATORS ##########
enum INDICATOR_MODES { 
	OFF, 
	LEFT, 
	RIGHT }


########## VEHICLE LIGHTS ##########
enum LIGHT_MODES { 
	OFF, 
	PARK, 
	MAIN }

enum HIGH_BEAM_MODES { 
	OFF,
	ON
}


########## WIPERS ##########
enum WIPER_MODE { 
	OFF, 
	SINGLE, 
	CONTINUOUS, 
	RAPID,
	RAPID_TO_OFF}
enum WIPER_MOVE_STATE { 
	OFF, 
	RESTART_DELAY, 
	TOWARDS_MAX, 
	TOWARDS_ZERO, 
	CURRENT_TOWARDS_MAX, 
	CURRENT_TOWARDS_ZERO }


