AnimalInseminationResultEvent = {}

local AnimalInseminationResultEvent_mt = Class(AnimalInseminationResultEvent, Event)
InitEventClass(AnimalInseminationResultEvent, "AnimalInseminationResultEvent")


function AnimalInseminationResultEvent.emptyNew()

    local self = Event.new(AnimalInseminationResultEvent_mt)
    return self

end


function AnimalInseminationResultEvent.new(object, animal, success)

	local event = AnimalInseminationResultEvent.emptyNew()

	event.object = object
	event.animal = animal
	event.success = success

	return event

end


function AnimalInseminationResultEvent:readStream(streamId, connection)

	self.object = NetworkUtil.readNodeObject(streamId)
	self.animal = Animal.readStreamIdentifiers(streamId, connection)	
	self.success = streamReadBool(streamId)

	self:run(connection)

end


function AnimalInseminationResultEvent:writeStream(streamId, connection)

	NetworkUtil.writeNodeObject(streamId, self.object)
	self.animal:writeStreamIdentifiers(streamId, connection)
	streamWriteBool(streamId, self.success)

end


function AnimalInseminationResultEvent:run(connection)

	if g_server ~= nil and not g_server.netIsRunning then return end

	local clusterSystem = self.object:getClusterSystem()
	local identifiers = self.animal

	for _, animal in pairs(clusterSystem.animals) do

		if animal.farmId == identifiers.farmId and animal.uniqueId == identifiers.uniqueId and animal.birthday.country == (identifiers.country or identifiers.birthday.country) then
					
			animal:addRLMessage(string.format("INSEMINATION_%s", self.success and "SUCCESS" or "FAIL"))
			return

		end

	end

end