extends Node3D

enum LIGHT_MODES { OFF, PARK, MAIN }


@onready var low_beam_l = $LowBeam_L
@onready var low_beam_r = $LowBeam_R
@onready var high_beam_l = $HighBeam_L
@onready var high_beam_r = $HighBeam_R


var light_mode: LIGHT_MODES

var car_body_mesh: MeshInstance3D
var headlight_material: Material



func _ready():
	
	light_mode = LIGHT_MODES.OFF


func toggle() -> void:
	
	if light_mode == LIGHT_MODES.OFF:
		headlight_material.emission_enabled = true
		headlight_material.emission_energy_multiplier = 1
		light_mode = LIGHT_MODES.PARK
	elif light_mode == LIGHT_MODES.PARK:
		headlight_material.emission_enabled = true
		headlight_material.emission_energy_multiplier = 10
		light_mode = LIGHT_MODES.MAIN
	elif light_mode == LIGHT_MODES.MAIN:
		headlight_material.emission_enabled = false
		headlight_material.emission_energy_multiplier = 1
		light_mode = LIGHT_MODES.OFF


func _input(event):
	if event.is_action_pressed("LightsToggle"):
		toggle()


func set_mesh_instance(mesh: MeshInstance3D) -> void:
	car_body_mesh = mesh
	headlight_material = car_body_mesh.get_active_material(10)
