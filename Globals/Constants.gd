extends Node
class_name CONSTANTS

# compile-time constant (accessible as CONSTANTS.DEFAULT_WAVE_FORMS)
const DEFAULT_WAVE_FORMS := {
	"SIN": {"name": "SIN", "color": Color.RED},
	"TRIANGLE": {"name": "TRIANGLE", "color": Color.BLUE},
	"SAWTOOTH": {"name": "SAWTOOTH", "color": Color.GREEN},
	"SQUARE": {"name": "SQUARE", "color": Color.YELLOW},
}

# editable copy exposed to the inspector; initialized from the constant
@export var WAVE_FORMS: Dictionary = DEFAULT_WAVE_FORMS.duplicate(true)
