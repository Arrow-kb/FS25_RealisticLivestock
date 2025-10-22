AnimalInseminationEvent = {}

local AnimalInseminationEvent_mt = Class(AnimalInseminationEvent, Event)
InitEventClass(AnimalInseminationEvent, "AnimalInseminationEvent")


function AnimalInseminationEvent.emptyNew()

    local self = Event.new(AnimalInseminationEvent_mt)
    return self

end


function AnimalInseminationEvent.new(object, animal, semen)

	local event = AnimalInseminationEvent.emptyNew()

	event.object = object
	event.animal = animal
	event.semen = semen

	return event

end


function AnimalInseminationEvent:readStream(streamId, connection)

	self.object = NetworkUtil.readNodeObject(streamId)
	self.animal = Animal.readStreamIdentifiers(streamId, connection)
	
	self.semen = { ["genetics"] = {} }

	semen.country = streamReadUInt8(streamId)
	semen.farmId = streamReadString(streamId)
	semen.uniqueId = streamReadString(streamId)
	semen.name = streamReadString(streamId)
	semen.typeIndex = streamReadUInt8(streamId)
	semen.subTypeIndex = streamReadUInt8(streamId)
	semen.success = streamReadFloat32(streamId)

	semen.genetics.metabolism = streamReadFloat32(streamId)
	semen.genetics.fertility = streamReadFloat32(streamId)
	semen.genetics.health = streamReadFloat32(streamId)
	semen.genetics.quality = streamReadFloat32(streamId)
	semen.genetics.productivity = streamReadFloat32(streamId)

	if semen.genetics.productivity < 0 then semen.genetics.productivity = nil end

	self:run(connection)

end


function AnimalInseminationEvent:writeStream(streamId, connection)

	NetworkUtil.writeNodeObject(streamId, self.object)
	self.animal:writeStreamIdentifiers(streamId, connection)

	local semen = self.semen

	streamWriteUInt8(streamId, semen.country)
	streamWriteString(streamId, semen.farmId)
	streamWriteString(streamId, semen.uniqueId)
	streamWriteString(streamId, semen.name or "")
	streamWriteUInt8(streamId, semen.typeIndex)
	streamWriteUInt8(streamId, semen.subTypeIndex)
	streamWriteFloat32(streamId, semen.success)

	streamWriteFloat32(streamId, semen.genetics.metabolism)
	streamWriteFloat32(streamId, semen.genetics.fertility)
	streamWriteFloat32(streamId, semen.genetics.health)
	streamWriteFloat32(streamId, semen.genetics.quality)
	streamWriteFloat32(streamId, semen.genetics.productivity or -1)

end


function AnimalInseminationEvent:run(connection)

	local clusterSystem = self.object:getClusterSystem()
	local identifiers = self.animal

	for _, animal in pairs(clusterSystem.animals) do

		if animal.farmId == identifiers.farmId and animal.uniqueId == identifiers.uniqueId and animal.birthday.country == (identifiers.country or identifiers.birthday.country) then
					
			animal:setInsemination(self.semen)
			break

		end

	end

end