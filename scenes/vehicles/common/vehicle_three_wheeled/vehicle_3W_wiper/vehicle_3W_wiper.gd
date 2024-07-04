extends Node3D

enum INTERACTION_STATE { OFF, SINGLE, CONTINUOUS, RAPID}

@export_category("Mesh")
## Mesh resource for the wiper
@export var wiper_meshres: Resource

@export_category("Rotation Params")
## Maximum angle that the wiper rotates from the starting position
@export var max_rotate_angle: float = 82.0
## Delay after which the wiper starts again in the SINGLE wiper mode
@export var restart_delay: float = 3.0
## Rotation speed of the wiper in the SINGLE and CONTINUOUS states (degrees per second)
@export var low_rotation_speed: float = 120
## Rotation speed of the wiper in the RAPID state (degrees per second)
@export var high_rotation_speed: float = 200

@onready var wiper_mesh = $WiperMesh
@onready var mouse_handle = $MouseHandle

var state: INTERACTION_STATE

var anim_length: float
var current_tween: Tween
var is_first_tween_step: bool = true
var tween_timer: float = 0.0



func _ready():
	# Set the mesh of the MeshInstance3D if not set
	if wiper_mesh.mesh == null:
		if wiper_meshres == null:
			print("ERROR @ Node " + name + ": Wiper mesh not set in the inspector")
			return
		else:
			wiper_mesh.mesh = wiper_meshres
	
	# Set the default interaction state
	state = INTERACTION_STATE.OFF
	
	# Connect the mouse handle click signal
	mouse_handle.mouse_clicked.connect(toggle)
	


func toggle() -> void:
	if state == INTERACTION_STATE.OFF:
		wiper_single_state()
	elif state == INTERACTION_STATE.SINGLE:
		wiper_continuous_state()
	elif state == INTERACTION_STATE.CONTINUOUS:
		wiper_rapid_state()
	elif state == INTERACTION_STATE.RAPID:
		wiper_off_state()





func wiper_single_state() -> void:
	# Set tween anim length
	anim_length = abs(max_rotate_angle) / low_rotation_speed
	
	# Set state to SINGLE
	state = INTERACTION_STATE.SINGLE
	
	var tween = create_tween().set_loops()
	tween.connect("step_finished", on_tween_step_finished)
	tween.tween_property(
		self,
		"rotation_degrees:y",
		max_rotate_angle,
		anim_length
	)
	tween.tween_property(
		self,
		"rotation_degrees:y",
		0.0,
		anim_length
	)
	tween.tween_interval(restart_delay)
	current_tween = tween


func wiper_continuous_state() -> void:
	
	# Wait for SINGLE tween to complete
	await wait_for_low_speed_tween_completed()
	
	# Set tween anim length
	anim_length = abs(max_rotate_angle) / low_rotation_speed
	
	# Change state to CONTINUOUS
	state = INTERACTION_STATE.CONTINUOUS
	
	var tween = create_tween().set_loops()
	tween.connect("step_finished", on_tween_step_finished)
	tween.tween_property(
		self,
		"rotation_degrees:y",
		max_rotate_angle,
		anim_length
	)
	tween.tween_property(
		self,
		"rotation_degrees:y",
		0.0,
		anim_length
	)
	current_tween = tween


func wiper_rapid_state() -> void:
	
	if is_first_tween_step:
		
		current_tween.kill()
		
		# Set tween anim length
		anim_length = (max_rotate_angle - rotation_degrees.y) / high_rotation_speed
		
		# Set state to SINGLE
		state = INTERACTION_STATE.RAPID
		
		var tween = create_tween()
		tween.connect("step_finished", on_tween_step_finished)
		tween.connect("finished", wiper_rapid_state_from_zero)
		tween.tween_property(
			self,
			"rotation_degrees:y",
			max_rotate_angle,
			anim_length
		).from_current()
		tween.tween_property(
			self,
			"rotation_degrees:y",
			0.0,
			anim_length
		)
		current_tween = tween
	else:
		current_tween.kill()
		
		# Set tween anim length
		anim_length = rotation_degrees.y / high_rotation_speed
		
		# Set state to SINGLE
		state = INTERACTION_STATE.RAPID
		
		var tween = create_tween()
		tween.connect("step_finished", on_tween_step_finished)
		tween.connect("finished", wiper_rapid_state_from_zero)
		tween.tween_property(
			self,
			"rotation_degrees:y",
			0.0,
			anim_length
		).from_current()
		current_tween = tween


func wiper_rapid_state_from_zero() -> void:

	# Set tween anim length
	anim_length = abs(max_rotate_angle) / high_rotation_speed
	
	# Kill the temporary tween
	current_tween.kill()
	
	var tween = create_tween().set_loops()
	tween.connect("step_finished", on_tween_step_finished)
	tween.tween_property(
		self,
		"rotation_degrees:y",
		max_rotate_angle,
		anim_length
	)
	tween.tween_property(
		self,
		"rotation_degrees:y",
		0.0,
		anim_length
	)
	current_tween = tween


func wiper_off_state() -> void:
	if is_first_tween_step:
		current_tween.kill()
		
		state = INTERACTION_STATE.OFF
		
		# Set tween anim length
		anim_length = (max_rotate_angle - rotation_degrees.y) / low_rotation_speed
		
		var tween = create_tween()
		tween.tween_property(
			self,
			"rotation_degrees:y",
			max_rotate_angle,
			anim_length
		).from_current()
		tween.tween_property(
			self,
			"rotation_degrees:y",
			0.0,
			anim_length
		)
		current_tween = tween
	else:
		current_tween.kill()
		
		state = INTERACTION_STATE.OFF
		
		# Set tween anim length
		anim_length = rotation_degrees.y / low_rotation_speed
		
		var tween = create_tween()
		tween.tween_property(
			self,
			"rotation_degrees:y",
			0.0,
			anim_length
		).from_current()
		current_tween = tween


func wait_for_low_speed_tween_completed() -> void:
	if is_first_tween_step:
		var remaining_time = (max_rotate_angle - rotation_degrees.y) / low_rotation_speed
		await get_tree().create_timer(remaining_time).timeout
		await get_tree().create_timer(anim_length).timeout
		current_tween.kill()
	else:
		var remaining_time = rotation_degrees.y / low_rotation_speed
		await get_tree().create_timer(remaining_time).timeout
		current_tween.kill()


func on_tween_step_finished(idx: int):
	if idx == 0:
		is_first_tween_step = false
	else:
		is_first_tween_step = true
