local system = {}

local api = require "player2.api"

local api_health = api.health

local SYSTEM_NAME = sys.get_sys_info().system_name 
local APP_WINDOWS = "%LocalAppData%\\Player2\\player2.exe"
local WEBSITE = "https://player2.game/"
local ping_interval = 60

local client_version
local health
local timer_handle

function system.ping(callback)
	api_health(function(response, error)
		if response then
			if response.client_version then
				health = true
				if not client_version then
					client_version = response.client_version
				end
			else
				health = false
			end
			if callback then
				callback(health, client_version)
			end
		else
			if callback then
				callback(false)
			end
		end
	end)
	return health
end

function system.init(t, callback)
	if timer_handle then
		timer.cancel(timer_handle)
	end
	local f = function() system.ping(callback) end
	f()
	timer_handle = timer.delay(t or ping_interval, true, f)
end

function system.get_health(callback)
	if callback then
		system.ping(callback)
	elseif not health then
		system.ping()
	end
	return health
end

function system.get_client_version(callback)
	if client_version then
		if callback then
			callback(client_version)
		end
		return client_version
	else
		if callback then
			system.ping(function(_, version)
				callback(version)
			end)
		else
			system.ping()
		end
	end
end

function system.start()
	if SYSTEM_NAME == "Windows" then
		return os.execute('IF EXIST '..APP_WINDOWS..' START '..APP_WINDOWS)
	end
end

function system.is_installed()
	if SYSTEM_NAME == "Windows" then
		return os.execute('IF NOT EXIST '..APP_WINDOWS..' EXIT 1') == 0
	end
end

function system.install()
	sys.open_url(WEBSITE, {target = "_blank"})
end

function system.start_if_not_running()
	system.ping(function(running)
		if not running then
			if system.is_installed() then
				system.start()
			end
		end
	end)
end

function system.show_popup()
	--msg.post("main:/player2#player2", "show")
end

return system