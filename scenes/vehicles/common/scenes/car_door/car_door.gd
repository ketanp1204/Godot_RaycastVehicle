extends Node3D

enum INTERACT_STATE { OPEN, CLOSED }
enum ROTATION_AXIS { X, Y, Z }
enum DOOR_LOCATION { FRONT_LEFT, FRONT_RIGHT, REAR_LEFT, REAR_RIGHT }


@export_group("Mesh")
@export var door_mesh: Resource

@export_group("Door Params")
@export var door_location: DOOR_LOCATION

@export_group("Rotation Properties")
## Maximum angle that the car part opens to (degrees)
@export var max_open_angle: float = 60.0
## Car part open speed (degrees per second)
@export var open_speed: float = 90
@export var rotation_axis: ROTATION_AXIS


@onready var mesh_instance = $MeshInstance3D
@onready var external_handle = $ExternalHandle


var state: INTERACT_STATE



func _ready() -> void:
	# Set the mesh of the MeshInstance3D
	mesh_instance.mesh = door_mesh
	
	# Set the default interaction state
	state = INTERACT_STATE.CLOSED
	
	# Connect the mouse handle click signal
	external_handle.mouse_clicked.connect(toggle)


func toggle() -> void:
	if state == INTERACT_STATE.CLOSED:
		open()
	else:
		close()


func open() -> void:
	var anim_length = abs(max_open_angle) / open_speed
	var tween = create_tween()
	tween.tween_property(
		self, 
		"rotation_degrees:" + 
		("x" if rotation_axis == ROTATION_AXIS.X 
		else "y" if rotation_axis == ROTATION_AXIS.Y else "z"), 
		max_open_angle, 
		anim_length)
	state = INTERACT_STATE.OPEN


func close() -> void:
	var anim_length = abs(max_open_angle) / open_speed
	var tween = create_tween()
	tween.tween_property(
		self, 
		"rotation_degrees:" + 
		("x" if rotation_axis == ROTATION_AXIS.X 
		else "y" if rotation_axis == ROTATION_AXIS.Y else "z"), 
		0.0, 
		anim_length).from_current()
	state = INTERACT_STATE.CLOSED

