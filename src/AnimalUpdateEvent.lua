AnimalUpdateEvent = {}

local AnimalUpdateEvent_mt = Class(AnimalUpdateEvent, Event)
InitEventClass(AnimalUpdateEvent, "AnimalUpdateEvent")


function AnimalUpdateEvent.emptyNew()
    local self = Event.new(AnimalUpdateEvent_mt)
    return self
end


function AnimalUpdateEvent.new(object, animal, trait, value)

    local self = AnimalUpdateEvent.emptyNew()

    self.object = object
    self.animal = animal
    self.trait = trait
    self.value = value

    return self

end


function AnimalUpdateEvent:readStream(streamId, connection)

    self.object = NetworkUtil.readNodeObject(streamId)
    self.animal = Animal.readStreamIdentifiers(streamId, connection)

    self.trait = streamReadString(streamId)
    local valueType = streamReadString(streamId)

    if valueType == "number" then
        self.value = streamReadFloat32(streamId)
    elseif valueType == "string" then
        self.value = streamReadString(streamId)
    else
        self.value = streamReadBool(streamId)
    end

    self:run(connection)

end


function AnimalUpdateEvent:writeStream(streamId, connection)

    NetworkUtil.writeNodeObject(streamId, self.object)
    
    self.animal:writeStreamIdentifiers(streamId, connection)
    streamWriteString(streamId, self.trait)
    
    local valueType = type(self.value)
    streamWriteString(streamId, valueType)

    if valueType == "number" then
        streamWriteFloat32(streamId, self.value)
    elseif valueType == "string" then
        streamWriteString(streamId, self.value)
    else
        streamWriteBool(streamId, self.value)
    end

end


function AnimalUpdateEvent:run(connection)

    local clusterSystem = self.object:getClusterSystem()
    local identifiers = self.animal

    for _, animal in pairs(clusterSystem.animals) do

        if animal.farmId == identifiers.farmId and animal.uniqueId == identifiers.uniqueId and animal.birthday.country == identifiers.country and animal.animalTypeIndex == identifiers.animalTypeIndex then

            animal[self.trait] = self.value
            return

        end

    end

end