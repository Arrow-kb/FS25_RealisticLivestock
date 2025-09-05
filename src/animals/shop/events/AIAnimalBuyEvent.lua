AIAnimalBuyEvent = {}

local AIAnimalBuyEvent_mt = Class(AIAnimalBuyEvent, Event)
InitEventClass(AIAnimalBuyEvent, "AIAnimalBuyEvent")


function AIAnimalBuyEvent.emptyNew()

    local self = Event.new(AIAnimalBuyEvent_mt)
    return self

end


function AIAnimalBuyEvent.new(object, animals, price)

	local event = AIAnimalBuyEvent.emptyNew()

	event.object = object
	event.animals = animals
	event.price = price

	return event

end


function AIAnimalBuyEvent:readStream(streamId, connection)

	self.object = NetworkUtil.readNodeObject(streamId)
	local numAnimals = streamReadUInt16(streamId)

	self.animals = {}

	for i = 1, numAnimals do

		local animal = Animal.new()
		animal:readStream(streamId, connection)
		table.insert(self.animals, animal)

	end

	self.price = streamReadFloat32(streamId)

	self:run(connection)

end


function AIAnimalBuyEvent:writeStream(streamId, connection)

	NetworkUtil.writeNodeObject(streamId, self.object)

	streamWriteUInt16(streamId, #self.animals)

	for _, animal in pairs(self.animals) do animal:writeStream(streamId, connection) end

	streamWriteFloat32(streamId, self.price)

end


function AIAnimalBuyEvent:run(connection)

	for _, animal in pairs(self.animals) do

		animal:setRecentlyBoughtByAI(true)

		g_currentMission.animalSystem:removeSaleAnimal(animal.animalTypeIndex, animal.birthday.country, animal.farmId, animal.uniqueId)

	end

	self.object:addAnimals(self.animals)

	if g_server ~= nil then

		local farmId = self.object:getOwnerFarmId()
		g_currentMission:addMoney(-self.price, farmId, MoneyType.NEW_ANIMALS_COST, true, true)

	end

end


function AIAnimalBuyEvent.validate(object, numAnimals, price, farmId)

	if object == nil then return AnimalBuyEvent.BUY_ERROR_OBJECT_DOES_NOT_EXIST end

	if object:getNumOfFreeAnimalSlots() < numAnimals then return AnimalBuyEvent.BUY_ERROR_NOT_ENOUGH_SPACE end
	
	if g_currentMission:getMoney(farmId) - price < 0 then return AnimalBuyEvent.BUY_ERROR_NOT_ENOUGH_MONEY end
	
	return nil

end