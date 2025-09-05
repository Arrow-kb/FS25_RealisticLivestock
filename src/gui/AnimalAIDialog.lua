AnimalAIDialog = {}

local AnimalAIDialog_mt = Class(AnimalAIDialog, MessageDialog)
local modDirectory = g_currentModDirectory

function AnimalAIDialog.register()
    local dialog = AnimalAIDialog.new()
    g_gui:loadGui(modDirectory .. "gui/AnimalAIDialog.xml", "AnimalAIDialog", dialog)
    AnimalAIDialog.INSTANCE = dialog
end


function AnimalAIDialog.new(target, customMt)
    local dialog = MessageDialog.new(target, customMt or AnimalAIDialog_mt)
    dialog.children = {}
    return dialog
end


function AnimalAIDialog.createFromExistingGui(gui)

    AnimalAIDialog.register()
    AnimalAIDialog.show()

end


function AnimalAIDialog.show(farmId, animalTypeIndex, animal)

    if AnimalAIDialog.INSTANCE == nil then AnimalAIDialog.register() end

    local dialog = AnimalAIDialog.INSTANCE

    dialog.farmId, dialog.animalTypeIndex, dialog.animal = farmId, animalTypeIndex, animal

    dialog:updateDewars()

    g_gui:showDialog("AnimalAIDialog")

end


function AnimalAIDialog:onCreate()
    AnimalAIDialog:superClass().onCreate(self)
    self:setDialogType(DialogElement.Type_INFO)
end


function AnimalAIDialog:onClickOk()

    local farmDewars = g_dewarManager:getDewarsByFarm(self.farmId)
    local selectedDewar = self.dewars[self.dewarList.selectedIndex]
    
    if farmDewars == nil or farmDewars[self.animalTypeIndex] == nil or selectedDewar == nil then return end

    local uniqueId = selectedDewar:getUniqueId()

    for _, dewar in pairs(farmDewars[self.animalTypeIndex]) do

        if dewar:getUniqueId() == uniqueId then

            dewar:changeStraws(-1)
            self.animal:setInsemination(dewar.animal)
            break

        end

    end

    self:updateDewars()

end


function AnimalAIDialog:onClickBack()

    self:close()

end


function AnimalAIDialog:updateDewars()

    local farmDewars = g_dewarManager:getDewarsByFarm(self.farmId)
    self.dewars = farmDewars and table.clone(farmDewars[self.animalTypeIndex], 5) or {}

    self:resetButtonStates()
    self.dewarList:reloadData()

end


function AnimalAIDialog:onListSelectionChanged(list, index)

    local dewar = self.dewars[index]

    if dewar == nil then return end

    self.okButton:setDisabled(not self.animal:getCanBeInseminatedByAnimal(dewar.animal))

end


function AnimalAIDialog:getNumberOfSections()

	if self.dewars == nil or #self.dewars == 0 then return 0 end

	return 1

end


function AnimalAIDialog:getNumberOfItemsInSection(list, section)

	return self.dewars == nil and 0 or #self.dewars

end


function AnimalAIDialog:getTitleForSectionHeader(list, section)

    return ""

end


function AnimalAIDialog:populateCellForItemInSection(list, section, index, cell)

	local dewar = self.dewars[index]

    if dewar == nil or dewar.animal == nil then return end

    local animal = dewar.animal
    local subType = g_currentMission.animalSystem:getSubTypeByIndex(animal.subTypeIndex)

    cell:getAttribute("name"):setText(animal.name)
    cell:getAttribute("identifier"):setText(string.format("%s %s %s", RealisticLivestock.AREA_CODES[animal.country].code, animal.farmId, animal.uniqueId))
    cell:getAttribute("subType"):setText(g_fillTypeManager:getFillTypeTitleByIndex(subType.fillTypeIndex))
    cell:getAttribute("straws"):setText(dewar.straws)
    cell:getAttribute("success"):setText(string.format("%s%%", tostring(math.round(animal.success * 100))))

    cell:getAttribute("productivity"):setText("N/A")

    for type, value in pairs(animal.genetics) do

		local valueText

		if value >= 1.65 then
            valueText = "extremelyHigh"
        elseif value >= 1.4 then
            valueText = "veryHigh"
        elseif value >= 1.1 then
            valueText = "high"
        elseif value >= 0.9 then
            valueText = "average"
        elseif value >= 0.7 then
            valueText = "low"
        elseif value >= 0.35 then
            valueText = "veryLow"
        else
            valueText = "extremelyLow"
        end

        cell:getAttribute(type):setText(g_i18n:getText("rl_ui_genetics_" .. valueText))

	end

end


function AnimalAIDialog:resetButtonStates()

	self.buttonStates = {
		[self.nameButton] = { ["sorter"] = false, ["target"] = "animal|name", ["pos"] = "-5px" },
		[self.identifierButton] = { ["sorter"] = false, ["target"] = "identifier", ["pos"] = "12px" },
		[self.subTypeButton] = { ["sorter"] = false, ["target"] = "animal|subTypeIndex", ["pos"] = "35px" },
		[self.strawsButton] = { ["sorter"] = false, ["target"] = "straws", ["pos"] = "12px" },
		[self.successButton] = { ["sorter"] = false, ["target"] = "animal|success", ["pos"] = "12px" },
		[self.metabolismButton] = { ["sorter"] = false, ["target"] = "animal|genetics|metabolism", ["pos"] = "22px" },
		[self.qualityButton] = { ["sorter"] = false, ["target"] = "animal|genetics|quality", ["pos"] = "36px" },
		[self.healthButton] = { ["sorter"] = false, ["target"] = "animal|genetics|health", ["pos"] = "36px" },
		[self.fertilityButton] = { ["sorter"] = false, ["target"] = "animal|genetics|fertility", ["pos"] = "10px" },
		[self.productivityButton] = { ["sorter"] = false, ["target"] = "animal|genetics|productivity", ["pos"] = "20px" }
	}

	self.sortingIcon_true:setVisible(false)
	self.sortingIcon_false:setVisible(false)

end


function AnimalAIDialog:onClickSortButton(button)
	
	local buttonState = self.buttonStates[button]

	self["sortingIcon_" .. tostring(buttonState.sorter)]:setVisible(false)
	self["sortingIcon_" .. tostring(not buttonState.sorter)]:setVisible(true)
	self["sortingIcon_" .. tostring(not buttonState.sorter)]:setPosition(button.position[1] + GuiUtils.getNormalizedXValue(buttonState.pos), 0)

	buttonState.sorter = not buttonState.sorter
	
	local sorter = buttonState.sorter
	local target = buttonState.target
    local targetPaths = string.split(target, "|")

	table.sort(self.dewars, function(a, b)

        local aTarget, bTarget

        if target == "identifier" then

            aTarget = string.format("%s %s %s", RealisticLivestock.AREA_CODES[a.animal.country].code, a.animal.farmId, a.animal.uniqueId)
            bTarget = string.format("%s %s %s", RealisticLivestock.AREA_CODES[b.animal.country].code, b.animal.farmId, b.animal.uniqueId)

        else

            aTarget = a[targetPaths[1]]
            bTarget = b[targetPaths[1]]

            for i = 2, #targetPaths do

                aTarget = aTarget[targetPaths[i]]
                bTarget = bTarget[targetPaths[i]]

            end

        end

		if sorter then return aTarget > bTarget end

		return aTarget < bTarget

	end)

	self.dewarList:reloadData()

end