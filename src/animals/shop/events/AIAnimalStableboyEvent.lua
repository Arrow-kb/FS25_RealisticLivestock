AIAnimalStableboyEvent = {}

local AIAnimalStableboyEvent_mt = Class(AIAnimalStableboyEvent, Event)
InitEventClass(AIAnimalStableboyEvent, "AIAnimalStableboyEvent")


function AIAnimalStableboyEvent.emptyNew()
	local self = Event.new(AIAnimalStableboyEvent_mt)
	return self
end

function AIAnimalStableboyEvent.new(object, items)
	local event = AIAnimalStableboyEvent.emptyNew()
	event.object = object
	event.items = items
	return event
end

function AIAnimalStableboyEvent:readStream(streamId, connection)
	print("[RealisticLivestock] AIAnimalStableboyEvent:readStream()")
	self.object = NetworkUtil.readNodeObject(streamId)
	local numAnimals = streamReadUInt16(streamId)

	self.items = {}

	for i = 1, numAnimals do
		local identifiers     = Animal.readStreamIdentifiers(streamId, connection)
		identifiers["riding"] = streamReadUInt8(streamId)
		identifiers["dirt"]   = streamReadUInt8(streamId)
		identifiers["price"]  = streamReadFloat32(streamId)

		table.insert(self.items, identifiers)
	end

	self:run(connection)
end

function AIAnimalStableboyEvent:writeStream(streamId, connection)
	print("[RealisticLivestock] AIAnimalStableboyEvent:writeStream()")
	NetworkUtil.writeNodeObject(streamId, self.object)

	streamWriteUInt16(streamId, #self.items)

	for _, item in pairs(self.items) do
		item.animal:writeStreamIdentifiers(streamId, connection)
		streamWriteUInt8(streamId, item.animal.riding)
		streamWriteUInt8(streamId, item.animal.dirt)
		streamWriteFloat32(streamId, item.price)
	end
end

function AIAnimalStableboyEvent:run(connection)
	print("[RealisticLivestock] AIAnimalStableboyEvent:run()")

	local totalPrice = 0.0

	local clusterSystem = self.object:getClusterSystem()
	for _, item in pairs(self.items) do
		totalPrice = totalPrice + item.price

		local identifier = item.animal

		for _, animal in pairs(clusterSystem.animals) do
			if animal.farmId == identifier.farmId and animal.uniqueId == identifier.uniqueId and animal.birthday.country == (identifier.country or identifier.birthday.country) then
				animal.riding = identifier.riding
				animal.dirt = identifier.dirt
				break
			end
		end
	end

	if g_server ~= nil and totalPrice > 0 then
		local farmId = self.object:getOwnerFarmId()
		g_currentMission:addMoney(totalPrice, farmId, MoneyType.AI, true, true)
	end
end
