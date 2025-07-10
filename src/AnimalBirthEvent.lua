AnimalBirthEvent = {}

local AnimalBirthEvent_mt = Class(AnimalBirthEvent, Event)
InitEventClass(AnimalBirthEvent, "AnimalBirthEvent")


function AnimalBirthEvent.emptyNew()
    local self = Event.new(AnimalBirthEvent_mt)
    return self
end


function AnimalBirthEvent.new(object, animal, children, parentDied)

    local self = AnimalBirthEvent.emptyNew()

    self.object = object
    self.animal = animal
    self.children = children or {}
    self.parentDied = parentDied or false

    return self

end


function AnimalBirthEvent:readStream(streamId, connection)

    local hasObject = streamReadBool(streamId)

    self.object = hasObject and NetworkUtil.readNodeObject(streamId) or nil
    self.animal = Animal.readStreamIdentifiers(streamId, connection)

    local numChildren = streamReadUInt8(streamId)
    self.children = {}

    for i = 1, numChildren do
        local child = Animal.new()
        child:readStream(streamId, connection)
        table.insert(self.children, child)
    end

    self.parentDied = streamReadBool(streamId)

    self:run(connection)

end


function AnimalBirthEvent:writeStream(streamId, connection)

    streamWriteBool(streamId, self.object ~= nil)

    if self.object ~= nil then NetworkUtil.writeNodeObject(streamId, self.object) end
    
    self.animal:writeStreamIdentifiers(streamId, connection)

    streamWriteUInt8(streamId, #self.children)

    for _, child in pairs(self.children) do child:writeStream(streamId, connection) end

    streamWriteBool(streamId, self.parentDied)

end


function AnimalBirthEvent:run(connection)

    local identifiers = self.animal

    if self.object == nil then

        local animals = g_currentMission.animalSystem.animals[identifiers.animalTypeIndex]

        for _, child in pairs(self.children) do table.insert(animals, child) end

        for i, animal in pairs(animals) do

            if animal.farmId == identifiers.farmId and animal.uniqueId == identifiers.uniqueId and animal.birthday.country == (identifiers.country or identifiers.birthday.country) then

                animal.isParent = true
                animal.monthsSinceLastBirth = 0
                animal.pregnancy = nil
                animal.impregnatedBy = nil
                animal.isPregnant = false
                animal.reproduction = 0

                if animal.animalTypeIndex == AnimalType.COW or animal.subType == "GOAT" then animal.isLactating = true end 

                if self.parentDied then table.remove(animals, i) end

                break

            end

        end

    else

        local clusterSystem = self.object:getClusterSystem()

        for _, child in pairs(self.children) do clusterSystem:addCluster(child) end

        for _, animal in pairs(clusterSystem.animals) do

            if animal.farmId == identifiers.farmId and animal.uniqueId == identifiers.uniqueId and animal.birthday.country == (identifiers.country or identifiers.birthday.country) then

                animal.isParent = true
                animal.monthsSinceLastBirth = 0
                animal.pregnancy = nil
                animal.impregnatedBy = nil
                animal.isPregnant = false
                animal.reproduction = 0

                if animal.animalTypeIndex == AnimalType.COW or animal.subType == "GOAT" then animal.isLactating = true end 

                break

            end

        end
        
        if self.parentDied then clusterSystem:removeCluster(identifiers.farmId .. " " .. identifiers.uniqueId .. " " .. (identifiers.country or identifiers.birthday.country)) end

    end

end