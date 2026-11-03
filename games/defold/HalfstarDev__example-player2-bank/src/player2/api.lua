local api = {}

local http_request = http.request
local json_decode = json.decode
local json_encode = json.encode

local JSON = "application/json"
local WEB_HOST = "https://api.player2.game/v1"
local LOCAL_HOST = "http://127.0.0.1:4315/v1"

local game_key = sys.get_config_string("player2.key") or sys.get_config_string("project.title", "Defold")
local game_client_id = sys.get_config_string("player2.id")
local host = WEB_HOST
local api_key

api.ROLE_SYSTEM = "system"
api.ROLE_USER = "user"
api.ROLE_ASSISTANT = "assistant"
api.ROLE_DEVELOPER = "developer"
api.ROLE_TOOL = "tool"
api.OK = 200

api.response_codes = {
	[0]   =   "0: HTTP request failed.",
	[200] = "200: OK.",
	[400] = "400: Bad Request.",
	[401] = "401: The user must be authenticated in the Player2 App.",
	[402] = "402: Insufficient credits to complete the request.",
	[404] = "404: Not found.",
	[409] = "409: Conflict.",
	[429] = "429: Too many requests have been made to the server.",
	[500] = "500: Internal server error.",
	[503] = "503: Service unavailable.",
}

local status_retry = {
	[429] = true,
	[500] = true,
	[503] = true,
}
local retries = {1, 2, 4}

local header_get = {
	["player2-game-key"] = game_key,
	["Accept"] = JSON,
}

local header_post = {
	["player2-game-key"] = game_key,
	["Content-Type"] = JSON,
}

local request_options = {
	report_progress = false,
	timeout = 60,
}

local function get_url()
	if html5 then
		return html5.run("window.location")
	end
end

local function get_domain()
	if html5 then
		return string.match(get_url(), "//([^/]*)/")
	end
end

local function get_game_client_id()
	if game_client_id then
		return game_client_id
	end
	if html5 then
		local id = string.match(get_url(), "https://player2.game/discover/games/([%w-]*)")
		if id then
			game_client_id = id
			return id
		end
	end
end

local function is_on_player2()
	if html5 then
		return get_domain() == "games.player2.game"
	end
end

local function request(endpoint, method, callback, header, data, retry)
	local function wrapped_callback(self, _, response)
		-- Retry request for statues that can be solved by waiting
		if status_retry[response.status] then
			retry = (retry or 0) + 1
			local delay = retries[retry]
			if delay then
				timer.delay(delay, false, function()
					request(endpoint, method, callback, header, data, retry)
				end)
				return
			end
		end
		if callback then
			if response.status == api.OK and response.response then
				local decoded = json_decode(response.response)
				callback(decoded, nil)
			else
				callback(nil, response)
			end
		end
	end
	if data and type(data) == "table" then
		data = json_encode(data)
	end
	http_request(host..endpoint, method, wrapped_callback, header, data, request_options)
end

local function post_request(endpoint, data, callback, header)
	request(endpoint, "POST", callback, header or header_post, data)
end

local function get_request(endpoint, callback, header)
	request(endpoint, "GET", callback, header or header_get)
end

function api.chat_post_completions(data, callback)
	post_request("/chat/completions", data, callback)
end

function api.health(callback)
	get_request("/health", callback)
end

function api.stt_start(data, callback)
	post_request("/stt/start", data, callback)
end

function api.stt_stop(callback)
	post_request("/stt/stop", nil, callback)
end

function api.stt_get_language(callback)
	get_request("/stt/language", callback)
end

function api.stt_post_language(data, callback)
	post_request("/stt/language", data, callback)
end

function api.stt_languages(callback)
	get_request("/stt/languages", callback)
end

function api.tts_speak(data, callback)
	post_request("/tts/speak", data, callback)
end

function api.tts_stop(callback)
	post_request("/tts/stop", callback)
end

function api.tts_voices(callback)
	get_request("/tts/voices", callback)
end

function api.tts_get_volume(callback)
	get_request("/tts/volume", callback)
end

function api.tts_post_volume(data, callback)
	post_request("/tts/volume", data, callback)
end

function api.selected_characters(callback)
	get_request("/selected_characters", callback)
end

local function set_api_key(key, callback)
	api_key = key
	header_post["Authorization"] = "Bearer "..api_key
	header_get["Authorization"] = "Bearer "..api_key
	if callback then
		callback(key)
	end
end

local function poll_token(device_code, interval, callback)
	http_request(WEB_HOST.."/login/device/token", "POST", function(self, _, response)
		if response and response.status == 200 and response.response and #response.response > 0 then
			local decoded = json_decode(response.response)
			set_api_key(decoded.p2Key, callback)
			host = WEB_HOST
		else
			timer.delay(interval, false, function() poll_token(device_code, interval, callback) end)
		end
	end, header_post, json_encode({
		client_id = get_game_client_id(),
		device_code = device_code,
		grant_type = "urn:ietf:params:oauth:grant-type:device_code",
	}), request_options)
end

local function web_login(callback)
	http_request(WEB_HOST.."/login/device/new", "POST", function(self, _, response)
		if response and response.status == 200 and response.response and #response.response > 0 then
			local decoded = json_decode(response.response)
			sys.open_url(decoded.verificationUriComplete, {target = "_blank"})
			local interval = (decoded.interval or 5) + 0.1
			local device_code = decoded.deviceCode
			timer.delay(interval, false, function() poll_token(device_code, interval, callback) end)
		else
			timer.delay(5, false, function() web_login(callback) end)
		end
	end, header_post, json_encode({client_id = get_game_client_id()}), request_options)
end

local function local_login(callback)
	http_request(LOCAL_HOST.."/login/web/"..get_game_client_id(), "POST", function(self, _, response)
		if response and response.response and #response.response > 0 then
			local decoded = json_decode(response.response)
			set_api_key(decoded.p2Key, callback)
			host = LOCAL_HOST
		else
			web_login(callback)
		end
	end, header_post, nil, request_options)
end

function api.login(p2key, callback)
	if is_on_player2() then
		return
	elseif p2key then
		set_api_key(p2key)
	else
		local_login(callback)
		--web_login(callback)
	end
end

return api
