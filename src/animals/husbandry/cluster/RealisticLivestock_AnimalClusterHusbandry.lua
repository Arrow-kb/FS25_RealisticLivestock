RealisticLivestock_AnimalClusterHusbandry = {}
RealisticLivestock_AnimalClusterHusbandry.MAX_HUSBANDRIES = 50

local modDirectory = g_currentModDirectory



function RealisticLivestock_AnimalClusterHusbandry:create(superFunc, xmlFilename, navigationNode, raycastDistance, collisionMask)

    if self.husbandryId ~= nil then
        self:deleteHusbandry()
    end

    self.navigationNode = navigationNode
    self.collisionMask = collisionMask
    self.xmlFilename = xmlFilename
    self.raycastDistance = raycastDistance
    self.visualAnimalCount = 0

    local animalPositioning = CollisionMask.ANIMAL_POSITIONING

    self.husbandryIds = {}
    self.husbandryIdsToVisualAnimalCount = {}

    for i=1, 8 do
        local husbandry = createAnimalHusbandry(self.animalTypeName, navigationNode, xmlFilename, raycastDistance, animalPositioning, collisionMask, AudioGroup.ENVIRONMENT)

        if husbandry == 0 then
            Logging.error("Failed to create animal husbandry for %q with navigation mesh %q and config %q", self.animalTypeName, I3DUtil.getNodePath(navigationNode), xmlFilename)
            break
        end

        table.insert(self.husbandryIds, husbandry)
        self.husbandryIdsToVisualAnimalCount[husbandry] = 0
    end

    self.husbandryId = self.husbandryIds[1]
    self.visualUpdatePending = true
    self:onIndoorStateChanged()

    return self.husbandryId

end

AnimalClusterHusbandry.create = Utils.overwrittenFunction(AnimalClusterHusbandry.create, RealisticLivestock_AnimalClusterHusbandry.create)



function RealisticLivestock_AnimalClusterHusbandry:deleteHusbandry(superFunc)
    if self.husbandryIds ~= nil then

        if self.animalIdToCluster == nil then self.animalIdToCluster = {} end

        for husbandryId, animalIds in pairs(self.animalIdToCluster) do

            for animalId, animal in pairs(animalIds) do

                removeHusbandryAnimal(self.husbandryIds[husbandryId], animalId)
                animal:deleteVisual()

            end

        end

        g_soundManager:removeIndoorStateChangedListener(self)

        for _, id in pairs(self.husbandryIds) do
            delete(id)
        end

        self.husbandryIds = nil
        self.husbandryId = nil
        self.husbandryIdsToVisualAnimalCount = nil
        self.animalIdToCluster = nil
    end
end

AnimalClusterHusbandry.deleteHusbandry = Utils.overwrittenFunction(AnimalClusterHusbandry.deleteHusbandry, RealisticLivestock_AnimalClusterHusbandry.deleteHusbandry)


function RealisticLivestock_AnimalClusterHusbandry:updateVisuals(superFunc, removeAll)

    if self.husbandryId == nil or not isHusbandryReady(self.husbandryId) then
        self.visualUpdatePending = true
        return
    end


    local animals = self.nextUpdateClusters or {}
    self.totalNumAnimalsPerVisualAnimalIndex = {}
    local newAnimalMapping = {}
    local newAnimalIdToVisualAnimalIndex = {}


    if self.animalIdToCluster == nil then self.animalIdToCluster = {} end

    for husbandryId, animalIds in pairs(self.animalIdToCluster) do
        if type(animalIds) ~= "table" then continue end

        local idsToRemove = {}

        for animalId, animal in pairs(animalIds) do

            if removeAll or animal == nil or animal.isSold or animal.isDead or animal.id == nil or animal.uniqueId == "1-1" or animal.uniqueId == "0-0" or animal.numAnimals <= 0 then
            
                self.husbandryIdsToVisualAnimalCount[self.husbandryIds[husbandryId]] = math.max(self.husbandryIdsToVisualAnimalCount[self.husbandryIds[husbandryId]] - 1, 0)
                self.visualAnimalCount = math.max(self.visualAnimalCount - 1, 0)
                removeHusbandryAnimal(self.husbandryIds[husbandryId], animalId)
                
                if animal ~= nil then
                    animal.id = nil
                    animal.idFull = nil
                    animal:deleteVisual()
                end

                table.insert(idsToRemove, animalId)

            end

        end

        for _, animalId in pairs(idsToRemove) do
            animalIds[animalId] = nil
        end

    end

    
    if removeAll then self.animalIdToCluster = {} end
    if RealisticLivestock_AnimalClusterHusbandry.MAX_HUSBANDRIES <= 0 or self.visualAnimalCount == RealisticLivestock_AnimalClusterHusbandry.MAX_HUSBANDRIES then return end

    
    local areaCode = RealisticLivestock.getMapCountryCode()


    local i = 1
    local profile = Utils.getPerformanceClassId()
    local maxAnimalsPerHusbandry = (profile == GS_PROFILE_VERY_LOW and 8) or (profile == GS_PROFILE_LOW and 10) or (profile == GS_PROFILE_MEDIUM and 16) or (profile == GS_PROFILE_HIGH and 20) or (profile == GS_PROFILE_VERY_HIGH and 25) or (profile == GS_PROFILE_ULTRA and 25) or 8
 
    local animalSystem = g_currentMission.animalSystem
    local animalType = animalSystem.types[self.placeable:getAnimalTypeIndex()]

    local colours = animalType.colours or animalSystem.baseColours

    if colours.earTagLeft == nil or colours.earTagLeft_text == nil or colours.earTagRight == nil or colours.earTagRight_text == nil then colours = animalSystem.baseColours end
    
    local earTagLeftR, earTagLeftG, earTagLeftB = colours.earTagLeft[1], colours.earTagLeft[2], colours.earTagLeft[3]
    local earTagLeftTextR, earTagLeftTextG, earTagLeftTextB = colours.earTagLeft_text[1], colours.earTagLeft_text[2], colours.earTagLeft_text[3]
    local earTagRightR, earTagRightG, earTagRightB = colours.earTagRight[1], colours.earTagRight[2], colours.earTagRight[3]
    local earTagRightTextR, earTagRightTextG, earTagRightTextB = colours.earTagRight_text[1], colours.earTagRight_text[2], colours.earTagRight_text[3]
    
    
    for _, animal in pairs(animals) do

        if self.visualAnimalCount >= RealisticLivestock_AnimalClusterHusbandry.MAX_HUSBANDRIES or i > #self.husbandryIds or animal.isDead or animal.numAnimals <= 0 or animal.uniqueId == "1-1" or animal.uniqueId == "0-0" or (animal.id ~= nil and animal.idFull ~= nil and animal.id ~= "0-0" and animal.visualAnimalIndex == nil) then continue end

        local husbandryAnimalCount = self.husbandryIdsToVisualAnimalCount[self.husbandryIds[i]] 

        local useTempId = false
        local tempHusbandryId
        local animalId = 0

        if animal.id ~= nil and animal.idFull ~= nil and animal.id ~= "0-0" and animal.visualAnimalIndex ~= nil then

            local age = animal:getAge()
            local newVisualAnimalIndex = self.animalSystem:getVisualAnimalIndexByAge(animal:getSubTypeIndex(), age == -1 and 0 or age)

            if newVisualAnimalIndex ~= animal.visualAnimalIndex then
                tempHusbandryId = tonumber(string.sub(animal.id, 1, 1))
                local tempAnimalId = tonumber(string.sub(animal.id, 3))

                removeHusbandryAnimal(self.husbandryIds[tempHusbandryId], tempAnimalId)
                animal:deleteVisual()
                animalId = addHusbandryAnimal(self.husbandryIds[tempHusbandryId], newVisualAnimalIndex - 1)

                self.visualAnimalCount = math.max(self.visualAnimalCount - 1, 0)
                husbandryAnimalCount = husbandryAnimalCount - 1
                self.animalIdToCluster[tempHusbandryId][tempAnimalId] = nil

                if animalId == nil then
                    
                    self.husbandryIdsToVisualAnimalCount[self.husbandryIds[i]] = self.husbandryIdsToVisualAnimalCount[self.husbandryIds[i]] - 1

                    continue

                end
                
                useTempId = true
            else
                continue
            end

        end


        local subTypeIndex = animal:getSubTypeIndex()
        local age = animal:getAge()

        age = age == -1 and 0 or age

        local visualAnimalIndex = self.animalSystem:getVisualAnimalIndexByAge(subTypeIndex, age)


        if animalId == 0 then

            while not useTempId and husbandryAnimalCount >= maxAnimalsPerHusbandry and i <= #self.husbandryIds and self.visualAnimalCount < RealisticLivestock_AnimalClusterHusbandry.MAX_HUSBANDRIES do
                i = i + 1
                if i > #self.husbandryIds then break end
                husbandryAnimalCount = self.husbandryIdsToVisualAnimalCount[self.husbandryIds[i]]
            end
        
            if i > #self.husbandryIds or (husbandryAnimalCount >= maxAnimalsPerHusbandry and not useTempId) then break end

            animalId = addHusbandryAnimal(self.husbandryIds[useTempId and tempHusbandryId or i], visualAnimalIndex - 1)


            while animalId == 0 and i <= #self.husbandryIds do
                i = useTempId and i or (i + 1)
                useTempId = false
                if i > #self.husbandryIds or self.husbandryIdsToVisualAnimalCount[self.husbandryIds[i]] >= maxAnimalsPerHusbandry then break end
                animalId = addHusbandryAnimal(self.husbandryIds[i], visualAnimalIndex - 1)
            end

        end


        if animalId > 0 then

            self.visualAnimalCount = self.visualAnimalCount + 1
            husbandryAnimalCount = husbandryAnimalCount + 1

            local visualData = self.animalSystem:getVisualByAge(subTypeIndex, age)
            local variations = visualData.visualAnimal.variations

            if #variations >= 1 then
                local variationIndex = animal.variation
                if variationIndex == nil or variationIndex > #variations then
                    variationIndex = math.random(1, #variations)
                    animal.variation = variationIndex
                end

                local variation = variations[variationIndex]
                setAnimalTextureTile(self.husbandryIds[useTempId and tempHusbandryId or i], animalId, variation.tileUIndex, variation.tileVIndex)
            end

            if not self.animalIdToCluster[useTempId and tempHusbandryId or i] then
                self.animalIdToCluster[useTempId and tempHusbandryId or i] = {}
            end

            animal.id = (useTempId and tempHusbandryId or i) .. "-" .. animalId
            animal.idFull = self.husbandryIds[useTempId and tempHusbandryId or i] .. "-" .. animalId
            animal.visualAnimalIndex = visualAnimalIndex

            self.animalIdToCluster[useTempId and tempHusbandryId or i][animalId] = animal

            animal:createVisual(self.husbandryIds[useTempId and tempHusbandryId or i], animalId)
            animal:setVisualEarTagColours(colours.earTagLeft, colours.earTagLeft_text, colours.earTagRight, colours.earTagRight_text)

        else
            animal.id = nil
            animal.idFull = nil
            animal.visualAnimalIndex = nil
        end

        self.husbandryIdsToVisualAnimalCount[self.husbandryIds[i]] = husbandryAnimalCount

        if self.visualAnimalCount > RealisticLivestock_AnimalClusterHusbandry.MAX_HUSBANDRIES then break end
        if animalId == 0 then break end

    end

    --print(string.format("RealisticLivestock: %d visual animals loaded out of %d total animals for husbandry (%d max)", visualAnimalCount, #animals, RealisticLivestock_AnimalClusterHusbandry.MAX_HUSBANDRIES))


    i = 1


    for husbandryId, animalIds in pairs(self.animalIdToCluster) do

        for animalId, animal in animalIds do

            local dirtFactor = 0.1

            local animalRootNode = getAnimalRootNode(self.husbandryIds[husbandryId], animalId)
            if animalRootNode == 0 then break end

            I3DUtil.setShaderParameterRec(animalRootNode, "dirt", dirtFactor, nil, nil, nil)

            local x, y, z, w = getAnimalShaderParameter(self.husbandryIds[husbandryId], animalId, "atlasInvSizeAndOffsetUV")

            I3DUtil.setShaderParameterRec(animalRootNode, "atlasInvSizeAndOffsetUV", x, y, z, w)

        end
    end




    --self.animalIdToCluster = newAnimalMapping
    self.animalIdToVisualAnimalIndex = newAnimalIdToVisualAnimalIndex
    self:getPlaceable().spec_husbandryAnimals.clusterSystem:updateIdMapping()
    self.nextUpdateClusters = nil
    self.visualUpdatePending = false

end

AnimalClusterHusbandry.updateVisuals = Utils.overwrittenFunction(AnimalClusterHusbandry.updateVisuals, RealisticLivestock_AnimalClusterHusbandry.updateVisuals)


function RealisticLivestock_AnimalClusterHusbandry:getAnimalPosition(superFunc, id)

    for husbandryId, animalIds in pairs(self.animalIdToCluster) do

        for animalId, animal in pairs(animalIds) do

            if animal.id == id or animal.farmId .. " " .. animal.uniqueId == id then
                local x, y, z = getAnimalPosition(self.husbandryIds[husbandryId], animalId)
                local a, b, c = getAnimalRotation(self.husbandryIds[husbandryId], animalId)
                return x, y, z, a, b, c
            end

        end

    end

    return nil

end

AnimalClusterHusbandry.getAnimalPosition = Utils.overwrittenFunction(AnimalClusterHusbandry.getAnimalPosition, RealisticLivestock_AnimalClusterHusbandry.getAnimalPosition)


function RealisticLivestock_AnimalClusterHusbandry:getClusterByAnimalId(superFunc, id, husbandryId)

    if husbandryId ~= nil then

        for index, husbandryIdFull in ipairs(self.husbandryIds) do
            if husbandryIdFull == husbandryId and self.animalIdToCluster[index] ~= nil and self.animalIdToCluster[index][id] ~= nil then return self.animalIdToCluster[index][id] end
        end

        return nil

    end


    if type(id) ~= "string" then id = tostring(id) end


    if string.contains(id, "-") then

        local a, _ = string.find(id, "-")
        husbandryId = string.sub(id, 1, (a - 1) or 2)
        local animalId = string.sub(id, (a + 1) or 1)

        if husbandryId ~= nil and animalId ~= nil and self.animalIdToCluster[husbandryId] ~= nil and self.animalIdToCluster[husbandryId][animalId] ~= nil then return self.animalIdToCluster[husbandryId][animalId] end

    end


    for husbandryId, animalIds in pairs(self.animalIdToCluster) do


        for animalId, animal in pairs(animalIds) do

            if animal.id == id then
                --return animal
            end

        end

    end

    return nil

end

AnimalClusterHusbandry.getClusterByAnimalId = Utils.overwrittenFunction(AnimalClusterHusbandry.getClusterByAnimalId, RealisticLivestock_AnimalClusterHusbandry.getClusterByAnimalId)