AnimalDeathEvent = {}

local AnimalDeathEvent_mt = Class(AnimalDeathEvent, Event)
InitEventClass(AnimalDeathEvent, "AnimalDeathEvent")


function AnimalDeathEvent.emptyNew()
    local self = Event.new(AnimalDeathEvent_mt)
    return self
end


function AnimalDeathEvent.new(object, animal)

    local self = AnimalDeathEvent.emptyNew()

    self.object = object
    self.animal = animal

    return self

end


function AnimalDeathEvent:readStream(streamId, connection)

    local hasObject = streamReadBool(streamId)

    self.object = hasObject and NetworkUtil.readNodeObject(streamId) or nil
    self.animal = Animal.readStreamIdentifiers(streamId, connection)

    self:run(connection)

end


function AnimalDeathEvent:writeStream(streamId, connection)

    streamWriteBool(streamId, self.object ~= nil)

    if self.object ~= nil then NetworkUtil.writeNodeObject(streamId, self.object) end
    
    self.animal:writeStreamIdentifiers(streamId, connection)

end


function AnimalDeathEvent:run(connection)

    local identifiers = self.animal

    if self.object == nil then
        local animals = g_currentMission.animalSystem.animals[identifiers.animalTypeIndex]

        for i, animal in pairs(animals) do

            if animal.farmId == identifiers.farmId and animal.uniqueId == identifiers.uniqueId and animal.birthday.country == identifiers.country then
                table.remove(animals, i)
                return
            end

        end
    else
        self.object:getClusterSystem():removeCluster(identifiers.farmId .. " " .. identifiers.uniqueId .. " " .. identifiers.country)
    end

end