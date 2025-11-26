extends Node
class_name GameJoltHelper

signal scores_fetched(scores)
signal request_finished(request_type, response_code)

@export var game_id: int = 1032259
@export var private_key: String = "18e050138157b1362afbfe1160582ceb"

var busy: bool = false
var request_type: String = ""

const BASE_URLS := {
	auth = 'http://gamejolt.com/api/game/v1/users/auth/',
	fetch_user = 'http://gamejolt.com/api/game/v1/users/',
	session_open = 'http://gamejolt.com/api/game/v1/sessions/open/',
	session_ping = 'http://gamejolt.com/api/game/v1/sessions/ping/',
	session_close = 'http://gamejolt.com/api/game/v1/sessions/close/',
	trophy = 'http://gamejolt.com/api/game/v1/trophies/',
	trophy_add = 'http://gamejolt.com/api/game/v1/trophies/add-achieved/',
	scores_fetch = 'http://gamejolt.com/api/game/v1/scores/',
	scores_add = 'http://gamejolt.com/api/game/v1/scores/add/',
	fetch_tables = 'http://gamejolt.com/api/game/v1/scores/tables/',
	fetch_data = 'http://gamejolt.com/api/game/v1/data-store/',
	set_data = 'http://gamejolt.com/api/game/v1/data-store/set/',
	update_data = 'http://gamejolt.com/api/game/v1/data-store/update/',
	remove_data = 'http://gamejolt.com/api/game/v1/data-store/remove/',
	get_data_keys = 'http://gamejolt.com/api/game/v1/data-store/get-keys/'
}

const PARAMETERS := {
	auth = ['*user_token=', '*username='],
	fetch_user = ['*username=', '*user_id='],
	sessions = ['*username=', '*user_token='],
	trophy_fetch = ['*username=', '*user_token=', '*achieved=', '*trophy_id='],
	trophy_add = ['*username=', '*user_token=', '*trophy_id='],
	scores_fetch = ['*username=', '*user_token=', '*limit=', '*table_id='],
	scores_add = ['*score=', '*sort=', '*username=', '*user_token=', '*guest=', '*table_id='],
	fetch_tables = [],
	fetch_data = ['*key=', '*username=', '*user_token='],
	set_data = ['*key=', '*data=', '*username=', '*user_token='],
	update_data = ['*key=', '*operation=', '*value=', '*username=', '*user_token='],
	remove_data = ['*key='],
	get_data_keys = ['*username=', '*user_token=']
}

@onready var _http_request: HTTPRequest = HTTPRequest.new()

func _ready() -> void:
	add_child(_http_request)
	# connect the request completed signal from HTTPRequest
	# Godot 4 uses `request_completed` with signature `(result, response_code, headers, body)`
	_http_request.request_completed.connect(_on_request_completed)

func add_score(score, sort, username: String = '', token: String = '', guest: String = '', table_id: int = 0) -> void:
	if busy:
		return
	var url := compose_url('scores_add/scores_add/scores_added', [score, sort, username, token, guest, table_id])
	_perform_request(url)

func _perform_request(url: String) -> void:
	busy = true
	var err := _http_request.request(url)
	if err != OK:
		busy = false
		push_warning('Failed to start HTTPRequest: %s' % str(err))


func _on_request_completed(_result, response_code, _headers, body) -> void:
	busy = false
	var out_body = body
	# In Godot 4 body is a PackedByteArray; try to convert to string if possible
	if typeof(body) == TYPE_PACKED_BYTE_ARRAY:
		# Use PackedByteArray.get_string_from_utf8() for proper decoding
		out_body = body.get_string_from_utf8()

	# Parse JSON response if this is a fetch_scores request
	if request_type == 'scores_fetched':
		var scores = _parse_scores_response(out_body)
		scores_fetched.emit(scores)

	emit_signal('request_completed', response_code, out_body)
	# Emit generic request_finished signal so callers can chain requests
	request_finished.emit(request_type, response_code)
func _parse_scores_response(body_str: String) -> Array:
	# Parse GameJolt API JSON response and extract scores
	# Expected format: { "response": { "scores": [ { "score": "...", "sort": "...", "user": "...", "guest": "...", ... }, ... ], "success": true, ... } }
	var scores = []
	var json = JSON.new()
	var error = json.parse(body_str)

	if error != OK:
		push_warning('Failed to parse JSON response: %s' % body_str)
		return scores

	var data = json.data
	if data is Dictionary and data.has('response'):
		var response = data['response']
		if response is Dictionary and response.has('scores'):
			var scores_list = response['scores']
			if scores_list is Array:
				scores = scores_list

	return scores


func fetch_scores(username: String = '', token: String = '', limit: int = 0, table_id: int = 0) -> void:
	if busy:
		return
	var url := compose_url('scores_fetch/scores_fetch/scores_fetched', [username, token, limit, table_id])
	_perform_request(url)


func compose_url(type: String, args: Array) -> String:
	# `type` encoded as '<parameters_key>/<base_key>/<request_type>' like the original code
	var types := type.split('/')
	if types.size() < 3:
		push_warning('compose_url: invalid type: %s' % type)
		return ''
	request_type = types[2]
	var base_key := types[1]
	if not BASE_URLS.has(base_key):
		push_warning('compose_url: unknown base key: %s' % base_key)
		return ''
	var final_url = BASE_URLS[base_key]
	var c := -1
	var params_key := types[0]
	var param_list := []
	if PARAMETERS.has(params_key):
		param_list = PARAMETERS[params_key]

	# GameJolt API: only include parameters that have non-empty values
	var first_param := true
	for i in param_list:
		c += 1
		var arg_val := ''
		if c < args.size():
			arg_val = str(args[c])

		# Skip empty parameters and '0' string values
		if arg_val == '' or arg_val == '0':
			continue

		# Add separator (? for first, & for rest)
		var sep := ('?' if first_param else '&')
		var parameter = i.replace('*', sep)

		# Add the parameter with its value
		final_url += parameter + _simple_percent_encode(arg_val)
		first_param = false

	# Add format and game_id
	final_url += ('?' if first_param else '&') + 'format=json'
	final_url += '&game_id=' + str(game_id)

	# GameJolt signature must be computed as MD5(url_with_params + private_key)
	var signature_str = final_url + private_key
	var signature = signature_str.md5_text()
	var final_url_with_sig = final_url + '&signature=' + signature
	return final_url_with_sig

func _simple_percent_encode(value: String) -> String:
	# Minimal percent-encoding: encode % FIRST to avoid double-encoding
	# This is intentionally conservative and avoids relying on engine helpers.
	var out := value.replace('%', '%25')
	out = out.replace(' ', '%20')
	out = out.replace('\n', '%0A')
	out = out.replace('"', '%22')
	out = out.replace('\'', '%27')
	out = out.replace('<', '%3C')
	out = out.replace('>', '%3E')
	out = out.replace('#', '%23')
	out = out.replace('{', '%7B')
	out = out.replace('}', '%7D')
	out = out.replace('|', '%7C')
	out = out.replace('\\', '%5C')
	out = out.replace('^', '%5E')
	out = out.replace('~', '%7E')
	out = out.replace('[', '%5B')
	out = out.replace(']', '%5D')
	out = out.replace('`', '%60')
	return out
