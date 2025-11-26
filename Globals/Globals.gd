extends Node
class_name Globals

var available_wave_forms
var time_slow_active = false
var master_volume: float = 0.0
var music_volume: float = 0.0
var sfx_volume: float = 0.0
var player_name: String = ""
var main_menu_visible = true
var settings_menu_visible = false
var high_scores_menu_visible = false
var current_wave: int = 0
var is_paused: bool = false

# Map dB range [-50, 0] to percentage [0,100].
# By default we use a linear mapping across the dB range so:
#  -50 dB -> 0%
#   0 dB -> 100%
# This keeps the slider simple for users. If you prefer a
# perceptual mapping, use `db_to_percent_perceptual` below.
func db_to_percent(db: float, min_db: float = -50.0, max_db: float = 0.0) -> float:
	var clamped = clamp(db, min_db, max_db)
	# linear interpolation across the dB range
	return ((clamped - min_db) / (max_db - min_db)) * 100.0

func percent_to_db(percent: float, min_db: float = -50.0, max_db: float = 0.0) -> float:
	var p = clamp(percent, 0.0, 100.0) / 100.0
	return lerp(min_db, max_db, p)

# Perceptual option: map dB -> linear amplitude (0..1) then to percent.
# This makes 0 dB -> 100% and -50 dB -> ~0.01% (very quiet) which
# reflects physical amplitude rather than a flat slider. Use if you want
# the percentage to represent perceived loudness more faithfully.
func db_to_percent_perceptual(db: float) -> float:
	# convert dB to linear amplitude: linear = 10^(db/20)
	var linear = pow(10.0, db / 20.0)
	return linear * 100.0

func percent_to_db_perceptual(percent: float) -> float:
	var lin = clamp(percent, 0.0, 100.0) / 100.0
	# avoid log of zero
	lin = max(lin, 1e-8)
	# convert linear to dB: db = 20 * log10(linear) == 20 * (ln(linear)/ln(10))
	return 20.0 * (log(lin) / log(10.0))


func add_score(player_name_input):
	player_name = player_name_input.text.strip_edges()

	if player_name && score.score:
			game_jolt_helper.add_score(str(score.score), str(score.score), '', '', player_name, 1045389)

