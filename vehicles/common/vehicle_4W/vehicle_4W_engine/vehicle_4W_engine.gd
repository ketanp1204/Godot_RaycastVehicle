class_name Vehicle_4W_Engine
extends Node

@export var torque_curve: Curve
@export var torque_curve_max_rpm: float = 9000.0
@export var start_friction: float = 50.0
@export var friction_coeff: float = 0.02
@export var engine_inertia: float = 0.2
@export var engine_angular_velocity: float = 100.0
@export var engine_max_rpm: float = 6000.0
@export var engine_idle_rpm: float = 800.0

var engine_rpm: float = 0.0
var engine_effective_torque: float = 0.0
var engine_torque: float = 0.0
var rpm_to_rad: float
var rad_to_rpm: float


func _ready():
	# Calculate RPM to Rad and Rad to RPM values
	rpm_to_rad = (PI * 2) / 60.0
	rad_to_rpm = 1.0 / rpm_to_rad


func update_physics(delta, throttle, load_torque):
	if torque_curve:
		# Max effective torque
		var max_effective_torque = torque_curve.sample_baked(engine_rpm / torque_curve_max_rpm)
		# Friction = StartFriction + (EngineRPM * FrictionCoeff)
		var friction = start_friction + (engine_rpm * friction_coeff)
		# CurrentInitialTorque = (MaxEffectiveTorque + Friction) * Throttle
		var current_initial_torque = (max_effective_torque + friction) * throttle
		# EngineEffectiveTorque = CurrentInitialTorque - Friction
		engine_effective_torque = current_initial_torque - friction
		# Add Load Torque to Engine
		engine_torque = engine_effective_torque - load_torque
		# Acceleration = Torque / Inertia
		var acceleration = engine_torque / engine_inertia
		# AngularVelocityDelta = Acceleration * DeltaTime
		var angular_velocity_delta = acceleration * delta
		# EngineAngularVelocity += AngularVelocityDelta
		engine_angular_velocity += angular_velocity_delta
		# Clamp between engine idle rpm and max rpm
		var engine_idle_rpm_rad = engine_idle_rpm * rpm_to_rad
		var engine_max_rpm_rad = engine_max_rpm * rpm_to_rad
		engine_angular_velocity = clampf(
			engine_angular_velocity, 
			engine_idle_rpm_rad,
			engine_max_rpm_rad)
		# EngineRPM = RadtoRPM(EngineAngularVelocity)
		engine_rpm = engine_angular_velocity * rad_to_rpm
		
