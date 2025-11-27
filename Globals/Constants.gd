extends Node
class_name CONSTANTS

# compile-time constant (accessible as CONSTANTS.DEFAULT_WAVE_FORMS)
const DEFAULT_WAVE_FORMS := {
    "SIN": {"name": "SIN", "color": Vector4(1,0,0,1.0), "tint_strength": .5},
    "TRIANGLE": {"name": "TRIANGLE", "color": Vector4(0.0, 0.0, 1.0, 1.0), "tint_strength": .5},
    "SAWTOOTH": {"name": "SAWTOOTH", "color": Vector4(0.0, 1.0, 0.0, 1.0), "tint_strength": .5},
    "SQUARE": {"name": "SQUARE", "color": Vector4(1.0, 1.0, 0.0, 1.0), "tint_strength": .5},
}

# editable copy exposed to the inspector; initialized from the constant
@export var WAVE_FORMS: Dictionary = DEFAULT_WAVE_FORMS.duplicate(true)
