extends Node3D

enum LIGHT_MODES { OFF, PARK, MAIN }

@export_category("References")
@export var lowbeam_l_node: NodePath
@export var lowbeam_r_node: NodePath
@export var highbeam_l_node: NodePath
@export var highbeam_r_node: NodePath

var lowbeam_l: SpotLight3D
var lowbeam_r: SpotLight3D
var highbeam_l: SpotLight3D
var highbeam_r: SpotLight3D

var light_mode: LIGHT_MODES
var body_mesh: MeshInstance3D
var headlight_material: Material



# Called when the node enters the scene tree for the first time.
func _ready():
	# Get nodes from NodePath
	lowbeam_l = get_node(lowbeam_l_node) as SpotLight3D
	lowbeam_r = get_node(lowbeam_r_node) as SpotLight3D
	highbeam_l = get_node(highbeam_l_node) as SpotLight3D
	highbeam_r = get_node(highbeam_r_node) as SpotLight3D
	
	# Set light mode to OFF
	light_mode = LIGHT_MODES.OFF


func toggle() -> void:
	
	if light_mode == LIGHT_MODES.OFF:
		headlight_material.emission_enabled = true
		headlight_material.emission_energy_multiplier = 1
		visible = false
		light_mode = LIGHT_MODES.PARK
	elif light_mode == LIGHT_MODES.PARK:
		headlight_material.emission_enabled = true
		headlight_material.emission_energy_multiplier = 10
		visible = true
		light_mode = LIGHT_MODES.MAIN
	elif light_mode == LIGHT_MODES.MAIN:
		headlight_material.emission_enabled = false
		headlight_material.emission_energy_multiplier = 1
		visible = false
		light_mode = LIGHT_MODES.OFF


func high_beam_toggle() -> void:
	if highbeam_l.visible:
		highbeam_l.visible = false
		highbeam_r.visible = false
	else:
		highbeam_l.visible = true
		highbeam_r.visible = true


func _input(event):
	if event.is_action_pressed("LightsToggle"):
		toggle()
	
	if event.is_action_pressed("HighBeamToggle"):
		high_beam_toggle()


func set_mesh_and_material_index(mesh: MeshInstance3D, index: int) -> void:
	body_mesh = mesh
	headlight_material = body_mesh.get_active_material(index)
	headlight_material.emission = Color.WHITE