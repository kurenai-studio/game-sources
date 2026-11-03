local audio = {}

local url = "main:/player2/audio#audio"

function audio.play(data)
	msg.post(url, "play", {data = data})
end

function audio.speak(text)
	msg.post(url, "speak", {text = text})
end

function audio.mute()
	msg.post(url, "mute")
end

function audio.unmute()
	msg.post(url, "unmute")
end

return audio