AnimalNameChangeEvent = {}

local AnimalNameChangeEvent_mt = Class(AnimalNameChangeEvent, Event)
InitEventClass(AnimalNameChangeEvent, "AnimalNameChangeEvent")


function AnimalNameChangeEvent.emptyNew()
    local self = Event.new(AnimalNameChangeEvent_mt)
    return self
end


function AnimalNameChangeEvent.new(object, animal, name)

    local self = AnimalNameChangeEvent.emptyNew()

    self.object = object
    self.animal = animal
    self.name = name

    return self

end


function AnimalNameChangeEvent:readStream(streamId, connection)

    self.object = NetworkUtil.readNodeObject(streamId)
    self.animal = Animal.readStreamIdentifiers(streamId, connection)

    local hasName = streamReadBool(streamId)

    if hasName then self.name = streamReadString(streamId) end

    self:run(connection)

end


function AnimalNameChangeEvent:writeStream(streamId, connection)

    NetworkUtil.writeNodeObject(streamId, self.object)
    
    self.animal:writeStreamIdentifiers(streamId, connection)

    streamWriteBool(streamId, self.name ~= nil and self.name ~= "")

    if self.name ~= nil and self.name ~= "" then streamWriteString(streamId, self.name) end

end


function AnimalNameChangeEvent:run(connection)

    local identifiers = self.animal
    local clusterSystem = self.object:getClusterSystem()

    for _, animal in pairs(clusterSystem.animals) do

        if animal.farmId == identifiers.farmId and animal.uniqueId == identifiers.uniqueId and animal.birthday.country == (identifiers.country or identifiers.birthday.country) then

            animal.name = self.name

            return

        end

    end

end


function AnimalNameChangeEvent.sendEvent(object, animal, name)

    if g_server ~= nil then
        g_server:broadcastEvent(AnimalNameChangeEvent.new(object, animal, name))
    else
        g_client:getServerConnection():sendEvent(AnimalNameChangeEvent.new(object, animal, name))
    end

end