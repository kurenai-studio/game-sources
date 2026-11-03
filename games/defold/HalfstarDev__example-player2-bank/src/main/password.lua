local password = {}

password.DEBUG = "WSBTPZ"

local passwords = {
	[1] = "ONION",
	[2] = "MEMORY",
	[3] = "EMOTION",
	[4] = "POWER",
	[5] = "DINNER",
	[6] = "TRUTH",
	[7] = "HISTORY",
}

local index = 1

function password.get()
	return passwords[index]
end

function password.set(n)
	if passwords[n] then
		index = n
	else
		index = 1
	end
end

function password.is(s)
	return string.lower(s) == string.lower(password.get())
end

return password