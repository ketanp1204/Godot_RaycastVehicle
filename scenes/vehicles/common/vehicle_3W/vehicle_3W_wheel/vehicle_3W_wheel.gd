@tool
extends Node3D

########## COMPONENTS ##########

var rigidbody: RigidBody3D


########## RAYCAST ##########
@export_category("Raycast")

## Toggle the display of the raycast during play
@export var show_raycast: bool = true
@onready var raycast = $RayCast3D
var raycast_hit: bool = false


########## SUSPENSION ##########
@export_category("Suspension")

## The length of the suspension when the auto is at rest (in m)
@export var rest_length: float = 0.367
## Stiffness of the suspension spring
@export var spring_stiffness: float = 500.0
## Stiffness of the suspension damper
@export var damper_stiffness: float = 30.0
var current_length: float = 0.0
var last_length: float = 0.0


########## WHEEL ##########

@export_category("Wheel")
## Radius of the wheel (in m)
@export var wheel_radius: float = 0.3
## Is this the front wheel?
@export var is_front_wheel: bool = false:
	set(value):
		if value == is_front_wheel : return
		is_front_wheel = value
		notify_property_list_changed()

var local_linear_velocity: Vector3 = Vector3.ZERO

# Front fender and wheel MeshInstance3D refs
var front_fender_mesh: MeshInstance3D
var front_wheel_mesh: MeshInstance3D

## Mesh for the front fender
var front_fender_meshres: Resource
## Mesh for the front wheel
var front_wheel_meshres: Resource
## Define the offset position of the front wheel from the fender position
var front_wheel_offset: Vector3 = Vector3.ZERO

# Rear wheel MeshInstance3D ref
var rear_wheel_mesh: MeshInstance3D

## Mesh for the rear wheel (L/R)
var rear_wheel_meshres: Resource


########## FORCES ##########

var susp_force: float = 0.0
var susp_force_vector: Vector3 = Vector3.ZERO


########## INPUT ##########

var throttle: float = 0.0



func _get_property_list() -> Array:
	var ret = []
	if is_front_wheel:
		ret.append({
			"name" : &"front_fender_meshres",
			"type" : TYPE_OBJECT,
			"hint" : PROPERTY_HINT_RESOURCE_TYPE,
			"usage" : PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_SCRIPT_VARIABLE
		})
		ret.append({
			"name" : &"front_wheel_meshres",
			"type" : TYPE_OBJECT,
			"hint" : PROPERTY_HINT_RESOURCE_TYPE,
			"usage" : PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_SCRIPT_VARIABLE
		})
		ret.append({
			"name" : &"front_wheel_offset",
			"type" : TYPE_VECTOR3,
			"usage" : PROPERTY_USAGE_DEFAULT
		})
	else:
		ret.append({
			"name" : &"rear_wheel_meshres",
			"type" : TYPE_OBJECT,
			"hint" : PROPERTY_HINT_RESOURCE_TYPE,
			"usage" : PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_SCRIPT_VARIABLE
		})
	return ret



func _ready():
	# Set meshes if not set in inspector
	set_meshes()
	# Set suspension raycast position and update wheel mesh relative position
	initialize_suspension()


func set_rigidbody(rb: RigidBody3D):
	rigidbody = rb
	raycast.add_exception(rigidbody)


func set_meshes():
	# Set front fender and front wheel meshes
	if is_front_wheel:
		
		# Get MeshInstance3D refs
		front_fender_mesh = $FrontFenderMesh
		front_wheel_mesh = $FrontFenderMesh/FrontWheelMesh
		
		# Set meshes
		if front_fender_mesh.mesh == null:
			if front_fender_meshres == null:
				print("ERROR @ Node " + name + ": Fender mesh not set in the inspector")
			else:
				front_fender_mesh.mesh = front_fender_meshres
		if front_wheel_mesh.mesh == null:
			if front_wheel_meshres == null:
				print("ERROR @ Node " + name + ": Front wheel mesh not set in the inspector")
				return
			else:
				front_wheel_mesh.mesh = front_wheel_meshres
		
		# Remove rear wheel mesh 
		if rear_wheel_mesh:
			$RearWheelMesh.queue_free()
		
		# TEMPORARY hide wheel mesh
		#front_fender_mesh.visible = false
		#front_wheel_mesh.visible = false
	
	# Set rear wheel mesh
	else:
		
		# Get rear wheel mesh ref
		rear_wheel_mesh = $RearWheelMesh
		
		if rear_wheel_mesh.mesh == null:
			if rear_wheel_meshres == null:
				print("ERROR @ Node " + name + ": Rear wheel mesh not set in the inspector")
				return
			else:
				rear_wheel_mesh.mesh = rear_wheel_meshres
		
		# Remove front fender and front wheel meshes
		if front_fender_mesh:
			$FrontFenderMesh.queue_free()
			$FrontFenderMesh/FrontWheelMesh.queue_free()
		
		# TEMPORARY hide wheel mesh
		#rear_wheel_mesh.visible = false


func initialize_suspension():
	if is_front_wheel:
		# Set the position of the front wheel mesh
		front_wheel_mesh.position = front_wheel_offset + Vector3(0, -rest_length, 0)
		
		# Set the start position of the RayCast3D node
		raycast.position = Vector3(front_wheel_offset.x, 0.0, front_wheel_offset.z)
	else:
		# Set the position of the rear wheel mesh
		rear_wheel_mesh.position = Vector3(0, -rest_length, 0)
	
	# Initializing current and last suspension length values to rest length
	current_length = rest_length
	last_length = rest_length


func _process(_delta):
	
	if show_raycast:
		DebugDraw3D.draw_line(
			raycast.global_transform.origin,
			raycast.global_transform.origin + (-raycast.global_transform.basis.y * (current_length + wheel_radius)),
			Color.RED
		)
	
	if not Engine.is_editor_hint():
		if Input.is_action_pressed("Throttle"):
			throttle = 1.0
		elif Input.is_action_pressed("Reverse"):
			throttle = -1.0


func _physics_process(delta):
	# Update raycast target position
	raycast.target_position = -raycast.global_transform.basis.y * (rest_length + wheel_radius)
	if raycast.is_colliding():
		# Get suspension current length
		var collision_point = raycast.get_collision_point()
		var wheel_location = collision_point + (raycast.global_transform.basis.y * wheel_radius)
		current_length = (raycast.global_transform.origin - wheel_location).length()
		
		# Position the wheel mesh based on the current length of the suspension
		if is_front_wheel:
			front_wheel_mesh.position = front_wheel_offset + Vector3(0, -current_length, 0)
		else:
			rear_wheel_mesh.position = Vector3(0, -current_length, 0)
		
		# Get spring and damper forces
		var spring_force = spring_stiffness * (rest_length - current_length)
		var damper_force = damper_stiffness * ((last_length - current_length) / delta)
		
		# Get suspension force
		susp_force = spring_force + damper_force
		susp_force_vector = raycast.get_collision_normal().normalized() * susp_force
		
		# Update last length to current spring length
		last_length = current_length
		
		# Apply suspension force on the car's rigidbody
		rigidbody.apply_force(susp_force_vector, raycast.transform.origin)
		
		# Calculate the local linear velocity of the wheel
		local_linear_velocity = raycast.global_transform.basis.inverse() * get_point_velocity(collision_point)
	else:
		# Reset values
		current_length = rest_length
		last_length = rest_length
		susp_force = 0.0
		susp_force_vector = Vector3.ZERO


func get_point_velocity(point: Vector3) -> Vector3:
	return rigidbody.linear_velocity + rigidbody.angular_velocity.cross(point - rigidbody.global_transform.origin)


func _input(event):
	if event.is_action_pressed("ToggleDebug"):
		show_raycast = !show_raycast
