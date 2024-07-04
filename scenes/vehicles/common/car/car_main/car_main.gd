extends RigidBody3D

@export_group("Mesh")
@export var car_body_mesh_resource: Resource


@onready var car_body_mesh = $CarBody
@onready var wheel_fl = $WheelFLDummy/WheelFL
@onready var wheel_fr = $WheelFRDummy/WheelFR
@onready var wheel_rl = $WheelRLDummy/WheelRL
@onready var wheel_rr = $WheelRRDummy/WheelRR


# Called when the node enters the scene tree for the first time.
func _ready():
	# Set the mesh of the MeshInstance3D if not set
	if car_body_mesh.mesh == null:
		if car_body_mesh_resource == null:
			print("ERROR @ Node " + name + ": Car body mesh not set in the inspector")
			# Prevent rigidbody being affected by gravity
			freeze = true
			return
		else:
			car_body_mesh.mesh = car_body_mesh_resource
	
	# Create convex collider for the car body mesh
	car_body_mesh.create_convex_collision(true, false)
	
	# Reparent the collider to use it for the rigidbody
	var collider = car_body_mesh.get_child(0).get_child(0)
	collider.reparent(car_body_mesh.get_parent())
	
	# Delete the created StaticBody3D under the mesh node
	car_body_mesh.get_child(0).queue_free()
	
	# Pass this rigidbody's reference to the wheel component nodes
	wheel_fl.set_car_rigidbody(self)
	wheel_fr.set_car_rigidbody(self)
	wheel_rl.set_car_rigidbody(self)
	wheel_rr.set_car_rigidbody(self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
