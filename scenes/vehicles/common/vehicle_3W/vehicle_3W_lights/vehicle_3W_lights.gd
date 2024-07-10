extends Node3D

enum LIGHT_MODES { OFF, PARK, MAIN }



@onready var low_beam_l = $LowBeam_L
@onready var low_beam_r = $LowBeam_R
@onready var high_beam_l = $HighBeam_L
@onready var high_beam_r = $HighBeam_R


var light_mode: LIGHT_MODES

var headlight_mesh_instance: MeshInstance3D
var headlight_material: Material
var mat: Material

func _ready():
	
	light_mode = LIGHT_MODES.OFF


func toggle() -> void:
	
	if not headlight_mesh_instance:
		return
	else:
		headlight_material = headlight_mesh_instance.get_surface_override_material(10)
		#headlight_mesh_instance.material_override = null
		#headlight_mesh_instance.set_surface_override_material(10, headlight_material)
	
	if light_mode == LIGHT_MODES.OFF:
		headlight_material.emission_enabled = true
		headlight_material.emission_energy_multiplier = 1
	elif light_mode == LIGHT_MODES.PARK:
		headlight_material.emission_enabled = true
		headlight_material.emission_energy_multiplier = 10
	elif light_mode == LIGHT_MODES.MAIN:
		headlight_material.emission_enabled = false
		headlight_material.emission_energy_multiplier = 1


func _input(event):
	if event.is_action_pressed("LightsToggle"):
		toggle()


func set_mesh_instance(mesh: MeshInstance3D) -> void:
	headlight_mesh_instance = mesh
