RealisticLivestock_PlaceableHusbandryAnimals = {}


function RealisticLivestock_PlaceableHusbandryAnimals.registerFunctions(placeable)
	SpecializationUtil.registerFunction(placeable, "setHasUnreadRLMessages", PlaceableHusbandryAnimals.setHasUnreadRLMessages)
	SpecializationUtil.registerFunction(placeable, "getHasUnreadRLMessages", PlaceableHusbandryAnimals.getHasUnreadRLMessages)
	SpecializationUtil.registerFunction(placeable, "getRLMessages", PlaceableHusbandryAnimals.getRLMessages)
	SpecializationUtil.registerFunction(placeable, "addRLMessage", PlaceableHusbandryAnimals.addRLMessage)
	SpecializationUtil.registerFunction(placeable, "deleteRLMessage", PlaceableHusbandryAnimals.deleteRLMessage)
	SpecializationUtil.registerFunction(placeable, "getNextRLMessageUniqueId", PlaceableHusbandryAnimals.getNextRLMessageUniqueId)
	SpecializationUtil.registerFunction(placeable, "getAIManager", PlaceableHusbandryAnimals.getAIManager)
end

PlaceableHusbandryAnimals.registerFunctions = Utils.appendedFunction(PlaceableHusbandryAnimals.registerFunctions, RealisticLivestock_PlaceableHusbandryAnimals.registerFunctions)


function PlaceableHusbandryAnimals:setHasUnreadRLMessages(hasUnreadMessages)
    
    self.spec_husbandryAnimals.unreadMessages = hasUnreadMessages

end


function PlaceableHusbandryAnimals:getHasUnreadRLMessages()
    
    return self.spec_husbandryAnimals.unreadMessages or false

end


function PlaceableHusbandryAnimals:getRLMessages()

    return self.spec_husbandryAnimals.messages or {}

end


function PlaceableHusbandryAnimals:addRLMessage(id, animal, args, date, uniqueId, isLoading)

    local spec = self.spec_husbandryAnimals

    if spec.messages == nil then spec.messages = {} end

    if date == nil then

        local environment = g_currentMission.environment
        local month = environment.currentPeriod + 2
        local currentDayInPeriod = environment.currentDayInPeriod

        if month > 12 then month = month - 12 end

        local daysPerPeriod = environment.daysPerPeriod
        local day = 1 + math.floor((currentDayInPeriod - 1) * (RealisticLivestock.DAYS_PER_MONTH[month] / daysPerPeriod))
        local year = environment.currentYear

        date = string.format("%s/%s/%s", day, month, year + RealisticLivestock.START_YEAR.FULL)

    end

    for i, arg in pairs(args or {}) do args[i] = tostring(arg) end

    table.insert(spec.messages, {
        ["id"] = id,
        ["animal"] = animal,
        ["args"] = args or {},
        ["date"] = date,
        ["uniqueId"] = uniqueId or spec:getNextRLMessageUniqueId()
    })

    if not isLoading and #spec.messages > PlaceableHusbandryAnimals.maxNumMessages then table.remove(spec.messages, 1) end

    spec.unreadMessages = true

end


function PlaceableHusbandryAnimals:deleteRLMessage(uniqueId)

    local spec = self.spec_husbandryAnimals

    for i, message in pairs(spec.messages or {}) do

        if message.uniqueId == uniqueId then
            table.remove(spec.messages, i)
            return
        end

    end

end


function PlaceableHusbandryAnimals:getNextRLMessageUniqueId()

    local spec = self.spec_husbandryAnimals

    if spec.rlMessageUniqueId == nil then spec.rlMessageUniqueId = 0 end

    spec.rlMessageUniqueId = spec.rlMessageUniqueId + 1

    return spec.rlMessageUniqueId

end


function RealisticLivestock_PlaceableHusbandryAnimals:saveToXMLFile(xmlFile, key)

    local spec = self.spec_husbandryAnimals

    xmlFile:setInt(key .. ".messages#uniqueId", spec.rlMessageUniqueId or 0)
    xmlFile:setBool(key .. ".messages#unreadMessages", spec.unreadMessages or false)

    for i, message in pairs(spec.messages or {}) do

        local messageKey = string.format("%s.messages.message(%d)", key, i - 1)

        xmlFile:setString(messageKey .. "#id", message.id)
        xmlFile:setString(messageKey .. "#date", message.date)
        if message.animal ~= nil then xmlFile:setString(messageKey .. "#animal", message.animal) end
        xmlFile:setInt(messageKey .. "#uniqueId", message.uniqueId)
        
        for j, arg in pairs(message.args) do

            xmlFile:setString(string.format("%s.args.arg(%d)#value", messageKey, j - 1), arg)

        end

    end

    spec.aiAnimalManager:saveToXMLFile(xmlFile, key)

end

PlaceableHusbandryAnimals.saveToXMLFile = Utils.prependedFunction(PlaceableHusbandryAnimals.saveToXMLFile, RealisticLivestock_PlaceableHusbandryAnimals.saveToXMLFile)


function RealisticLivestock_PlaceableHusbandryAnimals:loadFromXMLFile(xmlFile, key)

    local spec = self.spec_husbandryAnimals
    
    spec.rlMessageUniqueId = xmlFile:getInt(key .. ".messages#uniqueId", 0)

    xmlFile:iterate(key .. ".messages.message", function(_, messageKey)
    
        local id = xmlFile:getString(messageKey .. "#id")
        local date = xmlFile:getString(messageKey .. "#date")
        local animal = xmlFile:getString(messageKey .. "#animal")
        local uniqueId = xmlFile:getInt(messageKey .. "#uniqueId")
        local args = {}

        xmlFile:iterate(messageKey .. ".args.arg", function(_, argKey)

            table.insert(args, xmlFile:getString(argKey .. "#value"))

        end)
        
        self:addRLMessage(id, animal, args, date, uniqueId, true)
    
    end)

    spec.unreadMessages = xmlFile:getBool(key .. ".messages#unreadMessages", false)

    spec.aiAnimalManager:loadFromXMLFile(xmlFile, key)

end

PlaceableHusbandryAnimals.loadFromXMLFile = Utils.prependedFunction(PlaceableHusbandryAnimals.loadFromXMLFile, RealisticLivestock_PlaceableHusbandryAnimals.loadFromXMLFile)


function PlaceableHusbandryAnimals:getAIManager()

    local spec = self.spec_husbandryAnimals

    if spec.aiAnimalManager == nil then spec.aiAnimalManager = AIAnimalManager.new(self) end

    return spec.aiAnimalManager

end


function RealisticLivestock_PlaceableHusbandryAnimals:onLoad()

    self.spec_husbandryAnimals.aiAnimalManager = AIAnimalManager.new(self, self.isServer)

end

PlaceableHusbandryAnimals.onLoad = Utils.appendedFunction(PlaceableHusbandryAnimals.onLoad, RealisticLivestock_PlaceableHusbandryAnimals.onLoad)


function RealisticLivestock_PlaceableHusbandryAnimals.onSettingChanged(name, state)

    PlaceableHusbandryAnimals[name] = state

end


function RealisticLivestock_PlaceableHusbandryAnimals:updateVisualAnimals(_)
    local spec = self.spec_husbandryAnimals
    local animals = spec.clusterSystem:getAnimals()

    spec.clusterHusbandry:setClusters(animals)
    spec.clusterHusbandry:updateVisuals()
    self:raiseActive()
end

PlaceableHusbandryAnimals.updateVisualAnimals = Utils.overwrittenFunction(PlaceableHusbandryAnimals.updateVisualAnimals, RealisticLivestock_PlaceableHusbandryAnimals.updateVisualAnimals)



--function RealisticLivestock_PlaceableHusbandryAnimals:addAnimals(_, subTypeIndex, numAnimals, age)
function RealisticLivestock_PlaceableHusbandryAnimals:addAnimals(_, animals)

    --local newAnimals = {}

    --for i=1, numAnimals do

        --local subType = g_currentMission.animalSystem:getSubTypeByIndex(subTypeIndex)
        --local animal = Animal.new(age, 100, 0, subType.gender, subTypeIndex, 0, false, false, false, self.spec_husbandryAnimals.clusterSystem)
        --table.insert(newAnimals, animal)

    --end

    --if #newAnimals >= 1 then self:addCluster(newAnimals) end

    for _, animal in pairs(animals) do self:addCluster(animal) end

end

PlaceableHusbandryAnimals.addAnimals = Utils.overwrittenFunction(PlaceableHusbandryAnimals.addAnimals, RealisticLivestock_PlaceableHusbandryAnimals.addAnimals)




function RealisticLivestock_PlaceableHusbandryAnimals:onDayChanged(_)

    if self.isServer then

        local minTemp =  math.floor(g_currentMission.environment.weather.temperatureUpdater.currentMin)

        local environment = g_currentMission.environment
        local month = environment.currentPeriod + 2
        local currentDayInPeriod = environment.currentDayInPeriod

        if month > 12 then month = month - 12 end

        local daysPerPeriod = environment.daysPerPeriod
        local day = 1 + math.floor((currentDayInPeriod - 1) * (RealisticLivestock.DAYS_PER_MONTH[month] / daysPerPeriod))
        local year = environment.currentYear

        local spec = self.spec_husbandryAnimals
        local animals = spec.clusterSystem:getAnimals()

        local totalChildren, deadParents, childrenToSell, childrenToSellMoney, lowHealthDeaths, oldAgeDeaths, randomDeaths, randomDeathsMoney = 0, 0, 0, 0, 0, 0, 0, 0

        for _, animal in ipairs(animals) do

            if animal.monthsSinceLastBirth == nil then
                animal.monthsSinceLastBirth = 0
            end

            if animal.isParent == nil then
                animal.isParent = false
            end

            local a, b, c, d, e, f, g, h = animal:onDayChanged(spec, self.isServer, day, month, year, currentDayInPeriod, daysPerPeriod)

            totalChildren = totalChildren + a
            deadParents = deadParents + b
            childrenToSell = childrenToSell + c
            childrenToSellMoney = childrenToSellMoney + d
            lowHealthDeaths = lowHealthDeaths + e
            oldAgeDeaths = oldAgeDeaths + f
            randomDeaths = randomDeaths + g
            randomDeathsMoney = randomDeathsMoney + h

        end

        local animalType = (spec.animalTypeIndex == AnimalType.COW and 1) or (spec.animalTypeIndex == AnimalType.PIG and 2) or (spec.animalTypeIndex == AnimalType.SHEEP and 3) or (spec.animalTypeIndex == AnimalType.CHICKEN and 4) or (spec.animalTypeIndex == AnimalType.HORSE and 5)

        

        if childrenToSell > 0 and childrenToSellMoney > 0 then
            local farmIndex = spec:getOwnerFarmId()
            local farm = g_farmManager:getFarmById(farmIndex)

            if self.isServer then
                g_currentMission:addMoneyChange(childrenToSellMoney, farmIndex, MoneyType.SOLD_ANIMALS, true)
            else
                g_client:getServerConnection():sendEvent(MoneyChangeEvent.new(childrenToSellMoney, MoneyType.SOLD_ANIMALS, farmIndex))
            end

            if farm ~= nil then
                farm:changeBalance(childrenToSellMoney, MoneyType.SOLD_ANIMALS)
            end
        end

        if randomDeaths > 0 then

            local farmIndex = spec:getOwnerFarmId()
            local farm = g_farmManager:getFarmById(farmIndex)

            if randomDeathsMoney > 0 then

                if self.isServer then
                    g_currentMission:addMoneyChange(randomDeathsMoney, farmIndex, MoneyType.SOLD_ANIMALS, true)
                else
                    g_client:getServerConnection():sendEvent(MoneyChangeEvent.new(randomDeathsMoney, MoneyType.SOLD_ANIMALS, farmIndex))
                end

                if farm ~= nil then
                    farm:changeBalance(randomDeathsMoney, MoneyType.SOLD_ANIMALS)
                end

            end

        end


        spec.minTemp = minTemp

        if randomDeaths > 0 or oldAgeDeaths > 0 or lowHealthDeaths > 0 or deadParents > 0 or totalChildren > 0 then spec.clusterHusbandry:updateVisuals() end
        
        spec.aiAnimalManager:onDayChanged()

        self:raiseActive()

    end

    if self:getHasUnreadRLMessages() and g_localPlayer ~= nil and g_localPlayer.farmId == self:getOwnerFarmId() then

        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("rl_ui_unreadMessages"), self:getName()))

    end

end

PlaceableHusbandryAnimals.onDayChanged = Utils.overwrittenFunction(PlaceableHusbandryAnimals.onDayChanged, RealisticLivestock_PlaceableHusbandryAnimals.onDayChanged)


function RealisticLivestock_PlaceableHusbandryAnimals:onPeriodChanged(_)

    if self.isServer then

		local animals = self.spec_husbandryAnimals.clusterSystem:getClusters()
        local totalTreatmentCost = 0

        for _, animal in pairs(animals) do
            local treatmentCost = animal:onPeriodChanged()
            totalTreatmentCost = totalTreatmentCost + treatmentCost
        end

        if totalTreatmentCost > 0 then g_currentMission:addMoneyChange(totalTreatmentCost, self.spec_husbandryAnimals:getOwnerFarmId(), MoneyType.MEDICINE, true) end

        g_diseaseManager:calculateTransmission(animals)

    end

end

PlaceableHusbandryAnimals.onPeriodChanged = Utils.overwrittenFunction(PlaceableHusbandryAnimals.onPeriodChanged, RealisticLivestock_PlaceableHusbandryAnimals.onPeriodChanged)