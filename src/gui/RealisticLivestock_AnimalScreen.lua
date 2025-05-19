RealisticLivestock_AnimalScreen = {}



-- #################################################################################

-- NOTES:

-- the AnimalScreenDealer controller is really pissing me off
-- so now i disable it
-- inconsequential, who cares

-- #################################################################################


function RealisticLivestock_AnimalScreen.show(husbandry, vehicle, isDealer)

    if husbandry == nil and vehicle == nil then return end

    g_animalScreen.isTrailerFarm = husbandry ~= nil and vehicle ~= nil

	g_animalScreen:setController(husbandry, vehicle, isDealer)
	g_gui:showGui("AnimalScreen")

end

AnimalScreen.show = RealisticLivestock_AnimalScreen.show


function RealisticLivestock_AnimalScreen:setController(husbandry, vehicle, isDealer)

    self.isTrailer = husbandry == nil and vehicle ~= nil and not isDealer

end

AnimalScreen.setController = Utils.prependedFunction(AnimalScreen.setController, RealisticLivestock_AnimalScreen.setController)


function RealisticLivestock_AnimalScreen:onClickBuyMode(a, b)
    self.isInfoMode = false
    self.selectedItems = {}
    self.pendingBulkTransaction = nil

    self.buttonBuySelected:setText(self.isTrailerFarm and g_i18n:getText("rl_ui_moveSelected") or g_i18n:getText("rl_ui_buySelected"))
end

AnimalScreen.onClickBuyMode = Utils.prependedFunction(AnimalScreen.onClickBuyMode, RealisticLivestock_AnimalScreen.onClickBuyMode)


function RealisticLivestock_AnimalScreen:onClickSellMode(a, b)
    self.isInfoMode = false
    self.selectedItems = {}
    self.pendingBulkTransaction = nil

    self.buttonBuySelected:setText(self.isTrailerFarm and g_i18n:getText("rl_ui_moveSelected") or g_i18n:getText("rl_ui_sellSelected"))
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

    local item = self.controller:getTargetItems()[self.sourceList.selectedIndex]
    if item == nil or item.cluster == nil then return end

    local dialog = NameInputDialog.INSTANCE
    local name = item.cluster.name or g_currentMission.animalNameSystem:getRandomName(item.cluster.gender)
    dialog:setCallback(self.changeName, self, name, nil, 30, nil, item.cluster.gender)
    g_gui:showDialog("NameInputDialog")

end

AnimalScreen.onClickRename = RealisticLivestock_AnimalScreen.onClickRename


function RealisticLivestock_AnimalScreen:changeName(text, clickOk)

    if clickOk then
        local animal = g_animalScreen.controller:getTargetItems()[g_animalScreen.sourceList.selectedIndex].cluster
        
        if animal ~= nil then

            text = text ~= "" and text or nil
            animal.name = text

            local visualData = g_currentMission.animalSystem:getVisualByAge(animal.subTypeIndex, animal.age)

            if visualData.earTagRight ~= nil and animal.idFull ~= nil and animal.idFull ~= "1-1" then

                local sep = string.find(animal.idFull, "-")
                local husbandry = tonumber(string.sub(animal.idFull, 1, sep - 1))
                local animalId = tonumber(string.sub(animal.idFull, sep + 1))

                if husbandry ~= 0 and animalId ~= 0 then

                    local rootNode = getAnimalRootNode(husbandry, animalId)

                    if rootNode ~= 0 then

                        local earTagNode = I3DUtil.indexToObject(rootNode, visualData.earTagRight)

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

    local item = self.controller:getTargetItems()[self.sourceList.selectedIndex]
    local animalType = item.cluster.animalTypeIndex

    if button.id == "childInfoButton" then
        if item == nil or item.cluster == nil then return end
        local children = item.cluster.children
        if children == nil or #children == 0 then return end

        AnimalInfoDialog.show(children[1].farmId, children[1].uniqueId, children, animalType)

        return
    end

    local target = button.id == "motherInfoButton" and "mother" or "father"

    if item == nil or target == nil then return end

    local uniqueId = item.cluster[target .. "Id"]

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

    self.isInfoMode = true
    self.isBuyMode = false
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


function RealisticLivestock_AnimalScreen:updateInfoBox(superFunc, isSourceSelected)

    if not g_gui.currentlyReloading then

        --if isSourceSelected == nil then
            --local _ = self.isSourceSelected
        --end

        local animalType = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
        local item

        if self.isBuyMode then
            item = self.controller:getSourceItems(animalType, self.isBuyMode)[self.sourceList.selectedIndex]
        else
            item = self.controller:getTargetItems()[self.sourceList.selectedIndex]
        end

        self.infoIcon:setVisible(item ~= nil)
        self.infoName:setVisible(item ~= nil)
        if item ~= nil then

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

            if self.isInfoMode then

                self.motherInfoButton:setDisabled(item.cluster.motherId == nil or item.cluster.motherId == "-1")
                self.motherInfoButton:setText(g_i18n:getText("rl_ui_mother") .. " (" .. ((item.cluster.motherId == nil or item.cluster.motherId == "-1") and g_i18n:getText("rl_ui_unknown") or item.cluster.motherId) .. ")")

                self.fatherInfoButton:setDisabled(item.cluster.fatherId == nil or item.cluster.fatherId == "-1")
                self.fatherInfoButton:setText(g_i18n:getText("rl_ui_father") .. " (" .. ((item.cluster.fatherId == nil or item.cluster.fatherId == "-1") and g_i18n:getText("rl_ui_unknown") or item.cluster.fatherId) .. ")")

                self.childInfoButton:setDisabled(not item.cluster.isParent)

                local genetics = item.cluster:addGeneticsInfo()

                for i, title in ipairs(self.geneticsTitle) do
                    local value = self.geneticsValue[i]

                    title:setVisible(genetics[i] ~= nil)
                    value:setVisible(genetics[i] ~= nil)

                    if genetics[i] == nil then continue end

                    title:setText(genetics[i].title)
                    value:setText(g_i18n:getText(genetics[i].text))

                    local quality = genetics[i].text

                    if quality == "rl_ui_genetics_extremelyLow" or quality == "rl_ui_genetics_extremelyBad" then
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

            end

            if not Platform.isMobile then self:updatePrice() end


            self.infoBox:setVisible(not self.isInfoMode)
            self.numAnimalsBox:setVisible(not self.isInfoMode)
            self.parentBox:setVisible(self.isInfoMode and not self.isBuyMode)
            self.geneticsBox:setVisible(self.isInfoMode)
            self.buttonRename:setVisible(self.isInfoMode)

        end

    end

end

AnimalScreen.updateInfoBox = Utils.overwrittenFunction(AnimalScreen.updateInfoBox, RealisticLivestock_AnimalScreen.updateInfoBox)


function RealisticLivestock_AnimalScreen:updateScreen(superFunc, keepSelection)


    self.isAutoUpdatingList = true
    self.sourceList:reloadData(true)
    self.isAutoUpdatingList = false

    local v77, v78

    if self.isBuyMode then
        v77, v78 = self.controller:getSourceData(self.sourceSelector:getState())
    else
        v77, v78 = self.controller:getTargetData(self.sourceSelector:getState())
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
    self.numAnimalsBox:setVisible(not self.isInfoMode)
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

    if hasAnimals then
        self:updatePrice()
        self:updateInfoBox()
    end

    self.tabBuy:setSelected(self.isBuyMode and not self.isInfoMode)
    self.tabSell:setSelected(not self.isBuyMode and not self.isInfoMode)
    self.tabInfo:setSelected(not self.isBuyMode and self.isInfoMode)

    self.buttonBuySelected:setVisible(not self.isTrailer)

    self.buttonsPanel:invalidateLayout()

end

AnimalScreen.updateScreen = Utils.overwrittenFunction(AnimalScreen.updateScreen, RealisticLivestock_AnimalScreen.updateScreen)


function RealisticLivestock_AnimalScreen:setMaxNumAnimals()

    self.infoBox:setVisible(not self.isInfoMode)
    self.numAnimalsBox:setVisible(not self.isInfoMode)
    self.parentBox:setVisible(self.isInfoMode and not self.isBuyMode)
    self.geneticsBox:setVisible(self.isInfoMode)

end

AnimalScreen.setMaxNumAnimals = Utils.prependedFunction(AnimalScreen.setMaxNumAnimals, RealisticLivestock_AnimalScreen.setMaxNumAnimals)


function RealisticLivestock_AnimalScreen:getCellTypeForItemInSection(_, list, _, index)

    if list ~= self.sourceList then return nil end

    local animalTypeIndex = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
	local items

	if self.isInfoMode or not self.isBuyMode then
        items = self.controller:getTargetItems()
	else
		items = self.controller:getSourceItems(animalTypeIndex, self.isBuyMode)
	end

	local a = items[index]
	local b = items[index - 1]

	return (a == nil or b == nil or a:getSubTypeIndex() ~= b:getSubTypeIndex()) and "sectionCell" or "defaultCell"

end

AnimalScreen.getCellTypeForItemInSection = Utils.overwrittenFunction(AnimalScreen.getCellTypeForItemInSection, RealisticLivestock_AnimalScreen.getCellTypeForItemInSection)


function RealisticLivestock_AnimalScreen:populateCellForItemInSection(_, list, _, index, cell)

    local animalType = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]

    if list == self.sourceList then

        local item


        if self.isBuyMode then
            item = self.controller:getSourceItems(animalType, self.isBuyMode)[index]
        else
            item = self.controller:getTargetItems()[index]
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

                check:setVisible(false)
        
                checkbox.onClickCallback = function(animalScreen, button)

                    if self.selectedItems[index] then
                        self.selectedItems[index] = false
                        check:setVisible(false)
                    else
                        self.selectedItems[index] = true
                        check:setVisible(true)
                    end

                end

            end

        end

    else

        if list == self.targetList then

            local item

            if self.isBuyMode then
                item = self.controller:getTargetItems()[index]
            else
                item = self.controller:getSourceItems(animalType, self.isBuyMode)[index]
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