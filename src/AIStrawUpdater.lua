AIStrawUpdater = {}

local AIStrawUpdater_mt = Class(AIStrawUpdater)

function AIStrawUpdater.new()

	local self = setmetatable({}, AIStrawUpdater_mt)

	return self

end


function AIStrawUpdater:update(dT)

	if self.straw == nil then return end

	self.straw:updateStraw(dT)

end


function AIStrawUpdater:setStraw(straw)

	self.straw = straw

end

g_aiStrawUpdater = AIStrawUpdater.new()