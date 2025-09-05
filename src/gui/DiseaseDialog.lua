DiseaseDialog = {}

local diseaseDialog_mt = Class(DiseaseDialog, MessageDialog)
local modDirectory = g_currentModDirectory

function DiseaseDialog.register()

    local dialog = DiseaseDialog.new()
    g_gui:loadGui(modDirectory .. "gui/DiseaseDialog.xml", "DiseaseDialog", dialog)
    DiseaseDialog.INSTANCE = dialog

end


function DiseaseDialog.new(target, customMt)

    local self = MessageDialog.new(target, customMt or diseaseDialog_mt)

    return self

end


function DiseaseDialog.createFromExistingGui(gui)

    DiseaseDialog.register()
    DiseaseDialog.show()

end


function DiseaseDialog.show(animal)

    if DiseaseDialog.INSTANCE == nil then DiseaseDialog.register() end

    local dialog = DiseaseDialog.INSTANCE

    dialog.animal = animal
    dialog.diseases = table.clone(animal.diseases)

    g_gui:showDialog("DiseaseDialog")

end


function DiseaseDialog:onOpen()

    DiseaseDialog:superClass().onOpen(self)

    self.diseaseList:reloadData()

    self:onClickListItem(1)

end


function DiseaseDialog:onClickOk()

    local disease = self.diseases[self.diseaseList.selectedIndex]

    if disease == nil or disease.type.treatment == nil or disease.cured then return end

    disease.beingTreated = not disease.beingTreated

    if not disease.beingTreated then
        self.animal:addMessage("DISEASE_TREATMENT_STOP", { disease.type.name })
    else
        self.animal:addMessage("DISEASE_TREATMENT_" .. (disease.treatmentDuration > 0 and "RESUME" or "START"), { disease.type.name, string.format(g_i18n:getText("rl_ui_feePerMonth"), g_i18n:formatMoney(disease.type.treatment.cost, 2, true, true)) })
    end
    
    for _, aDisease in pairs(self.animal.diseases) do

        if aDisease.type.title == disease.type.title then
            aDisease.beingTreated = disease.beingTreated
            break
        end

    end

    self:onClickListItem(self.diseaseList.selectedIndex)
    self.diseaseList:reloadData()

end


function DiseaseDialog:onClickListItem(index)

    local disease = self.diseases[index]

    if disease == nil or disease.type.treatment == nil or disease.cured then

        self.yesButton:setDisabled(true)
        return

    end

    self.yesButton:setDisabled(false)
    self.yesButton:setText(g_i18n:getText("rl_ui_" .. (disease.beingTreated and "stop" or (disease.treatmentDuration > 0 and "resume" or "start")) .. "Treatment"))

end


function DiseaseDialog:getNumberOfSections()

	return 1

end


function DiseaseDialog:getNumberOfItemsInSection(list, section)

	return #self.animal.diseases

end


function DiseaseDialog:getTitleForSectionHeader(list, section)

    return ""

end


function DiseaseDialog:populateCellForItemInSection(list, section, index, cell)

	local disease = self.diseases[index]

    if disease == nil then return end

    local type = disease.type
    local treatment = type.treatment

    cell:getAttribute("title"):setText(type.name)
    cell:getAttribute("duration"):setText(treatment == nil and "N/A" or RealisticLivestock.formatAge(treatment.duration - disease.treatmentDuration))
    cell:getAttribute("fee"):setText(treatment == nil and "N/A" or string.format(g_i18n:getText("rl_ui_feePerMonth"), g_i18n:formatMoney(treatment.cost, 2, true, true)))
    cell:getAttribute("status"):setText(disease:getStatus())

    cell.setSelected = Utils.appendedFunction(cell.setSelected, function(cell, selected)
		if selected then self:onClickListItem(index) end
	end)
    
end