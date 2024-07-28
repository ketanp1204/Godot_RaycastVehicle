class_name Vehicle_4W_Clutch
extends Node

@export var clutch_stiffness: float = 40.0
@export var clutch_capacity: float = 1.3
@export var engine_max_torque: float = 400.0
@export_range(0, 1) var clutch_damping: float = 0.7

var clutch_angular_vel: float = 0.0
var clutch_slip: float = 0.0
var clutch_lock: float = 0.0
var rad_to_rpm: float = 0.0
var clutch_max_torque: float = 0.0
var clutch_torque: float = 0.0



func _ready():
	rad_to_rpm = 60.0 / (PI * 2)
	
	clutch_max_torque = engine_max_torque * clutch_capacity


func update_physics(output_shaft_vel: float, \
					engine_angular_vel: float, \
					current_gear_ratio: float) -> void:
	
	clutch_angular_vel = output_shaft_vel
	
	var engine_minus_clutch_ang_vel = engine_angular_vel - clutch_angular_vel
	clutch_slip = engine_minus_clutch_ang_vel * sign(abs(current_gear_ratio))
	
	var engine_angular_vel_rpm = engine_angular_vel * rad_to_rpm
	var engine_angular_vel_mapped = MathUtils.map_range_clamped(
		engine_angular_vel_rpm, 
		1000.0,
		1300.0,
		0.0,
		1.0
	)
	
	engine_angular_vel_mapped += float(current_gear_ratio == 0.0)
	clutch_lock = min(engine_angular_vel_mapped, 1.0)
	
	var clutch_slip_lock_stiffness = clutch_slip * clutch_lock * clutch_stiffness
	clutch_slip_lock_stiffness = clampf(
		clutch_slip_lock_stiffness, 
		-clutch_max_torque, 
		clutch_max_torque
		)
	
	clutch_torque = clutch_slip_lock_stiffness + \
					(clutch_torque - clutch_slip_lock_stiffness) * clutch_damping
