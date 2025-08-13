AnimalFilterDialog = {}

local animalFilterDialog_mt = Class(AnimalFilterDialog, MessageDialog)
local modDirectory = g_currentModDirectory

function AnimalFilterDialog.register()

    local dialog = AnimalFilterDialog.new()
    g_gui:loadGui(modDirectory .. "gui/AnimalFilterDialog.xml", "AnimalFilterDialog", dialog)
    AnimalFilterDialog.INSTANCE = dialog

end


function AnimalFilterDialog.new(target, customMt)

    local self = MessageDialog.new(target, customMt or animalFilterDialog_mt)

    self.items = nil
    self.filters = nil
    self.elementsToDelete = {}
    self.sliderTemplateOffset = GuiUtils.getNormalizedScreenValues("0px 45px")
    self.binaryOptionTemplateOffset = GuiUtils.getNormalizedScreenValues("0px 30px")

    return self

end


function AnimalFilterDialog.createFromExistingGui(gui)

    AnimalFilterDialog.register()
    AnimalFilterDialog.show()

end


function AnimalFilterDialog.show(items, animalTypeIndex, callback, target, isBuyMode)

    if AnimalFilterDialog.INSTANCE == nil then AnimalFilterDialog.register() end

    local dialog = AnimalFilterDialog.INSTANCE

    dialog.items = table.clone(items)
    dialog.animalTypeIndex = animalTypeIndex
    dialog.callback = callback
    dialog.target = target
    dialog.isBuyMode = isBuyMode

    g_gui:showDialog("AnimalFilterDialog")

end


function AnimalFilterDialog:onOpen()

    AnimalFilterDialog:superClass().onOpen(self)

    self.filters = {}

    for i = #self.elementsToDelete, 1, -1 do
        if self.elementsToDelete[i] ~= nil then self.elementsToDelete[i]:delete() end
        table.remove(self.elementsToDelete, i)
    end

    local items = self.items
    local anyText = g_i18n:getText("rl_ui_any")
    local geneticsText = g_i18n:getText("rl_ui_genetics") .. ": "

    local filters = {

        {
            ["target"] = "age",
            ["name"] = g_i18n:getText("infohud_age"),
            ["template"] = "sliderTemplate",
            ["text"] = {
                ["single"] = g_i18n:getText("rl_ui_formatMonth"),
                ["multiple"] = g_i18n:getText("rl_ui_formatMonths")
            },
            ["min"] = 0,
            ["max"] = 1
        },

        {
            ["target"] = "health",
            ["name"] = g_i18n:getText("infohud_health"),
            ["requiresMonitor"] = true,
            ["template"] = "sliderTemplate",
            ["text"] = {
                ["single"] = "%s%%",
                ["multiple"] = "%s%%"
            },
            ["min"] = 0,
            ["max"] = 1
        },

        {
            ["target"] = "weight",
            ["name"] = g_i18n:getText("rl_ui_weight"),
            ["requiresMonitor"] = true,
            ["template"] = "sliderTemplate",
            ["text"] = {
                ["single"] = "%skg",
                ["multiple"] = "%skg"
            },
            ["min"] = 0,
            ["max"] = 1
        },

        {
            ["target"] = "isPregnant",
            ["name"] = g_i18n:getText("rl_ui_pregnancy"),
            ["template"] = "binaryOptionTemplate",
            ["text"] = {
                {
                    ["text"] = g_i18n:getText("rl_ui_notPregnant"),
                    ["value"] = false
                },
                {
                    ["text"] = anyText,
                    ["value"] = "ignore"
                },
                {
                    ["text"] = g_i18n:getText("rl_ui_pregnant"),
                    ["value"] = true
                }
            },
            ["default"] = 2
        },

        {
            ["target"] = "gender",
            ["name"] = g_i18n:getText("rl_ui_gender"),
            ["template"] = "binaryOptionTemplate",
            ["text"] = {
                {
                    ["text"] = g_i18n:getText("rl_ui_female"),
                    ["value"] = "female"
                },
                {
                    ["text"] = anyText,
                    ["value"] = "ignore"
                },
                {
                    ["text"] = g_i18n:getText("rl_ui_male"),
                    ["value"] = "male"
                }
            },
            ["default"] = 2
        },

        {
            ["isFunction"] = true,
            ["target"] = "getHasName",
            ["name"] = g_i18n:getText("infohud_name"),
            ["template"] = "binaryOptionTemplate",
            ["text"] = {
                {
                    ["text"] = g_i18n:getText("rl_ui_doesntHaveName"),
                    ["value"] = false
                },
                {
                    ["text"] = anyText,
                    ["value"] = "ignore"
                },
                {
                    ["text"] = g_i18n:getText("rl_ui_doesHaveName"),
                    ["value"] = true
                }
            },
            ["default"] = 2
        },

        {
            ["isFunction"] = true,
            ["target"] = "getSellPrice",
            ["name"] = g_i18n:getText("rl_ui_value"),
            ["template"] = "sliderTemplate",
            ["text"] = {
                ["formatFunction"] = I18N.formatMoney,
                ["target"] = g_i18n,
                ["args"] = {
                    "value",
                    2,
                    true,
                    true
                }
            },
            ["min"] = 0,
            ["max"] = 1,
            ["multiplier"] = self.isBuyMode and 1.075 or 1
        },

        {
            ["isLayered"] = true,
            ["target"] = {
                "genetics",
                "metabolism"
            },
            ["name"] = geneticsText .. g_i18n:getText("rl_ui_metabolism"),
            ["template"] = "sliderTemplate",
            ["text"] = {
                ["formatFunction"] = AnimalFilterDialog.formatGenetics,
                ["target"] = self,
                ["args"] = {
                    "value"
                }
            },
            ["min"] = 0,
            ["max"] = 1,
            ["multiplier"] = 100
        },

        {
            ["isLayered"] = true,
            ["target"] = {
                "genetics",
                "health"
            },
            ["name"] = geneticsText .. g_i18n:getText("rl_ui_health"),
            ["template"] = "sliderTemplate",
            ["text"] = {
                ["formatFunction"] = AnimalFilterDialog.formatGenetics,
                ["target"] = self,
                ["args"] = {
                    "value"
                }
            },
            ["min"] = 0,
            ["max"] = 1,
            ["multiplier"] = 100
        },

        {
            ["isLayered"] = true,
            ["target"] = {
                "genetics",
                "fertility"
            },
            ["name"] = geneticsText .. g_i18n:getText("rl_ui_fertility"),
            ["template"] = "sliderTemplate",
            ["text"] = {
                ["formatFunction"] = AnimalFilterDialog.formatGenetics,
                ["target"] = self,
                ["args"] = {
                    "value"
                }
            },
            ["min"] = 0,
            ["max"] = 1,
            ["multiplier"] = 100
        },

        {
            ["isLayered"] = true,
            ["target"] = {
                "genetics",
                "quality"
            },
            ["name"] = geneticsText .. g_i18n:getText("rl_ui_meat"),
            ["template"] = "sliderTemplate",
            ["text"] = {
                ["formatFunction"] = AnimalFilterDialog.formatGenetics,
                ["target"] = self,
                ["args"] = {
                    "value"
                }
            },
            ["min"] = 0,
            ["max"] = 1,
            ["multiplier"] = 100
        }

    }



    if self.animalTypeIndex == AnimalType.COW or self.animalTypeIndex == AnimalType.SHEEP or self.animalTypeIndex == AnimalType.CHICKEN then
        
        table.insert(filters, {
            ["isLayered"] = true,
            ["target"] = {
                "genetics",
                "productivity"
            },
            ["name"] = geneticsText .. g_i18n:getText("statistic_productivity"),
            ["template"] = "sliderTemplate",
            ["text"] = {
                ["formatFunction"] = AnimalFilterDialog.formatGenetics,
                ["target"] = self,
                ["args"] = {
                    "value"
                }
            },
            ["min"] = 0,
            ["max"] = 1,
            ["multiplier"] = 100
        })

    end


    if self.animalTypeIndex == AnimalType.COW then

        table.insert(filters, 6, {
            ["target"] = "isLactating",
            ["name"] = g_i18n:getText("rl_ui_lactating"),
            ["template"] = "binaryOptionTemplate",
            ["text"] = {
                {
                    ["text"] = g_i18n:getText("rl_ui_no"),
                    ["value"] = false
                },
                {
                    ["text"] = anyText,
                    ["value"] = "ignore"
                },
                {
                    ["text"] = g_i18n:getText("rl_ui_yes"),
                    ["value"] = true
                }
            },
            ["default"] = 2
        })

    end


    for _, item in pairs(items) do

        local animal = item.animal or item.cluster

        for _, filter in pairs(filters) do

            if (filter.requiresMonitor and not animal.monitor.active and not animal.monitor.removed) or filter.template ~= "sliderTemplate" then continue end

            local value

            if filter.isLayered then

                value = animal

                for _, target in pairs(filter.target) do

                    value = value[target]

                end

            elseif filter.isFunction then

                value = animal[filter.target](animal)

            else

                value = animal[filter.target]

            end

            if value < filter.min then filter.min = math.floor(value) end
            if value > filter.max then filter.max = math.ceil(value) end

            filter.hasValues = true

        end

    end


    for i = #filters, 1, -1 do

        if filters[i].template == "sliderTemplate" and not filters[i].hasValues then table.remove(filters, i) end

    end


    self.filters = filters

    self.filterList:reloadData()

end


function AnimalFilterDialog:onClose()

    AnimalFilterDialog:superClass().onClose(self)

end


function AnimalFilterDialog:onClickOk()

    for i = #self.filters, 1, -1 do

        local filter = self.filters[i]
        local element = self.elementsToDelete[i]

        if filter.template == "sliderTemplate" and element ~= nil then

            local multiplier = filter.multiplier or 1

            filter.min, filter.max = (element:getLowestState() - 1) / multiplier , (element:getHighestState() - 1) / multiplier

        end

        if filter.template == "binaryOptionTemplate" then

            local state = element == nil and (filter.default or 1) or element:getState()
            local value = filter.text[state].value

            if value == "ignore" then
                table.remove(self.filters, i)
                continue
            end

            filter.value = value

        end

    end

    for i = #self.items, 1, -1 do

        local item = self.items[i]
        local animal = item.animal or item.cluster
        local meetsFilters = true

        for _, filter in pairs(self.filters) do

            if filter.requiresMonitor and not animal.monitor.active and not animal.monitor.removed then continue end

            if filter.template == "sliderTemplate" then

                local value

                if filter.isLayered then

                    value = animal

                    for _, target in pairs(filter.target) do value = value[target] end

                elseif filter.isFunction then

                    value = animal[filter.target](animal)

                    if filter.name == "Value" and self.isBuyMode then value = value * 1.075 end

                else

                    value = animal[filter.target]

                end

                if value < filter.min or value > filter.max then
                    meetsFilters = false
                    break
                end

            end


            if filter.template == "binaryOptionTemplate" then

                local Value

                if filter.isFunction then
                    
                    value = animal[filter.target](animal)

                else

                    value = animal[filter.target]

                end

                if value ~= filter.value then
                    meetsFilters = false
                    break
                end

            end

        end

        self.items[i].originalIndex = i

        if not meetsFilters then table.remove(self.items, i) end

    end

    if self.callback ~= nil then

        if self.target ~= nil then
            self.callback(self.target, self.filters, self.items)
        else
            self.callback(self.filters, self.items)
        end

    end

    self:close()

end


function AnimalFilterDialog:getNumberOfSections()

	return 1

end


function AnimalFilterDialog:getNumberOfItemsInSection(list, section)

	return #self.filters

end


function AnimalFilterDialog:getTitleForSectionHeader(list, section)

    return ""

end


function AnimalFilterDialog:populateCellForItemInSection(list, section, index, cell)

	local filter = self.filters[index]

    cell:findAllAttributes()

    cell:getAttribute("name"):setText(filter.name)

    if filter.template ~= nil then

        if self.elementsToDelete[index] ~= nil then

            local oldTemplate = self.elementsToDelete[index]
            local template = self[filter.template]:clone(cell, false, false)

            local texts = table.clone(oldTemplate.texts)
            template:setTexts(texts)

            template:setPosition(self[filter.template .. "Offset"][1], self[filter.template .. "Offset"][2])
            template:setVisible(true)

            if filter.template == "sliderTemplate" then

                template.leftState = oldTemplate.leftState
                template.rightState = oldTemplate.rightState

                template:updateContentElement()
                template:updateSlider()

            end

            if filter.template == "binaryOptionTemplate" then

                template:setState(oldTemplate:getState(), false, true)

            end

            oldTemplate:delete()
            self.elementsToDelete[index] = template


        else

            local template = self[filter.template]:clone(cell, false, false)
            local templateTexts = {}

            if filter.template == "sliderTemplate" then

                local multiplier = filter.multiplier or 1

                for i = filter.min * multiplier, filter.max * multiplier do

                    if filter.text.formatFunction ~= nil then

                        local args = table.clone(filter.text.args or {})

                        for argIndex, arg in pairs(args) do if arg == "value" then args[argIndex] = i end end

                        local text = filter.text.formatFunction(filter.text.target, args[1], args[2], args[3], args[4])
                        table.insert(templateTexts, text)
                
                    else

                        table.insert(templateTexts, string.format(filter.text[i == 1 and "single" or "multiple"], i))

                    end

                end

            end

            if filter.template == "binaryOptionTemplate" then

                for _, data in pairs(filter.text) do table.insert(templateTexts, data.text) end

            end

            template:setTexts(templateTexts)
            template:setPosition(self[filter.template .. "Offset"][1], self[filter.template .. "Offset"][2])
            template:setVisible(true)

            if filter.template == "binaryOptionTemplate" then template:setState(filter.default or 1) end

            self.elementsToDelete[index] = template

        end

    end

    for name, element in pairs(cell.attributes) do
    
        if name ~= "name" and name ~= "separator" then element:delete() end

    end
    
end


function AnimalFilterDialog:formatGenetics(value)

    local text

    if value >= 165 then
        text = "extremelyHigh"
    elseif value >= 140 then
        text = "veryHigh"
    elseif value >= 110 then
        text = "high"
    elseif value >= 90 then
        text = "average"
    elseif value >= 70 then
        text = "low"
    elseif value >= 35 then
        text = "veryLow"
    else
        text = "extremelyLow"
    end

    return g_i18n:getText("rl_ui_genetics_" .. text)

end