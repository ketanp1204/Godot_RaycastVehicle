extends StaticBody3D
signal mouse_clicked

@onready var circle = $Circle


func _ready() -> void:
	
	# Connect hover events to show/hide the interaction circle
	mouse_entered.connect(handle_mouse_entered)
	mouse_exited.connect(handle_mouse_exited)
	
	# Connect input event to send mouse clicked signal
	input_event.connect(handle_input_event)
	
	# Hide the circle on start
	circle.visible = false


func handle_mouse_entered() -> void:
	circle.visible = true


func handle_mouse_exited() -> void:
	circle.visible = false


func handle_input_event(_camera, event, _position, _normal, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		mouse_clicked.emit()
