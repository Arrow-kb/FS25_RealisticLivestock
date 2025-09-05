AnimalInfoDialog = {}

local animalInfoDialog_mt = Class(AnimalInfoDialog, MessageDialog)
local modDirectory = g_currentModDirectory

function AnimalInfoDialog.register()
    local dialog = AnimalInfoDialog.new()
    g_gui:loadGui(modDirectory .. "gui/AnimalInfoDialog.xml", "AnimalInfoDialog", dialog)
    AnimalInfoDialog.INSTANCE = dialog
end


function AnimalInfoDialog.new(target, customMt)
    local dialog = MessageDialog.new(target, customMt or animalInfoDialog_mt)
    dialog.children = {}
    return dialog
end


function AnimalInfoDialog.createFromExistingGui(gui)

    AnimalInfoDialog.register()
    AnimalInfoDialog.show()

end


function AnimalInfoDialog.show(farmId, uniqueId, children, animalType, identifiers)

    if AnimalInfoDialog.INSTANCE == nil then AnimalInfoDialog.register() end

    local dialog = AnimalInfoDialog.INSTANCE

    dialog.identifiers = identifiers
    dialog.animalType = animalType
    dialog:setDialogType(DialogElement.TYPE_INFO)
    dialog.children = children or {}
    dialog:setChildren(children or {})
    local success = dialog:updateContent(farmId, uniqueId, children ~= nil and #children > 0)

    if success then g_gui:showDialog("AnimalInfoDialog") end

end


function AnimalInfoDialog:onOpen()
    AnimalInfoDialog:superClass().onOpen(self)
    FocusManager:setFocus(self.dialogTextElement)
end


function AnimalInfoDialog:onClose()
    self.children = {}
    AnimalInfoDialog:superClass().onClose(self)
end


function AnimalInfoDialog:onCreate()
    AnimalInfoDialog:superClass().onCreate(self)
    self:setDialogType(DialogElement.Type_INFO)
end


function AnimalInfoDialog:onClickOk()
    self:close()
end


function AnimalInfoDialog:setTexts(baseStatsTexts, advancedStatsTexts, horseStatsTexts, geneticsStatsTexts)

    for i=10, #self.infoTitle do
        self.infoTitle[i]:setVisible(false)
        self.infoValue[i]:setVisible(false)
        self.infoTitle[i]:setTextColor(0.89627, 0.92158, 0.81485, 1)
        self.infoValue[i]:setTextColor(0.89627, 0.92158, 0.81485, 1)
    end

    self.separator1:setVisible(#advancedStatsTexts > 0 or #horseStatsTexts > 0 or #geneticsStatsTexts > 0)
    self.separator2:setVisible(#advancedStatsTexts > 0 and (#horseStatsTexts > 0 or #geneticsStatsTexts > 0))
    self.separator3:setVisible(#advancedStatsTexts > 0 and #horseStatsTexts > 0 and #geneticsStatsTexts > 0)



    for i=1, 9 do

        self.infoTitle[i]:setVisible(baseStatsTexts[i] ~= nil)
        self.infoValue[i]:setVisible(baseStatsTexts[i] ~= nil)

        if baseStatsTexts[i] ~= nil then
            self.infoTitle[i]:setText(baseStatsTexts[i].title)
            self.infoValue[i]:setText(baseStatsTexts[i].text)
        end

    end

    local k = 1

    if #advancedStatsTexts > 0 then

        for i=10, 15 do

            self.infoTitle[i]:setVisible(advancedStatsTexts[k] ~= nil)
            self.infoValue[i]:setVisible(advancedStatsTexts[k] ~= nil)

            if advancedStatsTexts[k] ~= nil then
                self.infoTitle[i]:setText(advancedStatsTexts[k].title)
                self.infoValue[i]:setText(advancedStatsTexts[k].text)
            end

            k = k + 1

        end

    elseif #horseStatsTexts > 0 then

        for i=10, 15 do

            self.infoTitle[i]:setVisible(horseStatsTexts[k] ~= nil)
            self.infoValue[i]:setVisible(horseStatsTexts[k] ~= nil)

            if horseStatsTexts[k] ~= nil then
                self.infoTitle[i]:setText(horseStatsTexts[k].title)
                self.infoValue[i]:setText(horseStatsTexts[k].text)
            end

            k = k + 1

        end

    elseif #geneticsStatsTexts > 0 then

        for i=10, 15 do

            self.infoTitle[i]:setVisible(geneticsStatsTexts[k] ~= nil)
            self.infoValue[i]:setVisible(geneticsStatsTexts[k] ~= nil)

           if geneticsStatsTexts[k] ~= nil then
                self.infoTitle[i]:setText(geneticsStatsTexts[k].title)
                self.infoValue[i]:setText(g_i18n:getText(geneticsStatsTexts[k].text))

                local quality = geneticsStatsTexts[k].text

                if quality == "rl_ui_genetics_extremelyLow" or quality == "rl_ui_genetics_extremelyBad" then
                    self.infoTitle[i]:setTextColor(1, 0, 0, 1)
                    self.infoValue[i]:setTextColor(1, 0, 0, 1)
                elseif quality == "rl_ui_genetics_veryLow" or quality == "rl_ui_genetics_veryBad" then
                    self.infoTitle[i]:setTextColor(1, 0.2, 0, 1)
                    self.infoValue[i]:setTextColor(1, 0.2, 0, 1)
                elseif quality == "rl_ui_genetics_low" or quality == "rl_ui_genetics_bad" then
                    self.infoTitle[i]:setTextColor(1, 0.52, 0, 1)
                    self.infoValue[i]:setTextColor(1, 0.52, 0, 1)
                elseif quality == "rl_ui_genetics_average" then
                    self.infoTitle[i]:setTextColor(1, 1, 0, 1)
                    self.infoValue[i]:setTextColor(1, 1, 0, 1)
                elseif quality == "rl_ui_genetics_high" or quality == "rl_ui_genetics_good" then
                    self.infoTitle[i]:setTextColor(0.52, 1, 0, 1)
                    self.infoValue[i]:setTextColor(0.52, 1, 0, 1)
                elseif quality == "rl_ui_genetics_veryHigh" or quality == "rl_ui_genetics_veryGood" then
                    self.infoTitle[i]:setTextColor(0.2, 1, 0, 1)
                    self.infoValue[i]:setTextColor(0.2, 1, 0, 1)
                else
                    self.infoTitle[i]:setTextColor(0, 1, 0, 1)
                    self.infoValue[i]:setTextColor(0, 1, 0, 1)
                end
            end

            k = k + 1

        end

    end

    k = 1

    if #advancedStatsTexts > 0 then

        if #horseStatsTexts > 0 then

            for i=16, 21 do

                self.infoTitle[i]:setVisible(horseStatsTexts[k] ~= nil)
                self.infoValue[i]:setVisible(horseStatsTexts[k] ~= nil)

                if horseStatsTexts[k] ~= nil then
                    self.infoTitle[i]:setText(horseStatsTexts[k].title)
                    self.infoValue[i]:setText(horseStatsTexts[k].text)
                end

                k = k + 1

            end

        elseif #geneticsStatsTexts > 0 then

            for i=16, 21 do

                self.infoTitle[i]:setVisible(geneticsStatsTexts[k] ~= nil)
                self.infoValue[i]:setVisible(geneticsStatsTexts[k] ~= nil)

                if geneticsStatsTexts[k] ~= nil then
                    self.infoTitle[i]:setText(geneticsStatsTexts[k].title)
                    self.infoValue[i]:setText(g_i18n:getText(geneticsStatsTexts[k].text))

                    local quality = geneticsStatsTexts[k].text

                    if quality == "rl_ui_genetics_extremelyLow" or quality == "rl_ui_genetics_extremelyBad" then
                        self.infoTitle[i]:setTextColor(1, 0, 0, 1)
                        self.infoValue[i]:setTextColor(1, 0, 0, 1)
                    elseif quality == "rl_ui_genetics_veryLow" or quality == "rl_ui_genetics_veryBad" then
                        self.infoTitle[i]:setTextColor(1, 0.2, 0, 1)
                        self.infoValue[i]:setTextColor(1, 0.2, 0, 1)
                    elseif quality == "rl_ui_genetics_low" or quality == "rl_ui_genetics_bad" then
                        self.infoTitle[i]:setTextColor(1, 0.52, 0, 1)
                        self.infoValue[i]:setTextColor(1, 0.52, 0, 1)
                    elseif quality == "rl_ui_genetics_average" then
                        self.infoTitle[i]:setTextColor(1, 1, 0, 1)
                        self.infoValue[i]:setTextColor(1, 1, 0, 1)
                    elseif quality == "rl_ui_genetics_high" or quality == "rl_ui_genetics_good" then
                        self.infoTitle[i]:setTextColor(0.52, 1, 0, 1)
                        self.infoValue[i]:setTextColor(0.52, 1, 0, 1)
                    elseif quality == "rl_ui_genetics_veryHigh" or quality == "rl_ui_genetics_veryGood" then
                        self.infoTitle[i]:setTextColor(0.2, 1, 0, 1)
                        self.infoValue[i]:setTextColor(0.2, 1, 0, 1)
                    else
                        self.infoTitle[i]:setTextColor(0, 1, 0, 1)
                        self.infoValue[i]:setTextColor(0, 1, 0, 1)
                    end
                end

                k = k + 1

            end

        end

    end

    k = 1

    if #advancedStatsTexts > 0 and #horseStatsTexts > 0  then

        for i=22, 27 do

                self.infoTitle[i]:setVisible(geneticsStatsTexts[k] ~= nil)
                self.infoValue[i]:setVisible(geneticsStatsTexts[k] ~= nil)

                if geneticsStatsTexts[k] ~= nil then
                    self.infoTitle[i]:setText(geneticsStatsTexts[k].title)
                    self.infoValue[i]:setText(g_i18n:getText(geneticsStatsTexts[k].text))

                    local quality = geneticsStatsTexts[k].text

                    if quality == "rl_ui_genetics_extremelyLow" or quality == "rl_ui_genetics_extremelyBad" then
                        self.infoTitle[i]:setTextColor(1, 0, 0, 1)
                        self.infoValue[i]:setTextColor(1, 0, 0, 1)
                    elseif quality == "rl_ui_genetics_veryLow" or quality == "rl_ui_genetics_veryBad" then
                        self.infoTitle[i]:setTextColor(1, 0.2, 0, 1)
                        self.infoValue[i]:setTextColor(1, 0.2, 0, 1)
                    elseif quality == "rl_ui_genetics_low" or quality == "rl_ui_genetics_bad" then
                        self.infoTitle[i]:setTextColor(1, 0.52, 0, 1)
                        self.infoValue[i]:setTextColor(1, 0.52, 0, 1)
                    elseif quality == "rl_ui_genetics_average" then
                        self.infoTitle[i]:setTextColor(1, 1, 0, 1)
                        self.infoValue[i]:setTextColor(1, 1, 0, 1)
                    elseif quality == "rl_ui_genetics_high" or quality == "rl_ui_genetics_good" then
                        self.infoTitle[i]:setTextColor(0.52, 1, 0, 1)
                        self.infoValue[i]:setTextColor(0.52, 1, 0, 1)
                    elseif quality == "rl_ui_genetics_veryHigh" or quality == "rl_ui_genetics_veryGood" then
                        self.infoTitle[i]:setTextColor(0.2, 1, 0, 1)
                        self.infoValue[i]:setTextColor(0.2, 1, 0, 1)
                    else
                        self.infoTitle[i]:setTextColor(0, 1, 0, 1)
                        self.infoValue[i]:setTextColor(0, 1, 0, 1)
                    end
                end

                k = k + 1

            end

    end


end


function AnimalInfoDialog:setChildren(children)

    local texts = {}
    local foundChildren = {}
    local placeables = g_currentMission.placeableSystem.placeables

    for _, placeable in ipairs(placeables) do

        if placeable.spec_husbandryAnimals == nil and placeable.spec_livestockTrailer == nil then continue end

        local clusterSystem = nil

        if placeable.spec_husbandryAnimals ~= nil then
            if placeable.spec_husbandryAnimals.animalTypeIndex ~= self.animalType then continue end
            clusterSystem = placeable.spec_husbandryAnimals.clusterSystem
        elseif placeable.spec_livestockTrailer ~= nil then
            clusterSystem = placeable.spec_livestockTrailer.clusterSystem
        end
        if clusterSystem == nil then continue end

        local animals = clusterSystem:getAnimals()

        for _, animal in ipairs(animals) do

            for _, child in ipairs(children) do
                if child.farmId == animal.farmId and child.uniqueId == animal.uniqueId then
                    table.insert(foundChildren, animal)
                    break
                end
            end

        end

    end

    self.children = foundChildren

    for _, child in ipairs(foundChildren) do
        table.insert(texts, child.farmId .. " " .. child.uniqueId)
    end

    self.childrenSelector:setTexts(texts or {})
    self.childrenSelector:setVisible(foundChildren ~= nil and #foundChildren > 0)
    if foundChildren ~= nil and #foundChildren > 0 then self.childrenSelector:setState(1) end

end


function AnimalInfoDialog:onClickItems(index, _, _)

    if self.children == nil or #self.children == 0 or self.children[index] == nil then return end
    self:updateContent(self.children[index].farmId, self.children[index].uniqueId, true)

end


function AnimalInfoDialog:updateContent(farmId, uniqueId, useChildren)

    if farmId == nil or uniqueId == nil then return false end

    local parent = nil

    if useChildren then

        for _, child in ipairs(self.children) do
            if child.farmId == farmId and child.uniqueId == uniqueId then
                parent = child
                break
            end
        end

    else

        local foundAnimals = {}

        local placeables = g_currentMission.placeableSystem.placeables

        for _, placeable in ipairs(placeables) do

            if placeable.spec_husbandryAnimals == nil and placeable.spec_livestockTrailer == nil then continue end

            local clusterSystem = nil

            if placeable.spec_husbandryAnimals ~= nil then
                if placeable.spec_husbandryAnimals.animalTypeIndex ~= self.animalType then continue end
                clusterSystem = placeable.spec_husbandryAnimals.clusterSystem
            elseif placeable.spec_livestockTrailer ~= nil then
                clusterSystem = placeable.spec_livestockTrailer.clusterSystem
            end
            if clusterSystem == nil then continue end

            local animals = clusterSystem:getAnimals()
            for _, animal in ipairs(animals) do

                if self.children ~= nil and #self.children > 1 and (animal.farmId ~= farmId or animal.uniqueId ~= uniqueId) then

                    for _, child in ipairs(self.children) do
                        if child.farmId == animal.farmId and child.uniqueId == animal.uniqueId then
                            table.insert(foundAnimals, animal)
                            break
                        end
                    end

                end

                if animal.farmId ~= farmId or animal.uniqueId ~= uniqueId then continue end

                --parent = animal
                table.insert(foundAnimals, animal)
                if self.children == nil or #self.children <= 1 then break end
            end

            --if parent ~= nil then break end

            if (self.children == nil or #self.children <= 1) and #foundAnimals >= 1 then
                parent = foundAnimals[1]
                break
            end

        end

        if parent == nil then
            --if self.children ~= nil and #self.children > 1 and self.childrenSelector:getState() < #self.children then
                --local index = self.childrenSelector:getState() + 1
                --self.childrenSelector:setState(index)
                --self:updateContent(self.children[index].farmId, self.children[index].uniqueId)
            --else
                --InfoDialog.INSTANCE:setText("Could not find animal")
                --g_gui:showDialog("InfoDialog")
                --return false
            --end

            if self.children ~= nil and #self.children > 1 and #foundAnimals >= 1 then

                local index = self.childrenSelector:getState()

                while index <= #self.children do
                    for _, child in ipairs(foundAnimals) do
                        if child.farmId == self.children[index].farmId and child.uniqueId == self.children[index].uniqueId then
                            parent = child
                            self.childrenSelector:setState(index)
                            break
                        end
                    end

                    if parent ~= nil then break end

                    index = index + 1
                end
            end



        end

    end

    if parent == nil then
        InfoDialog.INSTANCE:setText(g_i18n:getText("rl_ui_cantFindAnimal"))
        g_gui:showDialog("InfoDialog")
        return false
    end

        local visual = g_currentMission.animalSystem:getVisualByAge(parent:getSubTypeIndex(), parent.age)
        self.animalIcon:setImageFilename(visual.store.imageFilename)

        local baseStatsTexts = {}
        local advancedStatsTexts = {}
        local horseStatsTexts = {}
        local geneticsStatsTexts = {}

        local text = {
            title = g_i18n:getText("rl_ui_uniqueId"),
            text = uniqueId
        }

        table.insert(baseStatsTexts, text)

        text = {
            title = g_i18n:getText("rl_ui_farmId"),
            text = farmId
        }

        table.insert(baseStatsTexts, text)

        text = {
            title = g_i18n:getText("infohud_age"),
            text = g_i18n:formatNumMonth(parent.age)
        }

        table.insert(baseStatsTexts, text)

        text = {
            title = g_i18n:getText("infohud_health"),
            text = string.format("%d %%", parent.health)
        }

        table.insert(baseStatsTexts, text)

        text = {
            title = g_i18n:getText("rl_ui_gender"),
            text = g_i18n:getText("rl_ui_" .. parent.gender)
        }

        table.insert(baseStatsTexts, text)

        text = {
            title = g_i18n:getText("rl_ui_weight"),
            text = string.format("%.2f", parent.weight) .. "kg"
        }

        table.insert(baseStatsTexts, text)

        text = {
            title = g_i18n:getText("rl_ui_value"),
            text = g_i18n:formatMoney(parent:getSellPrice(), 2, true, true)
        }

        table.insert(baseStatsTexts, text)

        text = {
            title = g_i18n:getText("rl_ui_targetWeight"),
            text = string.format("%.2f", parent.targetWeight) .. "kg"
        }

        table.insert(baseStatsTexts, text)

        text = {
            title = g_i18n:getText("rl_ui_valuePerKilo"),
            text = g_i18n:formatMoney(parent:getSellPrice() / parent.weight, 2, true, true)
        }

        table.insert(baseStatsTexts, text)


        if parent.gender == "female" then

            text = {
                title = g_i18n:getText("infohud_reproduction"),
                text = string.format("%d %%", parent.reproduction)
            }

            table.insert(advancedStatsTexts, text)

            local subType = parent:getSubType()
            local healthFactor = parent:getHealthFactor()
            local canReproduce = g_i18n:getText("rl_ui_yes")

            if parent.age < subType.reproductionMinAgeMonth then
                canReproduce = g_i18n:getText("rl_ui_tooYoungBracketed")
            elseif parent.isParent and parent.monthsSinceLastBirth <= 2 then
                canReproduce = g_i18n:getText("rl_ui_recoveringLastBirthBracketed")
            elseif not RealisticLivestock.hasMaleAnimalInPen(parent.clusterSystem.owner.spec_husbandryAnimals, subType.name) and not parent.isPregnant then
                canReproduce = g_i18n:getText("rl_ui_noMaleAnimalBracketed")
            elseif healthFactor < subType.reproductionMinHealth then
                canReproduce = g_i18n:getText("rl_ui_unhealthyBracketed")
            end


            text = {
                title = g_i18n:getText("rl_ui_canReproduce"),
                text = canReproduce
            }

            table.insert(advancedStatsTexts, text)

            if parent.age >= subType.reproductionMinAgeMonth then
                text = {
                    title = g_i18n:getText("rl_ui_pregnant"),
                    text = parent.isPregnant and g_i18n:getText("rl_ui_yes") or g_i18n:getText("rl_ui_no")
                }

                table.insert(advancedStatsTexts, text)
            end

            if parent.isPregnant then
                text = {
                    title = g_i18n:getText("rl_ui_impregnatedBy"),
                    text = (parent.impregnatedBy ~= nil and parent.impregnatedBy.uniqueId ~= "-1") and parent.impregnatedBy.uniqueId or g_i18n:getText("rl_ui_unknown")
                }

                table.insert(advancedStatsTexts, text)
            end



            if parent.clusterSystem ~= nil and parent.clusterSystem.owner.spec_husbandryMilk ~= nil and parent.age >= 12 then
                text = {
                    title = g_i18n:getText("rl_ui_lactating"),
                    text = parent.isLactating and g_i18n:getText("rl_ui_yes") or g_i18n:getText("rl_ui_no")
                }

                table.insert(advancedStatsTexts, text)
            end

        end


        if string.contains(parent.subType, "HORSE", true) or string.contains(parent.subType, "STALLION", true) then

            text = {
                title = g_i18n:getText("infohud_riding"),
                text = string.format("%d %%", parent.riding)
            }

            table.insert(horseStatsTexts, text)

            text = {

                title = g_i18n:getText("infohud_fitness"),
                text = string.format("%d %%", parent.fitness)
            }

            table.insert(horseStatsTexts, text)

            text = {
                title = g_i18n:getText("statistic_cleanliness"),
                text = string.format("%d %%", parent.dirt)
            }

            table.insert(horseStatsTexts, text)

        end


        geneticsStatsTexts = parent:addGeneticsInfo()


        self:setTexts(baseStatsTexts, advancedStatsTexts, horseStatsTexts, geneticsStatsTexts)

        return true


end