RL_AnimalScreenTrailerFarm = {}

function RL_AnimalScreenTrailerFarm:initTargetItems(_)

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

AnimalScreenTrailerFarm.initTargetItems = Utils.overwrittenFunction(AnimalScreenTrailerFarm.initTargetItems, RL_AnimalScreenTrailerFarm.initTargetItems)


function RL_AnimalScreenTrailerFarm:initSourceItems(_)

    self.sourceItems = {}

    local animalType = self.trailer:getCurrentAnimalType()
    if animalType == nil then return end

    local animals = self.trailer:getClusters()

    if animals ~= nil then
        for _, animal in pairs(animals) do
            local item = AnimalItemStock.new(animal)

            if self.sourceItems[animalType.typeIndex] == nil then self.sourceItems[animalType.typeIndex] = {} end

            table.insert(self.sourceItems[animalType.typeIndex], item)
        end
    end


    for _, category in pairs(self.sourceItems) do
        table.sort(category, RL_AnimalScreenBase.sortAnimals)
    end

end

AnimalScreenTrailerFarm.initSourceItems = Utils.overwrittenFunction(AnimalScreenTrailerFarm.initSourceItems, RL_AnimalScreenTrailerFarm.initSourceItems)


function AnimalScreenTrailerFarm:applySourceBulk(animalTypeIndex, items)

    self.sourceAnimals = {}

    local trailer = self.trailer
    local husbandry = self.husbandry
    local clusterSystemTrailer = trailer:getClusterSystem()
    local clusterSystemHusbandry = husbandry:getClusterSystem()
    local ownerFarmId = trailer:getOwnerFarmId()

    local sourceItems = self.sourceItems[animalTypeIndex]
    --local indexesToRemove = {}
    --local indexesToReturn = {}
    local totalMovedAnimals = 0

    for _, item in pairs(items) do

        if sourceItems[item] ~= nil then

            local sourceItem = sourceItems[item]
            local animal = sourceItem.animal or sourceItem.cluster

            --local errorCode = AnimalMoveEvent.validate(trailer, husbandry, sourceItem:getClusterId(), 1, ownerFarmId)
            local errorCode = AnimalMoveEvent.validate(trailer, husbandry, ownerFarmId, animal.subTypeIndex)

            if errorCode ~= nil then continue end
    
            totalMovedAnimals = totalMovedAnimals + 1
            --clusterSystemTrailer:removeCluster(animal.farmId .. " " .. animal.uniqueId .. " " .. animal.birthday.country)
            --animal.id, animal.idFull = nil, nil
            --clusterSystemHusbandry:addCluster(animal)
            --table.insert(indexesToRemove, item)
            --table.insert(indexesToReturn, item)

            table.insert(self.sourceAnimals, animal)

        end

    end

    --table.sort(indexesToRemove)

    --for i = #indexesToRemove, 1, -1 do table.remove(sourceItems, indexesToRemove[i]) end

    --self.sourceItems[animalTypeIndex] = sourceItems

    --self.sourceBulkActionFinished(nil, string.format(g_i18n:getText("rl_ui_moveBulkResult"), totalMovedAnimals), indexesToReturn)

    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_SOURCE, g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.MOVE_TO_FARM))
	g_messageCenter:subscribe(AnimalMoveEvent, self.onAnimalMovedToFarm, self)
	g_client:getServerConnection():sendEvent(AnimalMoveEvent.new(trailer, husbandry, self.sourceAnimals))

    if totalMovedAnimals == 1 then
        husbandry:addRLMessage("MOVED_ANIMALS_TARGET_SINGLE", nil, { trailer:getName() })
    elseif totalMovedAnimals > 0 then
        husbandry:addRLMessage("MOVED_ANIMALS_TARGET_MULTIPLE", nil, { totalMovedAnimals, trailer:getName() })
    end

end


function AnimalScreenTrailerFarm:applyTargetBulk(animalTypeIndex, items)

    self.targetAnimals = {}

    local trailer = self.trailer
    local husbandry = self.husbandry
    local clusterSystemTrailer = trailer:getClusterSystem()
    local clusterSystemHusbandry = husbandry:getClusterSystem()
    local ownerFarmId = trailer:getOwnerFarmId()

    local targetItems = self.targetItems
    --local indexesToRemove = {}
    --local indexesToReturn = {}
    local totalMovedAnimals = 0

    for _, item in pairs(items) do

        if targetItems[item] ~= nil then

            local targetItem = targetItems[item]
            local animal = targetItem.animal or targetItem.cluster

            --local errorCode = AnimalMoveEvent.validate(husbandry, trailer, targetItem:getClusterId(), 1, ownerFarmId)
            local errorCode = AnimalMoveEvent.validate(husbandry, trailer, ownerFarmId, animal.subTypeIndex)

            if errorCode ~= nil then continue end
    
            totalMovedAnimals = totalMovedAnimals + 1
            --clusterSystemHusbandry:removeCluster(animal.farmId .. " " .. animal.uniqueId .. " " .. animal.birthday.country)
            --animal.id, animal.idFull = nil, nil
            --clusterSystemTrailer:addCluster(animal)
            --table.insert(indexesToRemove, item)
            --table.insert(indexesToReturn, item)

            table.insert(self.targetAnimals, animal)

        end

    end

    --table.sort(indexesToRemove)

    --for i = #indexesToRemove, 1, -1 do table.remove(targetItems, indexesToRemove[i]) end

    --self.targetItems = targetItems

    --self.targetBulkActionFinished(nil, string.format(g_i18n:getText("rl_ui_moveBulkResult"), totalMovedAnimals), indexesToReturn)

    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_TARGET, g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.MOVE_TO_TRAILER))
	g_messageCenter:subscribe(AnimalMoveEvent, self.onAnimalMovedToTrailer, self)
	g_client:getServerConnection():sendEvent(AnimalMoveEvent.new(husbandry, trailer, self.targetAnimals))

    if totalMovedAnimals == 1 then
        husbandry:addRLMessage("MOVED_ANIMALS_SOURCE_SINGLE", nil, { trailer:getName() })
    elseif totalMovedAnimals > 0 then
        husbandry:addRLMessage("MOVED_ANIMALS_SOURCE_MULTIPLE", nil, { totalMovedAnimals, trailer:getName() })
    end

end


function RL_AnimalScreenTrailerFarm:applyTarget(_, _, animalIndex)

    self.targetAnimals = nil

    local trailer = self.trailer
    local husbandry = self.husbandry
    local clusterSystemTrailer = trailer:getClusterSystem()
    local clusterSystemHusbandry = husbandry:getClusterSystem()
    local ownerFarmId = trailer:getOwnerFarmId()
    local item = self.targetItems[animalIndex]

    local animal = item.animal or item.cluster
    
    local id = item:getClusterId()
	--local errorCode = AnimalMoveEvent.validate(husbandry, trailer, id, 1, ownerFarmId)
	local errorCode = AnimalMoveEvent.validate(husbandry, trailer, ownerFarmId, animal.subTypeIndex)

    if errorCode ~= nil then
		self.errorCallback(g_i18n:getText(AnimalScreenTrailerFarm.MOVE_TO_TRAILER_ERROR_CODE_MAPPING[errorCode].text))
		return false
	end

    self.targetAnimals = { animal }

    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_TARGET, g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.MOVE_TO_TRAILER))
	g_messageCenter:subscribe(AnimalMoveEvent, self.onAnimalMovedToTrailer, self)
	g_client:getServerConnection():sendEvent(AnimalMoveEvent.new(husbandry, trailer, self.targetAnimals))

    --clusterSystemHusbandry:removeCluster(animal.farmId .. " " .. animal.uniqueId .. " " .. animal.birthday.country)
    --animal.id, animal.idFull = nil, nil
    --clusterSystemTrailer:addCluster(animal)

    --table.remove(self.targetItems, animalIndex)

    --self.targetActionFinished(false, g_i18n:getText(AnimalScreenTrailerFarm.MOVE_TO_TRAILER_ERROR_CODE_MAPPING[AnimalMoveEvent.MOVE_SUCCESS].text))

    husbandry:addRLMessage("MOVED_ANIMALS_SOURCE_SINGLE", nil, { trailer:getName() })

    return true

end

AnimalScreenTrailerFarm.applyTarget = Utils.overwrittenFunction(AnimalScreenTrailerFarm.applyTarget, RL_AnimalScreenTrailerFarm.applyTarget)


function RL_AnimalScreenTrailerFarm:applySource(_, animalTypeIndex, animalIndex)

    self.sourceAnimals = nil

    local trailer = self.trailer
    local husbandry = self.husbandry
    local clusterSystemTrailer = trailer:getClusterSystem()
    local clusterSystemHusbandry = husbandry:getClusterSystem()
    local ownerFarmId = trailer:getOwnerFarmId()

    local sourceItems = self.sourceItems[animalTypeIndex]
    local item = sourceItems[animalIndex]
    local animal = item.animal or item.cluster
    
    local id = item:getClusterId()
	--local errorCode = AnimalMoveEvent.validate(trailer, husbandry, id, 1, ownerFarmId)
	local errorCode = AnimalMoveEvent.validate(trailer, husbandry, ownerFarmId, animal.subTypeIndex)

    if errorCode ~= nil then
		self.errorCallback(g_i18n:getText(AnimalScreenTrailerFarm.MOVE_TO_FARM_ERROR_CODE_MAPPING[errorCode].text))
		return false
	end

    self.sourceAnimals = { animal }

    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_SOURCE, g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.MOVE_TO_FARM))
	g_messageCenter:subscribe(AnimalMoveEvent, self.onAnimalMovedToFarm, self)
	g_client:getServerConnection():sendEvent(AnimalMoveEvent.new(trailer, husbandry, self.sourceAnimals))

    --clusterSystemTrailer:removeCluster(animal.farmId .. " " .. animal.uniqueId .. " " .. animal.birthday.country)
    --animal.id, animal.idFull = nil, nil
    --clusterSystemHusbandry:addCluster(animal)

    --table.remove(sourceItems, animalIndex)

    --self.sourceActionFinished(false, g_i18n:getText(AnimalScreenTrailerFarm.MOVE_TO_FARM_ERROR_CODE_MAPPING[AnimalMoveEvent.MOVE_SUCCESS].text))

    husbandry:addRLMessage("MOVED_ANIMALS_TARGET_SINGLE", nil, { trailer:getName() })

    return true

end

AnimalScreenTrailerFarm.applySource = Utils.overwrittenFunction(AnimalScreenTrailerFarm.applySource, RL_AnimalScreenTrailerFarm.applySource)