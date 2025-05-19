RealisticLivestock_AnimalSystem = {}

local modName = g_currentModName
local modDirectory = g_currentModDirectory


function RealisticLivestock_AnimalSystem:loadAnimals(superFunc, _, _)

    local path = modDirectory .. "xml/animals.xml"
    local xmlFile = XMLFile.load("animals", path)

    self.customEnvironment = modName

    superFunc(self, xmlFile, modDirectory)

    local nameToBuyAges = {}

    for _, key in xmlFile:iterator("animals.animal") do

        local name = xmlFile:getString(key .. "#type"):upper()
        local averageBuyAge = xmlFile:getInt(key .. "#averageBuyAge", 12)
        local maxBuyAge = xmlFile:getInt(key .. "#maxBuyAge", 60)

        nameToBuyAges[name] = {
            ["averageBuyAge"] = averageBuyAge,
            ["maxBuyAge"] = maxBuyAge
        }

    end

    xmlFile:delete()


    for animalTypeIndex, animalType in pairs(self.types) do
        
        if nameToBuyAges[animalType.name] ~= nil then

            self.types[animalTypeIndex].averageBuyAge = nameToBuyAges[animalType.name].averageBuyAge
            self.types[animalTypeIndex].maxBuyAge = nameToBuyAges[animalType.name].maxBuyAge

        end

    end

end

AnimalSystem.loadAnimals = Utils.overwrittenFunction(AnimalSystem.loadAnimals, RealisticLivestock_AnimalSystem.loadAnimals)


function RealisticLivestock_AnimalSystem:loadSubType(superFunc, animalType, subType, xmlFile, subTypeKey, baseDirectory)

    local returnValue = superFunc(self, animalType, subType, xmlFile, subTypeKey, baseDirectory)

    local gender = xmlFile:getString(subTypeKey .. "#gender")
    local maxWeight = xmlFile:getFloat(subTypeKey .. "#maxWeight")
    local targetWeight = xmlFile:getFloat(subTypeKey .. "#targetWeight")
    local minWeight = xmlFile:getFloat(subTypeKey .. "#minWeight")

    if gender == nil then
        subType.gender = "female"
    else
        subType.gender = gender
    end

    if maxWeight == nil then
        subType.maxWeight = 1000
    else
        subType.maxWeight = maxWeight
    end

    if targetWeight == nil then
        subType.targetWeight = 500
    else
        subType.targetWeight = targetWeight
    end

    if minWeight == nil then
        subType.minWeight = 0
    else
        subType.minWeight = minWeight
    end


    return returnValue

end

AnimalSystem.loadSubType = Utils.overwrittenFunction(AnimalSystem.loadSubType, RealisticLivestock_AnimalSystem.loadSubType)


function RealisticLivestock_AnimalSystem:loadVisualData(superFunc, animalType, xmlFile, key, baseDirectory)

    local visualData = superFunc(self, animalType, xmlFile, key, baseDirectory)

    if visualData == nil then return nil end

    local earTagLeft = xmlFile:getString(key .. "#earTagLeft", nil)
    local earTagRight = xmlFile:getString(key .. "#earTagRight", nil)
    local noseRing = xmlFile:getString(key .. "#noseRing", nil)
    local bumId = xmlFile:getString(key .. "#bumId", nil)

    if earTagLeft ~= nil then visualData.earTagLeft = earTagLeft end
    if earTagRight ~= nil then visualData.earTagRight = earTagRight end
    if noseRing ~= nil then visualData.noseRing = noseRing end
    if bumId ~= nil then visualData.bumId = bumId end

    return visualData

end

AnimalSystem.loadVisualData = Utils.overwrittenFunction(AnimalSystem.loadVisualData, RealisticLivestock_AnimalSystem.loadVisualData)


function AnimalSystem:initialiseCountries()

    self.countries = {}
    self.animals = {}

    for _, animalType in pairs(self.types) do self.animals[animalType.typeIndex] = {} end


    for countryIndex, country in pairs(RealisticLivestock.AREA_CODES) do

        self.countries[countryIndex] = {
            ["index"] = countryIndex,
            ["farms"] = {}
        }

    end

    g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)
    g_messageCenter:subscribe(MessageType.DAY_CHANGED, self.onDayChanged, self)
    g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.onPeriodChanged, self)

end


function AnimalSystem:validateFarms(hasData)

    if self.countries == nil then self.countries = {} end

    
    -- validate every country exists


    for countryIndex, info in pairs(RealisticLivestock.AREA_CODES) do

        if self.countries[countryIndex] == nil then

            self.countries[countryIndex] = {
                ["index"] = countryIndex,
                ["farms"] = {}
            }

        end

    end


    -- validate all countries have at least 20 unique farms

    local mapCountryIndex = RealisticLivestock.getMapCountryIndex()


    for _, country in pairs(self.countries) do

        local farmIds = {}
        local farmsRequireId = {}

        if country.index == mapCountryIndex then

            for i, farm in pairs(g_farmManager.farms) do

                local statistics = farm.stats.statistics

                if statistics.farmId ~= nil then table.insert(farmIds, statistics.farmId) end

            end

        end

        local isFirstCreation = #country.farms == 0

        if #country.farms < 20 then

            for i = #country.farms + 1, 20 do

                local farm = { ["quality"] = math.random(250, 1750) / 1000 }

                for i = 0, math.random(0, 2) do

                    local randomProduce = math.random()
                    local baseChance = 1 / (5 - i)

                    if farm.cowId == nil and randomProduce <= baseChance then
                        farm.cowId = 0
                    elseif farm.pigId == nil and randomProduce <= baseChance * (farm.cowId == nil and 2 or 1) then
                        farm.pigId = 0
                    elseif farm.sheepId == nil and randomProduce <= baseChance * ((farm.cowId == nil and farm.pigId == nil and 3) or ((farm.cowId == nil or farm.pigId == nil) and 2) or 1) then
                        farm.sheepId = 0
                    elseif farm.chickenId == nil and randomProduce <= baseChance * ((farm.cowId == nil and farm.pigId == nil and farm.sheepId == nil and 4) or (i == 1 and farm.horseId == nil and 3) or 2) then
                        farm.chickenId = 0
                    else
                        farm.horseId = 0
                    end

                end

                table.insert(country.farms, farm)

            end

            if isFirstCreation and country.index == mapCountryIndex then
                
                -- validate there is at least 1 farm that produces each animal type

                for i = 1, 5 do

                    local randomFarmIndex = math.random(1, #country.farms)
        
                    if i == 1 then country.farms[randomFarmIndex].cowId = country.farms[randomFarmIndex].cowId or 0 end
                    if i == 2 then country.farms[randomFarmIndex].pigId = country.farms[randomFarmIndex].pigId or 0 end
                    if i == 3 then country.farms[randomFarmIndex].sheepId = country.farms[randomFarmIndex].sheepId or 0 end
                    if i == 4 then country.farms[randomFarmIndex].chickenId = country.farms[randomFarmIndex].chickenId or 0 end
                    if i == 5 then country.farms[randomFarmIndex].horseId = country.farms[randomFarmIndex].horseId or 0 end

                end

            end

        end


        for i, farm in pairs(country.farms) do
            if farm.id ~= nil then
                table.insert(farmIds, farm.id) 
            else
                table.insert(farmsRequireId, i) 
            end
        end


        for _, farmIndex in pairs(farmsRequireId) do

            local farmId = math.random(100000, 999999)

            while table.find(farmIds, farmId) ~= nil do farmId = math.random(100000, 999999) end

            country.farms[farmIndex].id = farmId
            table.insert(farmIds, farmId)

        end

    end



    -- validate there are at least 25 animals of each type for sale

    if not hasData then
    
        for animalTypeIndex, animals in pairs(self.animals) do

            if #animals < self.maxDealerAnimals then

                for i = #animals + 1, self.maxDealerAnimals do

                    local animal = self:createNewSaleAnimal(animalTypeIndex)

                    if animal ~= nil then table.insert(animals, animal) end

                end

            end

            self.animals[animalTypeIndex] = animals

        end
   
    end

end


function AnimalSystem:loadFromXMLFile()

    local savegameIndex = g_careerScreen.savegameList.selectedIndex
    local savegame = g_savegameController:getSavegame(savegameIndex)

    if savegame == nil or savegame.savegameDirectory == nil then return false end

    local xmlFile = XMLFile.loadIfExists("animalSystem", savegame.savegameDirectory .. "/animalSystem.xml")

    if xmlFile == nil then return false end


    local hasData = false


    xmlFile:iterate("animalSystem.countries.country", function(_, key)

        local countryIndex = xmlFile:getInt(key .. "#index")
        
        local farms = self.countries[countryIndex].farms

        xmlFile:iterate(key .. ".farm", function(_, farmKey)

            hasData = true

            local farmId = xmlFile:getInt(farmKey .. "#id")
            local cowId = xmlFile:getInt(farmKey .. "#cowId", nil)
            local pigId = xmlFile:getInt(farmKey .. "#pigId", nil)
            local sheepId = xmlFile:getInt(farmKey .. "#sheepId", nil)
            local horseId = xmlFile:getInt(farmKey .. "#horseId", nil)
            local chickenId = xmlFile:getInt(farmKey .. "#chickenId", nil)
            local quality = xmlFile:getFloat(farmKey .. "#quality", math.random(250, 1750) / 1000)
            
            table.insert(farms, { ["id"] = farmId, ["quality"] = quality, ["cowId"] = cowId, ["pigId"] = pigId, ["sheepId"] = sheepId, ["horseId"] = horseId, ["chickenId"] = chickenId })

        end)

        self.countries[countryIndex].farms = farms

    end)


    xmlFile:iterate("animalSystem.animals.animal", function(_, key)

        local animal = Animal.loadFromXMLFile(xmlFile, key)

        if animal ~= nil then
            local animalTypeIndex = animal.animalTypeIndex

            animal.sale = {
                ["day"] = xmlFile:getInt(key .. ".sale#day", 1),
                --["month"] = xmlFile:getInt(key .. ".sale#month"),
                --["year"] = xmlFile:getInt(key .. ".sale#year")
            }

            table.insert(self.animals[animalTypeIndex], animal)
        end

    end)


    xmlFile:delete()

    return hasData

end


function AnimalSystem:saveToXMLFile(path)

	if path == nil then return end

    local xmlFile = XMLFile.create("animalSystem", path, "animalSystem")
    if xmlFile == nil then return end

    
    xmlFile:setSortedTable("animalSystem.countries.country", self.countries, function (key, country)

        xmlFile:setInt(key .. "#index", country.index)

        for i = 1, #country.farms do

            local farmKey = string.format("%s.farm(%d)", key, i - 1)
            local farm = country.farms[i]
            
            xmlFile:setInt(farmKey .. "#id", farm.id)
            xmlFile:setFloat(farmKey .. "#quality", farm.quality)
            
            if farm.cowId ~= nil then xmlFile:setInt(farmKey .. "#cowId", farm.cowId) end
            if farm.pigId ~= nil then xmlFile:setInt(farmKey .. "#pigId", farm.pigId) end
            if farm.sheepId ~= nil then xmlFile:setInt(farmKey .. "#sheepId", farm.sheepId) end
            if farm.horseId ~= nil then xmlFile:setInt(farmKey .. "#horseId", farm.horseId) end
            if farm.chickenId ~= nil then xmlFile:setInt(farmKey .. "#chickenId", farm.chickenId) end

        end

    end)


    local allAnimals = {}

    for _, animals in pairs(self.animals) do

        for _, animal in pairs(animals) do
            if animal.sale ~= nil and animal.sale.day ~= nil then table.insert(allAnimals, animal) end
        end
        
    end

    
    xmlFile:setSortedTable("animalSystem.animals.animal", allAnimals, function (key, animal)

        animal:saveToXMLFile(xmlFile, key)
        xmlFile:setInt(key .. ".sale#day", animal.sale.day)
        --xmlFile:setInt(key .. ".sale#month", animal.sale.month)
        --xmlFile:setInt(key .. ".sale#year", animal.sale.year)

    end)


    xmlFile:save(false, true)
    xmlFile:delete()

end


function AnimalSystem:createNewSaleAnimal(animalTypeIndex)

    local animalType = self:getTypeByIndex(animalTypeIndex)
    local subTypeIndex = animalType.subTypes[math.random(1, #animalType.subTypes)]
    local subType = self:getSubTypeByIndex(subTypeIndex)
    
    local farmId, farmQuality, farmCountryIndex, lastAnimalId
    local attemptedCountryIndexes = {}

    
    while farmId == nil do

        if #attemptedCountryIndexes == #self.countries then return nil end

        local countryIndex

        if #attemptedCountryIndexes == 0 and math.random() >= 0.12 then
            countryIndex = RealisticLivestock.getMapCountryIndex()
        else
            countryIndex = math.random(1, #self.countries)
            while table.find(attemptedCountryIndexes, countryIndex) ~= nil do
                countryIndex = math.random(1, #self.countries)
            end
        end

        table.insert(attemptedCountryIndexes, countryIndex)

        local country = self.countries[countryIndex]
        local validFarms = {}

        for i = 1, #country.farms do
        
            local farm = country.farms[i]

            if animalTypeIndex == AnimalType.COW and farm.cowId ~= nil then
                table.insert(validFarms, i)
                continue
            end

            if animalTypeIndex == AnimalType.PIG and farm.pigId ~= nil then
                table.insert(validFarms, i)
                continue
            end

            if animalTypeIndex == AnimalType.SHEEP and farm.sheepId ~= nil then
                table.insert(validFarms, i)
                continue
            end

            if animalTypeIndex == AnimalType.CHICKEN and farm.chickenId ~= nil then
                table.insert(validFarms, i)
                continue
            end

            if animalTypeIndex == AnimalType.HORSE and farm.horseId ~= nil then
                table.insert(validFarms, i)
            end

        end

        if #validFarms == 0 then continue end

        local farmIndex = validFarms[math.random(1, #validFarms)]
        local farm = country.farms[farmIndex]

        farmId = farm.id
        farmQuality = farm.quality
        farmCountryIndex = countryIndex
        
        if animalTypeIndex == AnimalType.COW then
            country.farms[farmIndex].cowId = farm.cowId + 1
            lastAnimalId = country.farms[farmIndex].cowId
        elseif animalTypeIndex == AnimalType.PIG then
            country.farms[farmIndex].pigId = farm.pigId + 1
            lastAnimalId = country.farms[farmIndex].pigId
        elseif animalTypeIndex == AnimalType.SHEEP then
            country.farms[farmIndex].sheepId = farm.sheepId + 1
            lastAnimalId = country.farms[farmIndex].sheepId
        elseif animalTypeIndex == AnimalType.CHICKEN then
            country.farms[farmIndex].chickenId = farm.chickenId + 1
            lastAnimalId = country.farms[farmIndex].chickenId
        elseif animalTypeIndex == AnimalType.HORSE then
            country.farms[farmIndex].horseId = farm.horseId + 1
            lastAnimalId = country.farms[farmIndex].horseId
        end

    end


    local averageBuyAge = animalType.averageBuyAge or 12
    local maxBuyAge = animalType.maxBuyAge or 60
    local age

    if math.random() >= 0.5 then

        age = math.random(averageBuyAge * 0.85, averageBuyAge * 1.15)

    elseif math.random() >= 0.25 then

        age = math.random(0, averageBuyAge * 0.85)

    else

        age = math.random(averageBuyAge * 1.15, maxBuyAge)

    end

    age = math.clamp(age, 0, maxBuyAge)
    local viableReproductionMonths = age - (subType.reproductionMinAgeMonth + subType.reproductionDurationMonth)
    local isParent, isPregnant, monthsSinceLastBirth = false, false, 12
    local animalGender = subType.gender


    if viableReproductionMonths >= 0 and math.random(0, 100) <= viableReproductionMonths then
        isParent = true
        monthsSinceLastBirth = math.random(0, viableReproductionMonths)
    end

    if animalGender == "female" and age - subType.reproductionMinAgeMonth >= 0 and math.random() >= 0.95 then isPregnant = true end



    local uniqueId = tostring(lastAnimalId)
    local idLen = string.len(uniqueId)

    if idLen < 5 then
        if idLen == 1 then
            uniqueId = "1000" .. uniqueId
        elseif idLen == 2 then
            uniqueId = "100" .. uniqueId
        elseif idLen == 3 then
            uniqueId = "10" .. uniqueId
        elseif idLen == 4 then
            uniqueId = "1" .. uniqueId
        end
    end

    local concatenatedId = farmId .. uniqueId
    local checkDigit = (tonumber(concatenatedId)::number % 7) + 1
    uniqueId = checkDigit .. uniqueId


    local geneticsModifier = farmQuality * 1000
    local genetics = {
        ["metabolism"] = math.clamp(math.random(geneticsModifier - 150, geneticsModifier + 150) / 1000, 0.25, 1.75),
        ["quality"] = math.clamp(math.random(geneticsModifier - 150, geneticsModifier + 150) / 1000, 0.25, 1.75),
        ["fertility"] = math.clamp(math.random(geneticsModifier - 150, geneticsModifier + 150) / 1000, 0.25, 1.75),
        ["health"] = math.clamp(math.random(geneticsModifier - 150, geneticsModifier + 150) / 1000, 0.25, 1.75)
    }

    if animalTypeIndex == AnimalType.COW or animalTypeIndex == AnimalType.SHEEP or animalTypeIndex == AnimalType.CHICKEN then genetics.productivity = math.clamp(math.random(geneticsModifier - 150, geneticsModifier + 150) / 1000, 0.25, 1.75) end

  
    local name
    
    if math.random() >= 0.85 then name = g_currentMission.animalNameSystem:getRandomName(animalGender) end


    local animal = Animal.new(age, math.clamp((math.random(650, 1000) / 10) * genetics.health, 0, 100), monthsSinceLastBirth, animalGender, subTypeIndex, 0, isParent, isPregnant, animalTypeIndex == AnimalType.COW and isParent and monthsSinceLastBirth < 10, nil, nil, nil, nil, nil, name, nil, nil, nil, nil, nil, genetics)

    animal.farmId = tostring(farmId)
    animal.uniqueId = uniqueId
    animal.birthday.country = farmCountryIndex

    local variations = self:getVisualByAge(subTypeIndex, age).visualAnimal.variations
    local variationIndex = 1

    if #variations > 1 then variationIndex = math.random(1, #variations) end

    animal.variation = variationIndex

    local environment = g_currentMission.environment
    local month = environment.currentPeriod + 2

    if month > 12 then month = month - 12 end

    local day = 1 + math.floor((environment.currentDayInPeriod - 1) * (RealisticLivestock.DAYS_PER_MONTH[month] / environment.daysPerPeriod))
    local year = environment.currentYear


    if isPregnant then

        local childNum = animal:generateRandomOffspring()
        local children = {}

        local minMetabolism, maxMetabolism = genetics.metabolism * 0.9, genetics.metabolism * 1.1
        local minMeat, maxMeat = genetics.quality * 0.9, genetics.quality * 1.1
        local minHealth, maxHealth = genetics.health * 0.9, genetics.health * 1.1
        local minFertility, maxFertility = genetics.fertility * 0.9, genetics.fertility * 1.1
        local minProductivity, maxProductivity
        
        if genetics.productivity ~= nil then minProductivity, maxProductivity = genetics.productivity * 0.9, genetics.productivity * 1.1 end

        for i = 1, childNum do

            local gender = math.random() >= 0.5 and "male" or "female"
            local childSubTypeIndex = subTypeIndex + (gender == "male" and 1 or 0)


            local child = Animal.new(-1, 100, 0, gender, childSubTypeIndex, 0, false, false, false, nil, nil, animal.farmId .. " " .. animal.uniqueId)
                        
            local metabolism = math.random(minMetabolism * 100, maxMetabolism * 100) / 100
            local quality = math.random(minMeat * 100, maxMeat * 100) / 100
            local healthGenetics = math.random(minHealth * 100, maxHealth * 100) / 100
            local fertility = math.random(minFertility * 100, maxFertility * 100) / 100
            local productivity = nil
                        
            if genetics.productivity ~= nil then productivity = math.clamp(math.random(minProductivity * 100, maxProductivity * 100) / 100, 0.25, 1.75) end


            child:setGenetics({
                ["metabolism"] = math.clamp(metabolism, 0.25, 1.75),
                ["quality"] = math.clamp(quality, 0.25, 1.75),
                ["health"] = math.clamp(healthGenetics, 0.25, 1.75),
                ["fertility"] = math.clamp(fertility, 0.25, 1.75),
                ["productivity"] = productivity
            })


            table.insert(children, child)

        end


        local reproductionDuration = subType.reproductionDurationMonth
                    
        if math.random() >= 0.99 then

            if math.random() >= 0.95 then
                reproductionDuration = reproductionDuration + math.random() >= 0.75 and -2 or 2
            else
                reproductionDuration = reproductionDuration + math.random() >= 0.85 and -1 or 1
            end

            reproductionDuration = math.max(reproductionDuration, 2)

        end

        local expectedYear = year + math.floor(reproductionDuration / 12)
        local expectedMonth = month + (reproductionDuration % 12)

        while expectedMonth > 12 do
            expectedMonth = expectedMonth - 12
            expectedYear = expectedYear + 1
        end

        local expectedDay = math.random(1, RealisticLivestock.DAYS_PER_MONTH[expectedMonth])


        animal.pregnancy = {
            ["duration"] = reproductionDuration,
            ["expected"] = {
                ["day"] = expectedDay,
                ["month"] = expectedMonth,
                ["year"] = expectedYear
            },
            ["pregnancies"] = children
        }

    end

    animal.sale = {
        --["day"] = day,
        --["month"] = month,
        --["year"] = year
        ["day"] = environment.currentMonotonicDay
    }

    return animal

end


function AnimalSystem:getSaleAnimalsByTypeIndex(animalTypeIndex)

    return self.animals[animalTypeIndex] or {}

end


function AnimalSystem:getFarmQuality(country, farmId)

    if self.countries[country] ~= nil then

        local farms = self.countries[country].farms

        if type(farmId) == "string" then farmId = tonumber(farmId) end

        for _, farm in pairs(farms) do

            if farm.id == farmId then return farm.quality end

        end

    end

    return 1

end


function AnimalSystem:getNextAnimalIdForFarm(countryIndex, animalTypeIndex, farmId)

    local country = self.countries[countryIndex]

    if country == nil then return 1 end

    local farms = country.farms

    if type(farmId) == "string" then farmId = tonumber(farmId) end

    for _, farm in pairs(farms) do

        if farm.id == farmId then

            local index = "cowId"

            if animalTypeIndex == AnimalType.PIG then
                index = "pigId"
            elseif animalTypeIndex == AnimalType.SHEEP then
                index = "sheepId"
            elseif animalTypeIndex == AnimalType.CHICKEN then
                index = "chickenId"
            elseif animalTypeIndex == AnimalType.HORSE then
                index = "horseId"
            end

            if farm[index] ~= nil then
                farm[index] = farm[index] + 1
                return farm[index]
            end

            return 1

        end

    end

    return 1

end


function AnimalSystem:removeSaleAnimal(animalTypeIndex, countryIndex, farmId, uniqueId)

    for i, animal in pairs(self.animals[animalTypeIndex]) do

        if animal.birthday.country == countryIndex and animal.farmId == farmId and animal.uniqueId == uniqueId then
            table.remove(self.animals[animalTypeIndex], i)
            return
        end

    end

end


function AnimalSystem:onHourChanged()

    local day = g_currentMission.environment.currentMonotonicDay

    for animalTypeIndex, animals in pairs(self.animals) do

        local indexesToRemove = {}

        for i, animal in pairs(animals) do

            if animal.sale ~= nil then

                local saleDay = animal.sale.day

                if saleDay == day then continue end

                local geneticQuality = 0
                local totalGenetics = 0

                for _, value in pairs(animal.genetics) do
                    if value ~= nil then
                        totalGenetics = totalGenetics + 1
                        geneticQuality = geneticQuality + value
                    end
                end

                local averageGenetics = geneticQuality / totalGenetics

                if math.random() >= (saleDay / day) / (averageGenetics * 1.45) then table.insert(indexesToRemove, i) end

            end

        end

        for i = #indexesToRemove, 1, -1 do
            table.remove(animals, indexesToRemove[i])
        end

        local threshold = math.random(5, self.maxDealerAnimals)

        if #animals < threshold then

            for i = #animals + 1, threshold do

                local animal = self:createNewSaleAnimal(animalTypeIndex)

                if animal ~= nil then table.insert(animals, animal) end

            end

        end
    
    end



end


function AnimalSystem:onDayChanged()

    local environment = g_currentMission.environment
    local month = environment.currentPeriod + 2
    local currentDayInPeriod = environment.currentDayInPeriod

    if month > 12 then month = month - 12 end

    local daysPerPeriod = environment.daysPerPeriod
    local day = 1 + math.floor((currentDayInPeriod - 1) * (RealisticLivestock.DAYS_PER_MONTH[month] / daysPerPeriod))
    local year = environment.currentYear

    for _, animals in pairs(self.animals) do

        for _, animal in pairs(animals) do

            animal:onDayChanged(nil, self.isServer, day, month, year, currentDayInPeriod, daysPerPeriod, true)

        end

    end

end


function AnimalSystem:onPeriodChanged()

    for _, animals in pairs(self.animals) do

        for _, animal in pairs(animals) do

            animal:onPeriodChanged()

        end

    end

end


function AnimalSystem:addExistingSaleAnimal(animal)

    local animalTypeIndex = animal.animalTypeIndex or 0

    if self.animals[animalTypeIndex] ~= nil then table.insert(self.animals[animalTypeIndex], animal) end

end


function AnimalSystem.onSettingChanged(name, state)

    AnimalSystem[name] = state

end