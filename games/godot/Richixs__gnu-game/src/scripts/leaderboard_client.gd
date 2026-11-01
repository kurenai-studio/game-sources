extends Node

signal submit_score_succeeded(initials: String, score: int, response: Dictionary)
signal scores_loaded(scores: Array, scope: String, date_str: String, from_cache: bool)
signal request_error(message: String, http_code: int, context: Dictionary)

const DEFAULT_BASE_URL := "https://api.gnu.scesi.dev"
const SCORES_PATH := "/scores"
const DEFAULT_TIMEOUT_SECONDS := 8.0
const DEFAULT_MAX_RETRIES := 2
const DEFAULT_RETRY_DELAY_SECONDS := 0.35
const SUBMIT_DEBOUNCE_MS := 1500
const DEVELOPMENT_SECRET_SALT := "gnu-game-secret-salt"
const ENV_BASE_URL := "LEADERBOARD_BASE_URL"
const ENV_DEV_SECRET_SALT := "LEADERBOARD_SECRET_SALT"

class RequestJob:
	extends RefCounted
	signal completed

	var key: String = ""
	var request_type: String = ""
	var method: int = HTTPClient.METHOD_GET
	var url: String = ""
	var body: String = ""
	var headers: PackedStringArray = PackedStringArray()
	var context: Dictionary = {}
	var result: Dictionary = {}

@export var base_url: String = DEFAULT_BASE_URL
@export var request_timeout_seconds: float = DEFAULT_TIMEOUT_SECONDS
@export var max_retries: int = DEFAULT_MAX_RETRIES
@export var retry_delay_seconds: float = DEFAULT_RETRY_DELAY_SECONDS

var development_secret_salt: String = ""

var _request: HTTPRequest
var _queue: Array[RequestJob] = []
var _jobs_by_key: Dictionary = {}
var _cache: Dictionary = {}
var _processing_queue: bool = false
var _submit_debounce_until_msec: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_runtime_config()
	_request = HTTPRequest.new()
	_request.process_mode = Node.PROCESS_MODE_ALWAYS
	_request.use_threads = true
	_request.timeout = request_timeout_seconds
	add_child(_request)

func _apply_runtime_config() -> void:
	set_base_url(DEFAULT_BASE_URL)
	configure_development_salt(DEVELOPMENT_SECRET_SALT)

	var env_base_url := OS.get_environment(ENV_BASE_URL).strip_edges()
	if not env_base_url.is_empty():
		set_base_url(env_base_url)

	var env_salt := OS.get_environment(ENV_DEV_SECRET_SALT).strip_edges()
	if not env_salt.is_empty():
		configure_development_salt(env_salt)

func configure_development_salt(secret_salt: String) -> void:
	development_secret_salt = secret_salt.strip_edges()

func set_base_url(url: String) -> void:
	base_url = _normalize_base_url(url)

func submit_score(initials: String, score: int) -> Dictionary:
	var normalized_initials := _normalize_initials(initials)
	if normalized_initials.is_empty():
		return _emit_and_return_error("Initials inválidas. Usa exactamente 3 letras mayúsculas.", 0, {
			"operation": "submit_score",
			"initials": initials
		})

	if score < 0:
		return _emit_and_return_error("El score no puede ser negativo.", 0, {
			"operation": "submit_score",
			"initials": normalized_initials,
			"score": score
		})

	if not _can_sign_client_requests():
		return _emit_and_return_error("No hay SECRET_SALT configurado para el modo desarrollo. En producción, firma el request en tu backend intermedio.", 0, {
			"operation": "submit_score",
			"initials": normalized_initials,
			"score": score
		})

	var now_msec := Time.get_ticks_msec()
	if now_msec < _submit_debounce_until_msec:
		return _emit_and_return_error("Espera un momento antes de reenviar el score.", 0, {
			"operation": "submit_score",
			"initials": normalized_initials,
			"score": score,
			"reason": "debounce"
		})
	_submit_debounce_until_msec = now_msec + SUBMIT_DEBOUNCE_MS

	var body_payload := {
		"initials": normalized_initials,
		"score": score,
		"hash": _build_hash(normalized_initials, score)
	}
	var request_body := JSON.stringify(body_payload)
	var job := _queue_request("submit_score:%s:%d" % [normalized_initials, score], "submit_score", HTTPClient.METHOD_POST, _build_scores_url(), request_body, _json_headers(), {
		"initials": normalized_initials,
		"score": score
	})
	await job.completed
	return job.result

func get_top_all() -> Dictionary:
	var cache_key := "scores:all"
	var job := _queue_request(cache_key, "get_top_all", HTTPClient.METHOD_GET, _build_scores_url(), "", _json_headers(), {
		"scope": "all",
		"date": ""
	})
	await job.completed
	return job.result

func get_top_by_date(date_str: String) -> Dictionary:
	var normalized_date := date_str.strip_edges()
	if not _is_valid_date(normalized_date):
		return _emit_and_return_error("Fecha inválida. Usa el formato YYYY-MM-DD.", 0, {
			"operation": "get_top_by_date",
			"date": date_str
		})

	var cache_key := "scores:%s" % normalized_date
	var request_url := _build_scores_url(normalized_date)
	var job := _queue_request(cache_key, "get_top_by_date", HTTPClient.METHOD_GET, request_url, "", _json_headers(), {
		"scope": "date",
		"date": normalized_date
	})
	await job.completed
	return job.result

func clear_cache() -> void:
	_cache.clear()

func _queue_request(key: String, request_type: String, method: int, url: String, body: String, headers: PackedStringArray, context: Dictionary) -> RequestJob:
	if _jobs_by_key.has(key):
		return _jobs_by_key[key]

	var job := RequestJob.new()
	job.key = key
	job.request_type = request_type
	job.method = method
	job.url = url
	job.body = body
	job.headers = headers
	job.context = context

	_jobs_by_key[key] = job
	_queue.append(job)
	call_deferred("_process_queue")
	return job

func _process_queue() -> void:
	if _processing_queue:
		return

	_processing_queue = true
	while not _queue.is_empty():
		var job: RequestJob = _queue.pop_front()
		if job == null:
			continue

		job.result = await _perform_job(job)
		if job.result.get("ok", false) and job.request_type.begins_with("get_top"):
			_cache[job.key] = job.result.duplicate(true)

		_jobs_by_key.erase(job.key)
		job.completed.emit()

	_processing_queue = false

func _perform_job(job: RequestJob) -> Dictionary:
	var cache_hit: Dictionary = _cache.get(job.key, {})
	if cache_hit is not Dictionary:
		cache_hit = {}
	if job.method == HTTPClient.METHOD_GET and cache_hit is Dictionary and cache_hit.get("ok", false):
		var cached_result: Dictionary = cache_hit.duplicate(true)
		cached_result["from_cache"] = true
		_emit_scores_loaded(cached_result)
		return cached_result

	var attempt := 0
	while attempt <= max_retries:
		var response := await _send_http_request(job)
		if response.get("ok", false):
			if job.method == HTTPClient.METHOD_GET:
				response["from_cache"] = false
				_cache[job.key] = response.duplicate(true)
				_emit_scores_loaded(response)
			elif job.request_type == "submit_score":
				_emit_submit_success(job, response)
			return response

		if not response.get("retryable", false) or attempt >= max_retries:
			if job.method == HTTPClient.METHOD_GET:
				var fallback := _get_cached_fallback(job)
				if not fallback.is_empty():
					fallback["from_cache"] = true
					fallback["stale"] = true
					fallback["fallback_reason"] = response.get("message", "")
					_emit_scores_loaded(fallback)
					return fallback
			_emit_request_error(response.get("message", "Error desconocido"), int(response.get("http_code", 0)), job.context)
			return response

		attempt += 1
		if retry_delay_seconds > 0.0:
			await get_tree().create_timer(retry_delay_seconds).timeout

	return {
		"ok": false,
		"message": "No se pudo completar la solicitud.",
		"http_code": 0,
		"retryable": false,
		"context": job.context
	}

func _send_http_request(job: RequestJob) -> Dictionary:
	if _request == null:
		return _build_failure("El cliente HTTP no está listo.", 0, false, job.context)

	_request.timeout = request_timeout_seconds

	var error_code: int = OK
	if job.method == HTTPClient.METHOD_GET:
		error_code = _request.request(job.url, job.headers, HTTPClient.METHOD_GET)
	else:
		error_code = _request.request(job.url, job.headers, HTTPClient.METHOD_POST, job.body)

	if error_code != OK:
		return _build_failure("No se pudo iniciar la request: %s" % error_string(error_code), 0, true, job.context)

	var completed: Array = await _request.request_completed
	var request_result: int = completed[0]
	var response_code: int = completed[1]
	var response_body: PackedByteArray = completed[3]

	if request_result != HTTPRequest.RESULT_SUCCESS:
		return _build_failure(_http_result_message(request_result), response_code, _is_retryable_http_result(request_result), job.context)

	if response_code < 200 or response_code >= 300:
		return _build_failure(_http_error_message(response_code), response_code, _is_retryable_status_code(response_code), job.context)

	var body_text := response_body.get_string_from_utf8().strip_edges()
	if body_text.is_empty():
		var empty_result := {
			"ok": true,
			"http_code": response_code,
			"data": {},
			"scores": []
		}
		if job.method == HTTPClient.METHOD_GET:
			empty_result["scores"] = []
		return empty_result

	var parsed := _parse_json(body_text)
	if not parsed["ok"]:
		return _build_failure(parsed["message"], response_code, false, job.context)

	var parsed_data: Variant = parsed["data"]
	var normalized_scores := _normalize_scores(parsed_data)

	return {
		"ok": true,
		"http_code": response_code,
		"data": parsed_data,
		"scores": normalized_scores,
		"context": job.context
	}

func _parse_json(body_text: String) -> Dictionary:
	var parser := JSON.new()
	var parse_error := parser.parse(body_text)
	if parse_error != OK:
		return {
			"ok": false,
			"message": "Respuesta JSON inválida.",
			"error_code": parse_error
		}

	return {
		"ok": true,
		"data": parser.data
	}

func _emit_scores_loaded(response: Dictionary) -> void:
	var scores := _normalize_scores(response.get("data", []))
	var context: Dictionary = response.get("context", {})
	var scope := String(context.get("scope", "all"))
	var date_str := String(context.get("date", ""))
	scores_loaded.emit(scores, scope, date_str, bool(response.get("from_cache", false)))

func _emit_submit_success(job: RequestJob, response: Dictionary) -> void:
	var initials := String(job.context.get("initials", ""))
	var score := int(job.context.get("score", 0))
	submit_score_succeeded.emit(initials, score, response)

func _emit_request_error(message: String, http_code: int, context: Dictionary) -> void:
	request_error.emit(message, http_code, context)

func _emit_and_return_error(message: String, http_code: int, context: Dictionary) -> Dictionary:
	_emit_request_error(message, http_code, context)
	return {
		"ok": false,
		"message": message,
		"http_code": http_code,
		"retryable": false,
		"context": context
	}

func _build_failure(message: String, http_code: int, retryable: bool, context: Dictionary) -> Dictionary:
	return {
		"ok": false,
		"message": message,
		"http_code": http_code,
		"retryable": retryable,
		"context": context
	}

func _get_cached_fallback(job: RequestJob) -> Dictionary:
	var cached_result: Dictionary = _cache.get(job.key, {})
	if cached_result is Dictionary and not cached_result.is_empty():
		return cached_result.duplicate(true)
	return {}

func _normalize_scores(raw_scores: Variant) -> Array:
	var source_scores: Array = []
	if raw_scores is Array:
		source_scores = raw_scores
	elif raw_scores is Dictionary:
		var score_container: Variant = raw_scores.get("scores", raw_scores.get("data", raw_scores.get("items", [])))
		if score_container is Array:
			source_scores = score_container

	var normalized_scores: Array = []
	for entry in source_scores:
		if entry is Dictionary:
			normalized_scores.append({
				"initials": String(entry.get("initials", entry.get("name", ""))).to_upper(),
				"score": int(entry.get("score", 0)),
				"date": String(entry.get("date", ""))
			})

	return normalized_scores

func _normalize_initials(initials: String) -> String:
	var normalized := initials.strip_edges().to_upper()
	if not _is_valid_initials(normalized):
		return ""
	return normalized

func _is_valid_initials(initials: String) -> bool:
	if initials.length() != 3:
		return false
	for character_index in initials.length():
		var character := initials.substr(character_index, 1)
		if character < "A" or character > "Z":
			return false
	return true

func _is_valid_date(date_str: String) -> bool:
	if date_str.length() != 10:
		return false
	if date_str[4] != "-" or date_str[7] != "-":
		return false
	for index in [0, 1, 2, 3, 5, 6, 8, 9]:
		var character := date_str.substr(index, 1)
		if character < "0" or character > "9":
			return false
	return true

func _build_hash(initials: String, score: int) -> String:
	return ("%s%d%s" % [initials, score, development_secret_salt]).sha256_text()

func _can_sign_client_requests() -> bool:
	return not development_secret_salt.strip_edges().is_empty()

func _build_scores_url(date_str: String = "") -> String:
	var normalized_base := _normalize_base_url(base_url)
	var url := "%s%s" % [normalized_base, SCORES_PATH]
	if not date_str.is_empty():
		url += "?date=%s" % date_str
	return url

func _normalize_base_url(url: String) -> String:
	var normalized := url.strip_edges()
	while normalized.ends_with("/"):
		normalized = normalized.substr(0, normalized.length() - 1)
	return normalized

func _json_headers() -> PackedStringArray:
	return PackedStringArray([
		"Accept: application/json",
		"Content-Type: application/json"
	])

func _http_result_message(result_code: int) -> String:
	match result_code:
		HTTPRequest.RESULT_CANT_CONNECT:
			return "No se pudo conectar con la API."
		HTTPRequest.RESULT_CANT_RESOLVE:
			return "No se pudo resolver la URL de la API."
		HTTPRequest.RESULT_CONNECTION_ERROR:
			return "Error de conexión con la API."
		HTTPRequest.RESULT_CHUNKED_BODY_SIZE_MISMATCH:
			return "La respuesta llegó corrupta."
		HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED:
			return "La respuesta excedió el límite permitido."
		HTTPRequest.RESULT_TIMEOUT:
			return "La request expiró por timeout."
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			return "Falló el handshake TLS."
		_:
			return "Falló la request HTTP."

func _http_error_message(http_code: int) -> String:
	match http_code:
		403:
			return "Hash inválido. En producción firma desde tu backend intermedio."
		429:
			return "Rate limit excedido. Espera un minuto antes de reenviar."
		400:
			return "Solicitud inválida."
		500, 502, 503, 504:
			return "Error temporal del servidor."
		_:
			return "La API respondió con error HTTP %d." % http_code

func _is_retryable_http_result(result_code: int) -> bool:
	match result_code:
		HTTPRequest.RESULT_TIMEOUT, HTTPRequest.RESULT_CANT_CONNECT, HTTPRequest.RESULT_CANT_RESOLVE, HTTPRequest.RESULT_CONNECTION_ERROR, HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			return true
		_:
			return false

func _is_retryable_status_code(http_code: int) -> bool:
	return http_code >= 500 and http_code <= 599
