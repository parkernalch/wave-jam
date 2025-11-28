extends Node
class_name CONSTANTS

# compile-time constant (accessible as CONSTANTS.DEFAULT_WAVE_FORMS)
const DEFAULT_WAVE_FORMS := {
    "SIN": {"name": "SIN", "color": Color.RED, "tint_strength": .5},
    "TRIANGLE": {"name": "TRIANGLE", "color": Color.BLUE, "tint_strength": .5},
    "SAWTOOTH": {"name": "SAWTOOTH", "color": Color.GREEN, "tint_strength": .5},
    "SQUARE": {"name": "SQUARE", "color": Color.YELLOW, "tint_strength": .5},
}

# editable copy exposed to the inspector; initialized from the constant
@export var WAVE_FORMS: Dictionary = DEFAULT_WAVE_FORMS.duplicate(true)
