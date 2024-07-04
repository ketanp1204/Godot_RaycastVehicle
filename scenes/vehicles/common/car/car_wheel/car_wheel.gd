extends Node3D

########## COMPONENTS ##########

var car_body: RigidBody3D


########## RAYCAST ##########

## Toggle the display of the raycast during play
@export var show_raycast: bool = true
@onready var raycast = $RayCast3D
var raycast_hit: bool = false


########## SUSPENSION ##########

## The length of the suspension when the car is at rest
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
var relaxation_length: float = 0.01
var wheel_angular_vel: float = 0.0
var wheel_inertia: float = 1.5


########## FORCES ##########

var susp_force: float = 0.0
var susp_force_vector: Vector3 = Vector3.ZERO
var long_force: float = 0.0
var lat_force: float = 0.0


########## SLIP ##########
var long_slip: float = 0.0
var lat_slip: float = 0.0
var slip_angle: float = 0.0
var slip_angle_peak: float = 8.0
var slip_angle_dynamic: float = 0.0


########## INPUT ##########

var throttle: float = 0.0
var drive_torque: float = 0.0


func _ready():
	# Set the mesh of the MeshInstance3D if not set
	if wheel_mesh.mesh == null:
		if wheel_mesh_resource == null:
			print("ERROR @ Node " + name + ": Wheel mesh not set in the inspector")
			return
		else:
			wheel_mesh.mesh = wheel_mesh_resource
	
	#wheel_mesh.visible = false            # temp for debugging
	
	# Setting the position of the node to raycast start position
	position = Vector3(0, rest_length, 0)
	
	# Setting the position of the wheel mesh to the rest length of the suspension
	wheel_mesh.position = Vector3(0, -rest_length, 0)
	
	# Initializing last suspension length value to rest length
	last_length = rest_length


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	show_raycast_lines()
	
	if Input.is_action_pressed("Throttle"):
		throttle = 1.0
	elif Input.is_action_pressed("Reverse"):
		throttle = -1.0
	
	if Input.is_action_just_released("Throttle") or Input.is_action_just_released("Reverse"):
		throttle = 0.0
	
	drive_torque = throttle * 1000


func show_raycast_lines():
	if show_raycast:
		DebugDraw3D.draw_line(
			global_transform.origin,
			global_transform.origin + (-global_transform.basis.y * (current_length + wheel_radius)),
			Color.RED
		)


func _physics_process(delta):
	# Update raycast target position
	raycast.target_position = -global_transform.basis.y * (rest_length + wheel_radius)
	if raycast.is_colliding():
		# Raycast hit point
		var collision_point = raycast.get_collision_point()
		
		# WheelLocation = RaycastHitPoint + (UpVector * WheelRadius)
		var wheel_location = collision_point + (global_transform.basis.y * wheel_radius)
		
		# New suspension length 
		current_length = (global_transform.origin - wheel_location).length()
		
		# Position the wheel mesh based on the current length of the suspension
		wheel_mesh.position = Vector3(0, -current_length, 0)
		
		# SpringForce = SpringStiffness * (RestLength - CurrentLength)
		var spring_force = spring_stiffness * (rest_length - current_length)
		
		# DamperForce = DamperStiffness * ((LastLength - CurrentLength) / DeltaTime)
		var damper_force = damper_stiffness * ((last_length - current_length) / delta)
		
		# Net suspension force
		susp_force = spring_force + damper_force
		
		# Suspension force vector in raycast hit normal direction
		susp_force_vector = raycast.get_collision_normal().normalized() * susp_force
		
		# Update last length to current spring length
		last_length = current_length
		
		# Apply suspension force on the car's rigidbody
		car_body.apply_force(susp_force_vector, transform.origin)
		
		# Wheel local linear velocity
		local_linear_velocity = global_transform.basis.inverse() * get_point_velocity(collision_point)
		
		# FrictionTorque = LongitudinalForce * WheelRadius
		var friction_torque = long_force * wheel_radius
		
		# AngularAcceleration = Torque / Inertia
		var wheel_angular_accel = (drive_torque - friction_torque) / wheel_inertia
		
		# AngularVelocity = AngularAcceleration * DeltaTime
		wheel_angular_vel += wheel_angular_accel * delta
		# TEMP: Clamp value
		wheel_angular_vel = clampf(wheel_angular_vel, -120, 120)
		
		# TargetAngularVelocity = LocalForwardVelocity / WheelRadius
		var target_angular_vel = local_linear_velocity.x / wheel_radius
		
		# TargetAngularAcceleration = (Current Velocity - TargetAngularVelocity) / DeltaTime
		var target_angular_accel = (wheel_angular_vel - target_angular_vel) / delta
		
		# TargetTorque = TargetAngularAcceleration * WheelInertia
		var target_torque = target_angular_accel * wheel_inertia
		
		# Set longitudinal slip only if suspension force is not 0
		if susp_force == 0:
			long_slip = 0.0
		else:
			# MaxFrictionTorque = SuspForce * WheelRadius * Mu (coeff)
			var max_friction_torque = susp_force * wheel_radius * 1.0
		
			# LongitudinalSlip = TargetTorque / MaxFrictionTorque
			long_slip = target_torque / max_friction_torque
			long_slip = clampf(long_slip, -1.0, 1.0)
		
		# Set slip angle only if LocalForwardVelocity is not 0
		if local_linear_velocity.x == 0.0:
			slip_angle = 0.0
		else:
			# SlipAngle = Atan(-LocalRightVelocity / Abs(LocalForwardVelocity)
			slip_angle = atan(-local_linear_velocity.z / abs(local_linear_velocity.x))
		
		# LowSpeedSteadyStateSlipAngle = SlipAnglePeak * Sign(-LocalRightVelocity)
		var low_speed_steady_state_slip_angle = slip_angle_peak * sign(-local_linear_velocity.z)
		
		# HighSpeedSteadyStateSlipAngle = SlipAngle
		
		# Range of LocalLinearVelocity value mapped to 0-1
		var velocity_range = remap(local_linear_velocity.length(), 3.0, 6.0, 0.0, 1.0)
		
		# SlipAngle = Lerp(LowSpeedSA, HighSpeedSA, Range of LocalLinearVelocity values mapped to 0-1
		var steady_state_slip_angle = lerpf(low_speed_steady_state_slip_angle, 
											slip_angle, 
											velocity_range)
		
		# Coeff = (Abs(LocalRightVelocity) / RelaxationLength) * DeltaTime
		var coeff = (abs(local_linear_velocity.x) / relaxation_length) * delta
		coeff = clampf(coeff, 0.0, 1.0)
		
		# SlipAngleDynamic += (SteadyStateSA - SlipAngleDynamic) * Coeff
		slip_angle_dynamic += (steady_state_slip_angle - slip_angle_dynamic) * coeff
		slip_angle_dynamic = clampf(slip_angle_dynamic, -90.0, 90.0)
		
		# LateralSlip = SlipAngleDynamic / SlipAnglePeak
		lat_slip = slip_angle_dynamic / slip_angle_peak
		# Temporary action - delete if combined slip is used
		lat_slip = clampf(lat_slip, -1.0, 1.0)
		
		# LongitudinalForce = Max(SuspForce, 0) * LongitudinalSlip
		long_force = max(susp_force, 0.0) * long_slip
		
		# Global right vector of the wheel projected onto raycast hit normal plane
		var right_vec_projected = Plane(raycast.get_collision_normal()).project(global_transform.basis.z)
		right_vec_projected = right_vec_projected.normalized()
		
		# Global forward vector of the wheel projected onto raycast hit normal plane
		var forward_vec_projected = Plane(raycast.get_collision_normal()).project(global_transform.basis.x)
		forward_vec_projected = forward_vec_projected.normalized()
		
		# Tire force
		var lat_force_temp = right_vec_projected * (max(susp_force, 0.0) * lat_slip)
		var long_force_temp = forward_vec_projected * (max(susp_force, 0.0) * long_slip)
		var tire_force = lat_force_temp + long_force_temp
		
		# TireForceLocation = WheelPosition
		var tire_force_location = transform.origin
		
		# Apply tire force onto car rigidbody
		car_body.apply_force(tire_force, tire_force_location)
		
	else:
		# Reset values
		current_length = rest_length
		last_length = rest_length
		susp_force = 0.0
		susp_force_vector = Vector3.ZERO


func remap(val: float, from1: float, to1: float, from2: float, to2: float) -> float:
	return (val - from1) / (to1 - from1) * (to2 - from2) + from2;


func get_point_velocity(point: Vector3) -> Vector3:
	return car_body.linear_velocity + car_body.angular_velocity.cross(point - car_body.global_transform.origin)


func set_car_rigidbody(car: RigidBody3D):
	car_body = car
	raycast.add_exception(car_body)


func _input(event):
	if event.is_action_pressed("ToggleDebug"):
		show_raycast = !show_raycast
