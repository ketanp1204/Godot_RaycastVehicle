extends Node3D

enum INTERACT_STATE { OPEN, CLOSED }
enum ROTATION_AXIS { X, Y, Z }


@export_category("References")
## The mesh resource that will be used for this door
@export var door_mesh_res: Resource
## The NodePath for the MeshInstance3D node
@export var door_mesh_node: NodePath
## The NodePath for the external handle StaticBody3D node
@export var external_handle_node: NodePath
## The NodePath for the internal handle StaticBody3D node
@export var internal_handle_node: NodePath

@export_category("Rotation Properties")
## Maximum angle that the door opens to (degrees)
@export var max_open_angle: float = 60.0
## Door open speed (degrees per second)
@export var open_speed: float = 90
## Axis about which the door will rotate
@export var rotation_axis: ROTATION_AXIS
## Whether to use the negative value of MaxOpenAngle for the rotation
@export var negative_rotation: bool = false


var door_mesh: MeshInstance3D
var external_handle: StaticBody3D
var internal_handle: StaticBody3D
var state: INTERACT_STATE



func _ready() -> void:
	
	# Get nodes from the nodepaths
	door_mesh = get_node(door_mesh_node) as MeshInstance3D
	external_handle = get_node(external_handle_node) as StaticBody3D
	internal_handle = get_node(internal_handle_node) as StaticBody3D
	
	# Set the default interaction state
	state = INTERACT_STATE.CLOSED
	
	# Connect the mouse handle click signals
	external_handle.mouse_clicked.connect(toggle)
	internal_handle.mouse_clicked.connect(toggle)
	
	# Set the mesh of the MeshInstance3D if not set
	if door_mesh.mesh == null:
		if door_mesh_res == null:
			print("ERROR @ Node " + name + ": Door mesh not set in the inspector")
			return
		else:
			door_mesh.mesh = door_mesh_res


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
		-max_open_angle if negative_rotation else max_open_angle, 
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

