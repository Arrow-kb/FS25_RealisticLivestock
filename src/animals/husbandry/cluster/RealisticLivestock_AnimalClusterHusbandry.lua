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



-- #####################################################################

-- NOTES:

-- It does not seem to be possible to manually set the position of an
-- animal. setWorldTranslation() has no effect on animals, neither do
-- any other position related functions. On top of that, these functions
-- are engine functions (written in C++ no less) so there is seemingly 
-- NO WAY WHATSOEVER to set their position here. The only animals that
-- are affected by setWorldTranslation() and similar functions, are
-- mounted horses, as they get cloned into vehicles when they are
-- mounted.

-- #####################################################################


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
                animalId = addHusbandryAnimal(self.husbandryIds[tempHusbandryId], newVisualAnimalIndex - 1)

                self.visualAnimalCount = math.max(self.visualAnimalCount - 1, 0)
                husbandryAnimalCount = husbandryAnimalCount - 1

                if self.animalIdToCluster[tempHusbandryId][tempAnimalId] then
                    local p = 1
                    for k, _ in pairs(self.animalIdToCluster[tempHusbandryId]) do
                        if k == tempAnimalId then break end
                        p = p + 1
                    end

                    table.remove(self.animalIdToCluster[tempHusbandryId], p)
                end

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
        
            --if visualAnimalCount > 0 and visualAnimalCount % (maxAnimalsPerHusbandry + 1) == 0 then
                --i = i + 1
                --print("----", visualAnimalCount, i, "----")
                --if i > #self.husbandryIds then break end
            --end

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

            if #variations > 1 then
                local variationIndex = animal.variation
                if variationIndex == nil then
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

            local animalRootNode = getAnimalRootNode(self.husbandryIds[useTempId and tempHusbandryId or i], animalId)

            if animalRootNode ~= 0 then

                if visualData.monitor ~= nil and not animal.monitor.active and not animal.monitor.removed then

                    local monitorNode = I3DUtil.indexToObject(animalRootNode, visualData.monitor)
                    setVisibility(monitorNode, false)

                end


                local numCharacters = RealisticLivestock.NUM_CHARACTERS


                if visualData.noseRing ~= nil and animal.gender == "female" then
                    
                    local noseRingNode = I3DUtil.indexToObject(animalRootNode, visualData.noseRing)
                    setVisibility(noseRingNode, false)

                end

                if visualData.bumId ~= nil then

                    local bumIdNode = I3DUtil.indexToObject(animalRootNode, visualData.bumId)

                    if bumIdNode ~= 0 then

                        local animalUniqueId = animal.uniqueId
                        
                        -- partial animal id
                
                        for bumIdIndex = 1, 4 do

                            local characterIndex = tonumber(string.sub(animalUniqueId, bumIdIndex + 2, bumIdIndex + 2))

                            local node = getChild(bumIdNode, "bumId" .. bumIdIndex)

                            setShaderParameter(node, "playScale", characterIndex, 0, numCharacters, 1, false)

                        end

                    end

                end

                if visualData.marker ~= nil then

                    local markerNode = I3DUtil.indexToObject(animalRootNode, visualData.marker)

                    if markerNode ~= 0 then

                        local markerColour = AnimalSystem.BREED_TO_MARKER_COLOUR[animal.breed]
                        local isMarked = animal:getMarked()

                        setVisibility(markerNode, isMarked)
                        if isMarked then setShaderParameter(markerNode, "colorScale", markerColour[1], markerColour[2], markerColour[3], nil, false) end

                    end

                end


                if visualData.earTagLeft ~= nil then

                    local earTagNode = I3DUtil.indexToObject(animalRootNode, visualData.earTagLeft)

                    if earTagNode ~= 0 then

                        setShaderParameter(earTagNode, "colorScale", earTagLeftR, earTagLeftG, earTagLeftB, nil, false)

                        for colourI = 0, getNumOfChildren(earTagNode) - 1 do

                            local colourChild = getChildAt(earTagNode, colourI)
                            setShaderParameter(colourChild, "colorScale", earTagLeftTextR, earTagLeftTextG, earTagLeftTextB, nil, false)

                        end

                        local animalUniqueId = animal.uniqueId
                        local farmUniqueId = animal.farmId
                        local animalBirthday = animal:getBirthday()

                        local countryCode

                        if animalBirthday ~= nil and animalBirthday.country ~= nil and RealisticLivestock.AREA_CODES[animalBirthday.country] ~= nil then

                            countryCode = RealisticLivestock.AREA_CODES[animalBirthday.country].code

                        end

                        countryCode = countryCode or areaCode
                        
                        -- animal id
                
                        for earTagIndex = 1, 6 do

                            local characterIndex = tonumber(string.sub(animalUniqueId, earTagIndex, earTagIndex))

                            local nodeFront = getChild(earTagNode, "animalIdFront_" .. earTagIndex)
                            local nodeBack = getChild(earTagNode, "animalIdBack_" .. earTagIndex)

                            setShaderParameter(nodeFront, "playScale", characterIndex, 0, numCharacters, 1, false)
                            setShaderParameter(nodeBack, "playScale", characterIndex, 0, numCharacters, 1, false)

                        end

                        -- farm id
                
                        for earTagIndex = 1, 6 do

                            local characterIndex = tonumber(string.sub(farmUniqueId, earTagIndex, earTagIndex))

                            local nodeFront = getChild(earTagNode, "farmIdFront_" .. earTagIndex)
                            local nodeBack = getChild(earTagNode, "farmIdBack_" .. earTagIndex)

                            setShaderParameter(nodeFront, "playScale", characterIndex, 0, numCharacters, 1, false)
                            setShaderParameter(nodeBack, "playScale", characterIndex, 0, numCharacters, 1, false)

                        end

                        -- country code

                        for earTagIndex = 1, 2 do

                            local character = string.sub(countryCode, earTagIndex, earTagIndex)
                            local characterIndex = RealisticLivestock.ALPHABET[character:upper()]

                            local nodeFront = getChild(earTagNode, "areaCodeFront_" .. earTagIndex)
                            local nodeBack = getChild(earTagNode, "areaCodeBack_" .. earTagIndex)

                            setShaderParameter(nodeFront, "playScale", characterIndex, 0, numCharacters, 1, false)
                            setShaderParameter(nodeBack, "playScale", characterIndex, 0, numCharacters, 1, false)

                        end

                    end

                end


                if visualData.earTagRight ~= nil then

                    local earTagNode = I3DUtil.indexToObject(animalRootNode, visualData.earTagRight)

                    if earTagNode ~= 0 then

                        setShaderParameter(earTagNode, "colorScale", earTagRightR, earTagRightG, earTagRightB, nil, false)

                        for colourI = 0, getNumOfChildren(earTagNode) - 1 do

                            local colourChild = getChildAt(earTagNode, colourI)
                            setShaderParameter(colourChild, "colorScale", earTagRightTextR, earTagRightTextG, earTagRightTextB, nil, false)

                        end

                        local animalName = animal:getName()
                        local animalBirthday = animal:getBirthday()

                        if (animalName == "" or animalName == nil) and animalBirthday == nil then

                            setVisibility(earTagNode, false)

                        else

                            if animalBirthday ~= nil then

                                -- DAY

                                local day1FrontNode = getChild(earTagNode, "birthDayFront1")
                                local day1BackNode = getChild(earTagNode, "birthDayBack1")
                                local day2FrontNode = getChild(earTagNode, "birthDayFront2")
                                local day2BackNode = getChild(earTagNode, "birthDayBack2")

                                local day = tostring(animalBirthday.day)
                                local day1CharacterIndex = tonumber(#day == 1 and 0 or string.sub(day, 1, 1))
                                local day2CharacterIndex = tonumber(#day == 1 and string.sub(day, 1, 1) or string.sub(day, 2, 2))
                                
                                setShaderParameter(day1FrontNode, "playScale", day1CharacterIndex, 0, numCharacters, 1, false)
                                setShaderParameter(day1BackNode, "playScale", day1CharacterIndex, 0, numCharacters, 1, false)
                                setShaderParameter(day2FrontNode, "playScale", day2CharacterIndex, 0, numCharacters, 1, false)
                                setShaderParameter(day2BackNode, "playScale", day2CharacterIndex, 0, numCharacters, 1, false)

                                -- MONTH

                                local month1FrontNode = getChild(earTagNode, "birthMonthFront1")
                                local month1BackNode = getChild(earTagNode, "birthMonthBack1")
                                local month2FrontNode = getChild(earTagNode, "birthMonthFront2")
                                local month2BackNode = getChild(earTagNode, "birthMonthBack2")

                                local month = tostring(animalBirthday.month)
                                local month1CharacterIndex = tonumber(#month == 1 and 0 or string.sub(month, 1, 1))
                                local month2CharacterIndex = tonumber(#month == 1 and string.sub(month, 1, 1) or string.sub(month, 2, 2))
                                
                                setShaderParameter(month1FrontNode, "playScale", month1CharacterIndex, 0, numCharacters, 1, false)
                                setShaderParameter(month1BackNode, "playScale", month1CharacterIndex, 0, numCharacters, 1, false)
                                setShaderParameter(month2FrontNode, "playScale", month2CharacterIndex, 0, numCharacters, 1, false)
                                setShaderParameter(month2BackNode, "playScale", month2CharacterIndex, 0, numCharacters, 1, false)

                                -- YEAR

                                local year1FrontNode = getChild(earTagNode, "birthYearFront1")
                                local year1BackNode = getChild(earTagNode, "birthYearBack1")
                                local year2FrontNode = getChild(earTagNode, "birthYearFront2")
                                local year2BackNode = getChild(earTagNode, "birthYearBack2")

                                local year = tostring(animalBirthday.year + RealisticLivestock.START_YEAR.PARTIAL)
                                local year1CharacterIndex = tonumber(#year == 1 and 0 or string.sub(year, 1, 1))
                                local year2CharacterIndex = tonumber(#year == 1 and string.sub(year, 1, 1) or string.sub(year, 2, 2))
                                
                                setShaderParameter(year1FrontNode, "playScale", year1CharacterIndex, 0, numCharacters, 1, false)
                                setShaderParameter(year1BackNode, "playScale", year1CharacterIndex, 0, numCharacters, 1, false)
                                setShaderParameter(year2FrontNode, "playScale", year2CharacterIndex, 0, numCharacters, 1, false)
                                setShaderParameter(year2BackNode, "playScale", year2CharacterIndex, 0, numCharacters, 1, false)

                            end

                            local templateNodeFront = getChild(earTagNode, "animalNameFront")
                            local templateNodeBack = getChild(earTagNode, "animalNameBack")

                            if animalName ~= "" and animalName ~= nil then

                                local animalNameLength = string.len(animalName)

                                local fnx, fny, fnz = getTranslation(templateNodeFront)
                                local bnx, bny, bnz = getTranslation(templateNodeBack)

                                local sx, sy, sz

                                local words = string.split(animalName, " ")
                                local currentWord = 1

                                if #words == 1 then
                                    fny = fny - 0.012
                                    bny = bny - 0.012
                                end

                                local nodeNameCharacterIndex = 1

                                for wordIndex = 1, #words do

                                    local word = words[wordIndex]
                                    local characterOffset = 0.054 / #word
                                    local characterScale = 0

                                    if #word > 6 then
                                
                                        sx, sy, sz = getScale(templateNodeFront)
                                        characterScale = math.min((#word - 6) * 0.02, 0.2)

                                    end

                                    for earTagIndex = 1, #word do

                                        local character = string.sub(word, earTagIndex, earTagIndex)
                                        local characterIndex = RealisticLivestock.ALPHABET[character:upper()]

                                        if wordIndex == 1 and earTagIndex == 1 then

                                            setTranslation(templateNodeFront, fnx, fny, fnz - characterScale * 0.05 + characterOffset)
                                            setTranslation(templateNodeBack, bnx, bny, bnz + characterScale * 0.05 - characterOffset)
                                            setShaderParameter(templateNodeFront, "playScale", characterIndex, 0, numCharacters, 1, false)
                                            setShaderParameter(templateNodeBack, "playScale", characterIndex, 0, numCharacters, 1, false)

                                            if characterScale > 0 then setScale(templateNodeFront, sx, sy - characterScale, sz - characterScale) end
                                            if characterScale > 0 then setScale(templateNodeBack, sx, sy - characterScale, sz - characterScale) end

                                        else

                                            local fnode = clone(templateNodeFront, true, false, false)
                                            local bnode = clone(templateNodeBack, true, false, false)

                                            setName(fnode, "animalNameFront_" .. nodeNameCharacterIndex)
                                            setName(bnode, "animalNameBack_" .. nodeNameCharacterIndex)

                                            nodeNameCharacterIndex = nodeNameCharacterIndex + 1

                                            if earTagIndex == 1 then
                                                templateNodeFront = fnode
                                                templateNodeBack = bnode
                                            end

                                            setTranslation(fnode, fnx, fny - (wordIndex > 1 and (characterScale * 0.05) or 0) - (wordIndex - 1) * 0.032, fnz + characterScale * 0.1 + characterOffset + (earTagIndex - 1) * 0.024)
                                            setTranslation(bnode, bnx, bny - (wordIndex > 1 and (characterScale * 0.05) or 0) - (wordIndex - 1) * 0.032, bnz - characterScale * 0.1 - characterOffset - (earTagIndex - 1) * 0.024)

                                            if characterScale > 0 then setScale(fnode, sx, sy - characterScale, sz - characterScale) end
                                            if characterScale > 0 then setScale(bnode, sx, sy - characterScale, sz - characterScale) end

                                            setShaderParameter(fnode, "playScale", characterIndex, 0, numCharacters, 1, false)
                                            setShaderParameter(bnode, "playScale", characterIndex, 0, numCharacters, 1, false)

                                        end

                                    end

                                end

                            else

                                setVisibility(templateNodeFront, false)
                                setVisibility(templateNodeBack, false)

                            end

                        end

                    end

                end

            end

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