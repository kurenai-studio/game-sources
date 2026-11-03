local stt = {}

local api = require "player2.api"

local start = api.stt_start
local stop = api.stt_stop
local get_language = api.stt_get_language
local set_language = api.stt_post_language
local get_languages = api.stt_languages
local msg_post = msg.post
local msg_url = msg.url

local languages

function stt.start(timeout)
	timeout = timeout or 30
	local data = {timeout = timeout}
	start(data, function(response, error) end)
end

function stt.stop(callback)
	local sender = msg_url()
	stop(function(response, error)
		if response then
			if callback then
				callback(response.text)
			else
				msg_post(sender, "sst_text", response)
			end
		end
	end)
end

function stt.cancel()
	stop()
end

function stt.get_language(callback)
	local sender = msg_url()
	get_language(function(response, error)
		if response then
			if callback then
				callback(response)
			else
				msg_post(sender, "sst_language", response)
			end
		end
	end)
end

function stt.set_language(language)
	if not language then return end
	local data = {code = language}
	set_language(data, function(response, error) end)
end

function stt.get_languages(callback)
	if languages then
		return languages
	end
	local sender = msg_url()
	get_languages(function(response, error)
		if response then
			languages = {}
			for k, v in pairs(response.languages) do
				languages[v.code] = v.name
			end
			if callback then
				callback(languages)
			else
				msg_post(sender, "sst_languages", languages)
			end
		end
	end)
end

return stt