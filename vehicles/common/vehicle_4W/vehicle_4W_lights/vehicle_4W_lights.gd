extends Node3D

@export_category("References")
@export var car_body_mesh_node: NodePath
@export var lowbeam_l_node: NodePath
@export var lowbeam_r_node: NodePath
@export var highbeam_l_node: NodePath
@export var highbeam_r_node: NodePath

@export_category("Material")
@export var headlight_mat_index: int = 0

var car_body_mesh: MeshInstance3D
var lowbeam_l: SpotLight3D
var lowbeam_r: SpotLight3D
var highbeam_l: SpotLight3D
var highbeam_r: SpotLight3D

var light_mode: GlobalEnums.LIGHT_MODES
var body_mesh: MeshInstance3D
var headlight_material: Material

var headlight_mat_set: bool = false

var engine_state: GlobalEnums.ENGINE_STATES = GlobalEnums.ENGINE_STATES.OFF



# Called when the node enters the scene tree for the first time.
func _ready():
	# Get nodes from NodePath
	if car_body_mesh_node:
		car_body_mesh = get_node(car_body_mesh_node) as MeshInstance3D
		set_mesh_and_material_index(car_body_mesh, headlight_mat_index)
		headlight_mat_set = true
	if lowbeam_l_node:
		lowbeam_l = get_node(lowbeam_l_node) as SpotLight3D
	if lowbeam_r_node:
		lowbeam_r = get_node(lowbeam_r_node) as SpotLight3D
	if highbeam_l_node:
		highbeam_l = get_node(highbeam_l_node) as SpotLight3D
	if highbeam_r_node:
		highbeam_r = get_node(highbeam_r_node) as SpotLight3D
	
	# Set light mode to OFF
	light_mode = GlobalEnums.LIGHT_MODES.OFF
	
	# Subscribe to engine state changed signal
	SignalManager.engine_state_changed.connect(change_engine_state)


func change_engine_state(state: GlobalEnums.ENGINE_STATES) -> void:
	if state == GlobalEnums.ENGINE_STATES.OFF:
		engine_state = GlobalEnums.ENGINE_STATES.OFF
		if visible:
			visible = false
		if headlight_mat_set:
			headlight_material.emission_enabled = false
			headlight_material.emission_energy_multiplier = 1
	elif state == GlobalEnums.ENGINE_STATES.ELECTRICITY:
		engine_state = GlobalEnums.ENGINE_STATES.ELECTRICITY
		if visible:
			visible = false
		if headlight_mat_set and light_mode == GlobalEnums.LIGHT_MODES.PARK:
			headlight_material.emission_enabled = true
			headlight_material.emission_energy_multiplier = 1
	elif state == GlobalEnums.ENGINE_STATES.RUNNING:
		engine_state = GlobalEnums.ENGINE_STATES.RUNNING
		if light_mode == GlobalEnums.LIGHT_MODES.MAIN:
			visible = true


func toggle() -> void:
	if light_mode == GlobalEnums.LIGHT_MODES.OFF:
		headlight_mode_park()
	elif light_mode == GlobalEnums.LIGHT_MODES.PARK:
		headlight_mode_main()
	elif light_mode == GlobalEnums.LIGHT_MODES.MAIN:
		headlight_mode_off()


func headlight_mode_off() -> void:
	SignalManager.vehicle_light_mode_changed.emit(light_mode)
	visible = false
	light_mode = GlobalEnums.LIGHT_MODES.OFF
	if headlight_mat_set:
		headlight_material.emission_enabled = false
		headlight_material.emission_energy_multiplier = 1


func headlight_mode_park() -> void:
	SignalManager.vehicle_light_mode_changed.emit(light_mode)
	if engine_state != GlobalEnums.ENGINE_STATES.OFF:
		visible = false
		light_mode = GlobalEnums.LIGHT_MODES.PARK
		if headlight_mat_set and engine_state != GlobalEnums.ENGINE_STATES.OFF:
			headlight_material.emission_enabled = true
			headlight_material.emission_energy_multiplier = 1


func headlight_mode_main() -> void:
	SignalManager.vehicle_light_mode_changed.emit(light_mode)
	if engine_state != GlobalEnums.ENGINE_STATES.OFF:
		visible = true
		light_mode = GlobalEnums.LIGHT_MODES.MAIN
		if headlight_mat_set and engine_state != GlobalEnums.ENGINE_STATES.OFF:
			headlight_material.emission_enabled = true
			headlight_material.emission_energy_multiplier = 10


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
		toggle()
	
	if event.is_action_pressed("HighBeamToggle"):
		high_beam_toggle()


func set_mesh_and_material_index(mesh: MeshInstance3D, index: int) -> void:
	body_mesh = mesh
	headlight_material = body_mesh.get_active_material(index)
	headlight_material.emission = Color.WHITE
