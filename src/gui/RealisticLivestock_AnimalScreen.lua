RealisticLivestock_AnimalScreen = {}


AnimalScreen.DEWAR_QUANTITIES = {
    1,
    2,
    3,
    4,
    5,
    10,
    15,
    20,
    25,
    30,
    40,
    50,
    75,
    100,
    150,
    200,
    250,
    300,
    400,
    500,
    750,
    1000
}


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

    --if husbandry ~= nil then self.tabLogButton:setImageSlice(nil, "realistic_livestock.messages" .. (husbandry:getHasUnreadRLMessages() and "_new" or "")) end

    self.isTrailer = husbandry == nil and vehicle ~= nil and not isDealer
    self.isDirectFarm = husbandry ~= nil and vehicle == nil
    self.isDealer = isDealer
    self.husbandry = husbandry

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

    self.tabLog:setVisible(self.isDirectFarm)
    self.tabHerdsman:setVisible(self.isDirectFarm)

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


function RealisticLivestock_AnimalScreen:onGuiSetupFinished()

    local function getText(key)

        return g_i18n:getText(key)

    end
    
    local geneticTexts = {
        getText("rl_ui_genetics_extremelyBad"),
        getText("rl_ui_genetics_veryBad"),
        getText("rl_ui_genetics_bad"),
        getText("rl_ui_genetics_average"),
        getText("rl_ui_genetics_high"),
        getText("rl_ui_genetics_veryHigh"),
        getText("rl_ui_genetics_extremelyHigh"),
        getText("rl_ui_genetics_highest")
    }

    local fertilityTexts = table.clone(geneticTexts, 1)
    table.insert(fertilityTexts, 1, getText("rl_ui_genetics_infertile"))

    self.currentHerdsmanPage = "buy"

    self.herdsmanOptions = {
        ["enabled"] = { ["target"] = "enabled", ["type"] = "binary", ["values"] = { false, true }, ["texts"] = { getText("setting_disasterDestructionState_disabled"), getText("setting_disasterDestructionState_enabled") } },
        ["budget|type"] = { ["target"] = "budget|type", ["type"] = "binary", ["values"] = { "fixed", "percentage" }, ["texts"] = { getText("rl_ui_fixed"), getText("rl_ui_percentage") } },
        ["budget|fixed"] = { ["target"] = "budget|fixed", ["type"] = "input", ["inputType"] = "money" },
        ["budget|percentage"] = { ["target"] = "budget|percentage", ["type"] = "multi", ["values"] = { 0.5, 1, 1.5, 2, 2.5, 3, 4, 5, 6, 7, 8, 9, 10, 12.5, 15, 17.5, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100 }, ["texts"] = { "0.5%", "1%", "1.5%", "2%", "2.5%", "3%", "4%", "5%", "6%", "7%", "8%", "9%", "10%", "12.5%", "15%", "17.5%", "20%", "25%", "30%", "35%", "40%", "45%", "50%", "60%", "70%", "80%", "90%", "100%" } },
        ["maxAnimals"] = { ["target"] = "maxAnimals", ["type"] = "input", ["inputType"] = "number" },
        ["breed"] = { ["target"] = "breed", ["type"] = "multi", ["ignoreTexts"] = true },
        ["semen"] = { ["target"] = "semen", ["type"] = "multi", ["ignoreTexts"] = true },
        ["mark"] = { ["target"] = "mark", ["type"] = "binary", ["values"] = { false, true }, ["texts"] = { getText("rl_ui_dontMark"), getText("rl_ui_mark") } },
        ["diseases"] = { ["target"] = "diseases", ["type"] = "binary", ["values"] = { false, true }, ["texts"] = { getText("rl_ui_noDiseases"), getText("rl_ui_any") } },
        ["diseasesSecondary"] = { ["target"] = "diseases", ["type"] = "binary", ["values"] = { false, true }, ["texts"] = { getText("rl_ui_any"), getText("rl_ui_onlyDiseases") } },
        ["gender"] = { ["target"] = "gender", ["type"] = "tripleOption", ["values"] = { "female", "any", "male" }, ["texts"] = { getText("rl_ui_female"), getText("rl_ui_any"), getText("rl_ui_male") } },
        ["age"] = { ["target"] = "age", ["type"] = "doubleSlider", ["ignoreTexts"] = true },
        ["quality"] = { ["target"] = "quality", ["type"] = "doubleSlider", ["values"] = { 25, 35, 70, 90, 110, 140, 165, 175 }, ["texts"] = geneticTexts },
        ["fertility"] = { ["target"] = "fertility", ["type"] = "doubleSlider", ["values"] = { 0, 25, 35, 70, 90, 110, 140, 165, 175 }, ["texts"] = fertilityTexts },
        ["health"] = { ["target"] = "health", ["type"] = "doubleSlider", ["values"] = { 25, 35, 70, 90, 110, 140, 165, 175 }, ["texts"] = geneticTexts },
        ["productivity"] = { ["target"] = "productivity", ["type"] = "doubleSlider", ["values"] = { 25, 35, 70, 90, 110, 140, 165, 175 }, ["texts"] = geneticTexts },
        ["metabolism"] = { ["target"] = "metabolism", ["type"] = "doubleSlider", ["values"] = { 25, 35, 70, 90, 110, 140, 165, 175 }, ["texts"] = geneticTexts },
        ["convention"] = { ["target"] = "convention", ["type"] = "binary", ["values"] = { "random", "alphabetical" }, ["texts"] = { getText("rl_button_random"), getText("rl_ui_alphabetical") } }
    }

    local function updateTooltip(element)

        local option = self.herdsmanOptions[element.name]
            
        local tooltip = element:getDescendantByName("tooltip")
        tooltip:setVisible(true)

        if option.type == "doubleSlider" then

            local lowestState = element:getLowestState()
            local highestState = element:getHighestState()
            
            if lowestState == highestState then
                tooltip:setText(string.format(getText(string.format("rl_ui_herdsmanTooltip_%s_%s_equal", self.currentHerdsmanPage, element.name)), option.texts[lowestState]))
            else
                tooltip:setText(string.format(getText(string.format("rl_ui_herdsmanTooltip_%s_%s_range", self.currentHerdsmanPage, element.name)), option.texts[lowestState], option.texts[highestState]))
            end

        elseif option.type == "input" then

            if option.inputType == "money" then
                tooltip:setText(string.format(getText(string.format("rl_ui_herdsmanTooltip_%s_%s", self.currentHerdsmanPage, element.name)), g_i18n:formatMoney(tonumber(element:getText()) or 0, 2, true, true)))
            elseif option.inputType == "number" then
                tooltip:setText(string.format(getText(string.format("rl_ui_herdsmanTooltip_%s_%s", self.currentHerdsmanPage, element.name)), g_i18n:formatNumber(tonumber(element:getText()) or 0)))
            end

        elseif option.type == "multi" then

            if (option.target == "breed" or option.target == "semen") and option.values[element:getState()] == "any" then
                
                tooltip:setText(getText(string.format("rl_ui_herdsmanTooltip_%s_%s_any", self.currentHerdsmanPage, option.target)))
                
            else

                tooltip:setText(string.format(getText(string.format("rl_ui_herdsmanTooltip_%s_%s", self.currentHerdsmanPage, element.name)), option.texts[element:getState()]))

            end

        else

            tooltip:setText(getText(string.format("rl_ui_herdsmanTooltip_%s_%s_%s", self.currentHerdsmanPage, element.name, element:getState())))

        end

    end


    self.herdsmanPages = {
        ["buy"] = self.herdsmanPageBuyScrollingLayout,
        ["sell"] = self.herdsmanPageSellScrollingLayout,
        ["castrate"] = self.herdsmanPageCastrateScrollingLayout,
        ["naming"] = self.herdsmanPageNamingScrollingLayout,
        ["ai"] = self.herdsmanPageAIScrollingLayout
    }


    for _, page in pairs(self.herdsmanPages) do

        for _, element in pairs(page.elements) do

            if element.name == "ignore" then continue end
            
            element.onFocusEnter = updateTooltip
            
            if self.herdsmanOptions[element.name].type == "input" then
                element.updateVisibleTextElements = Utils.appendedFunction(element.updateVisibleTextElements, updateTooltip)
                continue
            end

            element.updateContentElement = Utils.appendedFunction(element.updateContentElement, updateTooltip)

            if self.herdsmanOptions[element.name].ignoreTexts then continue end

            element:setTexts(self.herdsmanOptions[element.name].texts)

        end

    end


    local aiQuantityTexts = {}

    for _, quantity in pairs(AnimalScreen.DEWAR_QUANTITIES) do table.insert(aiQuantityTexts, string.format("%s %s", quantity, g_i18n:getText("rl_ui_straw" .. (quantity == 1 and "Single" or "Multiple")))) end

    self.aiQuantitySelector:setTexts(aiQuantityTexts)

end

AnimalScreen.onGuiSetupFinished = Utils.appendedFunction(AnimalScreen.onGuiSetupFinished, RealisticLivestock_AnimalScreen.onGuiSetupFinished)


function AnimalScreen:resetMessageButtonStates()

	self.messageButtonStates = {
		[self.messagesImportanceButton] = { ["sorter"] = false, ["target"] = "importance", ["pos"] = "-5px" },
		[self.messagesTypeButton] = { ["sorter"] = false, ["target"] = "title", ["pos"] = "50px" },
		[self.messagesAnimalButton] = { ["sorter"] = false, ["target"] = "animal", ["pos"] = "30px" },
		[self.messagesMessageButton] = { ["sorter"] = false, ["target"] = "text", ["pos"] = "20px" },
	}

	self.sortingIcon_true:setVisible(false)
	self.sortingIcon_false:setVisible(false)

end


function AnimalScreen:onClickMessageSortButton(button)
	
	local buttonState = self.messageButtonStates[button]

	self["sortingIcon_" .. tostring(buttonState.sorter)]:setVisible(false)
	self["sortingIcon_" .. tostring(not buttonState.sorter)]:setVisible(true)
	self["sortingIcon_" .. tostring(not buttonState.sorter)]:setPosition(button.position[1] + GuiUtils.getNormalizedXValue(buttonState.pos), 0)

	buttonState.sorter = not buttonState.sorter
	
	local sorter = buttonState.sorter
	local target = buttonState.target

	table.sort(self.messages[self.currentMessagePage], function(a, b)

        local aTarget = a[target] or RLMessage[a.id][target]
        local bTarget = b[target] or RLMessage[b.id][target]

		if sorter then return aTarget > bTarget end

		return aTarget < bTarget
	end)

	self.husbandryList:reloadData()

end


function AnimalScreen:updateLog()

    self:resetMessageButtonStates()

    self.messageListPageNumber:setText(string.format("%s/%s", self.currentMessagePage, #self.messages))

    local totalNumMessages = (#self.messages - 1) * 250 + #self.messages[#self.messages]

    self.messageListMessageNumber:setText(string.format(g_i18n:getText("rl_ui_messageNumber"), (#self.messages[self.currentMessagePage] == 0 and 0 or 1) + 250 * (self.currentMessagePage - 1), (self.currentMessagePage - 1) * 250 + #self.messages[self.currentMessagePage], totalNumMessages))

    self.messageListPageFirst:setDisabled(self.currentMessagePage == 1)
    self.messageListPagePrevious:setDisabled(self.currentMessagePage == 1)
    self.messageListPageNext:setDisabled(self.currentMessagePage == #self.messages)
    self.messageListPageLast:setDisabled(self.currentMessagePage == #self.messages)

    self.husbandryList:reloadData()

end


function AnimalScreen:onClickDeleteMessage()

    local index = self.husbandryList.selectedIndex

    local message = self.messages[self.currentMessagePage][index]

    if message == nil then return end

    self.husbandry:deleteRLMessage(message.uniqueId)

    local currentMessagePage = self.currentMessagePage

    self:onClickLogMode()

    if #self.messages >= currentMessagePage then

        self.currentMessagePage = currentMessagePage
        self:updateLog()

    end

end


function AnimalScreen:onClickMessagePageFirst()

    self.currentMessagePage = 1
    self:updateLog()

end


function AnimalScreen:onClickMessagePagePrevious()

    self.currentMessagePage = self.currentMessagePage - 1
    self:updateLog()

end


function AnimalScreen:onClickMessagePageNext()

    self.currentMessagePage = self.currentMessagePage + 1
    self:updateLog()

end


function AnimalScreen:onClickMessagePageLast()

    self.currentMessagePage = #self.messages
    self:updateLog()

end


function AnimalScreen:onClickAIMode()

    self.filters = nil
    self.filteredItems = nil
    self.isInfoMode = false
    self.isBuyMode = false
    self.isLogMode = false
    self.isHerdsmanMode = false
    self.isAIMode = true

    self.buttonBuySelected:setVisible(false)
    self.buttonToggleSelectAll:setVisible(false)
    self.buttonBuy:setVisible(false)
    self.buttonMonitor:setVisible(false)
    self.buttonArtificialInsemination:setVisible(false)
    self.buttonMark:setVisible(false)
    self.buttonRename:setVisible(false)
    self.buttonSelect:setVisible(false)
    self.buttonSell:setVisible(false)
    self.buttonFilters:setVisible(false)
    self.buttonDiseases:setVisible(false)
    self.buttonDeleteMessage:setVisible(false)
    self.buttonApplyHerdsmanSettings:setVisible(false)
    self.buttonCastrate:setVisible(false)
    self.buttonBuyAI:setVisible(true)
    self.buttonFavourite:setVisible(true)

    self.logContainer:setVisible(false)
    self.herdsmanContainer:setVisible(false)
    self.aiContainer:setVisible(true)
    self.sourceBoxBg:setVisible(false)
    self.mainContentContainer:setVisible(false)

    self.tabBuy:setSelected(false)
    self.tabSell:setSelected(false)
    self.tabInfo:setSelected(false)
    self.tabLog:setSelected(false)
    self.tabHerdsman:setSelected(false)
    self.tabAI:setSelected(true)

    self.buttonsPanel:invalidateLayout()

    self.aiAnimals = {}
    local animalSystem = g_currentMission.animalSystem
    local texts = {}

    for animalTypeIndex, animalType in pairs(animalSystem:getTypes()) do

        self.aiAnimals[animalTypeIndex] = animalSystem:getAIAnimalsByTypeIndex(animalTypeIndex)
        table.sort(self.aiAnimals[animalTypeIndex], function(a, b) return a.subTypeIndex == b.subTypeIndex and a.age > b.age or a.subTypeIndex < b.subTypeIndex end)
        table.insert(texts, animalType.groupTitle)

    end


    self.aiPageAnimalTypeSelector:setTexts(texts)
    self.aiPageAnimalTypeSelector:setState(1)


    self:onClickChangeAIAnimalType(1)

end


function AnimalScreen:onClickBuyAI()

    if self.aiAnimals == nil or self.aiAnimalTypeIndex == nil or self.aiAnimals[self.aiAnimalTypeIndex] == nil then return end

    local animal = self.aiAnimals[self.aiAnimalTypeIndex][self.aiList.selectedIndex]

    if animal == nil then return end

    local spawnPlaces, usedPlaces = g_currentMission.storeSpawnPlaces, g_currentMission.usedStorePlaces

    local x, y, z, place, width = PlacementUtil.getPlace(spawnPlaces, { ["width"] = 1, ["height"] = 2.5, ["length"] = 1, ["widthOffset"] = 0.5, ["lengthOffset"] = 0.5 }, usedPlaces, true, true, false, true)
	
    if x == nil then
		return
	end
	
    PlacementUtil.markPlaceUsed(usedPlaces, place, width)

    local farmId = g_localPlayer.farmId
    
    local quantity = AnimalScreen.DEWAR_QUANTITIES[self.aiQuantitySelector:getState()]
    local price = g_currentMission.animalSystem:getFarmSemenPrice(animal.birthday.country, animal.farmId) * quantity * Dewar.PRICE_PER_STRAW * animal.success * 2.25

    for _, value in pairs(animal.genetics) do price = price * value end

    local errorCode

    if not g_currentMission:getHasPlayerPermission("tradeAnimals") then
        errorCode = AnimalBuyEvent.BUY_ERROR_NO_PERMISSION
    elseif g_currentMission:getMoney(farmId) + price < 0 then
        errorCode = AnimalBuyEvent.BUY_ERROR_NOT_ENOUGH_MONEY
    else
        errorCode = AnimalBuyEvent.BUY_SUCCESS
        g_client:getServerConnection():sendEvent(SemenBuyEvent.new(animal, quantity, -price, farmId, { x, y, z }, { 0, 0, 0 }), true)
    end

    self:onSemenBought(errorCode)

end


function AnimalScreen:onSemenBought(errorCode)

    local dialogType = DialogElement.TYPE_INFO
    local text = "rl_ui_semenPurchase_successful"
	
    if errorCode == AnimalBuyEvent.BUY_ERROR_NOT_ENOUGH_MONEY then
        dialogType = DialogElement.TYPE_WARNING
        text = "rl_ui_semenPurchaseNoMoney"
    elseif errorCode == AnimalBuyEvent.BUY_ERROR_NO_PERMISSION then
        dialogType = DialogElement.TYPE_WARNING
        text = "rl_ui_semenPurchaseNoPermission"
    elseif errorCode ~= AnimalBuyEvent.BUY_SUCCESS then
        dialogType = DialogElement.TYPE_WARNING
        text = "rl_ui_semenPurchase_unsuccessful"
    end
	
    InfoDialog.show(g_i18n:getText(text), self.postSemenBought, self, dialogType, nil, nil, true)

end


function AnimalScreen:postSemenBought()

    self.aiList:reloadData()

end


function RealisticLivestock_AnimalScreen:onMoneyChange()

    if g_localPlayer == nil then return end

	local farm = g_farmManager:getFarmById(g_localPlayer.farmId)

	if farm.money <= -1 then
		self.aiCurrentBalanceText:applyProfile(ShopMenu.GUI_PROFILE.SHOP_MONEY_NEGATIVE, nil, true)
	else
		self.aiCurrentBalanceText:applyProfile(ShopMenu.GUI_PROFILE.SHOP_MONEY, nil, true)
	end

	self.aiCurrentBalanceText:setText(g_i18n:formatMoney(farm.money, 0, true, false))
	if self.aiShopMoneyBox ~= nil then
		self.aiShopMoneyBox:invalidateLayout()
		self.aiShopMoneyBoxBg:setSize(self.aiShopMoneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
	end

end

AnimalScreen.onMoneyChange = Utils.appendedFunction(AnimalScreen.onMoneyChange, RealisticLivestock_AnimalScreen.onMoneyChange)


function AnimalScreen:onClickChangeAIAnimalType(animalTypeIndex)

    self.aiAnimalTypeIndex = animalTypeIndex
    self.aiList:reloadData()
    self:onAIListSelectionChanged()

end


function AnimalScreen:onAIListSelectionChanged()

    self.aiInfoContainer:setVisible(false)
    self.buttonBuyAI:setDisabled(true)
    self.buttonFavourite:setDisabled(true)

    if self.aiAnimals == nil or self.aiAnimalTypeIndex == nil or self.aiAnimals[self.aiAnimalTypeIndex] == nil then return end
    
    local index = self.aiList.selectedIndex
    local animal = self.aiAnimals[self.aiAnimalTypeIndex][index]

    if animal == nil then return end

    self.buttonBuyAI:setDisabled(false)
    self.buttonFavourite:setDisabled(false)

    local uniqueUserId = g_localPlayer:getUniqueId()

    self.buttonFavourite:setText(g_i18n:getText("rl_ui_" .. (animal.favouritedBy[uniqueUserId] ~= nil and animal.favouritedBy[uniqueUserId] and "unFavourite" or "favourite")))

    self.aiInfoContainer:setVisible(true)

    self.aiSuccessValue:setText(string.format("%s%%", tostring(math.round(animal.success * 100))))

    for i = 1, #self.aiGeneticsTitle do
        self.aiGeneticsTitle[i]:setVisible(false)
        self.aiGeneticsValue[i]:setVisible(false)
    end

    local i = 1

    for key, value in pairs(animal.genetics) do

        self.aiGeneticsTitle[i]:setVisible(true)
        self.aiGeneticsValue[i]:setVisible(true)

        local text

        if value >= 1.65 then
            text = "extremelyHigh"
        elseif value >= 1.4 then
            text = "veryHigh"
        elseif value >= 1.1 then
            text = "high"
        elseif value >= 0.9 then
            text = "average"
        elseif value >= 0.7 then
            text = "low"
        elseif value >= 0.35 then
            text = "veryLow"
        else
            text = "extremelyLow"
        end

        self.aiGeneticsTitle[i]:setText(g_i18n:getText("rl_ui_" .. key))
        self.aiGeneticsValue[i]:setText(g_i18n:getText("rl_ui_genetics_" .. text))

        i = i + 1

    end

    self.aiQuantitySelector:setState(1)
    self:onClickChangeAIQuantity(1)

end


function AnimalScreen:onClickChangeAIQuantity(state)

    local animal = self.aiAnimals[self.aiAnimalTypeIndex][self.aiList.selectedIndex]

    local quantity = AnimalScreen.DEWAR_QUANTITIES[state]
    local price = g_currentMission.animalSystem:getFarmSemenPrice(animal.birthday.country, animal.farmId) * quantity * animal.success * 2.25

    for _, value in pairs(animal.genetics) do price = price * value end

    self.aiQuantityPrice:setText(g_i18n:formatMoney(price * Dewar.PRICE_PER_STRAW, 2, true, true))

end


function AnimalScreen:onClickFavouriteAnimal()

    local animal = self.aiAnimals[self.aiAnimalTypeIndex][self.aiList.selectedIndex]

    if animal == nil then return end

    local uniqueId = g_localPlayer:getUniqueId()

    if animal.favouritedBy[uniqueId] == nil then
        animal.favouritedBy[uniqueId] = true
    else
        animal.favouritedBy[uniqueId] = not animal.favouritedBy[uniqueId]
    end

    self.buttonFavourite:setText(g_i18n:getText("rl_ui_" .. (animal.favouritedBy[uniqueUserId] ~= nil and animal.favouritedBy[uniqueUserId] and "unFavourite" or "favourite")))

    self.aiList:reloadData()

end


function AnimalScreen:onClickLogMode()

    if self.husbandry == nil or not self.isDirectFarm then return end

    self.filters = nil
    self.filteredItems = nil
    self.isInfoMode = false
    self.isBuyMode = false
    self.isLogMode = true
    self.isHerdsmanMode = false
    self.isAIMode = false

    self.buttonBuySelected:setVisible(false)
    self.buttonToggleSelectAll:setVisible(false)
    self.buttonBuy:setVisible(false)
    self.buttonMonitor:setVisible(false)
    self.buttonArtificialInsemination:setVisible(false)
    self.buttonMark:setVisible(false)
    self.buttonRename:setVisible(false)
    self.buttonSelect:setVisible(false)
    self.buttonSell:setVisible(false)
    self.buttonFilters:setVisible(false)
    self.buttonDiseases:setVisible(false)
    self.buttonDeleteMessage:setVisible(true)
    self.buttonApplyHerdsmanSettings:setVisible(false)
    self.buttonCastrate:setVisible(false)
    self.buttonBuyAI:setVisible(false)
    self.buttonFavourite:setVisible(false)

    self.logContainer:setVisible(true)
    self.herdsmanContainer:setVisible(false)
    self.aiContainer:setVisible(false)
    self.sourceBoxBg:setVisible(false)
    self.mainContentContainer:setVisible(false)

    self.tabBuy:setSelected(false)
    self.tabSell:setSelected(false)
    self.tabInfo:setSelected(false)
    self.tabLog:setSelected(true)
    self.tabHerdsman:setSelected(false)
    self.tabAI:setSelected(false)

    local allMessages = self.husbandry:getRLMessages()
    local messages = { {} }

    for i = #allMessages, 1, -1 do

        local message = allMessages[i]

        if #messages[#messages] >= 250 then table.insert(messages, { }) end

        table.insert(messages[#messages], message)

    end

    self.messages, self.currentMessagePage = messages, 1

    self:updateLog()

    self.husbandry:setHasUnreadRLMessages(false)
    self.buttonsPanel:invalidateLayout()

end


function AnimalScreen:onClickHerdsmanMode()

    if self.husbandry == nil or not self.isDirectFarm then return end

    self.filters = nil
    self.filteredItems = nil
    self.isInfoMode = false
    self.isBuyMode = false
    self.isLogMode = false
    self.isHerdsmanMode = true
    self.isAIMode = false

    self.buttonBuySelected:setVisible(false)
    self.buttonToggleSelectAll:setVisible(false)
    self.buttonBuy:setVisible(false)
    self.buttonMonitor:setVisible(false)
    self.buttonArtificialInsemination:setVisible(false)
    self.buttonMark:setVisible(false)
    self.buttonRename:setVisible(false)
    self.buttonSelect:setVisible(false)
    self.buttonSell:setVisible(false)
    self.buttonFilters:setVisible(false)
    self.buttonDiseases:setVisible(false)
    self.buttonDeleteMessage:setVisible(false)
    self.buttonApplyHerdsmanSettings:setVisible(true)
    self.buttonCastrate:setVisible(false)
    self.buttonBuyAI:setVisible(false)
    self.buttonFavourite:setVisible(false)

    self.logContainer:setVisible(false)
    self.herdsmanContainer:setVisible(true)
    self.aiContainer:setVisible(false)
    self.sourceBoxBg:setVisible(false)
    self.mainContentContainer:setVisible(false)

    self.herdsmanLoadProfileButton:setDisabled(not ProfileDialog.getHasProfiles())

    self.tabBuy:setSelected(false)
    self.tabSell:setSelected(false)
    self.tabInfo:setSelected(false)
    self.tabLog:setSelected(false)
    self.tabHerdsman:setSelected(true)
    self.tabAI:setSelected(false)

    self.buttonsPanel:invalidateLayout()
    self.currentHerdsmanPage = nil

    local animalTypeIndex = self.husbandry:getAnimalTypeIndex()
    
    
    local ageValues = {}
    local ageTexts = {}

    if animalTypeIndex == AnimalType.COW then

        ageValues = { 6, 12, 18, 24, 30, 36, 48, 60, 72, 84, 96, 108, 120 }

    elseif animalTypeIndex == AnimalType.SHEEP then

        ageValues = { 3, 6, 9, 12, 18, 24, 30, 36, 48, 60, 72 }

    elseif animalTypeIndex == AnimalType.PIG then

        ageValues = { 3, 6, 9, 12, 18, 24, 30, 36, 48, 60, 72 }

    elseif animalTypeIndex == AnimalType.HORSE then

        ageValues = { 12, 24, 36, 48, 60, 90, 120, 150, 180, 240 }

    elseif animalTypeIndex == AnimalType.CHICKEN then

        ageValues = { 3, 6, 9, 12, 18, 24, 30, 36, 48, 60 }

    end

    table.insert(ageValues, 1, 0)

    for _, value in pairs(ageValues) do table.insert(ageTexts, RealisticLivestock.formatAge(value)) end

    table.insert(ageValues, 999)
    table.insert(ageTexts, g_i18n:getText("rl_ui_infinite"))

    self.herdsmanOptions["age"].values = ageValues
    self.herdsmanOptions["age"].texts = ageTexts


    local breeds = g_currentMission.animalSystem:getBreedsByAnimalTypeIndex(animalTypeIndex)
    local breedsValues, breedsTexts = { "any" }, { "any" }

    for breed, subTypes in pairs(breeds) do

        table.insert(breedsValues, breed)
        table.insert(breedsTexts, AnimalSystem.BREED_TO_NAME[breed] or breed)

    end

    self.herdsmanOptions["breed"].values = breedsValues
    self.herdsmanOptions["breed"].texts = breedsTexts

    local farmDewars = g_localPlayer ~= nil and g_dewarManager:getDewarsByFarm(g_localPlayer.farmId)
    local dewars, dewarTexts, dewarValues = nil, { "any" }, { "any" }

    if farmDewars ~= nil then

        dewars = farmDewars[animalTypeIndex]

        if dewars ~= nil then

            for _, dewar in pairs(dewars) do

                table.insert(dewarTexts, string.format("%s %s %s (%s %s)", RealisticLivestock.AREA_CODES[dewar.animal.country].code, dewar.animal.farmId, dewar.animal.uniqueId, dewar.straws, g_i18n:getText("rl_ui_straw" .. (dewar.straws == 1 and "Single" or "Multiple"))))
                table.insert(dewarValues, dewar:getUniqueId())

            end

        end

    end

    self.herdsmanAIDewars = dewars
    self.herdsmanOptions["semen"].values = dewarValues
    self.herdsmanOptions["semen"].texts = dewarTexts


    self:onClickHerdsmanPageBuy()

    local wage = self.husbandry:getAIManager().wage or 0
    self.herdsmanPreviousWageText:setText(g_i18n:formatMoney(wage, 2, true, true))

end


function AnimalScreen:onClickHerdsmanPageBuy()

    if self.currentHerdsmanPage == "buy" then return end

    self.herdsmanPageBuy:setVisible(true)
    self.herdsmanPageSell:setVisible(false)
    self.herdsmanPageCastrate:setVisible(false)
    self.herdsmanPageNaming:setVisible(false)
    self.herdsmanPageAI:setVisible(false)

    self.herdsmanPageBuyButtonBg:setSelected(true)
    self.herdsmanPageSellButtonBg:setSelected(false)
    self.herdsmanPageCastrateButtonBg:setSelected(false)
    self.herdsmanPageNamingButtonBg:setSelected(false)
    self.herdsmanPageAIButtonBg:setSelected(false)

    self.currentHerdsmanPage = "buy"
    self:setDefaultHerdsmanOptions()

end


function AnimalScreen:onClickHerdsmanPageSell()

    if self.currentHerdsmanPage == "sell" then return end

    self.herdsmanPageBuy:setVisible(false)
    self.herdsmanPageSell:setVisible(true)
    self.herdsmanPageCastrate:setVisible(false)
    self.herdsmanPageNaming:setVisible(false)
    self.herdsmanPageAI:setVisible(false)

    self.herdsmanPageBuyButtonBg:setSelected(false)
    self.herdsmanPageSellButtonBg:setSelected(true)
    self.herdsmanPageCastrateButtonBg:setSelected(false)
    self.herdsmanPageNamingButtonBg:setSelected(false)
    self.herdsmanPageAIButtonBg:setSelected(false)

    self.currentHerdsmanPage = "sell"
    self:setDefaultHerdsmanOptions()

end


function AnimalScreen:onClickHerdsmanPageCastrate()

    if self.currentHerdsmanPage == "castrate" then return end

    self.herdsmanPageBuy:setVisible(false)
    self.herdsmanPageSell:setVisible(false)
    self.herdsmanPageCastrate:setVisible(true)
    self.herdsmanPageNaming:setVisible(false)
    self.herdsmanPageAI:setVisible(false)

    self.herdsmanPageBuyButtonBg:setSelected(false)
    self.herdsmanPageSellButtonBg:setSelected(false)
    self.herdsmanPageCastrateButtonBg:setSelected(true)
    self.herdsmanPageNamingButtonBg:setSelected(false)
    self.herdsmanPageAIButtonBg:setSelected(false)

    self.currentHerdsmanPage = "castrate"
    self:setDefaultHerdsmanOptions()

end


function AnimalScreen:onClickHerdsmanPageNaming()

    if self.currentHerdsmanPage == "naming" then return end

    self.herdsmanPageBuy:setVisible(false)
    self.herdsmanPageSell:setVisible(false)
    self.herdsmanPageCastrate:setVisible(false)
    self.herdsmanPageNaming:setVisible(true)
    self.herdsmanPageAI:setVisible(false)

    self.herdsmanPageBuyButtonBg:setSelected(false)
    self.herdsmanPageSellButtonBg:setSelected(false)
    self.herdsmanPageCastrateButtonBg:setSelected(false)
    self.herdsmanPageNamingButtonBg:setSelected(true)
    self.herdsmanPageAIButtonBg:setSelected(false)

    self.currentHerdsmanPage = "naming"
    self:setDefaultHerdsmanOptions()

end


function AnimalScreen:onClickHerdsmanPageAI()

    if self.currentHerdsmanPage == "ai" then return end

    self.herdsmanPageBuy:setVisible(false)
    self.herdsmanPageSell:setVisible(false)
    self.herdsmanPageCastrate:setVisible(false)
    self.herdsmanPageNaming:setVisible(false)
    self.herdsmanPageAI:setVisible(true)

    self.herdsmanPageBuyButtonBg:setSelected(false)
    self.herdsmanPageSellButtonBg:setSelected(false)
    self.herdsmanPageCastrateButtonBg:setSelected(false)
    self.herdsmanPageNamingButtonBg:setSelected(false)
    self.herdsmanPageAIButtonBg:setSelected(true)

    self.currentHerdsmanPage = "ai"
    self:setDefaultHerdsmanOptions()

end


function AnimalScreen:onClickHerdsmanSaveProfile()

    ProfileDialog.show("save", self.husbandry:getAIManager(), self.onHerdsmanSaveProfileCallback, self)

end


function AnimalScreen:onClickHerdsmanLoadProfile()

    ProfileDialog.show("load", self.husbandry:getAIManager(), self.onHerdsmanLoadProfileCallback, self)

end


function AnimalScreen:onHerdsmanSaveProfileCallback()

    self.herdsmanLoadProfileButton:setDisabled(not ProfileDialog.getHasProfiles())

end


function AnimalScreen:onHerdsmanLoadProfileCallback()

    self.herdsmanLoadProfileButton:setDisabled(not ProfileDialog.getHasProfiles())
    self:setDefaultHerdsmanOptions()

end


function AnimalScreen:onClickEnableHerdsman(state, button)

    if self.currentHerdsmanPage == "castrate" and self.husbandry:getAnimalTypeIndex() == AnimalType.CHICKEN then
        button:setState(1)
        return
    end

    local option = self.herdsmanOptions.enabled

    local enabled = option.values[state]
    local page = self.herdsmanPages[self.currentHerdsmanPage]

    for _, element in pairs(page.elements) do
    
        element:setDisabled(not enabled and element.name ~= "enabled")

    end

end


function AnimalScreen:setDefaultHerdsmanOptions()

    local container = self.herdsmanPages[self.currentHerdsmanPage]

    local settings = table.clone(self.husbandry:getAIManager():getSettings(), 5)
    self.aiManagerSettings = settings

    for _, element in pairs(container.elements) do
    
        element:setDisabled(not settings[self.currentHerdsmanPage]["enabled"] and element.name ~= "enabled")

        if element.name == "ignore" then continue end

        local option = self.herdsmanOptions[element.name]
        local value

        if string.contains(option.target, "|") then
            
            local paths = string.split(option.target, "|")
            value = self.aiManagerSettings[self.currentHerdsmanPage][paths[1]]

            for i = 2, #paths do value = value[paths[i]] end

        else

            value = self.aiManagerSettings[self.currentHerdsmanPage][option.target]

        end

        if option.ignoreTexts then

            element:setTexts(option.texts)

        end

        if option.type == "doubleSlider" then

            for i, state in pairs(option.values) do

                if state == value.min then
                    element.leftState = i
                elseif state == value.max then
                    element.rightState = i
                end

            end

            element:updateSlider()
            element:updateFillingBar()
            element:updateContentElement()

        elseif option.type == "input" then

            element:setText(tostring(value))

        else

            for i, state in pairs(option.values) do
                if state == value then
                    element:setState(i)
                    break
                end
            end

        end

        if element.name == "budget|type" then self:onClickChangeHerdsmanBudgetType(element:getState(), element) end

    end

end


function AnimalScreen:onClickApplyHerdsmanSettings()

    if self.currentHerdsmanPage == nil then return end

    local settings = self.aiManagerSettings[self.currentHerdsmanPage]
    local page = self.herdsmanPages[self.currentHerdsmanPage]

    for _, element in pairs(page.elements) do

        if element.name == "ignore" then continue end

        local option = self.herdsmanOptions[element.name]

        if option.type == "binary" or option.type == "tripleOption" or option.type == "input" or option.type == "multi" then

            local value
            
            if option.type == "input" then
                value = tonumber(element:getText()) or 0
            else
                value = option.values[element:getState()]
            end

            if string.contains(option.target, "|") then

                local paths = string.split(option.target, "|")
                
                if #paths == 2 then
                    settings[paths[1]][paths[2]] = value
                elseif #paths == 3 then
                    settings[paths[1]][paths[2]][paths[3]] = value
                end

            else

                settings[option.target] = value

            end

        elseif option.type == "doubleSlider" then
            
            settings[option.target].min = option.values[element:getLowestState()]
            settings[option.target].max = option.values[element:getHighestState()]

        end

    end

    self.husbandry:getAIManager():setSettings(self.aiManagerSettings[self.currentHerdsmanPage], self.currentHerdsmanPage)

end


function AnimalScreen:onHerdsmanTextChangedInt(element, text)

    text = string.gsub(text, "[%a%p]", "")

    element:setText(text)

end


function AnimalScreen:onClickChangeHerdsmanBudgetType(state, button)

    local value = self.herdsmanOptions[button.name].values[state]

    for _, element in pairs(button.parent.elements) do

        if element.name == "budget|fixed" then element:setVisible(value == "fixed") end
        if element.name == "budget|percentage" then element:setVisible(value == "percentage") end

    end

    button.parent:invalidateLayout()

end


function AnimalScreen:onClickDiseases()

    local item = (self.filteredItems == nil and self.controller:getTargetItems() or self.filteredItems)[self.sourceList.selectedIndex]

    if item == nil or (item.cluster == nil and item.animal == nil) then return end

    local animal = item.animal or item.cluster

    DiseaseDialog.show(animal)

end


function RealisticLivestock_AnimalScreen:onClickBuyMode(a, b)

    self.isInfoMode = false
    self.isLogMode = false
    self.isHerdsmanMode = false
    self.isAIMode = false

    self.selectedItems = {}
    self.pendingBulkTransaction = nil
    self.filters = nil
    self.filteredItems = nil

    self.buttonToggleSelectAll:setVisible(true)
    self.buttonToggleSelectAll:setText(g_i18n:getText("rl_ui_selectAll"))
    self.buttonBuySelected:setText(self.isTrailerFarm and g_i18n:getText("rl_ui_moveSelected") or g_i18n:getText("rl_ui_buySelected"))
    self.buttonCastrate:setVisible(false)
    self.buttonDeleteMessage:setVisible(false)
    self.buttonDiseases:setVisible(false)
    self.buttonFilters:setVisible(true)
    self.buttonApplyHerdsmanSettings:setVisible(false)
    self.buttonBuyAI:setVisible(false)
    self.buttonFavourite:setVisible(false)

    self.logContainer:setVisible(false)
    self.herdsmanContainer:setVisible(false)
    self.aiContainer:setVisible(false)
    self.sourceBoxBg:setVisible(true)
    self.tabListContainer:setVisible(true)
    self.mainContentContainer:setVisible(true)

    self.buttonsPanel:invalidateLayout()

end

AnimalScreen.onClickBuyMode = Utils.prependedFunction(AnimalScreen.onClickBuyMode, RealisticLivestock_AnimalScreen.onClickBuyMode)


function RealisticLivestock_AnimalScreen:onClickSellMode(a, b)

    self.isInfoMode = false
    self.isLogMode = false
    self.isHerdsmanMode = false
    self.isAIMode = false

    self.selectedItems = {}
    self.pendingBulkTransaction = nil
    self.filters = nil
    self.filteredItems = nil

    self.buttonToggleSelectAll:setVisible(true)
    self.buttonToggleSelectAll:setText(g_i18n:getText("rl_ui_selectAll"))
    self.buttonBuySelected:setText(self.isTrailerFarm and g_i18n:getText("rl_ui_moveSelected") or g_i18n:getText("rl_ui_sellSelected"))
    self.buttonCastrate:setVisible(false)
    self.buttonDeleteMessage:setVisible(false)
    self.buttonDiseases:setVisible(false)
    self.buttonFilters:setVisible(true)
    self.buttonApplyHerdsmanSettings:setVisible(false)
    self.buttonBuyAI:setVisible(false)
    self.buttonFavourite:setVisible(false)

    self.logContainer:setVisible(false)
    self.herdsmanContainer:setVisible(false)
    self.aiContainer:setVisible(false)
    self.sourceBoxBg:setVisible(true)
    self.tabListContainer:setVisible(true)
    self.mainContentContainer:setVisible(true)

    self.buttonsPanel:invalidateLayout()

end

AnimalScreen.onClickSellMode = Utils.prependedFunction(AnimalScreen.onClickSellMode, RealisticLivestock_AnimalScreen.onClickSellMode)



function RealisticLivestock_AnimalScreen:onPageNext(superFunc)
    if self.isBuyMode then
        self:onClickSellMode()
    elseif not self.isInfoMode and not self.isLogMode and not self.isHerdsmanMode and not self.isAIMode then
        self:onClickInfoMode()
    elseif self.isInfoMode then
        self:onClickAIMode()
    elseif self.isAIMode then
        self:onClickLogMode()
    elseif self.isLogMode then
        self:onClickHerdsmanMode()
    else
        self:onClickBuyMode()
    end
end

AnimalScreen.onPageNext = Utils.overwrittenFunction(AnimalScreen.onPageNext, RealisticLivestock_AnimalScreen.onPageNext)


function RealisticLivestock_AnimalScreen:onPagePrevious(superFunc)
    if self.isBuyMode then
        self:onClickHerdsmanMode()
    elseif self.isHerdsmanMode then
        self:onClickLogMode()
    elseif self.isLogMode then
        self:onClickAIMode()
    elseif self.isAIMode then
        self:onClickInfoMode()
    elseif not self.isInfoMode then
        self:onClickBuyMode()
    else
        self:onClickSellMode()
    end
end

AnimalScreen.onPagePrevious = Utils.overwrittenFunction(AnimalScreen.onPagePrevious, RealisticLivestock_AnimalScreen.onPagePrevious)


function AnimalScreen:onClickMark()

    local item = (self.filteredItems == nil and self.controller:getTargetItems() or self.filteredItems)[self.sourceList.selectedIndex]

    if item == nil or (item.cluster == nil and item.animal == nil) then return end

    local animal = item.animal or item.cluster

    local isMarked = not animal:getMarked()

    if isMarked then
        animal:setMarked("PLAYER", true)
    else
        animal:setMarked(nil, false)
    end

    self.sourceList:reloadData()

end


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

            if text ~= nil or animal.name ~= nil then

                if text == nil then
                    animal:addMessage("NAME_DELETED", { animal.name })
                elseif animal.name == nil then
                    animal:addMessage("NAME_ADDED", { text })
                elseif animal.name ~= text then
                    animal:addMessage("NAME_CHANGE", { animal.name, text })
                end

            end

            animal.name = text
            animal:updateVisualRightEarTag()

            AnimalNameChangeEvent.sendEvent(animal.clusterSystem.owner, animal, text)

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

    AnimalInfoDialog.show(farmId, uniqueId, nil, animalType, animal:getIdentifiers())

end

AnimalScreen.onClickAnimalInfo = RealisticLivestock_AnimalScreen.onClickAnimalInfo


function RealisticLivestock_AnimalScreen:onClickInfoMode(a, b)

    self.filters = nil
    self.filteredItems = nil
    self.isInfoMode = true
    self.isBuyMode = false
    self.isLogMode = false
    self.isHerdsmanMode = false
    self.isAIMode = false

    self.buttonToggleSelectAll:setVisible(false)
    self.buttonDeleteMessage:setVisible(false)
    self.buttonFilters:setVisible(true)
    self.buttonDiseases:setVisible(true)
    self.buttonBuyAI:setVisible(false)
    self.buttonFavourite:setVisible(false)
    self.buttonApplyHerdsmanSettings:setVisible(false)
    self.targetSelector.leftButtonElement:setVisible(false)
    self.targetSelector.rightButtonElement:setVisible(false)
    self:initSubcategories()

    self.sourceList:setSelectedItem(1, 1, nil, true)
    self.sourceSelector:setState(1, true)
    self.isAutoUpdatingList = a
    self:updateScreen()
    self.isAutoUpdatingList = false
    self:setSelectionState(AnimalScreen.SELECTION_SOURCE, true)

    self.logContainer:setVisible(false)
    self.herdsmanContainer:setVisible(false)
    self.aiContainer:setVisible(false)
    self.sourceBoxBg:setVisible(true)
    self.tabListContainer:setVisible(true)
    self.mainContentContainer:setVisible(true)

    self.buttonsPanel:invalidateLayout()

end

AnimalScreen.onClickInfoMode = RealisticLivestock_AnimalScreen.onClickInfoMode


function AnimalScreen:onClickArtificialInsemination()

    local item = (self.filteredItems == nil and self.controller:getTargetItems() or self.filteredItems)[self.sourceList.selectedIndex]

    if item == nil or g_localPlayer == nil then return end

    local animal = item.animal or item.cluster

    if animal == nil then return end

    AnimalAIDialog.show(g_localPlayer.farmId, animal.animalTypeIndex, animal)

end


function AnimalScreen:onClickMonitor()

    local item = (self.filteredItems == nil and self.controller:getTargetItems() or self.filteredItems)[self.sourceList.selectedIndex]

    if item == nil then return end

    local animal = item.animal or item.cluster

    if animal == nil then return end

    local monitor = animal.monitor

    monitor.active = not monitor.active
    monitor.removed = not monitor.active
    animal:updateVisualMonitor()

    AnimalMonitorEvent.sendEvent(animal.clusterSystem.owner, animal, monitor.active, monitor.removed)

    self.buttonMonitor:setText(g_i18n:getText("rl_ui_" .. (monitor.active and "remove" or "apply") .. "Monitor"))
    self.buttonMonitor:setDisabled(monitor.removed)

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


function RealisticLivestock_AnimalScreen:onListSelectionChanged(superFunc, list)

    if list == self.sourceList or list == self.targetList then
        superFunc(self, list)
    else
        self:onAIListSelectionChanged()
    end

end

AnimalScreen.onListSelectionChanged = Utils.overwrittenFunction(AnimalScreen.onListSelectionChanged, RealisticLivestock_AnimalScreen.onListSelectionChanged)


function RealisticLivestock_AnimalScreen:updateInfoBox(superFunc, isSourceSelected)

    if not g_gui.currentlyReloading then

        --if isSourceSelected == nil then
            --local _ = self.isSourceSelected
        --end

        local animalType = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
        local item
        self.buttonCastrate:setVisible(false)
        self.buttonMark:setVisible(false)

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

            self.diseasesBox:setVisible(not self.isInfoMode)

            if not self.isInfoMode then

                local diseases = animal.diseases

                for i = 1, #self.diseasesTitle do
                    self.diseasesTitle[i]:setVisible(false)
                    self.diseasesValue[i]:setVisible(false)
                end

                for i, disease in pairs(diseases) do

                    self.diseasesTitle[i]:setVisible(true)
                    self.diseasesValue[i]:setVisible(true)

                    self.diseasesTitle[i]:setText(disease.type.name)
                    self.diseasesValue[i]:setText(disease:getStatus())

                end

            end

            self.geneticsBox:applyProfile(self.isInfoMode and "rl_geneticsBoxInfo" or "rl_geneticsBox")
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

                local isMarked = animal:getMarked()
                self.buttonMark:setVisible(true)
                self.buttonMark:setText(isMarked and g_i18n:getText("rl_ui_unmark") or g_i18n:getText("rl_ui_mark"))

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
    self.buttonsPanel:invalidateLayout()

end

AnimalScreen.updateInfoBox = Utils.overwrittenFunction(AnimalScreen.updateInfoBox, RealisticLivestock_AnimalScreen.updateInfoBox)


function RealisticLivestock_AnimalScreen:updateScreen(superFunc, state)


    self.isAutoUpdatingList = true
    self.sourceList:reloadData(true)
    self.isAutoUpdatingList = false

    local placeables, targetText

    if self.isBuyMode then
        placeables, targetText = self.controller:getSourceData(self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()])
    else
        placeables, targetText = self.controller:getTargetData(self.sourceSelector:getState())
    end

    self.targetText:setText(targetText)
    self.targetItems = placeables
    local husbandryTexts = {}

    for _, placeable in pairs(placeables) do
        local animalType = g_currentMission.animalSystem:getTypeByIndex(self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()])
        local maxAnimalString = " (" .. placeable:getNumOfAnimals() .. "/" .. placeable:getMaxNumOfAnimals(animalType) .. ")"
        local husbandryString = placeable:getName() .. maxAnimalString
        table.insert(husbandryTexts, husbandryString)
    end


    self.targetSelector:setTexts(husbandryTexts)

    if #placeables > 0 and (not state or self.targetSelector:getState() == 0) then
        self.targetSelector:setState(1)
    end

    self:onTargetSelectionChanged(true)
    self:setSelectionState(AnimalScreen.SELECTION_SOURCE)

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
    self.buttonArtificialInsemination:setVisible(self.isInfoMode)

    if hasAnimals then
        self:updatePrice()
        self:updateInfoBox()
    end

    self.tabBuy:setSelected(self.isBuyMode and not self.isInfoMode)
    self.tabSell:setSelected(not self.isBuyMode and not self.isInfoMode and not self.isLogMode and not self.isHerdsmanMode)
    self.tabInfo:setSelected(not self.isBuyMode and self.isInfoMode)
    self.tabLog:setSelected(self.isLogMode)
    self.tabHerdsman:setSelected(self.isHerdsmanMode)
    self.tabAI:setSelected(self.isAIMode)

    self.buttonBuySelected:setVisible(not self.isTrailer and not self.isInfoMode)

    self.buttonsPanel:invalidateLayout()

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

    if list == self.aiList then

        local animals = self.aiAnimals[self.aiAnimalTypeIndex]

        local a = animals[index]
	    local b = animals[index - 1]

	    return (a == nil or b == nil or a:getSubTypeIndex() ~= b:getSubTypeIndex()) and "sectionCell" or "defaultCell"

    end

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

    if list == self.aiList then return #self.aiAnimals[self.aiAnimalTypeIndex] end

    if self.isLogMode then return #self.messages[self.currentMessagePage] end

    if self.filteredItems == nil or not self.isOpen then return superFunc(self, list) end

    return #self.filteredItems

end

AnimalScreen.getNumberOfItemsInSection = Utils.overwrittenFunction(AnimalScreen.getNumberOfItemsInSection, RealisticLivestock_AnimalScreen.getNumberOfItemsInSection)


function RealisticLivestock_AnimalScreen:populateCellForItemInSection(_, list, _, index, cell)

    if list == self.aiList then

        local animal = self.aiAnimals[self.aiAnimalTypeIndex][index]

        if animal == nil then return end

        local subType = animal:getSubType()

        if cell.name == "sectionCell" then cell:getAttribute("title"):setText(g_fillTypeManager:getFillTypeTitleByIndex(subType.fillTypeIndex)) end

        local name = animal:getName()

        if name == nil or name == "" then name = string.format("%s %s %s", RealisticLivestock.AREA_CODES[animal.birthday.country].code, animal.farmId, animal.uniqueId) end

        local visual = g_currentMission.animalSystem:getVisualByAge(animal.subTypeIndex, animal.age)

        cell:getAttribute("name"):setText(name)
        cell:getAttribute("icon"):setImageFilename(visual.store.imageFilename)

        local genetics = 0
        local numGenetics = 0

        for _, value in pairs(animal.genetics) do
            genetics = genetics + value
            numGenetics = numGenetics + 1
        end

        local avgGenetics = (numGenetics > 0 and genetics / numGenetics) or 0
        local geneticsText = "extremelyBad"

        if avgGenetics >= 1.65 then
            geneticsText = "extremelyGood"
        elseif avgGenetics >= 1.35 then
            geneticsText = "veryGood"
        elseif avgGenetics >= 1.15 then
            geneticsText = "good"
        elseif avgGenetics >= 0.85 then
            geneticsText = "average"
        elseif avgGenetics >= 0.65 then
            geneticsText = "bad"
        elseif avgGenetics >= 0.35 then
            geneticsText = "veryBad"
        end

        cell:getAttribute("price"):setText(g_i18n:getText("rl_ui_genetics_" .. geneticsText))

        local uniqueUserId = g_localPlayer:getUniqueId()
        local isFavourite = animal.favouritedBy[uniqueUserId] ~= nil and animal.favouritedBy[uniqueUserId]

        if cell.name == "defaultCell" then

            if isFavourite then
                cell:setImageColor(GuiOverlay.STATE_NORMAL, 1, 0.2, 0)
            else
                cell:setImageColor(GuiOverlay.STATE_NORMAL, 1, 1, 1)
            end

        else

            local background = cell:getAttribute("background")

            if isFavourite then
                background:setImageColor(GuiOverlay.STATE_NORMAL, 1, 0.2, 0)
            else
                background:setImageColor(GuiOverlay.STATE_NORMAL, 1, 1, 1)
            end

        end

        return

    end

    if list == self.husbandryList then

        local messagePage = self.messages[self.currentMessagePage]

        if messagePage == nil then return end

        local message = messagePage[index]

        if message == nil then return end

        local baseMessage = RLMessage[message.id]

        local text, argI = string.split(g_i18n:getText("rl_message_" .. baseMessage.text), " "), 1

        for i, split in pairs(text) do
        
            if split == "%s" then

                if string.contains(message.args[argI], "rl_") then
                    text[i] = g_i18n:getText(message.args[argI])
                else
                    text[i] = message.args[argI]
                end

                argI = argI + 1

            elseif split == "'%s'" then

                if string.contains(message.args[argI], "rl_") then
                    text[i] = "'" .. g_i18n:getText(message.args[argI]) .. "'"
                else
                    text[i] = "'" .. message.args[argI] .. "'"
                end

                argI = argI + 1

            end
        
        end

        text = table.concat(text, " ")


        cell:getAttribute("message"):setText(text)
        cell:getAttribute("type"):setText(g_i18n:getText("rl_messageTitle_" .. baseMessage.title))
        cell:getAttribute("date"):setText(message.date)
        cell:getAttribute("animal"):setText(message.animal or "N/A")
        cell:getAttribute("importance"):setImageSlice(nil, "realistic_livestock.importance_" .. baseMessage.importance)

        return

    end

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

        local isMarked = animal:getMarked()
        local recentlyBoughtByAI = animal:getRecentlyBoughtByAI()

        if cell.name == "defaultCell" then

            if isMarked then
                cell:setImageColor(GuiOverlay.STATE_NORMAL, 1, 0.2, 0)
            else
                cell:setImageColor(GuiOverlay.STATE_NORMAL, 1, 1, 1)
            end

        else

            local background = cell:getAttribute("background")

            if isMarked then
                background:setImageColor(GuiOverlay.STATE_NORMAL, 1, 0.2, 0)
            else
                background:setImageColor(GuiOverlay.STATE_NORMAL, 1, 1, 1)
            end

        end

        if animal:getName() == "" and not self.isHorse and (not self.isBuyMode or (self.controller.trailer ~= nil and self.controller.husbandry ~= nil and self.isBuyMode)) and animal.uniqueId ~= nil then name = string.format("%s %s %s", RealisticLivestock.AREA_CODES[animal.birthday.country].code, animal.farmId, animal.uniqueId) end

        cell:getAttribute("name"):setText(name)

        cell:getAttribute("icon"):setImageFilename(item:getFilename())
        cell:getAttribute("price"):setValue(item:getPrice())
        local descriptor = cell:getAttribute("herdsmanPurchase")
        descriptor:setVisible(recentlyBoughtByAI or isMarked)

        if recentlyBoughtByAI then

            descriptor:setText(g_i18n:getText("rl_ui_herdsmanRecentlyBought"))
        
        elseif isMarked then

            local markText = RealisticLivestock.MARKS[animal:getHighestPriorityMark()].text

            descriptor:setText(g_i18n:getText("rl_mark_" .. markText))

        end

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

    local animalTypeIndex = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]

    AnimalFilterDialog.show(self.isBuyMode and self.controller:getSourceItems(animalTypeIndex, self.isBuyMode) or self.controller:getTargetItems(), animalTypeIndex, self.onApplyFilters, self, self.isBuyMode)

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