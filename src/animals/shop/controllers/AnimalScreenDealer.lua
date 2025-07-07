RL_AnimalScreenDealer = {}

function RL_AnimalScreenDealer:initTargetItems(_)

    self.targetItems = {}
    if self.husbandry == nil then return end
    local animals = self.husbandry:getClusters()

    if animals ~= nil then
        for _, animal in pairs(animals) do
            local item = AnimalItemStock.new(animal)
            table.insert(self.targetItems, item)
        end
    end

    table.sort(self.targetItems, RL_AnimalScreenBase.sortAnimals)

end

AnimalScreenDealer.initTargetItems = Utils.overwrittenFunction(AnimalScreenDealer.initTargetItems, RL_AnimalScreenDealer.initTargetItems)



function RL_AnimalScreenDealer:initSourceItems(_)

    self.sourceItems = {}
	local animalSystem = g_currentMission.animalSystem
	self.sourceAnimalTypes = animalSystem:getTypes()

	local animalTypes = {}

	if g_localPlayer == nil then return end
	local farm = g_localPlayer.farmId

	for _, placeable in pairs(g_currentMission.placeableSystem.placeables) do

		if placeable.ownerFarmId == farm and placeable.spec_husbandryAnimals then
		
			local animalType = placeable.spec_husbandryAnimals:getAnimalTypeIndex()
		    animalTypes[animalType] = true

		end

	end


	for i = #self.sourceAnimalTypes, 1, -1 do

		local animalType = self.sourceAnimalTypes[i]

		if not animalTypes[animalType.typeIndex] then table.remove(self.sourceAnimalTypes, i) end

	end

	for index, animalType in pairs(self.sourceAnimalTypes) do

		local animals = animalSystem:getSaleAnimalsByTypeIndex(index)
    
		self.sourceItems[index] = {}

		for _, animal in pairs(animals) do
			local item = AnimalItemNew.new(animal)
			table.insert(self.sourceItems[index], item)
		end

		table.sort(self.sourceItems[index], RL_AnimalScreenBase.sortSaleAnimals)

	end

end

AnimalScreenDealer.initSourceItems = Utils.overwrittenFunction(AnimalScreenDealer.initSourceItems, RL_AnimalScreenDealer.initSourceItems)


function RL_AnimalScreenDealer:getSourceMaxNumAnimals(_, _)

    return 1

end

AnimalScreenDealer.getSourceMaxNumAnimals = Utils.overwrittenFunction(AnimalScreenDealer.getSourceMaxNumAnimals, RL_AnimalScreenDealer.getSourceMaxNumAnimals)


function RL_AnimalScreenDealer:applySource(_, animalTypeIndex, animalIndex)

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
    
	--self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_SOURCE, g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.BUYING))

    local animal = item.animal or item.cluster

    self.sourceAnimals = { animal }

    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_SOURCE, g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.BUYING))
    g_messageCenter:subscribe(AnimalBuyEvent, self.onAnimalBought, self)
	g_client:getServerConnection():sendEvent(AnimalBuyEvent.new(husbandry, self.sourceAnimals, price, transportationFee))

    --husbandry:getClusterSystem():addCluster(animal)
    --g_currentMission:addMoney(price + transportationFee, ownerFarmId, MoneyType.NEW_ANIMALS_COST, true, true)
    
    --g_currentMission.animalSystem:removeSaleAnimal(animalTypeIndex, animal.birthday.country, animal.farmId, animal.uniqueId)
    --table.remove(self.sourceItems[animalTypeIndex], animalIndex)

    --self.sourceActionFinished(nil, "Animal bought successfully")

    return true

end

AnimalScreenDealer.applySource = Utils.overwrittenFunction(AnimalScreenDealer.applySource, RL_AnimalScreenDealer.applySource)


function RL_AnimalScreenDealer:onAnimalBought(errorCode)

    if errorCode == AnimalBuyEvent.BUY_SUCCESS and self.sourceAnimals ~= nil then

        for _, animal in pairs(self.sourceAnimals) do g_currentMission.animalSystem:removeSaleAnimal(animal.animalTypeIndex, animal.birthday.country, animal.farmId, animal.uniqueId) end

    end

end

AnimalScreenDealer.onAnimalBought = Utils.prependedFunction(AnimalScreenDealer.onAnimalBought, RL_AnimalScreenDealer.onAnimalBought)


function RL_AnimalScreenDealer:applyTarget(_, animalTypeIndex, animalIndex)

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

AnimalScreenDealer.applyTarget = Utils.overwrittenFunction(AnimalScreenDealer.applyTarget, RL_AnimalScreenDealer.applyTarget)


function RL_AnimalScreenDealer:getSourcePrice(_, animalTypeIndex, animalIndex, _)

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

AnimalScreenDealer.getSourcePrice = Utils.overwrittenFunction(AnimalScreenDealer.getSourcePrice, RL_AnimalScreenDealer.getSourcePrice)


function AnimalScreenDealer:applySourceBulk(animalTypeIndex, items)

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

    --self.sourceItems[animalTypeIndex] = sourceItems

    --g_currentMission:addMoney(totalPrice, ownerFarmId, MoneyType.NEW_ANIMALS_COST, true, true)

    --self.sourceBulkActionFinished(nil, string.format(g_i18n:getText("rl_ui_buyBulkResult"), totalBoughtAnimals, g_i18n:formatMoney(math.abs(totalPrice), 2, true, true)), indexesToReturn)

    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_SOURCE, g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.BUYING))
    g_messageCenter:subscribe(AnimalBuyEvent, self.onAnimalBought, self)
    g_client:getServerConnection():sendEvent(AnimalBuyEvent.new(husbandry, self.sourceAnimals, totalPrice, totalTransportPrice))

end


function AnimalScreenDealer:applyTargetBulk(animalTypeIndex, items)

    self.targetAnimals = {}

    local husbandry = self.husbandry
    local clusterSystem = husbandry:getClusterSystem()
    local ownerFarmId = husbandry:getOwnerFarmId()

    local targetItems = self.targetItems
    --local indexesToRemove = {}
    --local indexesToReturn = {}
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

end