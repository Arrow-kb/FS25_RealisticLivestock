RealisticLivestockFrame = {}

local realisticLivestockFrame_mt = Class(RealisticLivestockFrame, TabbedMenuFrameElement)


function RealisticLivestockFrame.new()

	local self = RealisticLivestockFrame:superClass().new(nil, realisticLivestockFrame_mt)
	
	self.name = "RealisticLivestockFrame"
	self.husbandrySystem = g_currentMission.husbandrySystem

	return self

end


function RealisticLivestockFrame:delete()
	RealisticLivestockFrame:superClass().delete(self)
end


function RealisticLivestockFrame:initialize()

	self.backButtonInfo = {
		["inputAction"] = InputAction.MENU_BACK
	}

	self.nextPageButtonInfo = {
		["inputAction"] = InputAction.MENU_PAGE_NEXT,
		["text"] = g_i18n:getText("ui_ingameMenuNext"),
		["callback"] = self.onPageNext
	}

	self.prevPageButtonInfo = {
		["inputAction"] = InputAction.MENU_PAGE_PREV,
		["text"] = g_i18n:getText("ui_ingameMenuPrev"),
		["callback"] = self.onPagePrevious
	}

	self.changeMonitorsButtonInfo = {
		["inputAction"] = InputAction.MENU_ACTIVATE,
		["text"] = g_i18n:getText("rl_ui_applyAllMonitor"),
		["callback"] = function()
			self:onClickChangeMonitors()
		end,
		["profile"] = "buttonSelect"
	}
	
end


function RealisticLivestockFrame:onGuiSetupFinished()
	RealisticLivestockFrame:superClass().onGuiSetupFinished(self)
end


function RealisticLivestockFrame:onFrameOpen()
	RealisticLivestockFrame:superClass().onFrameOpen(self)
	self:updateContent()
	self:resetButtonStates()
	self:updateMenuButtons()
	self.husbandryList:reloadData()
end


function RealisticLivestockFrame:onFrameClose()
	RealisticLivestockFrame:superClass().onFrameClose(self)
end


function RealisticLivestockFrame:updateContent()

	self.currentBalanceText:setText(g_i18n:formatMoney(g_currentMission:getMoney(), 2, true, true))

	self.data = {}
	self.selectedRow = nil

	if g_localPlayer == nil then return end

	local placeables = self.husbandrySystem:getPlaceablesByFarm()
	
	for _, placeable in pairs(placeables) do

		local animals = placeable:getClusters()
		local numMonitored = 0
		local animalTypeIndex = placeable:getAnimalTypeIndex()
		local farmland = placeable:getFarmlandId()
		local numAnimals = #animals

		local data = {
			["placeable"] = placeable,
			["name"] = placeable:getName(),
			["totalAnimals"] = numAnimals,
			["farmland"] = farmland,
			["animalTypeIndex"] = animalTypeIndex,
			["fee"] = 0,
			["food"] = 0,
			["water"] = 0,
			["straw"] = 0,
			["product"] = 0,
			["manure"] = 0,
			["liquidManure"] = 0
		}

		for _, animal in pairs(animals) do

			if not animal.monitor.active and not animal.monitor.removed then continue end

			numMonitored = numMonitored + 1

			for fillType, amount in pairs(animal.input) do

				data[fillType] = data[fillType] + amount

			end

			for fillType, amount in pairs(animal.output) do

				local target = (fillType == "pallets" or fillType == "milk") and "product" or fillType

				data[target] = data[target] + amount

			end

			data.fee = data.fee + animal.monitor.fee

		end

		data.totalMonitored = numMonitored
		data.percentMonitored = numAnimals == 0 and 0 or (numMonitored / numAnimals)

		table.insert(self.data, data)

	end

end


function RealisticLivestockFrame:updateMenuButtons()

	self.menuButtonInfo = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }

	if self.data ~= nil and self.selectedRow ~= nil then

		self.changeMonitorsButtonInfo.disabled = self.selectedRow.totalAnimals == 0
		self.changeMonitorsButtonInfo.text = g_i18n:getText("rl_ui_" .. (self.selectedRow.percentMonitored == 1 and "remove" or "apply") .. "AllMonitor")
		
		table.insert(self.menuButtonInfo, self.changeMonitorsButtonInfo)

	end
	
	self:setMenuButtonInfoDirty()

end


function RealisticLivestockFrame:resetButtonStates()

	self.buttonStates = {
		[self.nameButton] = { ["sorter"] = false, ["target"] = "name", ["pos"] = "-5px" },
		[self.farmlandButton] = { ["sorter"] = false, ["target"] = "farmland", ["pos"] = "12px" },
		[self.animalTypeButton] = { ["sorter"] = false, ["target"] = "animalTypeIndex", ["pos"] = "35px" },
		[self.percentMonitoredButton] = { ["sorter"] = false, ["target"] = "percentMonitored", ["pos"] = "12px" },
		[self.feeButton] = { ["sorter"] = false, ["target"] = "fee", ["pos"] = "12px" },
		[self.foodButton] = { ["sorter"] = false, ["target"] = "food", ["pos"] = "22px" },
		[self.waterButton] = { ["sorter"] = false, ["target"] = "water", ["pos"] = "36px" },
		[self.strawButton] = { ["sorter"] = false, ["target"] = "straw", ["pos"] = "36px" },
		[self.productionButton] = { ["sorter"] = false, ["target"] = "product", ["pos"] = "10px" },
		[self.manureButton] = { ["sorter"] = false, ["target"] = "manure", ["pos"] = "20px" },
		[self.liquidManureButton] = { ["sorter"] = false, ["target"] = "liquidManure", ["pos"] = "20px" }
	}

	self.sortingIcon_true:setVisible(false)
	self.sortingIcon_false:setVisible(false)

end


function RealisticLivestockFrame:getNumberOfSections()

	if self.data == nil or #self.data == 0 then return 0 end

	return 1

end


function RealisticLivestockFrame:getNumberOfItemsInSection(list, section)

	return self.data == nil and 0 or #self.data

end


function RealisticLivestockFrame:getTitleForSectionHeader(list, section)

    return ""

end


function RealisticLivestockFrame:populateCellForItemInSection(list, section, index, cell)

	local item = self.data[index]

	cell:getAttribute("name"):setText(item.name)
	cell:getAttribute("farmland"):setText(item.farmland)

	local animalType

	for animalName, animalIndex in pairs(AnimalType) do

		if animalIndex == item.animalTypeIndex then
			animalType = animalName:lower()
			break
		end

	end

	if animalType ~= nil then animalType = string.sub(animalType, 1, 1):upper() .. string.sub(animalType, 2) end

	cell:getAttribute("animalType"):setText(animalType)
	cell:getAttribute("percentMonitored"):setText(string.format("%s / %s", item.totalMonitored, item.totalAnimals))
	cell:getAttribute("fee"):setText(string.format(g_i18n:getText("rl_ui_feePerMonth"), g_i18n:formatMoney(item.fee, 2, true, true)))

	local daysPerMonth = g_currentMission.environment.daysPerPeriod
	
	cell:getAttribute("food"):setText(string.format(g_i18n:getText("rl_ui_amountPerDay"), (item.food * 24) / daysPerMonth))
	cell:getAttribute("water"):setText(string.format(g_i18n:getText("rl_ui_amountPerDay"), (item.water * 24) / daysPerMonth))
	cell:getAttribute("straw"):setText(string.format(g_i18n:getText("rl_ui_amountPerDay"), (item.straw * 24) / daysPerMonth))
	
	cell:getAttribute("product"):setText(string.format(g_i18n:getText("rl_ui_amountPerDay"), (item.product * 24) / daysPerMonth))
	cell:getAttribute("manure"):setText(string.format(g_i18n:getText("rl_ui_amountPerDay"), (item.manure * 24) / daysPerMonth))
	cell:getAttribute("liquidManure"):setText(string.format(g_i18n:getText("rl_ui_amountPerDay"), (item.liquidManure * 24) / daysPerMonth))
	
	cell.setSelected = Utils.appendedFunction(cell.setSelected, function(cell, selected)
		if selected then self:onClickListItem(cell) end
	end)

end


function RealisticLivestockFrame:onClickSortButton(button)
	
	local buttonState = self.buttonStates[button]

	self["sortingIcon_" .. tostring(buttonState.sorter)]:setVisible(false)
	self["sortingIcon_" .. tostring(not buttonState.sorter)]:setVisible(true)
	self["sortingIcon_" .. tostring(not buttonState.sorter)]:setPosition(button.position[1] + GuiUtils.getNormalizedXValue(buttonState.pos), 0)

	buttonState.sorter = not buttonState.sorter
	
	local sorter = buttonState.sorter
	local target = buttonState.target

	table.sort(self.data, function(a, b)
		if sorter then return a[target] > b[target] end

		return a[target] < b[target]
	end)

	self.husbandryList:reloadData()

end


function RealisticLivestockFrame:onClickListItem(item)

	self.selectedRow = nil

	local index = item.indexInSection

	if self.data == nil or self.data[index] == nil then
		self:updateMenuButtons()
		return
	end

	self.selectedRow = self.data[index]

	self:updateMenuButtons()

end


function RealisticLivestockFrame:onClickChangeMonitors()

	local selectedRow = self.selectedRow

	if selectedRow == nil then return end

	local animals = selectedRow.placeable:getClusters()

	if selectedRow.percentMonitored == 1 then

		for _, animal in pairs(animals) do

			animal.monitor.active = false
			animal.monitor.removed = true

			AnimalMonitorEvent.sendEvent(selectedRow.placeable, animal, false, true)

		end

	else

		for _, animal in pairs(animals) do

			animal.monitor.active = true
			animal.monitor.removed = false

			AnimalMonitorEvent.sendEvent(selectedRow.placeable, animal, true, false)

		end

	end

	selectedRow.food, selectedRow.water, selectedRow.straw, selectedRow.product, selectedRow.manure, selectedRow.liquidManure, selectedRow.fee, selectedRow.totalMonitored = 0, 0, 0, 0, 0, 0, 0, 0

	for _, animal in pairs(animals) do

		if not animal.monitor.active and not animal.monitor.removed then continue end

		selectedRow.totalMonitored = selectedRow.totalMonitored + 1

		for fillType, amount in pairs(animal.input) do

			selectedRow[fillType] = selectedRow[fillType] + amount

		end

		for fillType, amount in pairs(animal.output) do

			local target = (fillType == "pallets" or fillType == "milk") and "product" or fillType

			selectedRow[target] = selectedRow[target] + amount

		end

		selectedRow.fee = selectedRow.fee + animal.monitor.fee

	end

	selectedRow.percentMonitored = selectedRow.totalAnimals == 0 and 0 or (selectedRow.totalMonitored / selectedRow.totalAnimals)

	self.husbandryList:reloadData()
	self:updateMenuButtons()

end