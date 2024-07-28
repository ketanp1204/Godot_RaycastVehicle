class_name MathUtils
extends Node


static func map_range_clamped(val: float, in1: float, in2: float, out1: float, out2: float) -> float:
	var result = out1 + (val - in1) * (out2 - out1) / (in2 - in1)
	
	if result < out1: 
		result = out1
	if result > out2:
		result = out2
	
	return result
