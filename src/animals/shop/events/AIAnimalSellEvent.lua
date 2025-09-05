AIAnimalSellEvent = {}

local AIAnimalSellEvent_mt = Class(AIAnimalSellEvent, Event)
InitEventClass(AIAnimalSellEvent, "AIAnimalSellEvent")


function AIAnimalSellEvent.emptyNew()

    local self = Event.new(AIAnimalSellEvent_mt)
    return self

end


function AIAnimalSellEvent.new(object, animals, price)

	local event = AIAnimalSellEvent.emptyNew()

	event.object = object
	event.animals = animals
	event.price = price

	return event

end


function AIAnimalSellEvent:readStream(streamId, connection)

	self.object = NetworkUtil.readNodeObject(streamId)
	local numAnimals = streamReadUInt16(streamId)

	self.animals = {}

	for i = 1, numAnimals do

		local identifiers = Animal.readStreamIdentifiers(streamId, connection)
		table.insert(self.animals, identifiers)

	end

	self.price = streamReadFloat32(streamId)

	self:run(connection)

end


function AIAnimalSellEvent:writeStream(streamId, connection)

	NetworkUtil.writeNodeObject(streamId, self.object)

	streamWriteUInt16(streamId, #self.animals)

	for _, animal in pairs(self.animals) do animal:writeStreamIdentifiers(streamId, connection) end

	streamWriteFloat32(streamId, self.price)

end


function AIAnimalSellEvent:run(connection)

	local clusterSystem = self.object:getClusterSystem()

	for i, identifier in pairs(self.animals) do

		clusterSystem:removeCluster(identifier.farmId .. " " .. identifier.uniqueId .. " " .. (identifier.country or identifier.birthday.country))

	end

	if g_server ~= nil then

		local farmId = self.object:getOwnerFarmId()

		g_currentMission:addMoney(self.price, farmId, MoneyType.SOLD_ANIMALS, true, true)

	end

end


function AIAnimalSellEvent.validate(object, numAnimals, price, farmId)

	if object == nil then return AnimalSellEvent.SELL_ERROR_OBJECT_DOES_NOT_EXIST end
	
	return nil

end