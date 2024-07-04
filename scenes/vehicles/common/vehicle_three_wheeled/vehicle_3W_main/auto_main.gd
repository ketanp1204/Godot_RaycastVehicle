extends RigidBody3D

@export_group("Mesh")
@export var auto_body_meshres: Resource

@onready var auto_body_mesh = $Body
@onready var front_fender = $FrontFenderDummy/Wheel_F
@onready var rear_left_wheel = $WheelRLDummy/Wheel_RL
@onready var rear_right_wheel = $WheelRRDummy/Wheel_RR



# Called when the node enters the scene tree for the first time.
func _ready():
	# Set the mesh of the MeshInstance3D if not set
	if auto_body_mesh.mesh == null:
		if auto_body_meshres == null:
			print("ERROR @ Node " + name + ": Body mesh not set in the inspector")
			# Prevent rigidbody being affected by gravity
			freeze = true
			return
		else:
			auto_body_mesh.mesh = auto_body_meshres
	
	# Pass this rigidbody's reference to the wheel component nodes
	front_fender.set_rigidbody(self)
	rear_left_wheel.set_rigidbody(self)
	rear_right_wheel.set_rigidbody(self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
