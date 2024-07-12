extends Node3D

enum INTERACT_STATE { OPEN, CLOSED }
enum ROTATION_AXIS { X, Y, Z }

@export_category("References")
## The mesh resource that will be used for this Vehicle_4W part
@export var mesh_res: Resource
## The NodePath for the MeshInstance3D node
@export var mesh_node: NodePath
## The NodePath for the external handle StaticBody3D node
@export var external_handle_node: NodePath
## The NodePath for the internal handle StaticBody3D node
@export var internal_handle_node: NodePath

@export_category("Rotation Properties")
## Maximum angle that this Vehicle_4W part opens to (degrees)
@export var max_open_angle: float = 60.0
## Vehicle_4W part open speed (degrees per second)
@export var open_speed: float = 90
## Axis about which this Vehicle_4W will rotate
@export var rotation_axis: ROTATION_AXIS
## Whether to use the negative value of MaxOpenAngle for the rotation
@export var negative_rotation: bool = false


var mesh: MeshInstance3D
var external_handle: StaticBody3D
var internal_handle: StaticBody3D
var state: INTERACT_STATE



func _ready() -> void:
	# Get mesh nodes from the NodePath
	mesh = get_node(mesh_node) as MeshInstance3D
	
	# Set the mesh of the MeshInstance3D if not set
	if mesh.mesh == null:
		if mesh_res == null:
			print("ERROR @ Node " + name + ": Vehicle_4W part mesh not set in the inspector")
			return
		else:
			mesh.mesh = mesh_res
	
	# Get external handle and connect clicked signal if set
	if external_handle_node:
		external_handle = get_node(external_handle_node) as StaticBody3D
		external_handle.mouse_clicked.connect(toggle)
	
	# Get internal handle and connect clicked signal if set
	if internal_handle_node:
		internal_handle = get_node(internal_handle_node) as StaticBody3D
		internal_handle.mouse_clicked.connect(toggle)
	
	# Set the default interaction state
	state = INTERACT_STATE.CLOSED
	
	


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
