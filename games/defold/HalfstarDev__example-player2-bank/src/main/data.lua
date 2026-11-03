local data = {}

local cache = {}

function data.get(file)
	local path = "/data/"..file
	if cache[path] then
		return cache[path]
	else
		local loaded = sys.load_resource(path)
		if loaded then
			-- Remove CR from CRLF, as font will render it as ~
			loaded = string.gsub(loaded, string.char(13), "")
			cache[path] = loaded
			return loaded
		end
	end
end

return data