require("proAudioRt")
proAudio.create()
local audio = {}
audio.__index = audio
function audio:new(path)
	local c = {}
	c.path = path
	c.handle = proAudio.sampleFromFile(path)
	setmetatable(c,audio)
	return c
end
function audio:play(volume,loop)
	local volume = volume or 1
	if loop then
		proAudio.soundLoop(self.handle, volume, volume, 0, 1)
	else
		proAudio.soundPlay(self.handle, volume, volume, 0, 1)
	end
end
function audio:stop()
	if not self then proAudio.soundStop() return end
	proAudio.soundStop(self.handle)
end
function audio:setVolume(volume)
	proAudio.soundUpdate(self.handle,volume,volume)
end
function parseManager:audio()
	return audio
end