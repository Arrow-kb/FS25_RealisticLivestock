AnimalPregnancyEvent = {}

local AnimalPregnancyEvent_mt = Class(AnimalPregnancyEvent, Event)
InitEventClass(AnimalPregnancyEvent, "AnimalPregnancyEvent")


function AnimalPregnancyEvent.emptyNew()
    local self = Event.new(AnimalPregnancyEvent_mt)
    return self
end


function AnimalPregnancyEvent.new(object, animal)

    local self = AnimalPregnancyEvent.emptyNew()

    self.object = object
    self.animal = animal

    return self

end


function AnimalPregnancyEvent:readStream(streamId, connection)

    local hasObject = streamReadBool(streamId)

    self.object = hasObject and NetworkUtil.readNodeObject(streamId) or nil
    self.animal = Animal.readStreamIdentifiers(streamId, connection)

    local pregnancy = { ["expected"] = {}, ["pregnancies"] = {} }
    local impregnatedBy = {}

    pregnancy.duration = streamReadUInt8(streamId)
    pregnancy.expected.day = streamReadUInt8(streamId)
    pregnancy.expected.month = streamReadUInt8(streamId)
    pregnancy.expected.year = streamReadUInt8(streamId)

    local numChildren = streamReadUInt8(streamId)

    for i = 1, numChildren do

        local child = Animal.new()
        child:readStream(streamId, connection)

        if child ~= nil then table.insert(pregnancy.pregnancies, child) end

    end

    impregnatedBy.uniqueId = streamReadString(streamId)
    impregnatedBy.metabolism = streamReadFloat32(streamId)
    impregnatedBy.health = streamReadFloat32(streamId)
    impregnatedBy.fertility = streamReadFloat32(streamId)
    impregnatedBy.quality = streamReadFloat32(streamId)
    impregnatedBy.productivity = streamReadFloat32(streamId)

    self.pregnancy = pregnancy
    self.impregnatedBy = impregnatedBy

    self:run(connection)

end


function AnimalPregnancyEvent:writeStream(streamId, connection)

    streamWriteBool(streamId, self.object ~= nil)

    if self.object ~= nil then

        NetworkUtil.writeNodeObject(streamId, self.object)

    end
    
    self.animal:writeStreamIdentifiers(streamId, connection)
    
    local pregnancy = self.animal.pregnancy
    local impregnatedBy = self.animal.impregnatedBy

    streamWriteUInt8(streamId, pregnancy.duration)
    streamWriteUInt8(streamId, pregnancy.expected.day)
    streamWriteUInt8(streamId, pregnancy.expected.month)
    streamWriteUInt8(streamId, pregnancy.expected.year)

    streamWriteUInt8(streamId, #pregnancy.pregnancies)

    for _, child in pairs(pregnancy.pregnancies) do

        child:writeStream(streamId, connection)

    end

    streamWriteString(streamId, impregnatedBy.uniqueId)
    streamWriteFloat32(streamId, impregnatedBy.metabolism)
    streamWriteFloat32(streamId, impregnatedBy.health)
    streamWriteFloat32(streamId, impregnatedBy.fertility)
    streamWriteFloat32(streamId, impregnatedBy.quality)
    streamWriteFloat32(streamId, impregnatedBy.productivity)

end


function AnimalPregnancyEvent:run(connection)

    local identifiers = self.animal
    local animals

    if self.object == nil then
        animals = g_currentMission.animalSystem.animals[identifiers.animalTypeIndex]
    else
        animals = self.object:getClusterSystem().animals
    end

    for _, animal in pairs(animals) do

        if animal.uniqueId == identifiers.unique and animal.farmId == identifiers.farmId and animal.birthday.country == (identifiers.country or identifiers.birthday.country) then

            animal.isPregnant = true
            animal.pregnancy = self.pregnancy
            animal.impregnatedBy = self.impregnatedBy
            animal.reproduction = 0

            animal:changeReproduction(animal:getReproductionDelta())

            return

        end

    end

end