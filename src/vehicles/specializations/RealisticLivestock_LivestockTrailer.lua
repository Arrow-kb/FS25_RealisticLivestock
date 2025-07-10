RealisticLivestock_LivestockTrailer = {}

function RealisticLivestock_LivestockTrailer:addAnimals(superFunc, subTypeIndex, numAnimals, age)

    for i=1, numAnimals do

        local subType = g_currentMission.animalSystem:getSubTypeByIndex(subTypeIndex)
        local animal = Animal.new(age, 100, 0, subType.gender, subTypeIndex, 0, false, false, false, self.spec_livestockTrailer.clusterSystem)
        self:addCluster(animal)

    end

end

LivestockTrailer.addAnimals = Utils.overwrittenFunction(LivestockTrailer.addAnimals, RealisticLivestock_LivestockTrailer.addAnimals)


function RealisticLivestock_LivestockTrailer:addCluster(superFunc, cluster)

    local clusterSystem = self.spec_livestockTrailer.clusterSystem

    if cluster.numAnimals > 1 or cluster.isIndividual == nil then

        for i=1, cluster.numAnimals do
            local subType = g_currentMission.animalSystem:getSubTypeByIndex(cluster.subTypeIndex)
            local animal = Animal.new(cluster.age, cluster.health, nil, subType.gender, cluster.subTypeIndex, cluster.reproduction, false, false, false, clusterSystem)
            clusterSystem:addCluster(animal)
        end
        clusterSystem:updateNow()
        return

    end

    clusterSystem:addCluster(cluster)
    clusterSystem:updateNow()
end

LivestockTrailer.addCluster = Utils.overwrittenFunction(LivestockTrailer.addCluster, RealisticLivestock_LivestockTrailer.addCluster)


function RealisticLivestock_LivestockTrailer:onLoadFinished(success)
    if success == nil then return end

    self.spec_livestockTrailer:updateAnimals()
end

LivestockTrailer.onLoadFinished = Utils.appendedFunction(LivestockTrailer.onLoadFinished, RealisticLivestock_LivestockTrailer.onLoadFinished)



function RealisticLivestock_LivestockTrailer:dayChanged(superFunc)

    superFunc(self)

    if self.isServer then

        local minTemp =  math.floor(g_currentMission.environment.weather.temperatureUpdater.currentMin)

        local environment = g_currentMission.environment
        local month = environment.currentPeriod + 2
        local currentDayInPeriod = environment.currentDayInPeriod

        if month > 12 then month = month - 12 end

        local daysPerPeriod = environment.daysPerPeriod
        local day = 1 + math.floor((currentDayInPeriod - 1) * (RealisticLivestock.DAYS_PER_MONTH[month] / daysPerPeriod))
        local year = environment.currentYear

        local spec = self.spec_livestockTrailer
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

        if totalChildren > 0 then
            local msgText = ""

            if animalType == 1 then msgText = totalChildren == 1 and g_i18n:getText("rl_ui_cow_singleBirth") or string.format(g_i18n:getText("rl_ui_cow_multipleBirths"), totalChildren) end
            if animalType == 2 then msgText = totalChildren == 1 and g_i18n:getText("rl_ui_pig_singleBirth") or string.format(g_i18n:getText("rl_ui_pig_multipleBirths"), totalChildren) end
            if animalType == 3 then msgText = totalChildren == 1 and g_i18n:getText("rl_ui_sheep_singleBirth") or string.format(g_i18n:getText("rl_ui_sheep_multipleBirths"), totalChildren) end
            if animalType == 4 then msgText = totalChildren == 1 and g_i18n:getText("rl_ui_chicken_singleBirth") or string.format(g_i18n:getText("rl_ui_chicken_multipleBirths"), totalChildren) end
            if animalType == 5 then msgText = totalChildren == 1 and g_i18n:getText("rl_ui_horse_singleBirth") or string.format(g_i18n:getText("rl_ui_horse_multipleBirths"), totalChildren) end

            g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, msgText)
        end

        if deadParents > 0 then

            local msgText = ""

            if animalType == 1 then msgText = deadParents == 1 and g_i18n:getText("rl_ui_cow_singleDeath_birth") or string.format(g_i18n:getText("rl_ui_cow_multipleDeaths_birth"), deadParents) end
            if animalType == 2 then msgText = deadParents == 1 and g_i18n:getText("rl_ui_pig_singleDeath_birth") or string.format(g_i18n:getText("rl_ui_pig_multipleDeaths_birth"), deadParents) end
            if animalType == 3 then msgText = deadParents == 1 and g_i18n:getText("rl_ui_sheep_singleDead_birth") or string.format(g_i18n:getText("rl_ui_sheep_multipleDeaths_birth"), deadParents) end
            if animalType == 5 then msgText = deadParents == 1 and g_i18n:getText("rl_ui_horse_singleDeath_birth") or string.format(g_i18n:getText("rl_ui_horse_multipleDeaths_birth"), deadParents) end

            g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, msgText)
        end

        if childrenToSell > 0 and childrenToSellMoney > 0 then
            local farmIndex = spec:getOwnerFarmId()
            local farm = g_farmManager:getFarmById(farmIndex)

            local msgText = ""

            if animalType == 1 then msgText = childrenToSell == 1 and g_i18n:getText("rl_ui_cow_singleSold_birth") or string.format(g_i18n:getText("rl_ui_cow_multipleSold_birth"), childrenToSell) end
            if animalType == 2 then msgText = childrenToSell == 1 and g_i18n:getText("rl_ui_pig_singleSold_birth") or string.format(g_i18n:getText("rl_ui_pig_multipleSold_birth"), childrenToSell) end
            if animalType == 3 then msgText = childrenToSell == 1 and g_i18n:getText("rl_ui_sheep_singleSold_birth") or string.format(g_i18n:getText("rl_ui_sheep_multipleSold_birth"), childrenToSell) end
            if animalType == 4 then msgText = childrenToSell == 1 and g_i18n:getText("rl_ui_chicken_singleSold_birth") or string.format(g_i18n:getText("rl_ui_chicken_multipleSold_birth"), childrenToSell) end
            if animalType == 5 then msgText = childrenToSell == 1 and g_i18n:getText("rl_ui_horse_singleSold_birth") or string.format(g_i18n:getText("rl_ui_horse_multipleSold_birth"), childrenToSell) end

            g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, msgText)

            if self.isServer then
                g_currentMission:addMoneyChange(childrenToSellMoney, farmIndex, MoneyType.SOLD_ANIMALS, true)
            else
                g_client:getServerConnection():sendEvent(MoneyChangeEvent.new(childrenToSellMoney, MoneyType.SOLD_ANIMALS, farmIndex))
            end

            if farm ~= nil then
                farm:changeBalance(childrenToSellMoney, MoneyType.SOLD_ANIMALS)
            end
        end

        if lowHealthDeaths > 0 then

            local msgText = ""

            if animalType == 1 then msgText = lowHealthDeaths == 1 and g_i18n:getText("rl_ui_cow_singleDeath_health") or string.format(g_i18n:getText("rl_ui_cow_multipleDeaths_health"), lowHealthDeaths) end
            if animalType == 2 then msgText = lowHealthDeaths == 1 and g_i18n:getText("rl_ui_pig_singleDeath_health") or string.format(g_i18n:getText("rl_ui_pig_multipleDeaths_health"), lowHealthDeaths) end
            if animalType == 3 then msgText = lowHealthDeaths == 1 and g_i18n:getText("rl_ui_sheep_singleDeath_health") or string.format(g_i18n:getText("rl_ui_sheep_multipleDeaths_health"), lowHealthDeaths) end
            if animalType == 4 then msgText = lowHealthDeaths == 1 and g_i18n:getText("rl_ui_chicken_singleDeath_health") or string.format(g_i18n:getText("rl_ui_chicken_multipleDeaths_health"), lowHealthDeaths) end
            if animalType == 5 then msgText = lowHealthDeaths == 1 and g_i18n:getText("rl_ui_horse_singleDeath_health") or string.format(g_i18n:getText("rl_ui_horse_multipleDeaths_health"), lowHealthDeaths) end

            g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, msgText)

        end

        if oldAgeDeaths > 0 then

            local msgText = ""

            if animalType == 1 then msgText = oldAgeDeaths == 1 and g_i18n:getText("rl_ui_cow_singleDeath_age") or string.format(g_i18n:getText("rl_ui_cow_multipleDeaths_age"), oldAgeDeaths) end
            if animalType == 2 then msgText = oldAgeDeaths == 1 and g_i18n:getText("rl_ui_pig_singleDeath_age") or string.format(g_i18n:getText("rl_ui_pig_multipleDeaths_age"), oldAgeDeaths) end
            if animalType == 3 then msgText = oldAgeDeaths == 1 and g_i18n:getText("rl_ui_sheep_singleDeath_age") or string.format(g_i18n:getText("rl_ui_sheep_multipleDeaths_age"), oldAgeDeaths) end
            if animalType == 4 then msgText = oldAgeDeaths == 1 and g_i18n:getText("rl_ui_chicken_singleDeath_age") or string.format(g_i18n:getText("rl_ui_chicken_multipleDeaths_age"), oldAgeDeaths) end
            if animalType == 5 then msgText = oldAgeDeaths == 1 and g_i18n:getText("rl_ui_horse_singleDeath_age") or string.format(g_i18n:getText("rl_ui_horse_multipleDeaths_age"), oldAgeDeaths) end

            g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, msgText)

        end

        if randomDeaths > 0 then

            local farmIndex = spec:getOwnerFarmId()
            local farm = g_farmManager:getFarmById(farmIndex)

            local msgText = ""

            if animalType == 1 then msgText = randomDeaths == 1 and string.format(g_i18n:getText("rl_ui_cow_singleDeath_random"), g_i18n:formatMoney(randomDeathsMoney, 2, true, true)) or string.format(g_i18n:getText("rl_ui_cow_multipleDeaths_random"), randomDeaths, g_i18n:formatMoney(randomDeathsMoney, 2, true, true)) end
            if animalType == 2 then msgText = randomDeaths == 1 and string.format(g_i18n:getText("rl_ui_pig_singleDeath_random"), g_i18n:formatMoney(randomDeathsMoney, 2, true, true)) or string.format(g_i18n:getText("rl_ui_pig_multipleDeaths_random"), randomDeaths, g_i18n:formatMoney(randomDeathsMoney, 2, true, true)) end
            if animalType == 3 then msgText = randomDeaths == 1 and string.format(g_i18n:getText("rl_ui_sheep_singleDeath_random"), g_i18n:formatMoney(randomDeathsMoney, 2, true, true)) or string.format(g_i18n:getText("rl_ui_sheep_multipleDeaths_random"), randomDeaths, g_i18n:formatMoney(randomDeathsMoney, 2, true, true)) end
            if animalType == 4 then msgText = randomDeaths == 1 and g_i18n:getText("rl_ui_chicken_singleDeath_random") or string.format(g_i18n:getText("rl_ui_chicken_multipleDeaths_random"), randomDeaths) end
            if animalType == 5 then msgText = randomDeaths == 1 and string.format(g_i18n:getText("rl_ui_horse_singleDeath_random"), g_i18n:formatMoney(randomDeathsMoney, 2, true, true)) or string.format(g_i18n:getText("rl_ui_horse_multipleDeaths_random"), randomDeaths, g_i18n:formatMoney(randomDeathsMoney, 2, true, true)) end

            g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, msgText)

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

        if randomDeaths > 0 or oldAgeDeaths > 0 or lowHealthDeaths > 0 or deadParents > 0 or totalChildren > 0 then spec:updateAnimals() end

        self:raiseActive()
    end

end

--LivestockTrailer.dayChanged = Utils.overwrittenFunction(LivestockTrailer.dayChanged, RealisticLivestock_LivestockTrailer.dayChanged)