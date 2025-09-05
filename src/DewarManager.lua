DewarManager = {}

local DewarManager_mt = Class(DewarManager)


function DewarManager.new()

	local self = setmetatable({}, DewarManager_mt)

	self.farms = {}

	return self

end


function DewarManager:addDewar(farmId, dewar)

	if self.farms[farmId] == nil then self.farms[farmId] = {} end

	local farm = self.farms[farmId]
	local typeIndex = dewar.animal.typeIndex

	if farm[typeIndex] == nil then farm[typeIndex] = {} end

	table.insert(farm[typeIndex], dewar)

end


function DewarManager:removeDewar(farmId, dewar)

	local typeIndex = dewar.animal.typeIndex

	if self.farms[farmId] == nil or self.farms[farmId][typeIndex] == nil then return end

	local id = dewar:getUniqueId()

	for i, object in pairs(self.farms[farmId][typeIndex]) do

		if object:getUniqueId() == id then
			table.remove(self.farms[farmId][typeIndex], i)
			return
		end

	end

end


function DewarManager:getDewarsByFarm(farmId)

	return self.farms[farmId]

end


g_dewarManager = DewarManager.new()