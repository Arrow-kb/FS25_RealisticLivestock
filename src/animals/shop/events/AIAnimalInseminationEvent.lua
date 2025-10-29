AIAnimalInseminationEvent = {}

local AIAnimalInseminationEvent_mt = Class(AIAnimalInseminationEvent, Event)
InitEventClass(AIAnimalInseminationEvent, "AIAnimalInseminationEvent")


function AIAnimalInseminationEvent.emptyNew()

    local self = Event.new(AIAnimalInseminationEvent_mt)
    return self

end


function AIAnimalInseminationEvent.new(object, items)

	local event = AIAnimalInseminationEvent.emptyNew()

	event.object = object
	event.items = items

	return event

end


function AIAnimalInseminationEvent:readStream(streamId, connection)

	self.object = NetworkUtil.readNodeObject(streamId)
	local numItems = streamReadUInt16(streamId)

	self.items = {}

	for i = 1, numItems do

		local identifiers = Animal.readStreamIdentifiers(streamId, connection)
		local dewarUniqueId = streamReadString(streamId)

		table.insert(self.items, { ["animal"] = identifiers, ["dewar"] = dewarUniqueId })

	end

	self:run(connection)

end


function AIAnimalInseminationEvent:writeStream(streamId, connection)

	NetworkUtil.writeNodeObject(streamId, self.object)

	streamWriteUInt16(streamId, #self.items)

	for _, item in pairs(self.items) do
		
		item.animal:writeStreamIdentifiers(streamId, connection)
		streamWriteString(item.dewar)

	end

end


function AIAnimalInseminationEvent:run(connection)

	local clusterSystem = self.object:getClusterSystem()
	local farmId = self.object:getOwnerFarmId()
	local farmDewars = g_dewarManager:getDewarsByFarm(farmId)

	if farmDewars == nil then return end

	for i, item in pairs(self.items) do
	
		local dewars = farmDewars[item.animal.animalTypeIndex]

		if dewars == nil or #dewars == 0 then continue end

		local identifiers = item.animal

		for _, dewar in pairs(dewars) do

			if dewar:getUniqueId() == item.dewar then

				for _, animal in pairs(clusterSystem.animals) do

					if animal.farmId == identifiers.farmId and animal.uniqueId == identifiers.uniqueId and animal.birthday.country == (identifiers.country or identifiers.birthday.country) then
					
						animal:setInsemination(dewar.animal)
						dewar:changeStraws(-1)

						break

					end

				end

				break

			end

		end

	end

end