local tts = {}

local api = require "player2.api"

local speak = api.tts_speak
local stop = api.tts_stop
local get_volume = api.tts_get_volume
local set_volume = api.tts_post_volume
local get_voices = api.tts_voices
local msg_post = msg.post
local msg_url = msg.url

local voices = {
	-- american_english
	-- female
	Abigail = "01955d76-ed5b-7468-83a7-bfc267cf4849",
	Amelia = "01955d76-ed5b-7441-a184-5f5ee015e4fe",
	Ava = "01955d76-ed5b-7436-a182-c4d21aaca9fc",
	Charlotte = "01955d76-ed5b-7451-92d6-5ef579d3ed28",
	Chloe = "01955d76-ed5b-7480-951c-af1dd9873e34",
	Evelyn = "01955d76-ed5b-745d-add1-b755d440192d",
	Madison = "01955d76-ed5b-7407-a03c-cdd993439ba4",
	Mia = "01955d76-ed5b-7474-86b2-a41b310c2a2d",
	Olivia = "01955d76-ed5b-7426-8748-4b0e5aea1974",
	Sophia = "01955d76-ed5b-73e0-a88d-cbeb3c5b499d",
	-- male
	Benjamin = "01955d76-ed5b-74ba-89e5-2b4b45e632cd",
	Caleb = "01955d76-ed5b-74de-83e5-800a44fee0d1",
	Ethan = "01955d76-ed5b-748c-8d98-0fb708ef0fbd",
	Harper = "01955d76-ed5b-7416-82d8-5fc486e2f676",
	Jackson = "01955d76-ed5b-74d2-a33c-b2b8e998658f",
	Lucas = "01955d76-ed5b-74c6-ac15-ab68ee19d560",
	Logan = "01955d76-ed5b-74af-a2be-9302077075b8",
	Mason = "01955d76-ed5b-74a3-9129-c3253d01f690",
	Nicholas = "01955d76-ed5b-74e9-9fea-1f8cad1cd9c5",
	Noah = "01955d76-ed5b-7497-9f8e-0e7448515bf3",
}

local default_voice = voices.Sophia

local function is_or_is_in_table(x, t)
	if x == t then
		return true
	elseif type(t) == "table" then
		for _, v in pairs(t) do
			if v == x then 
				return true
			end
		end
	end
end

function tts.speak(s, options, callback)
	options = options or {}
	local speed = options.speed or 1
	local gender = options.gender or "female"
	local language = options.language or "en_US"
	local voice
	if options.voice then
		voice = voices[options.voice] or options.voice
	else
		voice = default_voice
	end
	if not s or type(s) ~= "string" then return end
	local data = {
		audio_format = "wav",
		--play_in_app = false,
		speed = speed,
		text = s,
		voice_gender = gender,
		voice_ids = {voice},
		voice_language = language,
	}
	speak(data, function(response, error)
		if callback then
			callback(response, error)
		end
	end)
end

function tts.stop()
	stop(function(response, error) end)
end

function tts.get_volume(callback)
	local sender = msg_url()
	get_volume(function(response, error)
		if response then
			if callback then
				callback(response.volume)
			else
				msg_post(sender, "tts_volume", response)
			end
		end
	end)
end

function tts.set_volume(volume)
	if not tonumber(volume) then
		return
	elseif volume < 0 then
		volume = 0
	elseif volume > 1 then
		volume = 1
	end
	local data = {
		volume = volume
	}
	set_volume(data, function(response, error) end)
end

function tts.get_voices(language, callback)
	language = language or "american_english"
	local sender = msg_url()
	get_voices(function(response, error)
		if response  then
			voices = {}
			for k, v in pairs(response.voices) do
				if not language or is_or_is_in_table(v.language, language) then
					voices[v.name] = v.id
				end
			end
			if callback then
				callback(voices)
			else
				msg_post(sender, "tts_voices", response)
			end
		end
	end)
end

function tts.set_voice(voice)
	if voice then
		default_voice = voices[voice] or voice or default_voice
	end
end

return tts