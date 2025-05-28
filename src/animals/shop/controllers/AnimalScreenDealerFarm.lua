RL_AnimalScreenDealerFarm = {}

function RL_AnimalScreenDealerFarm:initTargetItems(_)

    self.targetItems = {}
    local animals = self.husbandry:getClusters()

    if animals ~= nil then
        for _, animal in pairs(animals) do
            local item = AnimalItemStock.new(animal)
            table.insert(self.targetItems, item)
        end
    end

    table.sort(self.targetItems, RL_AnimalScreenBase.sortAnimals)

end

AnimalScreenDealerFarm.initTargetItems = Utils.overwrittenFunction(AnimalScreenDealerFarm.initTargetItems, RL_AnimalScreenDealerFarm.initTargetItems)


function RL_AnimalScreenDealerFarm:initSourceItems(_)

    local animalTypeIndex = self.husbandry:getAnimalTypeIndex()
    local animals = g_currentMission.animalSystem:getSaleAnimalsByTypeIndex(animalTypeIndex)
    
    self.sourceItems = { [animalTypeIndex] = {} }

    for _, animal in pairs(animals) do
        local item = AnimalItemNew.new(animal)
        table.insert(self.sourceItems[animalTypeIndex], item)
    end

    table.sort(self.sourceItems[animalTypeIndex], RL_AnimalScreenBase.sortSaleAnimals)

end

AnimalScreenDealerFarm.initSourceItems = Utils.overwrittenFunction(AnimalScreenDealerFarm.initSourceItems, RL_AnimalScreenDealerFarm.initSourceItems)


function RL_AnimalScreenDealerFarm:getSourceMaxNumAnimals(_, _)

    return 1

end

AnimalScreenDealerFarm.getSourceMaxNumAnimals = Utils.overwrittenFunction(AnimalScreenDealerFarm.getSourceMaxNumAnimals, RL_AnimalScreenDealerFarm.getSourceMaxNumAnimals)


function RL_AnimalScreenDealerFarm:applySource(_, animalTypeIndex, animalIndex)

    local item = self.sourceItems[animalTypeIndex][animalIndex]
    local husbandry = self.husbandry
    local ownerFarmId = husbandry:getOwnerFarmId()

    local price = -item:getPrice()
	local transportationFee = -item:getTranportationFee(1)

    local errorCode = AnimalBuyEvent.validate(husbandry, item:getSubTypeIndex(), item:getAge(), 1, price, transportationFee, ownerFarmId)

    if errorCode ~= nil then
		local error = AnimalScreenDealerFarm.BUY_ERROR_CODE_MAPPING[errorCode]
		self.errorCallback(g_i18n:getText(error.text))
		return false
	end
    
	--self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_SOURCE, g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.BUYING))

    local animal = item.animal
    husbandry:getClusterSystem():addCluster(animal)
    g_currentMission:addMoney(price + transportationFee, ownerFarmId, MoneyType.NEW_ANIMALS_COST, true, true)
    
    g_currentMission.animalSystem:removeSaleAnimal(animalTypeIndex, animal.birthday.country, animal.farmId, animal.uniqueId)
    table.remove(self.sourceItems[animalTypeIndex], animalIndex)

    self.sourceActionFinished(nil, "Animal bought successfully")

    return true

end

AnimalScreenDealerFarm.applySource = Utils.overwrittenFunction(AnimalScreenDealerFarm.applySource, RL_AnimalScreenDealerFarm.applySource)


function RL_AnimalScreenDealerFarm:applyTarget(_, animalTypeIndex, animalIndex)

    local item = self.targetItems[animalIndex]
    local husbandry = self.husbandry
    local ownerFarmId = husbandry:getOwnerFarmId()

    local price = item:getPrice()
	local transportationFee = -item:getTranportationFee(1)

    local errorCode = AnimalSellEvent.validate(husbandry, item:getClusterId(), 1, price, transportationFee)

    if errorCode ~= nil then
		local error = AnimalScreenDealerFarm.SELL_ERROR_CODE_MAPPING[errorCode]
		self.errorCallback(g_i18n:getText(error.text))
		return false
	end
    
	--self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_SOURCE, g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.BUYING))

    local animal = item.animal or item.cluster
    husbandry:getClusterSystem():removeCluster(animal.farmId .. " " .. animal.uniqueId .. " " .. animal.birthday.country)
    g_currentMission:addMoney(price + transportationFee, ownerFarmId, MoneyType.NEW_ANIMALS_COST, true, true)
    
    g_currentMission.animalSystem:removeSaleAnimal(animalTypeIndex, animal.birthday.country, animal.farmId, animal.uniqueId)
    table.remove(self.targetItems, animalIndex)

    self.targetActionFinished(nil, "Animal sold successfully")

    return true

end

AnimalScreenDealerFarm.applyTarget = Utils.overwrittenFunction(AnimalScreenDealerFarm.applyTarget, RL_AnimalScreenDealerFarm.applyTarget)


function RL_AnimalScreenDealerFarm:getSourcePrice(_, animalTypeIndex, animalIndex, _)

    if self.sourceItems[animalTypeIndex] ~= nil then

        local item = self.sourceItems[animalTypeIndex][animalIndex]

        if item ~= nil then

	        local price = item:getPrice()
	        local transportationFee = item:getTranportationFee(1)
	        return true, price, transportationFee, price + transportationFee

        end

    end

    return false, 0, 0, 0

end

AnimalScreenDealerFarm.getSourcePrice = Utils.overwrittenFunction(AnimalScreenDealerFarm.getSourcePrice, RL_AnimalScreenDealerFarm.getSourcePrice)


function AnimalScreenDealerFarm:applySourceBulk(animalTypeIndex, items)

    local husbandry = self.husbandry
    local clusterSystem = husbandry:getClusterSystem()
    local ownerFarmId = husbandry:getOwnerFarmId()

    local sourceItems = self.sourceItems[animalTypeIndex]
    local indexesToRemove = {}
    local indexesToReturn = {}
    local totalPrice = 0
    local totalBoughtAnimals = 0

    for _, item in pairs(items) do

        if sourceItems[item] ~= nil then

            local sourceItem = sourceItems[item]
            local animal = sourceItem.animal
            local price = -sourceItem:getPrice()
            local transportationFee = -sourceItem:getTranportationFee(1)

            local errorCode = AnimalBuyEvent.validate(husbandry, animal.subTypeIndex, animal.age, 1, price, transportationFee, ownerFarmId)

            if errorCode ~= nil then continue end
    
            totalBoughtAnimals = totalBoughtAnimals + 1
            totalPrice = totalPrice + price + transportationFee
            clusterSystem:addCluster(animal)
            g_currentMission.animalSystem:removeSaleAnimal(animalTypeIndex, animal.birthday.country, animal.farmId, animal.uniqueId)
            table.insert(indexesToRemove, item)
            table.insert(indexesToReturn, item)

        end

    end

    table.sort(indexesToRemove)

    for i = #indexesToRemove, 1, -1 do table.remove(sourceItems, indexesToRemove[i]) end

    self.sourceItems[animalTypeIndex] = sourceItems

    g_currentMission:addMoney(totalPrice, ownerFarmId, MoneyType.NEW_ANIMALS_COST, true, true)

    self.sourceBulkActionFinished(nil, string.format(g_i18n:getText("rl_ui_buyBulkResult"), totalBoughtAnimals, g_i18n:formatMoney(math.abs(totalPrice), 2, true, true)), indexesToReturn)

end


function AnimalScreenDealerFarm:applyTargetBulk(animalTypeIndex, items)

    local husbandry = self.husbandry
    local clusterSystem = husbandry:getClusterSystem()
    local ownerFarmId = husbandry:getOwnerFarmId()

    local targetItems = self.targetItems
    local indexesToRemove = {}
    local indexesToReturn = {}
    local totalPrice = 0
    local totalSoldAnimals = 0

    for _, item in pairs(items) do

        if targetItems[item] ~= nil then

            local targetItem = targetItems[item]
            local animal = targetItem.animal or targetItem.cluster
            local price = targetItem:getPrice()
            local transportationFee = -targetItem:getTranportationFee(1)

            local errorCode = AnimalSellEvent.validate(husbandry, targetItem:getClusterId(), 1, price, transportationFee)

            if errorCode ~= nil then continue end
    
            totalSoldAnimals = totalSoldAnimals + 1
            totalPrice = totalPrice + price + transportationFee
            clusterSystem:removeCluster(animal.farmId .. " " .. animal.uniqueId .. " " .. animal.birthday.country)

            table.insert(indexesToRemove, item)
            table.insert(indexesToReturn, item)

        end

    end

    table.sort(indexesToRemove)

    for i = #indexesToRemove, 1, -1 do table.remove(targetItems, indexesToRemove[i]) end

    self.targetItems = targetItems

    g_currentMission:addMoney(totalPrice, ownerFarmId, MoneyType.SOLD_ANIMALS, true, true)

    self.targetBulkActionFinished(nil, string.format(g_i18n:getText("rl_ui_sellBulkResult"), totalSoldAnimals, g_i18n:formatMoney(math.abs(totalPrice), 2, true, true)), indexesToReturn)

end