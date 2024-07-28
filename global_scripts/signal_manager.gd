extends Node

########## ENGINE ##########
signal engine_state_changed(state: GlobalEnums.ENGINE_STATES)


########## VEHICLE LIGHTS ##########
signal vehicle_light_mode_changed(mode: GlobalEnums.LIGHT_MODES)


########## WIPERS ##########
signal wiper_mode_changed(mode: GlobalEnums.WIPER_MODES)
signal wiper_single_to_continuous()


########## INPUT ##########
signal turn_signal_changed(mode: GlobalEnums.INDICATOR_MODES)
signal high_beam_changed(mode: bool)


func _input(event):
	if event.is_action_pressed("LeftTurnIndicator"):
		turn_signal_changed.emit(GlobalEnums.INDICATOR_MODES.LEFT)
	
	if event.is_action_pressed("RightTurnIndicator"):
		turn_signal_changed.emit(GlobalEnums.INDICATOR_MODES.RIGHT)
	
