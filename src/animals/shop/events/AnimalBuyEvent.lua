function AnimalBuyEvent.new(object, animals, buyPrice, transportPrice)

	local event = AnimalBuyEvent.emptyNew()

	event.object = object
	event.animals = animals
	event.buyPrice = buyPrice
	event.transportPrice = transportPrice

	return event

end


function AnimalBuyEvent:readStream(streamId, connection)

	if connection:getIsServer() then

		self.errorCode = streamReadUIntN(streamId, 3)

	else

		self.object = NetworkUtil.readNodeObject(streamId)
		local numAnimals = streamReadUInt16(streamId)

		self.animals = {}

		for i = 1, numAnimals do

			local animal = Animal.new()
			animal:readStream(streamId, connection)
			table.insert(self.animals, animal)

		end

		self.buyPrice = streamReadFloat32(streamId)
		self.transportPrice = streamReadFloat32(streamId)

	end

	self:run(connection)

end


function AnimalBuyEvent:writeStream(streamId, connection)

	if not connection:getIsServer() then
		streamWriteUIntN(streamId, self.errorCode, 3)
		return
	end

	NetworkUtil.writeNodeObject(streamId, self.object)

	streamWriteUInt16(streamId, #self.animals)

	for _, animal in pairs(self.animals) do animal:writeStream(streamId, connection) end

	streamWriteFloat32(streamId, self.buyPrice)
	streamWriteFloat32(streamId, self.transportPrice)

end


function AnimalBuyEvent:run(connection)

	if connection:getIsServer() then

		g_messageCenter:publish(AnimalBuyEvent, self.errorCode)
		return

	end

	if not g_currentMission:getHasPlayerPermission("tradeAnimals", connection) then

		connection:sendEvent(AnimalBuyEvent.newServerToClient(AnimalBuyEvent.BUY_ERROR_NO_PERMISSION))
		return

	end

	local userId = g_currentMission.userManager:getUniqueUserIdByConnection(connection)
	local farmId = g_farmManager:getFarmForUniqueUserId(userId).farmId

	for _, animal in pairs(self.animals) do

		local errorCode = AnimalBuyEvent.validate(self.object, animal.subTypeIndex, animal.age, #self.animals, self.buyPrice, self.transportPrice, farmId)

		if errorCode ~= nil then
			connection:sendEvent(AnimalBuyEvent.newServerToClient(errorCode))
			return
		end
	
	end

	for _, animal in pairs(self.animals) do

		g_currentMission.animalSystem:removeSaleAnimal(animal.animalTypeIndex, animal.birthday.country, animal.farmId, animal.uniqueId)

	end

	self.object:addAnimals(self.animals)

	g_currentMission:addMoney(self.buyPrice + self.transportPrice, farmId, MoneyType.NEW_ANIMALS_COST, true, true)
	connection:sendEvent(AnimalBuyEvent.newServerToClient(AnimalBuyEvent.BUY_SUCCESS))

	if g_server ~= nil and not g_server.netIsRunning then return end

	if #self.animals == 1 then
        self.object:addRLMessage("BOUGHT_ANIMALS_SINGLE", nil, { g_i18n:formatMoney(math.abs(self.buyPrice + self.transportPrice), 2, true, true) })
    elseif #self.animals > 0 then
        self.object:addRLMessage("BOUGHT_ANIMALS_MULTIPLE", nil, { #self.animals, g_i18n:formatMoney(math.abs(self.buyPrice + self.transportPrice), 2, true, true) })
    end

end