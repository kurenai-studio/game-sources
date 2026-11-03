local save = {}

local filename = sys.get_save_file("My Bank Swapped All Its Tellers for Toasters", "save.dat")

local saved = {}

function save.load()
	local data = sys.load(filename)
	if data then
		saved = data
	end
end

function save.get(key)
	return saved[key]
end

function save.set(key, value)
	if saved[key] == value then
		return
	end
	saved[key] = value
	saved.timestamp = os.time()
	sys.save(filename, saved)
end

save.load()

return save