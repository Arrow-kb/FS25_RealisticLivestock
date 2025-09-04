RealisticLivestock_AnimalScreen = {}



-- #################################################################################

-- NOTES:

-- the AnimalScreenDealer controller is really pissing me off
-- so now i disable it
-- inconsequential, who cares

-- #################################################################################


function RealisticLivestock_AnimalScreen.show(husbandry, vehicle, isDealer)

    --if husbandry == nil and vehicle == nil then return end

    g_animalScreen.isTrailerFarm = husbandry ~= nil and vehicle ~= nil
    g_animalScreen.filters = nil
    g_animalScreen.filteredItems = nil

	g_animalScreen:setController(husbandry, vehicle, isDealer)
	g_gui:showGui("AnimalScreen")

end

AnimalScreen.show = RealisticLivestock_AnimalScreen.show


function RealisticLivestock_AnimalScreen:setController(_, husbandry, vehicle, isDealer)

    self.isTrailer = husbandry == nil and vehicle ~= nil and not isDealer
    self.isDealer = isDealer

    local controller

	if husbandry == nil then
		if vehicle == nil then
			controller = AnimalScreenDealer.new()
		elseif isDealer then
			controller = AnimalScreenDealerTrailer.new(vehicle)
		else
			controller = AnimalScreenTrailer.new(vehicle)
		end
	elseif vehicle == nil then
		controller = AnimalScreenDealerFarm.new(husbandry)
	else
		controller = AnimalScreenTrailerFarm.new(husbandry, vehicle)
	end

	controller:init()

	self.controller = controller
	self.controller:setAnimalsChangedCallback(self.onAnimalsChanged, self)
	self.controller:setActionTypeCallback(self.onActionTypeChanged, self)
	self.controller:setSourceActionFinishedCallback(self.onSourceActionFinished, self)
	self.controller:setTargetActionFinishedCallback(self.onTargetActionFinished, self)
	self.controller:setSourceBulkActionFinishedCallback(self.onSourceBulkActionFinished, self)
	self.controller:setTargetBulkActionFinishedCallback(self.onTargetBulkActionFinished, self)
	self.controller:setErrorCallback(self.onError, self)

	self.sourceList:reloadData(true)

end

AnimalScreen.setController = Utils.overwrittenFunction(AnimalScreen.setController, RealisticLivestock_AnimalScreen.setController)


function RealisticLivestock_AnimalScreen:onClickBuyMode(a, b)
    self.isInfoMode = false
    self.selectedItems = {}
    self.pendingBulkTransaction = nil
    self.filters = nil
    self.filteredItems = nil

    self.buttonToggleSelectAll:setVisible(true)
    self.buttonToggleSelectAll:setText(g_i18n:getText("rl_ui_selectAll"))
    self.buttonBuySelected:setText(self.isTrailerFarm and g_i18n:getText("rl_ui_moveSelected") or g_i18n:getText("rl_ui_buySelected"))
    self.buttonCastrate:setVisible(false)
end

AnimalScreen.onClickBuyMode = Utils.prependedFunction(AnimalScreen.onClickBuyMode, RealisticLivestock_AnimalScreen.onClickBuyMode)


function RealisticLivestock_AnimalScreen:onClickSellMode(a, b)
    self.isInfoMode = false
    self.selectedItems = {}
    self.pendingBulkTransaction = nil
    self.filters = nil
    self.filteredItems = nil

    self.buttonToggleSelectAll:setVisible(true)
    self.buttonToggleSelectAll:setText(g_i18n:getText("rl_ui_selectAll"))
    self.buttonBuySelected:setText(self.isTrailerFarm and g_i18n:getText("rl_ui_moveSelected") or g_i18n:getText("rl_ui_sellSelected"))
    self.buttonCastrate:setVisible(false)
end

AnimalScreen.onClickSellMode = Utils.prependedFunction(AnimalScreen.onClickSellMode, RealisticLivestock_AnimalScreen.onClickSellMode)



function RealisticLivestock_AnimalScreen:onPageNext(superFunc)
    if self.isBuyMode then
        self:onClickSellMode()
    elseif not self.isInfoMode then
        self:onClickInfoMode()
    else
        self:onClickBuyMode()
    end
end

AnimalScreen.onPageNext = Utils.overwrittenFunction(AnimalScreen.onPageNext, RealisticLivestock_AnimalScreen.onPageNext)


function RealisticLivestock_AnimalScreen:onPagePrevious(superFunc)
    if self.isBuyMode then
        self:onClickInfoMode()
    elseif not self.isInfoMode then
        self:onClickBuyMode()
    else
        self:onClickSellMode()
    end
end

AnimalScreen.onPagePrevious = Utils.overwrittenFunction(AnimalScreen.onPagePrevious, RealisticLivestock_AnimalScreen.onPagePrevious)


function RealisticLivestock_AnimalScreen:onClickRename()

    local item = (self.filteredItems == nil and self.controller:getTargetItems() or self.filteredItems)[self.sourceList.selectedIndex]

    if item == nil or (item.cluster == nil and item.animal == nil) then return end

    local animal = item.animal or item.cluster

    local dialog = NameInputDialog.INSTANCE
    local name = animal.name or g_currentMission.animalNameSystem:getRandomName(animal.gender)
    dialog:setCallback(self.changeName, self, name, nil, 30, nil, animal.gender)
    g_gui:showDialog("NameInputDialog")

end

AnimalScreen.onClickRename = RealisticLivestock_AnimalScreen.onClickRename


function RealisticLivestock_AnimalScreen:changeName(text, clickOk)

    if clickOk then

        local item = (self.filteredItems == nil and self.controller:getTargetItems() or self.filteredItems)[self.sourceList.selectedIndex]
        local animal = item.animal or item.cluster

        if animal ~= nil then

            text = text ~= "" and text or nil
            animal.name = text

            AnimalNameChangeEvent.sendEvent(animal.clusterSystem.owner, animal, text)

            local visualData = g_currentMission.animalSystem:getVisualByAge(animal.subTypeIndex, animal.age)

            if visualData.earTagRight ~= nil and animal.idFull ~= nil and animal.idFull ~= "1-1" then

                local sep = string.find(animal.idFull, "-")
                local husbandry = tonumber(string.sub(animal.idFull, 1, sep - 1))
                local animalId = tonumber(string.sub(animal.idFull, sep + 1))

                if husbandry ~= 0 and animalId ~= 0 then

                    local rootNode = getAnimalRootNode(husbandry, animalId)

                    if rootNode ~= 0 then

                        local earTagNode = I3DUtil.indexToObject(rootNode, visualData.earTagRight)
                        local numCharacters = RealisticLivestock.NUM_CHARACTERS

                        if earTagNode ~= nil and earTagNode ~= 0 then

                            local numExistingCharacters = getNumOfChildren(earTagNode) - 18

                            local templateNodeFront = getChild(earTagNode, "animalNameFront")
                            local templateNodeBack = getChild(earTagNode, "animalNameBack")

                            setTranslation(templateNodeFront, 0, 0.028, 0)
                            setTranslation(templateNodeBack, 0, 0.028, 0)
                            setScale(templateNodeFront, 1, 1, 1)
                            setScale(templateNodeBack, 1, 1, 1)

                            for i = 1, numExistingCharacters / 2 do

                                local fnode = getChild(earTagNode, "animalNameFront_" .. i)
                                local bnode = getChild(earTagNode, "animalNameBack_" .. i)

                                delete(fnode)
                                delete(bnode)

                            end


                            if text == nil then

                                setVisibility(templateNodeFront, false)
                                setVisibility(templateNodeBack, false)

                            else

                                local animalNameLength = string.len(text)

                                local fnx, fny, fnz = getTranslation(templateNodeFront)
                                local bnx, bny, bnz = getTranslation(templateNodeBack)

                                local sx, sy, sz

                                local words = string.split(text, " ")
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

                            end


                        end

                    end

                end

            end

        end

        g_animalScreen:updateInfoBox()
    end

end

AnimalScreen.changeName = RealisticLivestock_AnimalScreen.changeName

-- #################################################################################

-- NOTES:

-- sourceList:setSelectedItem() changes the selected animal in the leftmost animal list
-- targetSelector buttons change the arrow buttons visibility at the top

-- #################################################################################

function RealisticLivestock_AnimalScreen:onClickAnimalInfo(button)

    local item = (self.filteredItems == nil and self.controller:getTargetItems() or self.filteredItems)[self.sourceList.selectedIndex]

    if item == nil then return end

    local animal = item.animal or item.cluster

    if animal == nil then return end

    local animalType = animal.animalTypeIndex

    if button.id == "childInfoButton" then
        local children = animal.children
        if children == nil or #children == 0 then return end

        AnimalInfoDialog.show(children[1].farmId, children[1].uniqueId, children, animalType)

        return
    end

    local target = button.id == "motherInfoButton" and "mother" or "father"

    if target == nil then return end

    local uniqueId = animal[target .. "Id"]

    if uniqueId == "-1" then return end

    local farmId = ""
    local i = string.find(uniqueId, " ")

    farmId = string.sub(uniqueId, 1, i - 1)
    uniqueId = string.sub(uniqueId, i + 1)

    if uniqueId == nil or farmId == nil then return end

    AnimalInfoDialog.show(farmId, uniqueId, nil, animalType)

end

AnimalScreen.onClickAnimalInfo = RealisticLivestock_AnimalScreen.onClickAnimalInfo


function RealisticLivestock_AnimalScreen:onClickInfoMode(a, b)

    self.filters = nil
    self.filteredItems = nil
    self.isInfoMode = true
    self.isBuyMode = false

    self.buttonToggleSelectAll:setVisible(false)
    self.targetSelector.leftButtonElement:setVisible(false)
    self.targetSelector.rightButtonElement:setVisible(false)
    self:initSubcategories()

    self.sourceList:setSelectedItem(1, 1, nil, true)
    self.sourceSelector:setState(1, true)
    self.isAutoUpdatingList = a
    self:updateScreen()
    self.isAutoUpdatingList = false
    self:setSelectionState(AnimalScreen.SELECTION_SOURCE, true)

end

AnimalScreen.onClickInfoMode = RealisticLivestock_AnimalScreen.onClickInfoMode


function AnimalScreen:onClickMonitor()

    local item = (self.filteredItems == nil and self.controller:getTargetItems() or self.filteredItems)[self.sourceList.selectedIndex]

    if item == nil then return end

    local animal = item.animal or item.cluster

    if animal == nil then return end

    local monitor = animal.monitor

    monitor.active = not monitor.active
    monitor.removed = not monitor.active

    AnimalMonitorEvent.sendEvent(animal.clusterSystem.owner, animal, monitor.active, monitor.removed)

    self.buttonMonitor:setText(g_i18n:getText("rl_ui_" .. (monitor.active and "remove" or "apply") .. "Monitor"))
    self.buttonMonitor:setDisabled(monitor.removed)

    local visualData = g_currentMission.animalSystem:getVisualByAge(animal.subTypeIndex, animal.age)

    if not monitor.removed and visualData.monitor ~= nil and animal.idFull ~= nil and animal.idFull ~= "1-1" then

        local sep = string.find(animal.idFull, "-")
        local husbandry = tonumber(string.sub(animal.idFull, 1, sep - 1))
        local animalId = tonumber(string.sub(animal.idFull, sep + 1))

        if husbandry ~= 0 and animalId ~= 0 then

            local rootNode = getAnimalRootNode(husbandry, animalId)

            if rootNode ~= 0 then

                local monitorNode = I3DUtil.indexToObject(rootNode, visualData.monitor)

                if monitorNode ~= nil and monitorNode ~= 0 then setVisibility(monitorNode, monitor.active) end

            end

        end

    end

    self:updateInfoBox()

end


function AnimalScreen:onClickCastrate()

    self.buttonCastrate:setDisabled(true)

    local item = (self.filteredItems == nil and self.controller:getTargetItems() or self.filteredItems)[self.sourceList.selectedIndex]

    if item == nil then return end

    local animal = item.animal or item.cluster

    if animal == nil then return end

    animal.isCastrated = true
    animal.genetics.fertility = 0

end


function RealisticLivestock_AnimalScreen:updateInfoBox(superFunc, isSourceSelected)

    if not g_gui.currentlyReloading then

        --if isSourceSelected == nil then
            --local _ = self.isSourceSelected
        --end

        local animalType = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
        local item
        self.buttonCastrate:setVisible(false)

        if self.filteredItems == nil then

            if self.isBuyMode then
                item = self.controller:getSourceItems(animalType, self.isBuyMode)[self.sourceList.selectedIndex]
            else
                item = self.controller:getTargetItems()[self.sourceList.selectedIndex]
            end

        else

            item = self.filteredItems[self.sourceList.selectedIndex]

        end

        self.infoIcon:setVisible(item ~= nil)
        self.infoName:setVisible(item ~= nil)

        if item ~= nil then

            self.detailsContainer:setVisible(true)

            local animal = item.animal or item.cluster

            self.inputBox:setVisible(self.isInfoMode and (animal.monitor.active or animal.monitor.removed))
            self.outputBox:setVisible(self.isInfoMode and (animal.monitor.active or animal.monitor.removed))

            self.infoIcon:setImageFilename(item:getFilename())
            self.infoDescription:setText(item:getDescription())
            local subType = g_currentMission.animalSystem:getSubTypeByIndex(item:getSubTypeIndex())
            local fillTypeTitle = g_fillTypeManager:getFillTypeTitleByIndex(subType.fillTypeIndex)
            self.infoName:setText(fillTypeTitle)
            local infos = item:getInfos()

            for k, infoTitle in ipairs(self.infoTitle) do
                local info = infos[k]
                local infoValue = self.infoValue[k]
                infoTitle:setVisible(info ~= nil)
                infoValue:setVisible(info ~= nil)
                if info ~= nil then
                    infoTitle:setText(info.title)
                    infoValue:setText(info.value)

                    if info.colour ~= nil then
                        infoTitle:setTextColor(info.colour[1], info.colour[2], info.colour[3], 1)
                        infoValue:setTextColor(info.colour[1], info.colour[2], info.colour[3], 1)
                    else
                        infoTitle:setTextColor(1, 1, 1, 1)
                        infoValue:setTextColor(1, 1, 1, 1)
                    end
                end
            end

            if self.geneticsBoxPositionNormal == nil then

                self.geneticsBoxPositionNormal = GuiUtils.getNormalizedScreenValues("-15px 0px")
                self.geneticsBoxPositionInfo = GuiUtils.getNormalizedScreenValues("-15px 220px")
            
            end

            local geneticsPosition = self.isInfoMode and self.geneticsBoxPositionInfo or self.geneticsBoxPositionNormal

            self.geneticsBox:setPosition(geneticsPosition[1], geneticsPosition[2])
            self.geneticsBox:setVisible(true)
            
            local genetics = animal:addGeneticsInfo()

            for i, title in ipairs(self.geneticsTitle) do
                local value = self.geneticsValue[i]

                title:setVisible(genetics[i] ~= nil)
                value:setVisible(genetics[i] ~= nil)

                if genetics[i] == nil then continue end

                title:setText(genetics[i].title)
                value:setText(g_i18n:getText(genetics[i].text))

                local quality = genetics[i].text

                if quality == "rl_ui_genetics_infertile"  then
                    title:setTextColor(1, 0, 0, 1)
                    value:setTextColor(1, 0, 0, 1)
                elseif quality == "rl_ui_genetics_extremelyLow" or quality == "rl_ui_genetics_extremelyBad" then
                    title:setTextColor(1, 0, 0, 1)
                    value:setTextColor(1, 0, 0, 1)
                elseif quality == "rl_ui_genetics_veryLow" or quality == "rl_ui_genetics_veryBad" then
                    title:setTextColor(1, 0.2, 0, 1)
                    value:setTextColor(1, 0.2, 0, 1)
                elseif quality == "rl_ui_genetics_low" or quality == "rl_ui_genetics_bad" then
                    title:setTextColor(1, 0.52, 0, 1)
                    value:setTextColor(1, 0.52, 0, 1)
                elseif quality == "rl_ui_genetics_average" then
                    title:setTextColor(1, 1, 0, 1)
                    value:setTextColor(1, 1, 0, 1)
                elseif quality == "rl_ui_genetics_high" or quality == "rl_ui_genetics_good" then
                    title:setTextColor(0.52, 1, 0, 1)
                    value:setTextColor(0.52, 1, 0, 1)
                elseif quality == "rl_ui_genetics_veryHigh" or quality == "rl_ui_genetics_veryGood" then
                    title:setTextColor(0.2, 1, 0, 1)
                    value:setTextColor(0.2, 1, 0, 1)
                else
                    title:setTextColor(0, 1, 0, 1)
                    value:setTextColor(0, 1, 0, 1)
                end


            end


            if self.isInfoMode then

                if animal.gender == "male" and animal.animalTypeIndex ~= AnimalType.CHICKEN then
                    self.buttonCastrate:setVisible(true)
                    self.buttonCastrate:setDisabled(animal.isCastrated)
                end

                self.buttonMonitor:setText(g_i18n:getText("rl_ui_" .. (animal.monitor.active and "remove" or "apply") .. "Monitor"))
                self.buttonMonitor:setDisabled(animal.monitor.removed)

                self.motherInfoButton:setDisabled(animal.motherId == nil or animal.motherId == "-1")
                self.motherInfoButton:setText(g_i18n:getText("rl_ui_mother") .. " (" .. ((animal.motherId == nil or animal.motherId == "-1") and g_i18n:getText("rl_ui_unknown") or animal.motherId) .. ")")

                self.fatherInfoButton:setDisabled(animal.fatherId == nil or animal.fatherId == "-1")
                self.fatherInfoButton:setText(g_i18n:getText("rl_ui_father") .. " (" .. ((animal.fatherId == nil or animal.fatherId == "-1") and g_i18n:getText("rl_ui_unknown") or animal.fatherId) .. ")")

                self.childInfoButton:setDisabled(not animal.isParent)


                for i = 1, #self.inputTitle do
                    self.inputTitle[i]:setVisible(false)
                    self.inputValue[i]:setVisible(false)
                end


                for i = 1, #self.outputTitle do
                    self.outputTitle[i]:setVisible(false)
                    self.outputValue[i]:setVisible(false)
                end


                local infoIndex = 1
                local daysPerMonth = g_currentMission.environment.daysPerPeriod


                for fillType, amount in pairs(animal.input) do

                    if infoIndex > #self.inputTitle then break end

                    local title, value = self.inputTitle[infoIndex], self.inputValue[infoIndex]

                    title:setVisible(true)
                    value:setVisible(true)

                    title:setText(g_i18n:getText("rl_ui_input_" .. fillType))
                    value:setText(string.format(g_i18n:getText("rl_ui_amountPerDay"), (amount * 24) / daysPerMonth))

                    infoIndex = infoIndex + 1

                end


                infoIndex = 1


                for fillType, amount in pairs(animal.output) do

                    if infoIndex > #self.outputTitle then break end

                    local title, value = self.outputTitle[infoIndex], self.outputValue[infoIndex]

                    title:setVisible(true)
                    value:setVisible(true)

                    local outputText = fillType

                    if fillType == "pallets" then

                        if animal.animalTypeIndex == AnimalType.COW then outputText = "pallets_milk" end

                        if animal.animalTypeIndex == AnimalType.SHEEP then outputText = animal.subType == "GOAT" and "pallets_goatMilk" or "pallets_wool" end

                        if animal.animalTypeIndex == AnimalType.CHICKEN then outputText = "pallets_eggs" end

                    end

                    title:setText(g_i18n:getText("rl_ui_output_" .. outputText))
                    value:setText(string.format(g_i18n:getText("rl_ui_amountPerDay"), (amount * 24) / daysPerMonth))

                    infoIndex = infoIndex + 1

                end

            end


            if not Platform.isMobile then self:updatePrice() end


            self.infoBox:setVisible(not self.isInfoMode)
            --self.numAnimalsBox:setVisible(not self.isInfoMode)
            self.parentBox:setVisible(self.isInfoMode and not self.isBuyMode)
            self.buttonRename:setVisible(self.isInfoMode)

        else

            self.detailsContainer:setVisible(false)
            self.buttonRename:setVisible(false)

        end

    end

    self.numAnimalsBox:setVisible(false)

end

AnimalScreen.updateInfoBox = Utils.overwrittenFunction(AnimalScreen.updateInfoBox, RealisticLivestock_AnimalScreen.updateInfoBox)


function RealisticLivestock_AnimalScreen:updateScreen(superFunc, keepSelection)


    self.isAutoUpdatingList = true
    self.sourceList:reloadData(true)
    self.isAutoUpdatingList = false

    local v77, v78

    local animalTypeIndex = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]

    if self.isBuyMode then
        v77, v78 = self.controller:getSourceData(animalTypeIndex)
    else
        v77, v78 = self.controller:getTargetData(animalTypeIndex)
    end

    self.targetText:setText(v78)
    self.targetItems = v77
    local v79 = {}

    for _, v80 in pairs(v77) do
        local animalType = g_currentMission.animalSystem:getTypeByIndex(self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()])
        local maxAnimalString = " (" .. v80:getNumOfAnimals() .. "/" .. v80:getMaxNumOfAnimals(animalType) .. ")"
        local husbandryString = v80:getName() .. maxAnimalString
        table.insert(v79, husbandryString)
    end


    self.targetSelector:setTexts(v79)

    if not keepSelection and #v77 > 0 then
        self.targetSelector:setState(1)
        self:setSelectionState(AnimalScreen.SELECTION_SOURCE)
    end

    self:onTargetSelectionChanged(true)

    local hasAnimals = self.sourceList:getItemCount() > 0


    self.detailsContainer:setVisible(hasAnimals)
    self.infoBox:setVisible(not self.isInfoMode)
    --self.numAnimalsBox:setVisible(not self.isInfoMode)
    self.numAnimalsBox:setVisible(false)
    self.parentBox:setVisible(self.isInfoMode)
    self.geneticsBox:setVisible(self.isInfoMode)

    if self.isInfoMode then
        self.buttonBuy:setVisible(false)
        self.buttonSell:setVisible(false)
    else

        local isItemSelected = self.numAnimalsElement:getIsFocused()

        self.buttonBuy:setVisible(self.isBuyMode and isItemSelected)
        self.buttonSell:setVisible(isItemSelected and not self.isBuyMode)
        self.buttonSelect:setVisible(not isItemSelected)

    end


    self.buttonBuy:setDisabled(not self.isBuyMode)
    self.buttonBuy:setVisible(not self.isInfoMode and self.isBuyMode)
    self.buttonSell:setDisabled(self.isInfoMode or self.isBuyMode)
    self.buttonSell:setVisible(not self.isInfoMode and not self.isBuyMode)
    self.buttonRename:setVisible(self.isInfoMode)
    self.buttonMonitor:setVisible(self.isInfoMode)

    if hasAnimals then
        self:updatePrice()
        self:updateInfoBox()
    end

    self.tabBuy:setSelected(self.isBuyMode and not self.isInfoMode)
    self.tabSell:setSelected(not self.isBuyMode and not self.isInfoMode)
    self.tabInfo:setSelected(not self.isBuyMode and self.isInfoMode)

    self.buttonBuySelected:setVisible(not self.isTrailer and not self.isInfoMode)

    self.buttonsPanel:invalidateLayout()

    self:setSelectionState(1) -- ?

end

AnimalScreen.updateScreen = Utils.overwrittenFunction(AnimalScreen.updateScreen, RealisticLivestock_AnimalScreen.updateScreen)


function RealisticLivestock_AnimalScreen:setMaxNumAnimals()

    self.infoBox:setVisible(not self.isInfoMode)
    --self.numAnimalsBox:setVisible(not self.isInfoMode)
    self.numAnimalsBox:setVisible(false)
    self.parentBox:setVisible(self.isInfoMode and not self.isBuyMode)
    self.geneticsBox:setVisible(self.isInfoMode)

end

AnimalScreen.setMaxNumAnimals = Utils.appendedFunction(AnimalScreen.setMaxNumAnimals, RealisticLivestock_AnimalScreen.setMaxNumAnimals)


function RealisticLivestock_AnimalScreen:getCellTypeForItemInSection(_, list, _, index)

    if list ~= self.sourceList then return nil end

    local animalTypeIndex = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
	local items

    if self.filteredItems == nil then

	    if self.isInfoMode or not self.isBuyMode then
            items = self.controller:getTargetItems()
	    else
		    items = self.controller:getSourceItems(animalTypeIndex, self.isBuyMode)
	    end

    else

        items = self.filteredItems

    end

	local a = items[index]
	local b = items[index - 1]

	return (a == nil or b == nil or a:getSubTypeIndex() ~= b:getSubTypeIndex()) and "sectionCell" or "defaultCell"

end

AnimalScreen.getCellTypeForItemInSection = Utils.overwrittenFunction(AnimalScreen.getCellTypeForItemInSection, RealisticLivestock_AnimalScreen.getCellTypeForItemInSection)


function RealisticLivestock_AnimalScreen:getNumberOfItemsInSection(superFunc, list)

    if self.filteredItems == nil or not self.isOpen then return superFunc(self, list) end

    return #self.filteredItems

end

AnimalScreen.getNumberOfItemsInSection = Utils.overwrittenFunction(AnimalScreen.getNumberOfItemsInSection, RealisticLivestock_AnimalScreen.getNumberOfItemsInSection)


function RealisticLivestock_AnimalScreen:populateCellForItemInSection(_, list, _, index, cell)

    local animalType = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
    local filteredItems = self.filteredItems

    if list == self.sourceList then

        local item

        if filteredItems == nil then

            if self.isBuyMode then
                item = self.controller:getSourceItems(animalType, self.isBuyMode)[index]
            else
                item = self.controller:getTargetItems()[index]
            end

        else

            item = filteredItems[index]

        end

        if item == nil then return end

        local subType = g_currentMission.animalSystem:getSubTypeByIndex(item:getSubTypeIndex())
        self.isHorse = subType.typeIndex == AnimalType.HORSE

        if cell.name == "sectionCell" then
            cell:getAttribute("title"):setText(g_fillTypeManager:getFillTypeTitleByIndex(subType.fillTypeIndex))
        end

        self.isHorse = g_currentMission.animalSystem:getSubTypeByIndex(item:getSubTypeIndex()).typeIndex == AnimalType.HORSE

        local name = item:getName()
        local animal = item.animal or item.cluster

        if animal:getName() == "" and not self.isHorse and (not self.isBuyMode or (self.controller.trailer ~= nil and self.controller.husbandry ~= nil and self.isBuyMode)) and animal.uniqueId ~= nil then name = string.format("%s %s %s", RealisticLivestock.AREA_CODES[animal.birthday.country].code, animal.farmId, animal.uniqueId) end

        cell:getAttribute("name"):setText(name)

        cell:getAttribute("icon"):setImageFilename(item:getFilename())
        cell:getAttribute("price"):setValue(item:getPrice())

        cell:getAttribute("amount"):setValue("")
        cell:getAttribute("amount"):setText("")

        local checkbox = cell:getAttribute("checkbox")

        if (self.isInfoMode and not self.isBuyMode) or self.isTrailer then
            checkbox:setVisible(false)
        else

            checkbox:setVisible(true)
            local check = cell:getAttribute("check")

            if check ~= nil then

                local originalIndex = self.filteredItems == nil and index or item.originalIndex

                check:setVisible(self.selectedItems[originalIndex] ~= nil and self.selectedItems[originalIndex])

                local selectAllText = g_i18n:getText("rl_ui_selectAll")
                local selectNoneText = g_i18n:getText("rl_ui_selectNone")

                checkbox.onClickCallback = function(animalScreen, button)

                    if self.selectedItems[originalIndex] then
                        self.selectedItems[originalIndex] = false
                        check:setVisible(false)

                        local hasSelection = false

                        for _, selected in pairs(self.selectedItems) do
                            if selected then
                                hasSelection = true
                                break
                            end
                        end

                        self.buttonToggleSelectAll:setText(hasSelection and selectNoneText or selectAllText)

                    else
                        self.selectedItems[originalIndex] = true
                        check:setVisible(true)
                        self.buttonToggleSelectAll:setText(selectNoneText)
                    end

                end

            end

        end

    else

        if list == self.targetList then

            local item

            if filteredItems == nil then

                if self.isBuyMode then
                    item = self.controller:getTargetItems()[index]
                else
                    item = self.controller:getSourceItems(animalType, self.isBuyMode)[index]
                end

            else

                item = filteredItems[index]

            end

            if item == nil then return end


            self.isHorse = g_currentMission.animalSystem:getSubTypeByIndex(item:getSubTypeIndex()).typeIndex == AnimalType.HORSE


            local name = item:getName()

            if not self.isHorse and not self.isBuyMode and item.cluster ~= nil and item.cluster.uniqueId ~= nil then name = item.cluster.uniqueId .. (name == "" and "" or (" (" .. name .. ")")) end

            cell:getAttribute("name"):setText(name)


            cell:getAttribute("icon"):setImageFilename(item:getFilename())
            cell:getAttribute("separator"):setVisible(index > 1)

            cell:getAttribute("amount"):setValue("")
            cell:getAttribute("amount"):setText("")

        end

        return

    end

end

AnimalScreen.populateCellForItemInSection = Utils.overwrittenFunction(AnimalScreen.populateCellForItemInSection, RealisticLivestock_AnimalScreen.populateCellForItemInSection)


function AnimalScreen:onClickBuySelected()

    local itemsToProcess = {}
    local money = 0
    local animalTypeIndex = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]

    for animalIndex, isSelected in pairs(self.selectedItems) do
        if isSelected then

            if isSelected then

                if self.isTrailerFarm then
                    table.insert(itemsToProcess, animalIndex)
                elseif self.isBuyMode then
                    local animalFound, _, _, totalPrice = self.controller:getSourcePrice(animalTypeIndex, animalIndex, 1)
                    if animalFound then
                        table.insert(itemsToProcess, animalIndex)
                        money = money + totalPrice
                    end
                else
                    local animalFound, _, _, totalPrice = self.controller:getTargetPrice(animalTypeIndex, animalIndex, 1)
                    if animalFound then
                        table.insert(itemsToProcess, animalIndex)
                        money = money + totalPrice
                    end
                end

            end

        end
    end

    self.pendingBulkTransaction = { ["items"] = itemsToProcess, ["animalTypeIndex"] = animalTypeIndex }

    local callback, confirmationText, text

    if self.isBuyMode then

        confirmationText = self.isTrailerFarm and g_i18n:getText("rl_ui_moveConfirmation") or g_i18n:getText("rl_ui_buyConfirmation")
        callback = self.buySelected
	    text = self.controller:getSourceActionText()

    else

        confirmationText = self.isTrailerFarm and g_i18n:getText("rl_ui_moveConfirmation") or g_i18n:getText("rl_ui_sellConfirmation")
        callback = self.sellSelected
	    text = self.controller:getTargetActionText()

    end

    YesNoDialog.show(callback, self, string.format(confirmationText, #itemsToProcess, g_i18n:formatMoney(money, 2, true, true)), g_i18n:getText("ui_attention"), text, g_i18n:getText("button_back"))

end


function AnimalScreen:buySelected(clickYes)

    if not clickYes or self.pendingBulkTransaction == nil then return end

    self.controller:applySourceBulk(self.pendingBulkTransaction.animalTypeIndex, self.pendingBulkTransaction.items)

    self.selectedItems = {}

end


function AnimalScreen:sellSelected(clickYes)

    if not clickYes or self.pendingBulkTransaction == nil then return end

    self.controller:applyTargetBulk(self.pendingBulkTransaction.animalTypeIndex, self.pendingBulkTransaction.items)

    self.selectedItems = {}

end


function AnimalScreen:onClickFilter()

    local animalTypeIndex = self.sourceSelector:getState()

    AnimalFilterDialog.show(self.isBuyMode and self.controller:getSourceItems(self.sourceSelectorStateToAnimalType[animalTypeIndex], self.isBuyMode) or self.controller:getTargetItems(), animalTypeIndex, self.onApplyFilters, self, self.isBuyMode)

end


function AnimalScreen:onApplyFilters(filters, filteredItems)

    self.filters = filters
    self.filteredItems = filteredItems
    self.selectedItems = {}
    self.buttonToggleSelectAll:setText(g_i18n:getText("rl_ui_selectAll"))
    self.sourceList:reloadData(true)

end


function RealisticLivestock_AnimalScreen:getPrice()

    local animalIndex
    local animalTypeIndex = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]

    if self.filteredItems == nil then
        animalIndex = self.sourceList.selectedIndex
    elseif #self.filteredItems > 0 and self.filteredItems[self.sourceList.selectedIndex] ~= nil then
        animalIndex = self.filteredItems[self.sourceList.selectedIndex].originalIndex
    else
        return false, 0, 0, 0
    end

    local isFound, price, transportationFee, totalPrice = false, 0, 0, 0

	if self.isBuyMode then
		isFound, price, transportationFee, totalPrice = self.controller:getSourcePrice(animalTypeIndex, animalIndex, 1)
	else
	    isFound, price, transportationFee, totalPrice = self.controller:getTargetPrice(animalTypeIndex, animalIndex, 1)
	end

    return isFound, price, transportationFee, totalPrice

end

AnimalScreen.getPrice = Utils.overwrittenFunction(AnimalScreen.getPrice, RealisticLivestock_AnimalScreen.getPrice)


function RealisticLivestock_AnimalScreen:onClickBuy()

	self.numAnimals = 1

	local animalIndex

    if self.filteredItems == nil then
        animalIndex = self.sourceList.selectedIndex
    else
        animalIndex = self.filteredItems[self.sourceList.selectedIndex].originalIndex
    end

	local confirmationText = self.controller:getApplySourceConfirmationText(self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()], animalIndex, 1)
	local actionText = self.controller:getSourceActionText()

	YesNoDialog.show(self.onYesNoSource, self, confirmationText, g_i18n:getText("ui_attention"), actionText, g_i18n:getText("button_back"))

	return true

end

AnimalScreen.onClickBuy = Utils.overwrittenFunction(AnimalScreen.onClickBuy, RealisticLivestock_AnimalScreen.onClickBuy)


function RealisticLivestock_AnimalScreen:onClickSell()

	self.numAnimals = 1

	local animalIndex

    if self.filteredItems == nil then
        animalIndex = self.sourceList.selectedIndex
    else
        animalIndex = self.filteredItems[self.sourceList.selectedIndex].originalIndex
    end

	local confirmationText = self.controller:getApplyTargetConfirmationText(self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()], animalIndex, 1)
	local actionText = self.controller:getTargetActionText()

	YesNoDialog.show(self.onYesNoTarget, self, confirmationText, g_i18n:getText("ui_attention"), actionText, g_i18n:getText("button_back"))

	return true

end

AnimalScreen.onClickSell = Utils.overwrittenFunction(AnimalScreen.onClickSell, RealisticLivestock_AnimalScreen.onClickSell)


function RealisticLivestock_AnimalScreen:onYesNoSource(_, clickYes)

	if clickYes then
		local animalIndex

        if self.filteredItems == nil then
            animalIndex = self.sourceList.selectedIndex
        else
            animalIndex = self.filteredItems[self.sourceList.selectedIndex].originalIndex
        end

		self.controller:applySource(self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()], animalIndex, 1)
	end

end

AnimalScreen.onYesNoSource = Utils.overwrittenFunction(AnimalScreen.onYesNoSource, RealisticLivestock_AnimalScreen.onYesNoSource)


function RealisticLivestock_AnimalScreen:onYesNoTarget(_, clickYes)

	if clickYes then
		local animalIndex

        if self.filteredItems == nil then
            animalIndex = self.sourceList.selectedIndex
        else
            animalIndex = self.filteredItems[self.sourceList.selectedIndex].originalIndex
        end

		self.controller:applyTarget(self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()], animalIndex, 1)
	end

end

AnimalScreen.onYesNoTarget = Utils.overwrittenFunction(AnimalScreen.onYesNoTarget, RealisticLivestock_AnimalScreen.onYesNoTarget)


function RealisticLivestock_AnimalScreen:onSourceActionFinished(_, error, text)

	local dialogType = error and DialogElement.TYPE_WARNING or DialogElement.TYPE_INFO

    if self.filteredItems ~= nil then

        local item = self.filteredItems[self.sourceList.selectedIndex]

        if item ~= nil then table.remove(self.filteredItems, self.sourceList.selectedIndex) end

    end

	InfoDialog.show(text, self.updateScreen, self, dialogType, nil, nil, true)

end

AnimalScreen.onSourceActionFinished = Utils.overwrittenFunction(AnimalScreen.onSourceActionFinished, RealisticLivestock_AnimalScreen.onSourceActionFinished)


function RealisticLivestock_AnimalScreen:onTargetActionFinished(_, error, text)

	local dialogType = error and DialogElement.TYPE_WARNING or DialogElement.TYPE_INFO

    if self.filteredItems ~= nil then

        local item = self.filteredItems[self.sourceList.selectedIndex]

        if item ~= nil then table.remove(self.filteredItems, self.sourceList.selectedIndex) end

    end

	InfoDialog.show(text, self.updateScreen, self, dialogType, nil, nil, true)

end

AnimalScreen.onTargetActionFinished = Utils.overwrittenFunction(AnimalScreen.onTargetActionFinished, RealisticLivestock_AnimalScreen.onTargetActionFinished)


function AnimalScreen:onSourceBulkActionFinished(error, text, indexes)

    local dialogType = error and DialogElement.TYPE_WARNING or DialogElement.TYPE_INFO

    if self.filteredItems ~= nil then

        for _, index in pairs(indexes) do

            for i, item in pairs(self.filteredItems) do

                if item.originalIndex == index then
                    table.remove(self.filteredItems, i)
                    break
                end

            end

        end

    end

	InfoDialog.show(text, self.updateScreen, self, dialogType, nil, nil, true)

end


function AnimalScreen:onTargetBulkActionFinished(error, text, indexes)

    local dialogType = error and DialogElement.TYPE_WARNING or DialogElement.TYPE_INFO

    if self.filteredItems ~= nil then

        for _, index in pairs(indexes) do

            for i, item in pairs(self.filteredItems) do

                if item.originalIndex == index then
                    table.remove(self.filteredItems, i)
                    break
                end

            end

        end

    end

	InfoDialog.show(text, self.updateScreen, self, dialogType, nil, nil, true)

end


function AnimalScreen:onClickToggleSelectAll()

    local selectAll = true

    for _, selected in pairs(self.selectedItems) do
        if selected then
            selectAll = false
            break
        end
    end


    local animalType = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
    local items

    if self.filteredItems == nil then

        if self.isBuyMode then
            items = self.controller:getSourceItems(animalType, self.isBuyMode)
        else
            items = self.controller:getTargetItems()
        end

    else
        items = self.filteredItems
    end


    for i, item in pairs(items) do

        self.selectedItems[self.filteredItems == nil and i or item.originalIndex] = selectAll

    end


    self.buttonToggleSelectAll:setText(selectAll and g_i18n:getText("rl_ui_selectNone") or g_i18n:getText("rl_ui_selectAll"))
    self.sourceList:reloadData()

end


function RealisticLivestock_AnimalScreen:setSelectionState(superFunc, state) -- ?

    local returnValue = superFunc(self, state)

    local hasItems = self.sourceList:getItemCount() > 0

    self.buttonBuy:setVisible(self.isBuyMode and hasItems)
    self.buttonSell:setVisible(not self.isBuyMode and not self.isInfoMode and hasItems)

	self.buttonsPanel:invalidateLayout()

    return returnValue

end

AnimalScreen.setSelectionState = Utils.overwrittenFunction(AnimalScreen.setSelectionState, RealisticLivestock_AnimalScreen.setSelectionState)


function AnimalScreen:onClickInfoPrompt() end


function AnimalScreen:onHighlightInfoPrompt(button)

    self.infoPrompt:setVisible(true)

    local x = button.absPosition[1] - self.infoPrompt.size[1]
    local y = button.absPosition[2] - self.infoPrompt.size[2] * 0.5

    self.infoPrompt:setAbsolutePosition(x, y)

end


function AnimalScreen:onHighlightRemoveInfoPrompt()

    self.infoPrompt:setVisible(false)

end