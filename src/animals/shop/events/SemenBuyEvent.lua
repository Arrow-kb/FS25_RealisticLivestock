SemenBuyEvent = {}

local SemenBuyEvent_mt = Class(SemenBuyEvent, Event)
InitEventClass(SemenBuyEvent, "SemenBuyEvent")


function SemenBuyEvent.emptyNew()

    local self = Event.new(SemenBuyEvent_mt)
    return self

end


function SemenBuyEvent.new(animal, quantity, price, farmId, position, rotation)

	local event = SemenBuyEvent.emptyNew()

	event.animal = animal
	event.quantity = quantity
	event.price = price
	event.farmId = farmId
	event.position = position
	event.rotation = rotation

	return event

end


function SemenBuyEvent.newServerToClient(errorCode)

	local event = SemenBuyEvent.emptyNew()

	event.errorCode = errorCode

	return event

end


function SemenBuyEvent:readStream(streamId, connection)

	self.animal = Animal.new()
	self.animal:readStream(streamId, connection)
	self.animal.success = streamReadFloat32(streamId)

	self.quantity = streamReadUInt16(streamId)
	self.price = streamReadFloat32(streamId)
	self.farmId = streamReadUInt8(streamId)

	local x = streamReadFloat32(streamId)
	local y = streamReadFloat32(streamId)
	local z = streamReadFloat32(streamId)

	local rx = streamReadFloat32(streamId)
	local ry = streamReadFloat32(streamId)
	local rz = streamReadFloat32(streamId)
		
	self.position = { x, y, z }
	self.rotation = { rx, ry, rz }

	self:run(connection)

end


function SemenBuyEvent:writeStream(streamId, connection)

	self.animal:writeStream(streamId, connection)
	streamWriteFloat32(streamId, self.animal.success or 0.65)

	streamWriteUInt16(streamId, self.quantity)
	streamWriteFloat32(streamId, self.price)
	streamWriteUInt8(streamId, self.farmId)
	
	streamWriteFloat32(streamId, self.position[1])
	streamWriteFloat32(streamId, self.position[2])
	streamWriteFloat32(streamId, self.position[3])

	streamWriteFloat32(streamId, self.rotation[1])
	streamWriteFloat32(streamId, self.rotation[2])
	streamWriteFloat32(streamId, self.rotation[3])

	self:run(connection)

end


function SemenBuyEvent:run(connection)

	local dewar = Dewar.new(g_currentMission:getIsServer(), g_currentMission:getIsClient())

    dewar:setOwnerFarmId(self.farmId)
    dewar:register(self.position, self.rotation, self.animal, self.quantity)

	g_currentMission:addMoney(self.price, self.farmId, MoneyType.SEMEN_PURCHASE, true, true)

end