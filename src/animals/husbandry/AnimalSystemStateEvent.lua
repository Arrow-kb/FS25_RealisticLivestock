AnimalSystemStateEvent = {}

local AnimalSystemStateEvent_mt = Class(AnimalSystemStateEvent, Event)
InitEventClass(AnimalSystemStateEvent, "AnimalSystemStateEvent")


function AnimalSystemStateEvent.emptyNew()
    local self = Event.new(AnimalSystemStateEvent_mt)
    return self
end


function AnimalSystemStateEvent.new(countries, animals)

    local self = AnimalSystemStateEvent.emptyNew()

    self.countries, self.animals = countries, animals

    return self

end


function AnimalSystemStateEvent:readStream(streamId, connection)

    local numCountries = streamReadUInt8(streamId)
    local countries = {}

    for i = 1, numCountries do

        local farms = {}
        local numFarms = streamReadUInt8(streamId)

        for j = 1, numFarms do

            local quality = streamReadFloat32(streamId)
            local id = streamReadUInt32(streamId)
            local numIds = streamReadUInt8(streamId)
            local ids = {}

            for k = 1, numIds do
                local animalTypeIndex = streamReadUInt8(streamId)
                local animalId = streamReadUInt32(streamId)
                ids[animalTypeIndex] = animalId
            end

            table.insert(farms, {
                ["quality"] = quality,
                ["id"] = id,
                ["ids"] = ids
            })

        end

        countries[i] = {
            ["farms"] = farms
        }

    end

    self.countries = countries


    self.animals = {}
    local numAnimals = streamReadUInt8(streamId)

    for i = 1, numAnimals do

        local animals = {}
        local numSaleAnimals = streamReadUInt16(streamId)

        for j = 1, numSaleAnimals do

            local animal = Animal.new()
            local success = animal:readStream(streamId, connection)
            local day = streamReadUInt16(streamId)

            animal.sale = {
                ["day"] = day
            }

            table.insert(animals, animal)

        end

        self.animals[i] = animals

    end

    self:run(connection)

end


function AnimalSystemStateEvent:writeStream(streamId, connection)
    
    local countries = self.countries
    streamWriteUInt8(streamId, #countries)

    for i = 1, #countries do

        local farms = countries[i].farms

        streamWriteUInt8(streamId, #farms)

        for _, farm in pairs(farms) do

            streamWriteFloat32(streamId, farm.quality)
            streamWriteUInt32(streamId, farm.id)

            local ids, numIds = farm.ids, 0

            for animalTypeIndex, id in pairs(ids) do numIds = numIds + 1 end

            streamWriteUInt8(streamId, numIds)

            for animalTypeIndex, id in pairs(ids) do
                streamWriteUInt8(streamId, animalTypeIndex)
                streamWriteUInt32(streamId, id)
            end

        end

    end


    streamWriteUInt8(streamId, #self.animals)

    for i = 1, #self.animals do

        local animals = self.animals[i] or {}

        streamWriteUInt16(streamId, #animals)

        for _, animal in pairs(animals) do

            local success = animal:writeStream(streamId, connection)
            streamWriteUInt16(streamId, animal.sale.day)

        end

    end


end


function AnimalSystemStateEvent:run(connection)

    local animalSystem = g_currentMission.animalSystem

    animalSystem.countries = self.countries
    animalSystem.animals = self.animals

end