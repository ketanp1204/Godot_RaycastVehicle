extends Node3D

@export_category("References")
@export var lowbeam_l_node: NodePath
@export var lowbeam_r_node: NodePath
@export var highbeam_l_node: NodePath
@export var highbeam_r_node: NodePath
@export var audio_stream_player_node: NodePath

var lowbeam_l: SpotLight3D
var lowbeam_r: SpotLight3D
var highbeam_l: SpotLight3D
var highbeam_r: SpotLight3D
var audio_stream_player: AudioStreamPlayer3D

var light_mode: GlobalEnums.LIGHT_MODES
var body_mesh: MeshInstance3D
var headlight_material: Material



# Called when the node enters the scene tree for the first time.
func _ready():
	# Get nodes from NodePath
	lowbeam_l = get_node(lowbeam_l_node) as SpotLight3D
	lowbeam_r = get_node(lowbeam_r_node) as SpotLight3D
	highbeam_l = get_node(highbeam_l_node) as SpotLight3D
	highbeam_r = get_node(highbeam_r_node) as SpotLight3D
	audio_stream_player = get_node(audio_stream_player_node) as AudioStreamPlayer3D
	
	# Set light mode to OFF
	light_mode = GlobalEnums.LIGHT_MODES.OFF


func toggle() -> void:
	
	if light_mode == GlobalEnums.LIGHT_MODES.OFF:
		headlight_material.emission_enabled = true
		headlight_material.emission_energy_multiplier = 1
		visible = false
		light_mode = GlobalEnums.LIGHT_MODES.PARK
		SignalManager.vehicle_light_mode_changed.emit(light_mode)
	elif light_mode == GlobalEnums.LIGHT_MODES.PARK:
		headlight_material.emission_enabled = true
		headlight_material.emission_energy_multiplier = 10
		visible = true
		light_mode = GlobalEnums.LIGHT_MODES.MAIN
		SignalManager.vehicle_light_mode_changed.emit(light_mode)
	elif light_mode == GlobalEnums.LIGHT_MODES.MAIN:
		headlight_material.emission_enabled = false
		headlight_material.emission_energy_multiplier = 1
		visible = false
		light_mode = GlobalEnums.LIGHT_MODES.OFF
		SignalManager.vehicle_light_mode_changed.emit(light_mode)


func high_beam_toggle() -> void:
	if highbeam_l.visible:
		highbeam_l.visible = false
		highbeam_r.visible = false
		SignalManager.high_beam_changed.emit(false)
	else:
		highbeam_l.visible = true
		highbeam_r.visible = true
		SignalManager.high_beam_changed.emit(true)


func _input(event):
	if event.is_action_pressed("LightsToggle"):
		SoundManager.play_light_switch_toggle(audio_stream_player)
		toggle()
	
	if event.is_action_pressed("HighBeamToggle"):
		SoundManager.play_light_switch_toggle(audio_stream_player)
		high_beam_toggle()


func set_mesh_and_material_index(mesh: MeshInstance3D, index: int) -> void:
	body_mesh = mesh
	headlight_material = body_mesh.get_active_material(index)
	headlight_material.emission = Color.WHITE
