class_name Vehicle_4W_Gearbox
extends Node

@export var gear_count: int = 5
@export var gear_shift_time: float = 0.3
@export var gear_ratios: Array[float] = [ 0.0, 3.545, 1.904, 1.31, 0.969, 0.815 ]
@export var reverse_gear_ratio: float = -3.25

var current_gear_ratio: float = 0.0
var in_gear: bool = true
var current_gear: int = 0


func shift_gear_up() -> void:

	if current_gear < gear_count and in_gear:
		in_gear = false
		current_gear_ratio = 0.0
		await get_tree().create_timer(gear_shift_time).timeout
		in_gear = true
		current_gear += 1
		set_gear_ratio()


func shift_gear_down() -> void:
	if current_gear > -1 and in_gear:
		in_gear = false
		current_gear_ratio = 0.0
		await get_tree().create_timer(gear_shift_time).timeout
		in_gear = true
		current_gear -= 1
		set_gear_ratio()


func set_gear_ratio() -> void:
	if current_gear == -1:
		current_gear_ratio = reverse_gear_ratio
	else:
		current_gear_ratio = gear_ratios[current_gear]


func get_output_torque(input_torque: float) -> float:
	return input_torque * current_gear_ratio


func get_input_shaft_velocity(output_shaft_velocity: float) -> float:
	return output_shaft_velocity * current_gear_ratio
