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

    self.sourceAnimals = nil

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

    local animal = item.animal

    self.sourceAnimals = { animal }

    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_SOURCE, g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.BUYING))
    g_messageCenter:subscribe(AnimalBuyEvent, self.onAnimalBought, self)
	g_client:getServerConnection():sendEvent(AnimalBuyEvent.new(husbandry, self.sourceAnimals, price, transportationFee))

    --husbandry:getClusterSystem():addCluster(animal)
   -- g_currentMission:addMoney(price + transportationFee, ownerFarmId, MoneyType.NEW_ANIMALS_COST, true, true)
    
    --g_currentMission.animalSystem:removeSaleAnimal(animalTypeIndex, animal.birthday.country, animal.farmId, animal.uniqueId)
    --table.remove(self.sourceItems[animalTypeIndex], animalIndex)

    --self.sourceActionFinished(nil, "Animal bought successfully")

    self.husbandry:addRLMessage("BOUGHT_ANIMALS_SINGLE", nil, { g_i18n:formatMoney(math.abs(price + transportationFee), 2, true, true) })

    return true

end

AnimalScreenDealerFarm.applySource = Utils.overwrittenFunction(AnimalScreenDealerFarm.applySource, RL_AnimalScreenDealerFarm.applySource)


function RL_AnimalScreenDealerFarm:onAnimalBought(errorCode)

    if errorCode == AnimalBuyEvent.BUY_SUCCESS and self.sourceAnimals ~= nil then

        for _, animal in pairs(self.sourceAnimals) do g_currentMission.animalSystem:removeSaleAnimal(animal.animalTypeIndex, animal.birthday.country, animal.farmId, animal.uniqueId) end

    end

end

AnimalScreenDealerFarm.onAnimalBought = Utils.prependedFunction(AnimalScreenDealerFarm.onAnimalBought, RL_AnimalScreenDealerFarm.onAnimalBought)


function RL_AnimalScreenDealerFarm:applyTarget(_, animalTypeIndex, animalIndex)

    self.targetAnimals = nil

    local item = self.targetItems[animalIndex]
    local husbandry = self.husbandry
    local ownerFarmId = husbandry:getOwnerFarmId()

    local price = item:getPrice()
	local transportationFee = -item:getTranportationFee(1)

    --local errorCode = AnimalSellEvent.validate(husbandry, item:getClusterId(), 1, price, transportationFee)

    --if errorCode ~= nil then
		--local error = AnimalScreenDealerFarm.SELL_ERROR_CODE_MAPPING[errorCode]
		--self.errorCallback(g_i18n:getText(error.text))
		--return false
	--end
    
	--self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_SOURCE, g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.BUYING))

    local animal = item.animal or item.cluster

    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_TARGET, g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.SELLING))

    self.targetAnimals = { animal }

    g_messageCenter:subscribe(AnimalSellEvent, self.onAnimalSold, self)
	g_client:getServerConnection():sendEvent(AnimalSellEvent.new(husbandry, self.targetAnimals, price, transportationFee))
    
    --husbandry:getClusterSystem():removeCluster(animal.farmId .. " " .. animal.uniqueId .. " " .. animal.birthday.country)
    --g_currentMission:addMoney(price + transportationFee, ownerFarmId, MoneyType.NEW_ANIMALS_COST, true, true)
    
    --g_currentMission.animalSystem:removeSaleAnimal(animalTypeIndex, animal.birthday.country, animal.farmId, animal.uniqueId)
    --table.remove(self.targetItems, animalIndex)

    --self.targetActionFinished(nil, "Animal sold successfully")

    self.husbandry:addRLMessage("SOLD_ANIMALS_SINGLE", nil, { g_i18n:formatMoney(price + transportationFee, 2, true, true) })

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

    self.sourceAnimals = {}

    local husbandry = self.husbandry
    local clusterSystem = husbandry:getClusterSystem()
    local ownerFarmId = husbandry:getOwnerFarmId()

    local sourceItems = self.sourceItems[animalTypeIndex]
    --local indexesToRemove = {}
    --local indexesToReturn = {}
    local totalPrice = 0
    local totalTransportPrice = 0
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
            totalPrice = totalPrice + price
            totalTransportPrice = totalTransportPrice + transportationFee

            table.insert(self.sourceAnimals, animal)
            --clusterSystem:addCluster(animal)
            --g_currentMission.animalSystem:removeSaleAnimal(animalTypeIndex, animal.birthday.country, animal.farmId, animal.uniqueId)
            --table.insert(indexesToRemove, item)
            --table.insert(indexesToReturn, item)

        end

    end

    --table.sort(indexesToRemove)

    --for i = #indexesToRemove, 1, -1 do table.remove(sourceItems, indexesToRemove[i]) end

   -- self.sourceItems[animalTypeIndex] = sourceItems

   --g_currentMission:addMoney(totalPrice, ownerFarmId, MoneyType.NEW_ANIMALS_COST, true, true)

   --self.sourceBulkActionFinished(nil, string.format(g_i18n:getText("rl_ui_buyBulkResult"), totalBoughtAnimals, g_i18n:formatMoney(math.abs(totalPrice), 2, true, true)), indexesToReturn)

    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_SOURCE, g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.BUYING))
    g_messageCenter:subscribe(AnimalBuyEvent, self.onAnimalBought, self)
    g_client:getServerConnection():sendEvent(AnimalBuyEvent.new(husbandry, self.sourceAnimals, totalPrice, totalTransportPrice))

    if totalBoughtAnimals == 1 then
        self.husbandry:addRLMessage("BOUGHT_ANIMALS_SINGLE", nil, { g_i18n:formatMoney(math.abs(totalPrice + totalTransportPrice), 2, true, true) })
    elseif totalBoughtAnimals > 0 then
        self.husbandry:addRLMessage("BOUGHT_ANIMALS_MULTIPLE", nil, { totalBoughtAnimals, g_i18n:formatMoney(math.abs(totalPrice + totalTransportPrice), 2, true, true) })
    end
    
end


function AnimalScreenDealerFarm:applyTargetBulk(animalTypeIndex, items)

    self.targetAnimals = {}

    local husbandry = self.husbandry
    local clusterSystem = husbandry:getClusterSystem()
    local ownerFarmId = husbandry:getOwnerFarmId()

    local targetItems = self.targetItems
    local indexesToRemove = {}
    local indexesToReturn = {}
    local totalPrice = 0
    local totalTransportPrice = 0
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
            totalPrice = totalPrice + price
            totalTransportPrice = totalTransportPrice + transportationFee

            table.insert(self.targetAnimals, animal)

            --clusterSystem:removeCluster(animal.farmId .. " " .. animal.uniqueId .. " " .. animal.birthday.country)

            --table.insert(indexesToRemove, item)
            --table.insert(indexesToReturn, item)

        end

    end

    --table.sort(indexesToRemove)

    --for i = #indexesToRemove, 1, -1 do table.remove(targetItems, indexesToRemove[i]) end

    --self.targetItems = targetItems

    --g_currentMission:addMoney(totalPrice, ownerFarmId, MoneyType.SOLD_ANIMALS, true, true)

    --self.targetBulkActionFinished(nil, string.format(g_i18n:getText("rl_ui_sellBulkResult"), totalSoldAnimals, g_i18n:formatMoney(math.abs(totalPrice), 2, true, true)), indexesToReturn)

    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_SOURCE, g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.SELLING))
    g_messageCenter:subscribe(AnimalSellEvent, self.onAnimalSold, self)
	g_client:getServerConnection():sendEvent(AnimalSellEvent.new(husbandry, self.targetAnimals, totalPrice, totalTransportPrice))

    if totalSoldAnimals == 1 then
        self.husbandry:addRLMessage("SOLD_ANIMALS_SINGLE", nil, { g_i18n:formatMoney(totalPrice + totalTransportPrice, 2, true, true) })
    elseif totalSoldAnimals > 0 then
        self.husbandry:addRLMessage("SOLD_ANIMALS_MULTIPLE", nil, { totalSoldAnimals, g_i18n:formatMoney(totalPrice + totalTransportPrice, 2, true, true) })
    end

end