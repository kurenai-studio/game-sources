
function getSounds(folderName, type, volume)
    local sounds = {}
    for i, v in ipairs(love.filesystem.getDirectoryItems(folderName)) do
		local sound = love.audio.newSource(folderName .. "/" .. v, type)
		sound:setVolume(volume)
		table.insert(sounds, sound)
	end
    return sounds
end

--Play sound
function sound(num)
	if SOUNDS[num]:isPlaying() then
		love.audio.stop(SOUNDS[num])
	end
	love.audio.play(SOUNDS[num])
end

--Play song
function music(num, looping)
	if looping == true then
		MUSIC[num]:setLooping(true)
	else
		MUSIC[num]:setLooping(false)
	end

	if MUSIC[num]:isPlaying() then
		love.audio.stop(MUSIC[num])
	end
	love.audio.play(MUSIC[num])
end
