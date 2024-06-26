extends Node3D

########## COMPONENTS ##########
var car_body: RigidBody3D

########## RAYCAST ##########
@export var show_raycast: bool = true
@onready var raycast = $RayCast3D
var raycast_hit: bool = false

########## SUSPENSION ##########
@export var rest_length: float = 0.5
@export var spring_stiffness: float = 500.0
@export var damper_stiffness: float = 30.0
var current_length: float = 0.0
var last_length: float = 0.0

########## WHEEL ##########
@export var wheel_mesh_resource: Resource
@export var wheel_radius: float = 0.342
@onready var wheel_mesh = $WheelMesh
var local_linear_velocity: Vector3 = Vector3.ZERO


########## FORCES ##########
var force_z: float = 0.0
var force_z_vector: Vector3 = Vector3.ZERO



func _ready():
	# Set the mesh of the MeshInstance3D if not set
	if wheel_mesh.mesh == null:
		if wheel_mesh_resource == null:
			print("ERROR @ Node " + name + ": Wheel mesh not set in the inspector")
			return
		else:
			wheel_mesh.mesh = wheel_mesh_resource
	
	# Setting the position of the node to raycast start position
	position = Vector3(0, rest_length, 0)
	
	# Setting the position of the wheel mesh to the rest length of the suspension
	wheel_mesh.position = Vector3(0, -rest_length, 0)
	
	# Initializing last suspension length value to rest length
	last_length = rest_length


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	DebugDraw3D.draw_line(
		global_transform.origin,
		global_transform.origin + (-global_transform.basis.y * (current_length + wheel_radius)),
		Color.RED
	)


func _physics_process(delta):
	# Update raycast target position
	raycast.target_position = -global_transform.basis.y * (rest_length + wheel_radius)
	if raycast.is_colliding():
		# Get suspension current length
		var collision_point = raycast.get_collision_point()
		var wheel_location = collision_point + (global_transform.basis.y * wheel_radius)
		current_length = (global_transform.origin - wheel_location).length()
		
		# Position the wheel mesh based on the current length of the suspension
		wheel_mesh.position = Vector3(0, -current_length, 0)
		
		# Get spring and damper forces
		var spring_force = spring_stiffness * (rest_length - current_length)
		var damper_force = damper_stiffness * ((last_length - current_length) / delta)
		
		# Get suspension force
		force_z = spring_force + damper_force
		force_z_vector = raycast.get_collision_normal().normalized() * force_z
		
		# Update last length to current spring length
		last_length = current_length
		
		# Apply suspension force on the car's rigidbody
		car_body.apply_force(force_z_vector, global_transform.origin)
		
		# Calculate the local linear velocity of the wheel
		local_linear_velocity = global_transform.basis.inverse() * get_point_velocity(collision_point)
		
		
	else:
		current_length = rest_length
		last_length = rest_length
		force_z = 0.0
		force_z_vector = Vector3.ZERO


func get_point_velocity(point: Vector3) -> Vector3:
	return car_body.linear_velocity + car_body.angular_velocity.cross(point - car_body.global_transform.origin)


func set_car_rigidbody(car: RigidBody3D):
	car_body = car
	raycast.add_exception(car_body)
