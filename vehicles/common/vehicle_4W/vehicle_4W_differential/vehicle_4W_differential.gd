class_name Vehicle_4W_Differential
extends Node

@export var differential_ratio: float = 4.38


func get_output_torque(input_torque: float) -> Array[float]:
	var symmetrical_output_torque: float = input_torque * differential_ratio * 0.5
	return [symmetrical_output_torque, symmetrical_output_torque]


func get_input_shaft_velocity(output_shaft_vel_left: float, output_shaft_vel_right: float) -> float:
	return differential_ratio * ((output_shaft_vel_left + output_shaft_vel_right) * 0.5)
