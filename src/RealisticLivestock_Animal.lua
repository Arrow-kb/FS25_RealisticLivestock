Animal = {}
local Animal_mt = Class(Animal)


function Animal.new(age, health, monthsSinceLastBirth, gender, subTypeIndex, reproduction, isParent, isPregnant, isLactating, clusterSystem, id, motherId, fatherId, pos, name, dirt, fitness, riding, farmId, weight, genetics, impregnatedBy, variation, children)

    local self = setmetatable({}, Animal_mt)

    self.clusterSystem = clusterSystem

    self.children = children or {}
    self.age = age or 0
    self.health = health or 0
    self.monthsSinceLastBirth = monthsSinceLastBirth or 0
    self.gender = gender or "female"
    self.subTypeIndex = subTypeIndex or 1
    self.subType = g_currentMission.animalSystem:getSubTypeByIndex(self.subTypeIndex).name or "COW_SWISS_BROWN"
    self.reproduction = reproduction or 0
    self.isParent = isParent or false
    self.isPregnant = isPregnant or false
    self.isLactating = isLactating or false
    self.isDirty = false
    self.isIndividual = true
    self.name = nil
    self.isDead = false
    self.isSold = false
    self.weight = weight or nil

    self.variation = variation or nil

    self.genetics = genetics
    self.impregnatedBy = impregnatedBy

    self.animalTypeIndex = g_currentMission.animalSystem:getTypeIndexBySubTypeIndex(self.subTypeIndex)
    local subType = g_currentMission.animalSystem:getSubTypeByIndex(self.subTypeIndex)
    local targetWeight = subType.targetWeight

    if genetics == nil then
    
        self.genetics = {}

        local healthChance = math.random()

        if healthChance < 0.05 then
            self.genetics.health = math.random(25, 35) / 100
        elseif healthChance < 0.25 then
            self.genetics.health = math.random(35, 90) / 100
        elseif healthChance > 0.95 then
            self.genetics.health = math.random(165, 175) / 100
        elseif healthChance > 0.75 then
            self.genetics.health = math.random(110, 165) / 100
        else
            self.genetics.health = math.random(90, 110) / 100
        end


        local fertilityChance = math.random()

        if fertilityChance < 0.05 then
            self.genetics.fertility = math.random(25, 35) / 100
        elseif fertilityChance < 0.25 then
            self.genetics.fertility = math.random(35, 90) / 100
        elseif fertilityChance > 0.95 then
            self.genetics.fertility = math.random(165, 175) / 100
        elseif fertilityChance > 0.75 then
            self.genetics.fertility = math.random(110, 165) / 100
        else
            self.genetics.fertility = math.random(90, 110) / 100
        end


        if self.animalTypeIndex == AnimalType.COW or self.animalTypeIndex == AnimalType.SHEEP or self.animalTypeIndex == AnimalType.CHICKEN then

            local productivityChance = math.random()

            if productivityChance < 0.05 then
                self.genetics.productivity = math.random(25, 35) / 100
            elseif productivityChance < 0.25 then
                self.genetics.productivity = math.random(35, 90) / 100
            elseif productivityChance > 0.95 then
                self.genetics.productivity = math.random(165, 175) / 100
            elseif productivityChance > 0.75 then
                self.genetics.productivity = math.random(110, 165) / 100
            else
                self.genetics.productivity = math.random(90, 110) / 100
            end

        end


        local meatQualityChance = math.random()

        if meatQualityChance < 0.05 then
            self.genetics.quality = math.random(25, 35) / 100
        elseif meatQualityChance < 0.25 then
            self.genetics.quality = math.random(35, 90) / 100
        elseif meatQualityChance > 0.95 then
            self.genetics.quality = math.random(165, 175) / 100
        elseif meatQualityChance > 0.75 then
            self.genetics.quality = math.random(110, 165) / 100
        else
            self.genetics.quality = math.random(90, 110) / 100
        end
        

        local metabolismChance = math.random()

        if metabolismChance < 0.05 then
            self.genetics.metabolism = math.random(25, 35) / 100
        elseif metabolismChance < 0.25 then
            self.genetics.metabolism = math.random(35, 90) / 100
        elseif metabolismChance > 0.95 then
            self.genetics.metabolism = math.random(165, 175) / 100
        elseif metabolismChance > 0.75 then
            self.genetics.metabolism = math.random(110, 165) / 100
        else
            self.genetics.metabolism = math.random(90, 110) / 100
        end

    end


    if self.weight == nil then

        local minWeight = subType.minWeight
        local maxWeight = subType.maxWeight

        local weightPerMonth = (targetWeight - minWeight) / (subType.reproductionMinAgeMonth * 1.5)
        self.weight = math.clamp((minWeight + (weightPerMonth * math.clamp(self.age, 0, 20))) * (math.random(85, 115) / 100), minWeight, maxWeight)

    end


    self.targetWeight = targetWeight + (((targetWeight * self.genetics.metabolism) - targetWeight) / 2.5)

    self.farmId = farmId or nil

    if self.clusterSystem ~= nil then

        if id == nil then

            local ownerFarmId = clusterSystem.owner.ownerFarmId
            local farm = g_farmManager.farmIdToFarm[ownerFarmId]


            if farm == nil then
                id = "1"
            else
                id = farm.stats:getNextAnimalId(g_currentMission.animalSystem:getSubTypeByIndex(self.subTypeIndex).typeIndex)

                local farmHerdId = farm.stats.statistics.farmId
                if farmHerdId == nil then
                    farmHerdId = math.random(100000, 999999)
                    farm.stats.statistics.farmId = farmHerdId
                end

                self.farmId = tostring(farmHerdId)

                id = tostring(id)
                local idLen = string.len(id)

                if idLen < 5 then
                    if idLen == 1 then
                        id = "1000" .. id
                    elseif idLen == 2 then
                        id = "100" .. id
                    elseif idLen == 3 then
                        id = "10" .. id
                    elseif idLen == 4 then
                        id = "1" .. id
                    end
                end

                local concatenated = farmHerdId .. id
                local checkDigit = (tonumber(concatenated)::number % 7) + 1
                id = checkDigit .. id
            end
        end

        if farmId == nil then
            local farm = g_farmManager.farmIdToFarm[clusterSystem.owner.ownerFarmId]
            if farm == nil then
                self.farmId = "1"
            else
                local farmHerdId = farm.stats.statistics.farmId
                if farmHerdId == nil then
                    farmHerdId = math.random(100000, 999999)
                    farm.stats.statistics.farmId = farmHerdId
                end

                self.farmId = tostring(farmHerdId)
            end
        end

    end

    self.uniqueId = id
    self.id = "0-0"
    self.idFull = "0-0"

    self.motherId = motherId or "-1"
    self.fatherId = fatherId or "-1"


    -- for compatibility reasons with mods such as InfoDisplayExtension

    self.numAnimals = 1
    self.maxNumAnimals = 1

    local reproductionText = g_i18n:getText("statistic_reproduction")

    self.infoReproduction = {
        text = "",
        title = reproductionText,
        titleOrg = reproductionText
    }
    self.infoHealth = {
        text = "",
        title = g_i18n:getText("ui_horseHealth")
    }

    self.name = name or nil


    self.dirt = dirt or 0
    self.fitness = fitness or 0
    self.riding = riding or 0
    if name == "" then name = nil end
    self.name = name or ((string.contains(self.subType, "HORSE", true) or string.contains(self.subType, "STALLION", true)) and g_currentMission.animalNameSystem:getRandomName(self.gender) or nil)


    self.pos = pos or nil
    

    if self.age >= 0 then

        local environment = g_currentMission.environment

        local currentMonth = environment.currentPeriod + 2
        local currentYear = environment.currentYear

        if currentMonth > 12 then currentMonth = currentMonth - 12 end

        local birthYear = currentYear - math.floor(self.age / 12)
        local birthMonth = currentMonth - (self.age % 12)

        if birthMonth <= 0 then birthMonth = 12 + birthMonth end

        local birthCountry = math.random() >= 0.01 and RealisticLivestock.getMapCountryIndex() or math.random(1, #RealisticLivestock.AREA_CODES)

        self.birthday = {
            ["day"] = math.random(1, RealisticLivestock.DAYS_PER_MONTH[birthMonth]),
            ["month"] = birthMonth,
            ["year"] = birthYear,
            ["country"] = birthCountry,
            ["lastAgeMonth"] = currentMonth
        }

    end


    return self

end

function Animal:delete()
    local clusterSystem = self.clusterSystem or nil

    if clusterSystem ~= nil then

        for i, animal in pairs(clusterSystem.animals) do
            if animal == self then
                table.remove(clusterSystem.animals, i)
                break
            end
        end

    end

    self = nil

end


function Animal:setClusterSystem(clusterSystem)
    self.clusterSystem = clusterSystem
    if clusterSystem ~= nil then self.sale = nil end
end


function Animal:getSupportsMerging()
    return false
end


function Animal.loadFromXMLFile(xmlFile, key, clusterSystem, isLegacy)

    local subTypeIndex
    
    if isLegacy then
        subTypeIndex = xmlFile:getInt(key .. "#subType", 3)
    else
        local subTypeName = xmlFile:getString(key .. "#subType", "COW_HOLSTEIN")
        subTypeIndex = g_currentMission.animalSystem:getSubTypeIndexByName(subTypeName)
    end

    if subTypeIndex == nil then return nil end

    local age = xmlFile:getInt(key .. "#age")
    local health = xmlFile:getFloat(key .. "#health")
    local monthsSinceLastBirth = xmlFile:getInt(key .. "#monthsSinceLastBirth")
    local gender = xmlFile:getString(key .. "#gender")
    local reproduction = xmlFile:getFloat(key .. "#reproduction")
    local isParent = xmlFile:getBool(key .. "#isParent")
    local isPregnant = xmlFile:getBool(key .. "#isPregnant")
    local isLactating = xmlFile:getBool(key .. "#isLactating")
    local id = xmlFile:getString(key .. "#id", nil)
    local farmId = xmlFile:getString(key .. "#farmId", nil)
    local motherId = xmlFile:getString(key .. "#motherId", nil)
    local fatherId = xmlFile:getString(key .. "#fatherId", nil)
    local weight = xmlFile:getFloat(key .. "#weight", nil)
    local variation = xmlFile:getInt(key .. "#variation", nil)

    if subTypeIndex == nil then
        local subTypeName = xmlFile:getString(key .. "#subType", nil)
        if subTypeName == nil then return nil end
        subTypeIndex = g_currentMission.animalSystem:getSubTypeIndexByName(subTypeName)
    end


    local name = xmlFile:getString(key .. "#name", nil)
    local dirt = xmlFile:getFloat(key .. "#dirt", nil)
    local fitness = xmlFile:getFloat(key .. "#fitness", nil)
    local riding = xmlFile:getFloat(key .. "#riding", nil)

    local pos = nil

    local children = {}

    xmlFile:iterate(key .. ".children.child", function (_, childrenKey)

        local childUniqueId = xmlFile:getString(childrenKey .. "#uniqueId", nil)
        local childFarmId = xmlFile:getString(childrenKey .. "#farmId", nil)
        local child = {
            farmId = childFarmId,
            uniqueId = childUniqueId
        }
        table.insert(children, child)

    end)


    local pregnancy

    if xmlFile:hasProperty(key .. ".pregnancy") then

        pregnancy = { ["pregnancies"] = {} }
        local pregnancyKey = key .. ".pregnancy"

        pregnancy.expected = {
            ["day"] = xmlFile:getInt(pregnancyKey .. "#day", 1),
            ["month"] = xmlFile:getInt(pregnancyKey .. "#month", 1),
            ["year"] = xmlFile:getInt(pregnancyKey .. "#year", 1)
        }

        pregnancy.duration = xmlFile:getInt(pregnancyKey .. "#duration", 1)

        xmlFile:iterate(pregnancyKey .. ".pregnancies.pregnancy", function (_, pregnanciesKey)

            local child = Animal.loadFromXMLFile(xmlFile, pregnanciesKey)

            table.insert(pregnancy.pregnancies, child)

        end)

    end


    local birthdayDay = xmlFile:getInt(key .. ".birthday#day", nil)
    local birthdayMonth = xmlFile:getInt(key .. ".birthday#month", nil)
    local birthdayYear = xmlFile:getInt(key .. ".birthday#year", nil)
    local birthdayCountry = xmlFile:getInt(key .. ".birthday#country", nil)
    local lastAgeMonth = xmlFile:getInt(key .. ".birthday#lastAgeMonth", 0)


    local birthday

    if birthdayDay ~= nil and birthdayMonth ~= nil and birthdayYear ~= nil and birthdayCountry ~= nil then
        birthday = {
            ["day"] = birthdayDay,
            ["month"] = birthdayMonth,
            ["year"] = birthdayYear,
            ["country"] = birthdayCountry,
            ["lastAgeMonth"] = lastAgeMonth
        }
    end

    


    --local impregnatedById = xmlFile:getString(key .. ".impregnatedBy#uniqueId", nil)
    --local impregnatedByMetabolism = xmlFile:getFloat(key .. ".impregnatedBy#metabolism", nil)
    --local impregnatedByMeatQuality = xmlFile:getFloat(key .. ".impregnatedBy#quality", nil)
    --local impregnatedByProductivity = xmlFile:getFloat(key .. ".impregnatedBy#productivity", nil)
    --local impregnatedByHealth = xmlFile:getFloat(key .. ".impregnatedBy#health", nil)
    --local impregnatedByFertility = xmlFile:getFloat(key .. ".impregnatedBy#fertility", nil)

    local impregnatedBy

    if xmlFile:hasProperty(key .. ".impregnatedBy") then
    
        impregnatedBy = {
            ["uniqueId"] = xmlFile:getString(key .. ".impregnatedBy#uniqueId", nil),
            ["metabolism"] = xmlFile:getFloat(key .. ".impregnatedBy#metabolism", nil),
            ["productivity"] = xmlFile:getFloat(key .. ".impregnatedBy#productivity", nil),
            ["quality"] = xmlFile:getFloat(key .. ".impregnatedBy#quality", nil),
            ["health"] = xmlFile:getFloat(key .. ".impregnatedBy#health", nil),
            ["fertility"] = xmlFile:getFloat(key .. ".impregnatedBy#fertility", nil)
        }

    end


    --local metabolism = xmlFile:getFloat(key .. ".genetics#metabolism", nil)
    --local productivity = xmlFile:getFloat(key .. ".genetics#productivity", nil)
    --local quality = xmlFile:getFloat(key .. ".genetics#quality", nil)
    --local healthGenetics = xmlFile:getFloat(key .. ".genetics#health", nil)
    --local fertility = xmlFile:getFloat(key .. ".genetics#fertility", nil)
    
    local genetics

    if xmlFile:hasProperty(key .. ".genetics") then

        genetics = {
            ["metabolism"] = xmlFile:getFloat(key .. ".genetics#metabolism", nil),
            ["productivity"] = xmlFile:getFloat(key .. ".genetics#productivity", nil),
            ["quality"] = xmlFile:getFloat(key .. ".genetics#quality", nil),
            ["health"] = xmlFile:getFloat(key .. ".genetics#health", nil),
            ["fertility"] = xmlFile:getFloat(key .. ".genetics#fertility", nil)
        }

    end



    local animal = Animal.new(age, health, monthsSinceLastBirth, gender, subTypeIndex, reproduction, isParent, isPregnant, isLactating, clusterSystem, id, motherId, fatherId, pos, name, dirt, fitness, riding, farmId, weight, genetics, impregnatedBy, variation, children)
    --local animal = Animal.new(age, health, monthsSinceLastBirth, gender, subTypeIndex, reproduction, isParent, isPregnant, isLactating, clusterSystem, id, motherId, fatherId, impregnatedById, pos, name, dirt, fitness, riding, farmId, weight, metabolism, impregnatedByMetabolism, impregnatedByProductivity, productivity, quality, impregnatedByMeatQuality, impregnatedByHealth, impregnatedByFertility, healthGenetics, fertility, variation, children)

    animal:setBirthday(birthday)
    
    if pregnancy ~= nil and #pregnancy.pregnancies > 0 then animal.pregnancy = pregnancy end

    return animal

end


function Animal:saveToXMLFile(xmlFile, key)

    xmlFile:setInt(key .. "#age", self.age)
    xmlFile:setFloat(key .. "#health", self.health)
    xmlFile:setInt(key .. "#monthsSinceLastBirth", self.monthsSinceLastBirth)
    xmlFile:setInt(key .. "#numAnimals", 1)
    xmlFile:setString(key .. "#gender", self.gender)
    xmlFile:setString(key .. "#subType", self.subType)
    xmlFile:setFloat(key .. "#reproduction", self.reproduction)
    xmlFile:setBool(key .. "#isParent", self.isParent)
    xmlFile:setBool(key .. "#isPregnant", self.isPregnant)
    xmlFile:setBool(key .. "#isLactating", self.isLactating)
    xmlFile:setString(key .. "#id", self.uniqueId)
    if self.variation ~= nil then xmlFile:setInt(key .. "#variation", self.variation) end
    xmlFile:setString(key .. "#farmId", self.farmId)
    xmlFile:setString(key .. "#motherId", self.motherId)
    xmlFile:setString(key .. "#fatherId", self.fatherId)
    xmlFile:setFloat(key .. "#weight", self.weight)

    if self.name ~= nil and self.name ~= "" then xmlFile:setString(key .. "#name", self.name) end
    if self.dirt ~= nil then xmlFile:setFloat(key .. "#dirt", self.dirt) end
    if self.fitness ~= nil then xmlFile:setFloat(key .. "#fitness", self.fitness) end
    if self.riding ~= nil then xmlFile:setFloat(key .. "#riding", self.riding) end

    xmlFile:setSortedTable(key .. ".children.child", self.children, function (index, child)
        xmlFile:setString(index .. "#uniqueId", child.uniqueId)
        xmlFile:setString(index .. "#farmId", child.farmId)
    end)

    if self.pregnancy ~= nil then

        local pregnancy = self.pregnancy
        local pregnancyKey = key .. ".pregnancy"

        xmlFile:setInt(pregnancyKey .. "#day", pregnancy.expected.day)
        xmlFile:setInt(pregnancyKey .. "#month", pregnancy.expected.month)
        xmlFile:setInt(pregnancyKey .. "#year", pregnancy.expected.year)
        xmlFile:setInt(pregnancyKey .. "#duration", pregnancy.duration)

        xmlFile:setSortedTable(pregnancyKey .. ".pregnancies.pregnancy", pregnancy.pregnancies, function (index, child)
        
            xmlFile:setFloat(index .. "#health", child.health)
            xmlFile:setString(index .. "#gender", child.gender)
            xmlFile:setInt(index .. "#subType", child.subTypeIndex)
            xmlFile:setString(index .. "#motherId", child.motherId)
            xmlFile:setString(index .. "#fatherId", child.fatherId)

            local pregnancyGenetics = child.genetics

            if pregnancyGenetics ~= nil then

                xmlFile:setFloat(index .. ".genetics#metabolism", pregnancyGenetics.metabolism)
                xmlFile:setFloat(index .. ".genetics#quality", pregnancyGenetics.quality)
                xmlFile:setFloat(index .. ".genetics#health", pregnancyGenetics.health)
                xmlFile:setFloat(index .. ".genetics#fertility", pregnancyGenetics.fertility)
                if pregnancyGenetics.productivity ~= nil then xmlFile:setFloat(index .. ".genetics#productivity", pregnancyGenetics.productivity) end

            end

        end)

    end

    if self.impregnatedBy ~= nil then

        xmlFile:setString(key .. ".impregnatedBy#uniqueId", self.impregnatedBy.uniqueId)
        xmlFile:setFloat(key .. ".impregnatedBy#metabolism", self.impregnatedBy.metabolism)
        xmlFile:setFloat(key .. ".impregnatedBy#quality", self.impregnatedBy.quality)
        xmlFile:setFloat(key .. ".impregnatedBy#health", self.impregnatedBy.health)
        xmlFile:setFloat(key .. ".impregnatedBy#fertility", self.impregnatedBy.fertility)
        if self.impregnatedBy.productivity ~= nil then xmlFile:setFloat(key .. ".impregnatedBy#productivity", self.impregnatedBy.productivity) end
    end

    if self.genetics ~= nil then

        xmlFile:setFloat(key .. ".genetics#metabolism", self.genetics.metabolism)
        xmlFile:setFloat(key .. ".genetics#quality", self.genetics.quality)
        xmlFile:setFloat(key .. ".genetics#health", self.genetics.health)
        xmlFile:setFloat(key .. ".genetics#fertility", self.genetics.fertility)
        if self.genetics.productivity ~= nil then xmlFile:setFloat(key .. ".genetics#productivity", self.genetics.productivity) end
    end

    if self.birthday ~= nil then

        xmlFile:setInt(key .. ".birthday#day", self.birthday.day)
        xmlFile:setInt(key .. ".birthday#month", self.birthday.month)
        xmlFile:setInt(key .. ".birthday#year", self.birthday.year)
        xmlFile:setInt(key .. ".birthday#country", self.birthday.country)
        xmlFile:setInt(key .. ".birthday#lastAgeMonth", self.birthday.lastAgeMonth)

    end

end


function Animal:clone()

    local impregnatedBy = self.impregnatedBy or nil
    
    --local newAnimal = self.new(self.age, self.health, self.monthsSinceLastBirth, self.gender, self.subTypeIndex, self.reproduction, self.isParent, self.isPregnant, self.isLactating, self.clusterSystem, self.uniqueId, self.motherId, self.fatherId, impregnatedBy ~= nil and impregnatedBy.uniqueId or nil, self.pos or nil, self.name or nil, self.dirt or nil, self.fitness or nil, self.riding or nil, self.farmId, self.weight, self.metabolism, impregnatedBy ~= nil and impregnatedBy.metabolism or nil, impregnatedBy ~= nil and impregnatedBy.productivity or nil, self.genetics.productivity or nil, self.genetics.quality, impregnatedBy ~= nil and impregnatedBy.quality or nil, impregnatedBy ~= nil and impregnatedBy.health or nil, impregnatedBy ~= nil and impregnatedBy.fertility or nil, self.genetics.health, self.genetics.fertility, self.variation, self.children)
    local newAnimal = self.new(self.age, self.health, self.monthsSinceLastBirth, self.gender, self.subTypeIndex, self.reproduction, self.isParent, self.isPregnant, self.isLactating, self.clusterSystem, self.uniqueId, self.motherId, self.fatherId, self.pos, self.name, self.dirt, self.fitness, self.riding, self.farmId, self.weight, self.genetics, self.impregnatedBy, self.variation, self.children)

    --if self.impregnatedBy ~= nil then
        --newAnimal.impregnatedBy = {
            --uniqueId = self.impregnatedBy.uniqueId,
            --metabolism = self.impregnatedBy.metabolism,
            --quality = self.impregnatedBy.quality,
            --health = self.impregnatedBy.health,
            --fertility = self.impregnatedBy.fertility
        --}
    --end

    newAnimal:setBirthday(self.birthday)
    
    if self.pregnancy ~= nil then newAnimal.pregnancy = self.pregnancy end

    return newAnimal

end


function Animal:setBirthday(birthday)
    
    if birthday ~= nil then self.birthday = birthday end

end

function Animal:getBirthday()

    return self.birthday

end


function Animal:setGenetics(genetics)

    self.genetics = genetics

end


function Animal:getGenetics()

    return self.genetics

end


function Animal:setUniqueId(farmId)

    if self.clusterSystem == nil then
    
        if farmId == nil then return end

        if type(farmId) == "string" then farmId = tonumber(farmId) end

        local id = g_currentMission.animalSystem:getNextAnimalIdForFarm(self.birthday.country, self.animalTypeIndex, farmId)

        id = tostring(id)
        local idLen = string.len(id)

        if idLen < 5 then
            if idLen == 1 then
                id = "1000" .. id
            elseif idLen == 2 then
                id = "100" .. id
            elseif idLen == 3 then
                id = "10" .. id
            elseif idLen == 4 then
                id = "1" .. id
            end
        end

        local concatenated = farmId .. id
        local checkDigit = (tonumber(concatenated)::number % 7) + 1
        id = checkDigit .. id

        self.farmId = tostring(farmId)
        self.uniqueId = id

        return
    
    end

    local ownerFarmId = self.clusterSystem.owner.ownerFarmId
    local farm = g_farmManager.farmIdToFarm[ownerFarmId]


    if farm == nil then

        self.uniqueId, self.farmId = "1", "1"

    else

        id = farm.stats:getNextAnimalId(g_currentMission.animalSystem:getSubTypeByIndex(self.subTypeIndex).typeIndex)

        local farmHerdId = farm.stats.statistics.farmId
        if farmHerdId == nil then
            farmHerdId = math.random(100000, 999999)
            farm.stats.statistics.farmId = farmHerdId
        end

        id = tostring(id)
        local idLen = string.len(id)

        if idLen < 5 then
            if idLen == 1 then
                id = "1000" .. id
            elseif idLen == 2 then
                id = "100" .. id
            elseif idLen == 3 then
                id = "10" .. id
            elseif idLen == 4 then
                id = "1" .. id
            end
        end

        local concatenated = farmHerdId .. id
        local checkDigit = (tonumber(concatenated)::number % 7) + 1
        id = checkDigit .. id

        self.farmId = tostring(farmHerdId)
        self.uniqueId = id

    end

end


function Animal:getHash()
    return (100 + self.age) + (1000 * (100 + self.health)) + (1000000 * (100 + self.reproduction)) + (1000000000 * (100 + self.subTypeIndex))
end



function Animal:changeNumAnimals(delta)

    local oldNum = self.numAnimals
    self.numAnimals = math.clamp(math.floor(self.numAnimals + delta), 0, 1)
    self:setDirty()
    return delta - (self.numAnimals - oldNum)

end


function Animal:setDirty()
    self.isDirty = true
    if self.clusterSystem ~= nil then self.clusterSystem:setDirty() end
end



function Animal:getRidableFilename()
    return self:getSubType().rideableFilename or nil
end


function Animal:getNumAnimals()
    return self.numAnimals
end

function Animal:getSubTypeIndex()
    return self.subTypeIndex
end

function Animal:getSubType()
    return g_currentMission.animalSystem:getSubTypeByName(self.subType)
end

function Animal:increaseAge()
    self.age = self.age + 1
end

function Animal:getAge()
    return self.age
end


function Animal:getName()
    return self.name or ""
end


function Animal:setName(name)
    self.name = name
end


function Animal:getTranportationFee(factor)
    return g_currentMission.animalSystem:getAnimalTransportFee(self.subTypeIndex, self.age) * factor
end


function Animal:getCanBeSold()
    return self.isDead == false
end


function Animal:addInfos(infos)

    local subType = self:getSubType()

    local healthFactor = self:getHealthFactor()
    self.infoHealth.value = healthFactor
    self.infoHealth.ratio = healthFactor
    self.infoHealth.valueText = string.format("%d %%", g_i18n:formatNumber(healthFactor * 100, 0))

    table.insert(infos, self.infoHealth)

    if self:getSupportsReproduction() then
        local reproductionFactor = self:getReproductionFactor()
        self.infoReproduction.value = reproductionFactor
        self.infoReproduction.ratio = reproductionFactor
        self.infoReproduction.valueText = string.format("%d %%", g_i18n:formatNumber(reproductionFactor * 100, 0))
        self.infoReproduction.disabled = not self:getCanReproduce()
        self.infoReproduction.title = self.infoReproduction.titleOrg

        if self.infoReproduction.disabled then
            local attributeText, valueText = nil

            if self.age < subType.reproductionMinAgeMonth then
                attributeText = g_i18n:getText("rl_ui_tooYoung")
                valueText = g_i18n:formatNumMonth(subType.reproductionMinAgeMonth)
            elseif self.isParent and self.monthsSinceLastBirth <= 2 then
                attributeText = g_i18n:getText("rl_ui_recoveringLastBirth")
                valueText = g_i18n:formatNumMonth(3 - self.monthsSinceLastBirth)
            elseif not RealisticLivestock.hasMaleAnimalInPen(self.clusterSystem, subType.name, self) and self.reproduction == 0 then
                attributeText = g_i18n:getText("rl_ui_noMaleAnimal")
                valueText = "0"
            elseif healthFactor < subType.reproductionMinHealth then
                attributeText = g_i18n:getText("rl_ui_unhealthy")
                valueText = string.format("%d %%", subType.reproductionMinHealth)
            end

            self.infoReproduction.title = self.infoReproduction.title .. string.format(" (%s < %s)", attributeText, valueText)
        end

        table.insert(infos, self.infoReproduction)
    end


    if self.infoWeight == nil then
        self.infoWeight = {
            text = g_i18n:getText("rl_ui_weight"),
            title = g_i18n:getText("rl_ui_weight")
        }
    end


    self.infoWeight.value = 1
    self.infoWeight.ratio = self.weight / self.targetWeight
    self.infoWeight.valueText = string.format("%.2f", self.weight) .. "kg / " .. string.format("%.2f", self.targetWeight) .. "kg"

    table.insert(infos, self.infoWeight)


    if self.gender ~= nil and self.gender == "female" then

        if self.infoPregnant == nil then
            self.infoPregnant = {
                text = g_i18n:getText("rl_ui_pregnant"),
                title = g_i18n:getText("rl_ui_pregnant")
            }
        end


        self.infoPregnant.value = 1
        self.infoPregnant.ratio = self.isPregnant and 1 or 0
        self.infoPregnant.valueText = self.isPregnant and g_i18n:getText("rl_ui_yes") or g_i18n:getText("rl_ui_no")

        table.insert(infos, self.infoPregnant)

        local pregnancy = self.pregnancy

        if pregnancy ~= nil and pregnancy.pregnancies and #pregnancy.pregnancies > 0 then

            if self.infoPregnancyExpecting == nil then
                self.infoPregnancyExpecting = {
                    text = g_i18n:getText("rl_ui_pregnancyExpecting"),
                    title = g_i18n:getText("rl_ui_pregnancyExpecting"),
                    value = 1,
                    ratio = 1
                }
            end

            if self.infoPregnancyExpected == nil then
                self.infoPregnancyExpected = {
                    text = g_i18n:getText("rl_ui_pregnancyExpected"),
                    title = g_i18n:getText("rl_ui_pregnancyExpected"),
                    value = 1,
                    ratio = 1
                }
            end

            self.infoPregnancyExpecting.valueText = string.format("%s %s", #pregnancy.pregnancies, g_i18n:getText("rl_ui_pregnancy" .. (#pregnancy.pregnancies == 1 and "Baby" or "Babies")))
            self.infoPregnancyExpected.valueText = string.format("%s/%s/%s", pregnancy.expected.day, pregnancy.expected.month, pregnancy.expected.year + RealisticLivestock.START_YEAR.FULL)

            table.insert(infos, self.infoPregnancyExpecting)
            table.insert(infos, self.infoPregnancyExpected)

        end

        if self.isLactating ~= nil and self.age > 12 and self.clusterSystem.owner.spec_husbandryMilk ~= nil then

            if self.infoLactation == nil then
                self.infoLactation = {
                    text = g_i18n:getText("rl_ui_lactating"),
                    title = g_i18n:getText("rl_ui_lactating")
                }
            end

            self.infoLactation.value = 1
            self.infoLactation.ratio = self.isLactating and 1 or 0
            self.infoLactation.valueText = self.isLactating and g_i18n:getText("rl_ui_yes") or g_i18n:getText("rl_ui_no")

            table.insert(infos, self.infoLactation)

        end

    end


    if self.animalTypeIndex == AnimalType.HORSE then

        if self.infoFitness == nil then
                self.infoFitness = {
                    text = "",
                    title = g_i18n:getText("ui_horseFitness")
                }
        end

        local fitness = self:getFitnessFactor()

        self.infoFitness.value = fitness
        self.infoFitness.ratio = fitness
        self.infoFitness.valueText = string.format("%d %%", g_i18n:formatNumber(fitness * 100, 0))

        table.insert(infos, self.infoFitness)


        if self.infoRiding == nil then
                self.infoRiding = {
                    text = "",
                    title = g_i18n:getText("ui_horseDailyRiding")
                }
        end

        local riding = self:getRidingFactor()

        self.infoRiding.value = riding
        self.infoRiding.ratio = riding
        self.infoRiding.valueText = string.format("%d %%", g_i18n:formatNumber(riding * 100, 0))

        table.insert(infos, self.infoRiding)


        if Platform.gameplay.needHorseCleaning then

            if self.infoCleanliness == nil then
                self.infoCleanliness = {
                    text = "",
                    title = g_i18n:getText("statistic_cleanliness")
                }
            end

            local cleanliness = 1 - self:getDirtFactor()

            self.infoCleanliness.value = cleanliness
            self.infoCleanliness.ratio = cleanliness
            self.infoCleanliness.valueText = string.format("%d %%", g_i18n:formatNumber(cleanliness * 100, 0))

            table.insert(infos, self.infoCleanliness)

        end
    end


end


function Animal:showInfo(box)

    local index = self:getSubTypeIndex()
    local subType = self:getSubType()
    local name = subType.name

    local yesText = g_i18n:getText("rl_ui_yes")
    local noText = g_i18n:getText("rl_ui_no")

    local fillTypeTitle = g_fillTypeManager:getFillTypeTitleByIndex(subType.fillTypeIndex)

    box:addLine(g_i18n:getText("infohud_type"), fillTypeTitle)
    if self:getName() ~= "" then box:addLine(g_i18n:getText("infohud_name"), self:getName()) end
    box:addLine(g_i18n:getText("rl_ui_uniqueId"), self.uniqueId)
    box:addLine(g_i18n:getText("rl_ui_farmId"), self.farmId)
    box:addLine(g_i18n:getText("infohud_age"), RealisticLivestock.formatAge(self.age))

    if self.birthday ~= nil then

        local birthday = self.birthday
        box:addLine(g_i18n:getText("rl_ui_birthday"), string.format("%d/%d/%d", birthday.day, birthday.month, RealisticLivestock.START_YEAR.FULL + birthday.year))

    end

    box:addLine(g_i18n:getText("infohud_health"), string.format("%d%%", self.health))
    box:addLine(g_i18n:getText("rl_ui_gender"), self.gender == "male" and g_i18n:getText("rl_ui_male") or g_i18n:getText("rl_ui_female"))

    box:addLine(g_i18n:getText("rl_ui_weight"), string.format("%.2f", self.weight) .. "kg")
    box:addLine(g_i18n:getText("rl_ui_targetWeight"), string.format("%.2f", self.targetWeight) .. "kg")


    if string.contains(self.subType, "HORSE", true) or string.contains(self.subType, "STALLION", true) then
        box:addLine(g_i18n:getText("infohud_riding"), string.format("%d%%", self.riding))
        box:addLine(g_i18n:getText("infohud_fitness"), string.format("%d%%", self.fitness))
        if Platform.gameplay.needHorseCleaning then box:addLine(g_i18n:getText("statistic_cleanliness"), string.format("%d%%", 100 - self.dirt)) end
    end


    if self.clusterSystem ~= nil and self.clusterSystem.owner.spec_husbandryMilk ~= nil and self.gender ~= nil and self.gender == "female" and self.age >= 12 then
        if self.isLactating ~= nil then box:addLine(g_i18n:getText("rl_ui_lactating"), self.isLactating and yesText or noText) end
    end

    if self.gender ~= nil and self.gender == "female" and subType.supportsReproduction then

        box:addLine(g_i18n:getText("infohud_reproduction"), string.format("%d%%", self.reproduction))


        local pregnancy = self.pregnancy

        if pregnancy ~= nil and pregnancy.pregnancies and #pregnancy.pregnancies > 0 then

            box:addLine(g_i18n:getText("rl_ui_pregnancyExpecting"), string.format("%s %s", #pregnancy.pregnancies, g_i18n:getText("rl_ui_pregnancy" .. (#pregnancy.pregnancies == 1 and "Baby" or "Babies"))))
            box:addLine(g_i18n:getText("rl_ui_pregnancyExpected"), string.format("%s/%s/%s", pregnancy.expected.day, pregnancy.expected.month, pregnancy.expected.year + RealisticLivestock.START_YEAR.FULL))

        end


        local healthFactor = self:getHealthFactor()
        local text = yesText

        if self.age < subType.reproductionMinAgeMonth then
            text = g_i18n:getText("rl_ui_tooYoungBracketed")
        elseif self.isParent and self.monthsSinceLastBirth <= 2 then
            text = g_i18n:getText("rl_ui_recoveringLastBirthBracketed")
        elseif not RealisticLivestock.hasMaleAnimalInPen(self.clusterSystem.owner.spec_husbandryAnimals, name, self) and not self.isPregnant then
            text = g_i18n:getText("rl_ui_noMaleAnimalBracketed")
        elseif healthFactor < subType.reproductionMinHealth then
            text = g_i18n:getText("rl_ui_unhealthyBracketed")
        end

        box:addLine(g_i18n:getText("rl_ui_canReproduce"), text)

        if self.age >= subType.reproductionMinAgeMonth then box:addLine(g_i18n:getText("rl_ui_pregnant"), self.isPregnant and yesText or noText) end

        if self.isPregnant then box:addLine(g_i18n:getText("rl_ui_impregnatedBy"), (self.impregnatedBy ~= nil and self.impregnatedBy.uniqueId ~= "-1") and self.impregnatedBy.uniqueId or g_i18n:getText("rl_ui_unknown")) end
    elseif self.gender ~= nil and self.gender == "male" and subType.reproductionMinAgeMonth ~= nil and self.age >= subType.reproductionMinAgeMonth then
        local monotonicHour = g_currentMission.environment:getMonotonicHour()
        if self.numImpregnatableAnimals == nil or (self.lastNumImpregnatableAnimalsUpdate ~= nil and monotonicHour >= self.lastNumImpregnatableAnimalsUpdate + 1) then
            self.lastNumImpregnatableAnimalsUpdate = monotonicHour
            self.numImpregnatableAnimals = self:getNumberOfImpregnatableFemalesForMale()
        end

        box:addLine(g_i18n:getText("rl_ui_maleNumImpregnatable"), string.format("%s", self.numImpregnatableAnimals or 0))
    end

    box:addLine(g_i18n:getText("rl_ui_value"), g_i18n:formatMoney(self:getSellPrice(), 2, true, true))
    box:addLine(g_i18n:getText("rl_ui_valuePerKilo"), g_i18n:formatMoney(self:getSellPrice() / self.weight, 2, true, true))

end


function Animal:showGeneticsInfo(box)

    local genetics = self.genetics
    local metabolism = genetics.metabolism
    local typeIndex = self.animalTypeIndex


    local overallGenetics = metabolism + genetics.quality + genetics.health + genetics.fertility + (genetics.productivity ~= nil and genetics.productivity or 0)
    local bestGenetics = 1.75 + 1.75 + 1.75 + 1.75 + (genetics.productivity ~= nil and 1.75 or 0)
    local qualityText = "extremelyBad"
    local geneticsFactor = overallGenetics / bestGenetics

    if geneticsFactor >= 0.95 then
        qualityText = "extremelyGood"
    elseif geneticsFactor >= 0.8 then
        qualityText = "veryGood"
    elseif geneticsFactor >= 0.65 then
        qualityText = "good"
    elseif geneticsFactor >= 0.35 then
        qualityText = "average"
    elseif geneticsFactor >= 0.2 then
        qualityText = "bad"
    elseif geneticsFactor >= 0.05 then
        qualityText = "veryBad"
    end

    box:addLine("rl_ui_overall", "rl_ui_genetics_" .. qualityText)

    if metabolism >= 1.65 then
        qualityText = "extremelyHigh"
    elseif metabolism >= 1.4 then
        qualityText = "veryHigh"
    elseif metabolism >= 1.1 then
        qualityText = "high"
    elseif metabolism >= 0.9 then
        qualityText = "average"
    elseif metabolism >= 0.7 then
        qualityText = "low"
    elseif metabolism >= 0.35 then
        qualityText = "veryLow"
    else
        qualityText = "extremelyLow"
    end

    box:addLine(g_i18n:getText("rl_ui_metabolism"), "rl_ui_genetics_" .. qualityText)

    local health = genetics.health

    if health >= 1.65 then
        qualityText = "extremelyHigh"
    elseif health >= 1.4 then
        qualityText = "veryHigh"
    elseif health >= 1.1 then
        qualityText = "high"
    elseif health >= 0.9 then
        qualityText = "average"
    elseif health >= 0.7 then
        qualityText = "low"
    elseif health >= 0.35 then
        qualityText = "veryLow"
    else
        qualityText = "extremelyLow"
    end

    box:addLine(g_i18n:getText("rl_ui_health"), "rl_ui_genetics_" .. qualityText)

    local fertility = genetics.fertility

    if fertility >= 1.65 then
        qualityText = "extremelyHigh"
    elseif fertility >= 1.4 then
        qualityText = "veryHigh"
    elseif fertility >= 1.1 then
        qualityText = "high"
    elseif fertility >= 0.9 then
        qualityText = "average"
    elseif fertility >= 0.7 then
        qualityText = "low"
    elseif fertility >= 0.35 then
        qualityText = "veryLow"
    else
        qualityText = "extremelyLow"
    end

    box:addLine(g_i18n:getText("rl_ui_fertility"), "rl_ui_genetics_" .. qualityText)

    local meat = genetics.quality

    if meat >= 1.65 then
        qualityText = "extremelyHigh"
    elseif meat >= 1.4 then
        qualityText = "veryHigh"
    elseif meat >= 1.1 then
        qualityText = "high"
    elseif meat >= 0.9 then
        qualityText = "average"
    elseif meat >= 0.7 then
        qualityText = "low"
    elseif meat >= 0.35 then
        qualityText = "veryLow"
    else
        qualityText = "extremelyLow"
    end

    box:addLine(g_i18n:getText("rl_ui_meat"), "rl_ui_genetics_" .. qualityText)

    if genetics.productivity ~= nil then

        local productivity = genetics.productivity

        if productivity >= 1.65 then
            qualityText = "extremelyHigh"
        elseif productivity >= 1.4 then
            qualityText = "veryHigh"
        elseif productivity >= 1.1 then
            qualityText = "high"
        elseif productivity >= 0.9 then
            qualityText = "average"
        elseif productivity >= 0.7 then
            qualityText = "low"
        elseif productivity >= 0.35 then
            qualityText = "veryLow"
        else
            qualityText = "extremelyLow"
        end

        if typeIndex == AnimalType.COW then box:addLine(g_i18n:getText("rl_ui_milk"), "rl_ui_genetics_" .. qualityText) end
        if typeIndex == AnimalType.SHEEP then box:addLine(g_i18n:getText("rl_ui_wool"), "rl_ui_genetics_" .. qualityText) end
        if typeIndex == AnimalType.CHICKEN then box:addLine(g_i18n:getText("rl_ui_eggs"), "rl_ui_genetics_" .. qualityText) end

    end

end


function Animal:addGeneticsInfo()

    local texts = {}

    local genetics = self.genetics
    if genetics == nil then return {} end

    local text = {}

    local metabolism = genetics.metabolism
    local overallGenetics = metabolism + genetics.quality + genetics.health + genetics.fertility + (genetics.productivity ~= nil and genetics.productivity or 0)
    local bestGenetics = 1.75 + 1.75 + 1.75 + 1.75 + (genetics.productivity ~= nil and 1.75 or 0)
    local qualityText = "extremelyBad"
    local geneticsFactor = overallGenetics / bestGenetics

    if geneticsFactor >= 0.95 then
        qualityText = "extremelyGood"
    elseif geneticsFactor >= 0.8 then
        qualityText = "veryGood"
    elseif geneticsFactor >= 0.6 then
        qualityText = "good"
    elseif geneticsFactor >= 0.4 then
        qualityText = "average"
    elseif geneticsFactor >= 0.2 then
        qualityText = "bad"
    elseif geneticsFactor >= 0.05 then
        qualityText = "veryBad"
    end

    text = {
        title = g_i18n:getText("rl_ui_overall"),
        text = "rl_ui_genetics_" .. qualityText
    }

    table.insert(texts, text)

    if metabolism >= 1.65 then
        qualityText = "extremelyHigh"
    elseif metabolism >= 1.4 then
        qualityText = "veryHigh"
    elseif metabolism >= 1.1 then
        qualityText = "high"
    elseif metabolism >= 0.9 then
        qualityText = "average"
    elseif metabolism >= 0.7 then
        qualityText = "low"
    elseif metabolism >= 0.35 then
        qualityText = "veryLow"
    else
        qualityText = "extremelyLow"
    end

    text = {
        title = g_i18n:getText("rl_ui_metabolism"),
        text = "rl_ui_genetics_" .. qualityText
    }

    table.insert(texts, text)

    local health = genetics.health

    if health >= 1.65 then
        qualityText = "extremelyHigh"
    elseif health >= 1.4 then
        qualityText = "veryHigh"
    elseif health >= 1.1 then
        qualityText = "high"
    elseif health >= 0.9 then
        qualityText = "average"
    elseif health >= 0.7 then
        qualityText = "low"
    elseif health >= 0.35 then
        qualityText = "veryLow"
    else
        qualityText = "extremelyLow"
    end

    text = {
        title = g_i18n:getText("rl_ui_health"),
        text = "rl_ui_genetics_" .. qualityText
    }

    table.insert(texts, text)

    local fertility = genetics.fertility

    if fertility >= 1.65 then
        qualityText = "extremelyHigh"
    elseif fertility >= 1.4 then
        qualityText = "veryHigh"
    elseif fertility >= 1.1 then
        qualityText = "high"
    elseif fertility >= 0.9 then
        qualityText = "average"
    elseif fertility >= 0.7 then
        qualityText = "low"
    elseif fertility >= 0.35 then
        qualityText = "veryLow"
    else
        qualityText = "extremelyLow"
    end

    text = {
        title = g_i18n:getText("rl_ui_fertility"),
        text = "rl_ui_genetics_" .. qualityText
    }

    table.insert(texts, text)

    local meat = genetics.quality

    if meat >= 1.65 then
        qualityText = "extremelyHigh"
    elseif meat >= 1.4 then
        qualityText = "veryHigh"
    elseif meat >= 1.1 then
        qualityText = "high"
    elseif meat >= 0.9 then
        qualityText = "average"
    elseif meat >= 0.7 then
        qualityText = "low"
    elseif meat >= 0.35 then
        qualityText = "veryLow"
    else
        qualityText = "extremelyLow"
    end

    text = {
        title = g_i18n:getText("rl_ui_meat"),
        text = "rl_ui_genetics_" .. qualityText
    }

    table.insert(texts, text)

    if genetics.productivity ~= nil then

        local productivity = genetics.productivity

        if productivity >= 1.65 then
            qualityText = "extremelyHigh"
        elseif productivity >= 1.4 then
            qualityText = "veryHigh"
        elseif productivity >= 1.1 then
            qualityText = "high"
        elseif productivity >= 0.9 then
            qualityText = "average"
        elseif productivity >= 0.7 then
            qualityText = "low"
        elseif productivity >= 0.35 then
            qualityText = "veryLow"
        else
            qualityText = "extremelyLow"
        end

        local productivityTitle = ""
        if self.animalTypeIndex == AnimalType.COW then productivityTitle = g_i18n:getText("rl_ui_milk") end
        if self.animalTypeIndex == AnimalType.SHEEP then productivityTitle = g_i18n:getText("rl_ui_wool") end
        if self.animalTypeIndex == AnimalType.CHICKEN then productivityTitle = g_i18n:getText("rl_ui_eggs") end

        text = {
            title = productivityTitle,
            text = "rl_ui_genetics_" .. qualityText
        }

        table.insert(texts, text)

    end

    return texts

end


function Animal:getFillTypeTitle()
    return g_fillTypeManager:getFillTypeTitleByIndex(self:getSubType().fillTypeIndex)
end



function Animal:getHealthFactor()
    return self.health /100
end

function Animal:getReproductionFactor()
    return self.reproduction / 100
end

function Animal:getSupportsReproduction()
    return self:getSubType().supportsReproduction
end

function Animal:changeReproduction(delta)

    local old = self.reproduction
    self.reproduction = math.clamp(math.floor(self.reproduction + delta), 0, 100)

    if math.abs(self.reproduction - old) > 0 then
        --self:setDirty()
    end

end

function Animal:getReproductionDelta()

    local duration

    if self.pregnancy ~= nil then duration = self.pregnancy.duration end

    if duration == nil then

        local subType = self:getSubType()
        duration = subType.reproductionDurationMonth

    end

    if duration > 0 then
        return math.floor((100 / duration) / g_currentMission.environment.daysPerPeriod)
    end

    return 0
end

function Animal:getCanReproduce()

    if self.isPregnant or self.pregnancy ~= nil then return true end

    local subType = self:getSubType()

    if not subType.supportsReproduction then return false end

    local canReproduce = RealisticLivestock.hasMaleAnimalInPen(self.clusterSystem.owner.spec_husbandryAnimals, self.subType, self) and (self.monthsSinceLastBirth > 2 or not self.isParent)

    if self:getHealthFactor() >= subType.reproductionMinHealth then
        canReproduce = canReproduce and self.age >= subType.reproductionMinAgeMonth
    else
        canReproduce = false
    end

    return canReproduce

end


function Animal:updateHealth(foodFactor)

    local subType = self:getSubType()
    local healthThresholdFactor = subType.healthThresholdFactor
    local healthGenetics = self.genetics.health

    local factor, delta = nil

    if healthThresholdFactor < foodFactor then
        factor = (foodFactor - healthThresholdFactor) / (1 - healthThresholdFactor)
        delta = subType.healthIncreaseHour
    else
        factor = foodFactor / healthThresholdFactor - 1
        delta = subType.healthDecreaseHour
    end

    local healthDelta = delta * factor * healthGenetics

    if healthDelta ~= 0 then self.health = math.clamp(math.floor(self.health + healthDelta), 0, 100) end

    self:updateWeight(foodFactor)

end


function Animal:updateWeight(foodFactor)

    local subType = self:getSubType()
    local minWeight = subType.minWeight
    local targetWeight = self.targetWeight
    local weight = self.weight
    local metabolism = self.genetics.metabolism
    local adultMonth = subType.reproductionMinAgeMonth * 1.5

    local baseIncrease = ((targetWeight - minWeight) / adultMonth) / 24
    local increase = baseIncrease * (self.gender == "female" and 0.6 or 1.0) * (1 + ((adultMonth - self.age) / 75)) * math.min(foodFactor * 1.25, 1)

    if increase < 0  then metabolism = 1 + (1 - metabolism) end

    increase = increase * metabolism

    if self.clusterSystem ~= nil and self.clusterSystem.owner ~= nil and self.clusterSystem.owner.spec_husbandryMilk ~= nil and self.isLactating then increase = increase * 0.75 end

    local decrease = 0
    if weight > targetWeight then decrease = (weight - targetWeight) / (metabolism * 25) end

    if foodFactor == 0 then
        if weight < targetWeight then
            decrease = (targetWeight - weight) / ((1 - (metabolism - 1)) * 150)
        elseif weight > targetWeight then
            decrease = decrease + ((weight - targetWeight) / ((1 - (metabolism - 1)) * 150))
        end
    end

    self.weight = math.max(self.weight + increase - decrease, 0.001)

    local minWeightForAge = minWeight * (math.min(self.age, subType.reproductionMinAgeMonth * 1.5) + 0.5) * 0.5
    if self.weight < minWeightForAge then self.health = math.clamp(self.health - (((minWeightForAge - self.weight) / minWeightForAge) * 0.2), 0, 100) end

end


function Animal:onPeriodChanged()

    self.monthsSinceLastBirth = self.monthsSinceLastBirth + 1
    
    --if self.birthday ~= nil then self.birthday.needsAgeIncrease = true end

end


function Animal:onDayChanged(spec, isServer, day, month, year, currentDayInPeriod, daysPerPeriod, isSaleAnimal)
    
    local birthday = self.birthday

    --if self.uniqueId == "610017" and self.farmId == "988324" then

        --print(birthday.needsAgeIncrease, self.age)

    --end

    if day == nil then

        local environment = g_currentMission.environment
        month = environment.currentPeriod + 2
        currentDayInPeriod = environment.currentDayInPeriod

        if month > 12 then month = month - 12 end

        daysPerPeriod = environment.daysPerPeriod
        day = 1 + math.floor((currentDayInPeriod - 1) * (RealisticLivestock.DAYS_PER_MONTH[month] / daysPerPeriod))
        year = environment.currentYear

    end


    if birthday ~= nil and birthday.lastAgeMonth ~= month then

        if birthday.day <= day or currentDayInPeriod == daysPerPeriod then
            self:increaseAge()
            self.birthday.lastAgeMonth = month
        end

    elseif birthday == nil and day == 1 then

        self:increaseAge()

    end

    --if self.uniqueId == "610017" and self.farmId == "988324" then

        --print(birthday.needsAgeIncrease, self.age, "-----")

    --end


    local children = 0
    local deadAnimals = 0
    local childrenSold = 0
    local childrenSoldAmount = 0

    if isSaleAnimal or self.clusterSystem ~= nil then

        if self.isPregnant then

            self:changeReproduction(self:getReproductionDelta())

            if self.reproduction >= 100 and self.pregnancy ~= nil and spec ~= nil then

                if self.impregnatedBy == nil then
                    self.impregnatedBy = {
                        uniqueId = "-1",
                        metabolism = self.genetics.metabolism,
                        quality = self.genetics.quality,
                        health = self.genetics.health,
                        fertility = self.genetics.fertility,
                        productivity = self.genetics.productivity or nil
                    }
                end

                if self.impregnatedBy.uniqueId == nil then self.impregnatedBy.uniqueId = "-1" end
                if self.impregnatedBy.metabolism == nil then self.impregnatedBy.metabolism = self.genetics.metabolism end
                if self.impregnatedBy.quality == nil then self.impregnatedBy.quality = self.genetics.meatQuality end
                if self.impregnatedBy.health == nil then self.impregnatedBy.health = self.genetics.health end
                if self.impregnatedBy.fertility == nil then self.impregnatedBy.fertility = self.genetics.fertility end

                self.isLactating = false
                self.isPregnant = false

                local parentDied = false

                children, parentDied, childrenSold, childrenSoldAmount = self:reproduce(spec, day, month, year, isSaleAnimal)

                self.reproduction = 0
                    
                if parentDied then deadAnimals = 1 end
                self.impregnatedBy = nil
                self.pregnancy = nil

            end

        elseif not isSaleAnimal and self:getCanReproduce() then

            local fertility = self.genetics.fertility
            local childNum = self:generateRandomOffspring()


            if math.random() >= (2 - fertility) * 0.5 and childNum > 0 then

                self.isPregnant = true

                local father = {
                    uniqueId = "-1",
                    metabolism = 1.0,
                    quality = 1.0,
                    health = 1.0,
                    fertility = 1.0,
                    productivity = 1.0
                }

                local fatherSubTypeIndex

                for _, animal in pairs(self.clusterSystem:getAnimals()) do

                    if animal.gender ~= "male" then continue end

                    if animal.subType == "BULL_WATERBUFFALO" and self.subType ~= "COW_WATERBUFFALO" then continue end
                    if animal.subType == "RAM_GOAT" and self.subType ~= "GOAT" then continue end
                    if self.subType == "COW_WATERBUFFALO" and animal.subType ~= "BULL_WATERBUFFALO" then continue end
                    if self.subType == "GOAT" and animal.subType ~= "RAM_GOAT" then continue end

                    local animalType = animal.animalTypeIndex


                    local animalSubType = animal:getSubType()
                    local maxFertilityMonth = (animalType == AnimalType.COW and 132) or (animalType == AnimalType.SHEEP and 72) or (animalType == AnimalType.HORSE and 300) or (animalType == AnimalType.CHICKEN and 1000) or (animalType == AnimalType.PIG and 48) or 120
                    maxFertilityMonth = maxFertilityMonth * animal.genetics.fertility

                    if animalSubType.reproductionMinAgeMonth ~= nil and animal:getAge() >= animalSubType.reproductionMinAgeMonth and animal:getAge() < maxFertilityMonth then

                        fatherSubTypeIndex = animal.subTypeIndex

                        father.uniqueId = animal.farmId .. " " .. animal.uniqueId
                        father.metabolism = animal.genetics.metabolism
                        father.quality = animal.genetics.quality
                        father.health = animal.genetics.health
                        father.fertility = animal.genetics.fertility
                        father.productivity = animal.genetics.productivity or nil

                        break

                    end

                end

                self.impregnatedBy = father

                self:changeReproduction(self:getReproductionDelta())

                local genetics = self.genetics

                local motherMetabolism = genetics.metabolism
                local fatherMetabolism = father.metabolism
                local minMetabolism = motherMetabolism >= fatherMetabolism and fatherMetabolism or motherMetabolism
                local maxMetabolism = motherMetabolism < fatherMetabolism and fatherMetabolism or motherMetabolism
                if maxMetabolism == minMetabolism then maxMetabolism = maxMetabolism + 0.01 end

                local motherMeat = genetics.quality
                local fatherMeat = father.quality
                local minMeat = motherMeat >= fatherMeat and fatherMeat or motherMeat
                local maxMeat = motherMeat < fatherMeat and fatherMeat or motherMeat
                if maxMeat == minMeat then maxMeat = maxMeat + 0.01 end

                local motherHealth = genetics.health
                local fatherHealth = father.health
                local minHealth = motherHealth >= fatherHealth and fatherHealth or motherHealth
                local maxHealth = motherHealth < fatherHealth and fatherHealth or motherHealth
                if maxHealth == minHealth then maxHealth = maxHealth + 0.01 end

                local motherFertility = genetics.fertility
                local fatherFertility = father.fertility
                local minFertility = motherFertility >= fatherFertility and fatherFertility or motherFertility
                local maxFertility = motherFertility < fatherFertility and fatherFertility or motherFertility
                if maxFertility == minFertility then maxFertility = maxFertility + 0.01 end

                local motherProductivity
                local fatherProductivity
                local minProductivity
                local maxProductivity

                if genetics.productivity ~= nil then
                    motherProductivity = genetics.productivity
                    fatherProductivity = father.productivity
                    minProductivity = motherProductivity >= fatherProductivity and fatherProductivity or motherProductivity
                    maxProductivity = motherProductivity < fatherProductivity and fatherProductivity or motherProductivity
                    if maxProductivity == minProductivity then maxProductivity = maxProductivity + 0.01 end
                end


                local children = {}


                for i = 1, childNum do


                    local gender = math.random() >= 0.5 and "male" or "female"
                    local subTypeIndex

                    if fatherSubTypeIndex ~= nil and math.random() >= 0.5 then

                        subTypeIndex = fatherSubTypeIndex + (gender == "male" and 0 or -1)

                    else

                        subTypeIndex = self.subTypeIndex + (gender == "male" and 1 or 0)

                    end


                    local child = Animal.new(-1, 100, 0, gender, subTypeIndex, 0, false, false, false, nil, nil, self.farmId .. " " .. self.uniqueId, father.uniqueId)
                        
                    local metabolism = math.random(minMetabolism * 100, maxMetabolism * 100) / 100
                    local quality = math.random(minMeat * 100, maxMeat * 100) / 100
                    local healthGenetics = math.random(minHealth * 100, maxHealth * 100) / 100
                    local fertility = math.random(minFertility * 100, maxFertility * 100) / 100
                    local productivity = nil
                        
                    if genetics.productivity ~= nil then productivity = math.random(minProductivity * 100, maxProductivity * 100) / 100 end


                    child:setGenetics({
                        ["metabolism"] = metabolism,
                        ["quality"] = quality,
                        ["health"] = healthGenetics,
                        ["fertility"] = fertility,
                        ["productivity"] = productivity
                    })


                    table.insert(children, child)

                end


                local reproductionDuration = self:getSubType().reproductionDurationMonth
                    
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


                self.pregnancy = {
                    ["duration"] = reproductionDuration,
                    ["expected"] = {
                        ["day"] = expectedDay,
                        ["month"] = expectedMonth,
                        ["year"] = expectedYear
                    },
                    ["pregnancies"] = children
                }


            end

        end

    end

    local lowHealthDeath, oldDeath, randomDeath, randomDeathMoney = 0, 0, 0, 0

    if self.deathEnabled and (self.clusterSystem == nil or self.clusterSystem.owner:getOwnerFarmId() ~= FarmManager.INVALID_FARM_ID) then

        lowHealthDeath = self:CalculateLowHealthMonthlyAnimalDeaths()
        oldDeath = self:CalculateOldAgeMonthlyAnimalDeaths()
        if spec ~= nil then randomDeath, randomMoney = self:CalculateRandomMonthlyAnimalDeaths(spec) end

    end

    return children, deadAnimals, childrenSold, childrenSoldAmount, lowHealthDeath, oldDeath, randomDeath, randomDeathMoney

end


function Animal:getAnimalTypeIndex()

    return g_currentMission.animalSystem:getTypeIndexBySubTypeIndex(self.subTypeIndex)

end


function Animal:generateRandomOffspring()

    local age = self.age
    local health = self.health
    local animalType = self.animalTypeIndex
    local isParent = self.isParent
    local childNumProb = 500
    local childNum = 1
    local noChildProb = 50

    if health <= 60 then
        childNumProb = math.random(0, 250)
    elseif health <= 75 then
        childNumProb = math.random(10, 500)
    elseif health <= 90 then
        childNumProb = math.random(50, 900)
    else
        childNumProb = math.random(70, 1000)
    end

    childNumProb = childNumProb * self.genetics.fertility


    if animalType == AnimalType.COW then

        if age <= 28 then
            noChildProb = 40
        elseif age <= 36 then
            noChildProb = 32
        elseif age <= 48 then
            noChildProb = 24
        elseif age <= 60 then
            noChildProb = 21
        elseif age <= 84 then
            noChildProb = 70
        elseif age <= 108 then
            noChildProb = 220
        elseif age <= 132 then
            noChildProb = 460
        else
            noChildProb = 1000
        end


        if childNumProb <= noChildProb then
            childNum = 0
        elseif childNumProb >= 950 and childNumProb <= 997 then
            childNum = 2
        elseif childNumProb >= 997 then
            childNum = 3
        end

    elseif animalType == AnimalType.PIG then

        if age <= 12 then
            noChildProb = 60
        elseif age <= 36 then
            noChildProb = 40
        elseif age <= 60 then
            noChildProb = 130
        elseif age <= 80 then
            noChildProb = 250
        elseif age <= 96 then
            noChildProb = 460
        else
            noChildProb = 1000
        end


        if childNumProb <= noChildProb then
            childNum = 0
        elseif childNumProb <= 90 then
            childNum = math.random(1, 6)
        elseif childNumProb <= 240 then
            childNum = math.random(7, 10)
        elseif childNumProb <= 850 then
            childNum = math.random(11, 13)
        else
            childNum = math.random(14, 16)
        end

    elseif animalType == AnimalType.HORSE then

        if age <= 12 then
            noChildProb = 60
        elseif age <= 48 then
            noChildProb = 50
        elseif age <= 60 then
            noChildProb = 65
        elseif age <= 84 then
            noChildProb = 85
        elseif age <= 108 then
            noChildProb = 120
        elseif age <= 132 then
            noChildProb = 160
        elseif age <= 156 then
            noChildProb = 220
        elseif age <= 180 then
            noChildProb = 290
        elseif age <= 216 then
            noChildProb = 460
        elseif age <= 240 then
            noChildProb = 630
        elseif age <= 264 then
            noChildProb = 850
        else
            noChildProb = 1000
        end


        if childNumProb <= noChildProb then
            childNum = 0
        elseif childNumProb >= 955 and childNumProb <= 997 then
            childNum = 2
        elseif childNumProb >= 997 then
            childNum = 3
        end

    elseif animalType == AnimalType.CHICKEN then

        if age <= 12 then
            noChildProb = 400
        elseif age <= 24 then
            noChildProb = 440
        elseif age <= 36 then
            noChildProb = 500
        elseif age <= 48 then
            noChildProb = 580
        elseif age <= 60 then
            noChildProb = 675
        elseif age <= 84 then
            noChildProb = 820
        elseif age <= 120 then
            noChildProb = 960
        else
            noChildProb = 1000
        end


        if childNumProb <= noChildProb then
            childNum = 0
        elseif childNumProb <= 480 then
            childNum = math.random(1, 5)
        elseif childNumProb <= 760 then
            childNum = math.random(5, 7)
        elseif childNumProb <= 920 then
            childNum = math.random(7, 9)
        else
            childNum = math.random(10, 12)
        end

    elseif animalType == AnimalType.SHEEP then

        if age <= 18 then
            noChildProb = 280
        elseif age <= 24 then
            noChildProb = 220
        elseif age <= 36 then
            noChildProb = 180
        elseif age <= 72 then
            noChildProb = 140
        elseif age <= 84 then
            noChildProb = 320
        elseif age <= 108 then
            noChildProb = 600
        elseif age <= 120 then
            noChildProb = 870
        else
            noChildProb = 1000
        end


        if childNumProb <= noChildProb then
            childNum = 0
        elseif not isParent and childNumProb <= 870 then
            childNum = 1
        elseif age < 36 and childNumProb >= 500 and childNumProb <= 965 then
            childNum = 2
        elseif age >= 36 and age < 72 and childNumProb >= 350 and childNumProb <= 920 then
            childNum = 2
        elseif age >= 72 and childNumProb <= 980 then
            childNum = 2
        elseif age < 36 and childNumProb >= 965 then
            childNum = 3
        elseif age >= 36 and age < 72 and childNumProb >= 920 then
            childNum = 3
        elseif age >= 72 and childNumProb >= 980 then
            childNum = 3
        end

    end

    return childNum

end


local function sortChildSellPrices(a, b)

    return a.sellPrice > b.sellPrice

end


function Animal:reproduce(spec, day, month, year, isSaleAnimal)

    if self.pregnancy == nil or self.pregnancy.pregnancies == nil then return 0, false, 0, 0 end

    local pregnancies = self.pregnancy.pregnancies
    local freeSlots = isSaleAnimal and 100 or spec.maxNumAnimals
    local childNum = #pregnancies
    local animalsToSell = 0
    local subType = self:getSubType()
    local animalType = self:getAnimalTypeIndex()
    local parentDied = false

    if freeSlots - childNum < 0 then
        animalsToSell = childNum - freeSlots
    end

    self.monthsSinceLastBirth = 0

    if childNum > 0 then
        self.isParent = true
        if animalType == AnimalType.COW or self.subType == "GOAT" then self.isLactating = true end
    end

    childNum = childNum - animalsToSell

        
    local fatherFull

    if not isSaleAnimal and self.impregnatedBy ~= nil and self.impregnatedBy.uniqueId ~= nil and self.impregnatedBy.uniqueId ~= "-1" then

        local placeables = g_currentMission.placeableSystem.placeables

        for _, placeable in ipairs(placeables) do

            if placeable.spec_husbandryAnimals == nil and placeable.spec_livestockTrailer == nil then continue end

            local clusterSystem = nil

            if placeable.spec_husbandryAnimals ~= nil then
                clusterSystem = placeable.spec_husbandryAnimals.clusterSystem
            elseif placeable.spec_livestockTrailer ~= nil then
                clusterSystem = placeable.spec_livestockTrailer.clusterSystem
            end

            if clusterSystem == nil then continue end

            local animals = clusterSystem:getAnimals()
            for _, animal in ipairs(animals) do
                if animal.farmId .. " " .. animal.uniqueId ~= self.impregnatedBy.uniqueId then continue end

                fatherFull = animal
                break
            end

            if fatherFull ~= nil then break end

        end

    end

    if fatherFull ~= nil then fatherFull.isParent = true end


    local sellPrices = {}
    local childrenToRemove = {}
    local birthday = self.pregnancy.expected
    birthday.country = isSaleAnimal and self.birthday.country or RealisticLivestock.getMapCountryIndex()
    birthday.lastAgeMonth = 0


    for i, child in pairs(pregnancies) do
        
        local genetics = child.genetics
        local weightChance = math.random() * genetics.metabolism
        local minWeight = child:getSubType().minWeight
        local weight = minWeight + 0.5

        if weightChance < 0.05 then
            weight = weight * (math.random(70, 90) / 100)
        elseif weightChance <= 0.95 then
            weight = weight * (math.random(90, 110) / 100)
        else
            weight = weight * (math.random(110, 130) / 100)
        end

        if self.deathEnabled and math.random() >= genetics.health * (weight / minWeight) * 1.15 then

            childNum = childNum - 1
            animalsToSell = animalsToSell - 1

            table.insert(childrenToRemove, i)

            child.isDead = true

            continue

        end

        child.weight = weight
        child.age = -1

        child:setBirthday(birthday)

        if not isSaleAnimal then
            child:setClusterSystem(self.clusterSystem)
            child:setUniqueId()
        else
            child:setUniqueId(self.farmId)
        end

        local childInfo = {
            farmId = child.farmId,
            uniqueId = child.uniqueId
        }

        table.insert(self.children, childInfo)
        if fatherFull ~= nil then table.insert(fatherFull.children, childInfo) end


        table.insert(sellPrices, {
            ["index"] = i,
            ["sellPrice"] = child:getSellPrice()
        })

    end

    if #childrenToRemove > 0 and math.random() >= 0.35 + self.genetics.health * 1.25 then parentDied = true end


    table.sort(sellPrices, sortChildSellPrices)

    local totalAnimalPrice = 0

   
    for i = 1, animalsToSell do

        local childToSell = sellPrices[i]

        if childToSell == nil or pregnancies[childToSell.index] == nil then break end

        table.insert(childrenToRemove, childToSell.index)
        totalAnimalPrice = totalAnimalPrice + childToSell.sellPrice

    end

    table.sort(childrenToRemove)

    for i = #childrenToRemove, 1, -1 do

        table.remove(pregnancies, childrenToRemove[i])

    end

    local animalSystem = g_currentMission.animalSystem

    for _, child in pairs(pregnancies) do

        if isSaleAnimal then
            animalSystem:addExistingSaleAnimal(child)
        else
            self.clusterSystem:addCluster(child)
        end

    end


    if not isSaleAnimal then
        
        local farmIndex = spec:getOwnerFarmId()
        local animalTypeReal = animalSystem:getTypeByIndex(subType.typeIndex)
        
        if animalTypeReal.statsBreedingName ~= nil then
            local stats = g_currentMission:farmStats(farmIndex)
            stats:updateStats(animalTypeReal.statsBreedingName, childNum)
        end

    end


    self.impregnatedBy = nil

    if parentDied then self:die() end


    return childNum, parentDied, animalsToSell, totalAnimalPrice



end



function Animal:die()

    self.numAnimals = 0
    self.isDead = true
    if self.sale ~= nil then g_currentMission.animalSystem:removeSaleAnimal(self.animalTypeIndex, self.birthday.country, self.farmId, self.uniqueId) end
    if self.clusterSystem ~= nil then self.clusterSystem:addPendingRemoveCluster(self) end

end




function Animal:CalculateLowHealthMonthlyAnimalDeaths()

    if self.numAnimals <= 0 or self.isDead then
        return 0
    end

    local deathChance = 0.01
    local health = self.health
    local healthGenetics = self.genetics.health

    if health >= 80 then
        return 0
    end

    if self.age < 6 then health = health - 10 end
    deathChance = (0.5 * (2 - healthGenetics)) - (health / 100)

    if math.random() <= deathChance then
        self:die()
        return 1
    end

    return 0

end



function Animal:CalculateOldAgeMonthlyAnimalDeaths()

    if self.numAnimals <= 0 or self.isDead then
        return 0
    end

    local animalType = self.animalTypeIndex
    local deathChance = 0.01
    local age = self.age
    local healthGenetics = self.genetics.health

    local minAge = 20000
    local maxAge = 30000

    if animalType == AnimalType.COW then
        -- cattle old age min: 15y (180m)
        -- cattle old age max: 20y (240m)
        minAge = 180
        maxAge = 240
    elseif animalType == AnimalType.SHEEP then
        -- sheep old age min: 10y (120m)
        -- sheep old age max: 12y (144m)
        minAge = 120
        maxAge = 144
    elseif animalType == AnimalType.HORSE then
        -- horse old age min: 25y (300m)
        -- horse old age max: 30y (360m)
        minAge = 300
        maxAge = 360
    elseif animalType == AnimalType.PIG then
        -- pig old age min: 15y (180m)
        -- pig old age max: 20y (240m)
        minAge = 180
        maxAge = 240
    elseif animalType == AnimalType.CHICKEN then
        -- chicken old age min: 5y (60m)
        -- chicken old age max: 8y (96m)
        minAge = 60
        maxAge = 96
    end

    if age < minAge then
        return 0
    end

    deathChance = 0.7 - ((maxAge - age) / 100)
    if math.random() <= deathChance * (2 - healthGenetics) then
        self:die()
        return 1
    end

    return 0

end


-- Animals can die randomly regardless of health such as due to broken legs - will be sold at a reduced price (lower quality meat)

function Animal:CalculateRandomMonthlyAnimalDeaths(spec)

    if self.numAnimals <= 0 or self.isDead then
        return 0, 0
    end

    local animalType = spec.animalTypeIndex
    local animalsCanBeSold = true
    local deathChance = 0.01
    local temp = spec.minTemp

    if animalType == AnimalType.COW then
        deathChance = 0.01
        if self.age < 6 then
            deathChance = 0.013
        elseif self.age < 18 then
            deathChance = 0.011
        end
    elseif animalType == AnimalType.SHEEP then
        deathChance = 0.012
        if self.age < 3 then
            deathChance = 0.011
        elseif self.age < 8 then
            deathChance = 0.006
        end
    elseif animalType == AnimalType.HORSE then
        deathChance = 0.013
    elseif animalType == AnimalType.PIG then
        deathChance = 0.005
        if self.age < 3 then
            deathChance = 0.021
        elseif self.age < 6 then
            deathChance = 0.009
        end
    elseif animalType == AnimalType.CHICKEN then
        if self.age < 6 then
            deathChance = 0.003
        else
            deathChance = 0.004
        end
        animalsCanBeSold = false
    end

    -- animals are more likely to die in cold weather, especially young animals due to ice, pneumonia etc

    if temp ~= nil and temp < 10 and temp >= 0 then
        deathChance = deathChance * (1 + (1 - (temp / 12)))
    elseif temp ~= nil and temp < 0 then
        deathChance = deathChance * (1 + (1 - (temp / 10)))
    end

    deathChance = deathChance * self.accidentsChance

    if math.random() <= deathChance then
        local animalPrice = 0
        if animalsCanBeSold then animalPrice = self:getSellPrice() * 0.33 end

        self:die()
        return 1, animalPrice
    end

    return 0, 0

end





-- ##################################

--             HORSES

-- ##################################



function Animal:getHealthChangeFactor(foodFactor)
    local fitnessFactor = self:getFitnessFactor()

    if not Platform.gameplay.needHorseCleaning then
        return 0.6 * foodFactor + 0.4 * fitnessFactor
    end

    local dirtFactor = 1 - self:getDirtFactor()
    return 0.5 * foodFactor + 0.4 * fitnessFactor + 0.1 * dirtFactor
end


function Animal:getFitnessFactor()
    return self.fitness / 100
end


function Animal:changeFitness(delta)
    self.fitness = math.clamp(math.floor(self.fitness + delta), 0, 100)
end


function Animal:getRidingFactor()
    return self.riding / 100
end


function Animal:setRiding(riding)
    self.riding = riding
end


function Animal:resetRiding()
    self.riding = 0
end


function Animal:changeRiding(delta)
    self.riding = math.clamp(math.floor(self.riding + delta), 0, 100)
end


function Animal:getDirtFactor()
    return self.dirt / 100
end


function Animal:changeDirt(delta)
    self.dirt = math.clamp(math.floor(self.dirt + delta), 0, 100)
end


function Animal:getSellPrice()
    local subType = self:getSubType()
    local sellPrice = subType.sellPrice:get(self.age < 0 and 0 or self.age)

    local weight = self.weight
    local targetWeightForAge = ((self.targetWeight - subType.minWeight) / (subType.reproductionMinAgeMonth * 1.5)) * math.min(self.age + 1.5, subType.reproductionMinAgeMonth * 1.5) * 0.85

    local weightFactor = 1 + ((weight - targetWeightForAge) / targetWeightForAge)

    local meatFactor = self.genetics.quality

    sellPrice = sellPrice + (sellPrice * 0.25 * (meatFactor - 1))

    sellPrice = sellPrice + (((sellPrice * 0.6) / subType.targetWeight) * weight * (-1 + meatFactor))

    if string.contains(self.subType, "HORSE", true) or string.contains(self.subType, "STALLION", true) then
        return math.max(sellPrice * meatFactor * weightFactor * (0.3 + 0.5 * self:getHealthFactor() + 0.3 * self:getRidingFactor() + 0.2 * self:getFitnessFactor() - 0.2 * self:getDirtFactor()), sellPrice * 0.05)
    end

    return math.max(sellPrice * 0.6 + (sellPrice * 0.4 * weightFactor * (0.75 * self:getHealthFactor())) + sellPrice * (self.isLactating and 0.15 or 0) + sellPrice * (self.isPregnant and 0.25 or 0), sellPrice * 0.05)
end


function Animal:getDailyRidingTime()
    return 300000
end


function Animal:getNumberOfImpregnatableFemalesForMale()

    if self.gender == "female" or self.clusterSystem == nil then return 0 end

    local subType = self:getSubType()
    local animalType = self.animalTypeIndex

    if (subType.reproductionMinAgeMonth ~= nil and subType.reproductionMinAgeMonth > self.age) or ((animalType == AnimalType.COW and self.age >= 132) or (animalType == AnimalType.SHEEP and self.age >= 72) or (animalType == AnimalType.HORSE and self.age >= 300) or (animalType == AnimalType.PIG and self.age >= 48)) then return 0 end

    local i = 0
    local id = self.farmId .. " " .. self.uniqueId

    for _, animal in ipairs(self.clusterSystem:getAnimals()) do

        if animal.gender == "male" or (animal.fatherId ~= nil and id == animal.fatherId) or animal.isPregnant then continue end
        
        local s = animal:getSubType()
        if s.reproductionMinAgeMonth == nil or s.reproductionMinAgeMonth > animal.age then continue end

        if subType.name == "BULL_WATERBUFFALO" then
            if s.name == "COW_WATERBUFFALO" then i = i + 1 end
        elseif subType.name == "RAM_GOAT" then
            if s.name == "GOAT" then i = i + 1 end
        elseif s.name ~= "GOAT" and s.name ~= "COW_WATERBUFFALO" then
            i = i + 1
        end

    end

    return i

end


function Animal.onSettingChanged(name, state)

    Animal[name] = state

end