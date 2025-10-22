function AnimalMoveEvent.new(sourceObject, targetObject, animals, moveType)

	local event = AnimalMoveEvent.emptyNew()

	event.sourceObject = sourceObject
	event.targetObject = targetObject
	event.animals = animals
	event.moveType = moveType

	return event

end


function AnimalMoveEvent:readStream(streamId, connection)

	if connection:getIsServer() then

		self.errorCode = streamReadUIntN(streamId, 3)

	else

		self.moveType = streamReadString(streamId)

		self.sourceObject = NetworkUtil.readNodeObject(streamId)
		self.targetObject = NetworkUtil.readNodeObject(streamId)

		local numAnimals = streamReadUInt16(streamId)

		self.animals = {}

		for i = 1, numAnimals do

			local animal = Animal.new()
			local success = animal:readStream(streamId, connection)
			table.insert(self.animals, animal)

		end

	end

	self:run(connection)

end


function AnimalMoveEvent:writeStream(streamId, connection)

	if not connection:getIsServer() then
		streamWriteUIntN(streamId, self.errorCode, 3)
		return
	end

	streamWriteString(streamId, self.moveType)

	NetworkUtil.writeNodeObject(streamId, self.sourceObject)
	NetworkUtil.writeNodeObject(streamId, self.targetObject)

	streamWriteUInt16(streamId, #self.animals)

	for _, animal in pairs(self.animals) do local success = animal:writeStream(streamId, connection) end

end


function AnimalMoveEvent:run(connection)

	if connection:getIsServer() then

		g_messageCenter:publish(AnimalMoveEvent, self.errorCode)
		return

	end

	local userId = g_currentMission.userManager:getUniqueUserIdByConnection(connection)
	local farmId = g_farmManager:getFarmForUniqueUserId(userId).farmId

	for _, animal in pairs(self.animals) do

		local errorCode = AnimalMoveEvent.validate(self.sourceObject, self.targetObject, farmId, animal.subTypeIndex)

		if errorCode ~= nil then
			connection:sendEvent(AnimalMoveEvent.newServerToClient(errorCode))
			return
		end
	
	end

	local clusterSystemSource = self.sourceObject:getClusterSystem()
	local clusterSystemTarget = self.targetObject:getClusterSystem()

	for _, animal in pairs(self.animals) do

		clusterSystemSource:removeCluster(animal.farmId .. " " .. animal.uniqueId .. " " .. animal.birthday.country)
		animal.id, animal.idFull = nil, nil
		clusterSystemTarget:addCluster(animal)

	end

	connection:sendEvent(AnimalMoveEvent.newServerToClient(AnimalMoveEvent.MOVE_SUCCESS))

	if g_server ~= nil and not g_server.netIsRunning then return end

	local husbandry, trailer
	
	if self.moveType == "SOURCE" then 
		husbandry, trailer = self.sourceObject, self.targetObject
	else
		husbandry, trailer = self.targetObject, self.sourceObject
	end

	if #self.animals == 1 then
        husbandry:addRLMessage(string.format("MOVE_ANIMALS_%s_SINLGE", self.moveType), nil, { trailer:getName() })
    elseif #self.animals > 0 then
        husbandry:addRLMessage(string.format("MOVE_ANIMALS_%s_MULTIPLE", self.moveType), nil, { #self.animals, trailer:getName() })
    end

end


function AnimalMoveEvent.validate(sourceObject, targetObject, farmId, subTypeIndex)

	if sourceObject == nil then return AnimalMoveEvent.MOVE_ERROR_SOURCE_OBJECT_DOES_NOT_EXIST end
	
	if targetObject == nil then return AnimalMoveEvent.MOVE_ERROR_TARGET_OBJECT_DOES_NOT_EXIST end

	if not g_currentMission.accessHandler:canFarmAccess(farmId, sourceObject) or not g_currentMission.accessHandler:canFarmAccess(farmId, targetObject) then return AnimalMoveEvent.MOVE_ERROR_NO_PERMISSION end

	if not targetObject:getSupportsAnimalSubType(subTypeIndex) then return AnimalMoveEvent.MOVE_ERROR_ANIMAL_NOT_SUPPORTED end

	if targetObject:getNumOfFreeAnimalSlots(subTypeIndex) < 1 then return AnimalMoveEvent.MOVE_ERROR_NOT_ENOUGH_SPACE end

	return nil

end