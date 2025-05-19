RLSettings = {}
local modDirectory = g_currentModDirectory

g_gui:loadProfiles(modDirectory .. "gui/guiProfiles.xml")

RLSettings.SETTINGS = {

	["deathEnabled"] = {
		["index"] = 1,
		["type"] = "BinaryOption",
		["dynamicTooltip"] = true,
		["default"] = 2,
		["binaryType"] = "offOn",
		["values"] = { false, true },
		["callback"] = Animal.onSettingChanged
	},

	["accidentsChance"] = {
		["index"] = 2,
		["type"] = "MultiTextOption",
		["default"] = 11,
		["valueType"] = "float",
		["values"] = { 0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.0 },
		["callback"] = Animal.onSettingChanged,
		["dependancy"] = {
			["name"] = "deathEnabled",
			["state"] = 2
		}
	},

	["foodScale"] = {
		["index"] = 3,
		["type"] = "MultiTextOption",
		["default"] = 2,
		["valueType"] = "float",
		["values"] = { 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5 },
		["callback"] = RealisticLivestock_PlaceableHusbandryFood.onSettingChanged
	},

	["maxDealerAnimals"] = {
		["index"] = 4,
		["type"] = "MultiTextOption",
		["default"] = 4,
		["valueType"] = "int",
		["values"] = { 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170, 180, 190, 200 },
		["callback"] = AnimalSystem.onSettingChanged
	}

}

RLSettings.BinaryOption = nil
RLSettings.MultiTextOption = nil
RLSettings.Button = nil


function RLSettings.loadFromXMLFile()

	local savegameIndex = g_careerScreen.savegameList.selectedIndex
	local savegame = g_savegameController:getSavegame(savegameIndex)

	if savegame ~= nil and savegame.savegameDirectory ~= nil then

		local path = savegame.savegameDirectory .. "/rlSettings.xml"

		local xmlFile = XMLFile.loadIfExists("rlSettings", path)

		if xmlFile ~= nil then

			local key = "settings"
			
			for name, setting in pairs(RLSettings.SETTINGS) do

				if setting.ignore then continue end

				setting.state = xmlFile:getInt(key .. "." .. name .. "#value", setting.default)

				if setting.state > #setting.values then setting.state = #setting.values end

			end

			xmlFile:delete()

		end

	end

end


function RLSettings.saveToXMLFile(name, state)

	if g_server ~= nil then

		local savegameIndex = g_careerScreen.savegameList.selectedIndex
		local savegame = g_savegameController:getSavegame(savegameIndex)

		if savegame ~= nil and savegame.savegameDirectory ~= nil then

			local path = savegame.savegameDirectory .. "/rlSettings.xml"
			--local xmlFile = XMLFile.loadIfExists("rlSettings", path)
			local xmlFile = XMLFile.create("rlSettings", path, "settings")

			--if xmlFile == nil then xmlFile = XMLFile.create("rlSettings", path, "settings") end

			if xmlFile ~= nil then

				--xmlFile:setInt("settings." .. name .. "#value", state)

				for settingName, setting in pairs(RLSettings.SETTINGS) do
					if setting.ignore then continue end
					xmlFile:setInt("settings." .. settingName .. "#value", setting.state)
				end

				local saved = xmlFile:save(false, true)

				xmlFile:delete()

			end

		end

	end

end


function RLSettings.initialize()

	if g_server ~= nil then RLSettings.loadFromXMLFile() end

	local settingsPage = g_inGameMenu.pageSettings
	local scrollPanel = settingsPage.gameSettingsLayout

	local sectionHeader, binaryOptionElement, multiOptionElement, buttonElement

	for _, element in pairs(scrollPanel.elements) do

		if element.name == "sectionHeader" and sectionHeader == nil then sectionHeader = element:clone(scrollPanel) end

		if element.typeName == "Bitmap" then

			if element.elements[1].typeName == "BinaryOption" and binaryOptionElement == nil then binaryOptionElement = element end

			if element.elements[1].typeName == "MultiTextOption" and multiOptionElement == nil then multiOptionElement = element end

			if element.elements[1].typeName == "Button" and buttonElement == nil then buttonElement = element end

		end

		if multiOptionElement and binaryOptionElement and sectionHeader and buttonElement then break end	

	end

	if multiOptionElement == nil or binaryOptionElement == nil or sectionHeader == nil or buttonElement == nil then return end

	RLSettings.BinaryOption = binaryOptionElement
	RLSettings.MultiTextOption  = multiOptionElement
	RLSettings.Button = buttonElement

	local prefix = "rl_settings_"

	sectionHeader:setText(g_i18n:getText("rl_settings"))

	local maxIndex = 0

	for _, setting in pairs(RLSettings.SETTINGS) do maxIndex = maxIndex < setting.index and setting.index or maxIndex end

	for i = 1, maxIndex do

		for name, setting in pairs(RLSettings.SETTINGS) do

			if setting.index ~= i then continue end
	
			setting.state = setting.state or setting.default
			local template = RLSettings[setting.type]:clone(scrollPanel)
			local settingsPrefix = "rl_settings_" .. name .. "_"
			template.id = nil
		
			for _, element in pairs(template.elements) do

				if element.typeName == "Text" then
					element:setText(g_i18n:getText(settingsPrefix .. "label"))
					element.id = nil
				end

				if element.typeName == setting.type then

					if setting.type == "Button" then
						element:setText(g_i18n:getText(settingsPrefix .. "text"))
						element:applyProfile("rl_settingsButton")
						element.isAlwaysFocusedOnOpen = false
						element.focused = false
					else

						local texts = {}

						if setting.binaryType == "offOn" then
							texts[1] = g_i18n:getText("rl_settings_off")
							texts[2] = g_i18n:getText("rl_settings_on")
						else

							for i, value in pairs(setting.values) do

								if setting.valueType == "int" then
									texts[i] = tostring(value)
								elseif setting.valueType == "float" then
									texts[i] = string.format("%.0f%%", value * 100)
								else
									texts[i] = g_i18n:getText(settingsPrefix .. "texts_" .. i)
								end
							end

						end

						element:setTexts(texts)
						element:setState(setting.state)

						if setting.dynamicTooltip then
							element.elements[1]:setText(g_i18n:getText(settingsPrefix .. "tooltip_" .. setting.state))
						else
							element.elements[1]:setText(g_i18n:getText(settingsPrefix .. "tooltip"))
						end

					end

					element.id = "rls_" .. name
					element.onClickCallback = RLSettings.onSettingChanged

					setting.element = element

					if setting.dependancy then
						local dependancy = RLSettings.SETTINGS[setting.dependancy.name]
						if dependancy ~= nil and dependancy.element ~= nil then element:setDisabled(dependancy.state ~= setting.dependancy.state) end
					end

				end
			
			end

		end

	end

end


function RLSettings.onSettingChanged(_, state, button)

	if button == nil then button = state end

	if button == nil or button.id == nil then return end

	if not string.contains(button.id, "rls_") then return end

	local name = string.sub(button.id, 5)
	local setting = RLSettings.SETTINGS[name]

	if setting == nil then return end

	if setting.ignore then
		if setting.callback then setting.callback() end
		return
	end

	if setting.callback then setting.callback(name, setting.values[state]) end

	setting.state = state

	for _, s in pairs(RLSettings.SETTINGS) do
		if s.dependancy and s.dependancy.name == name then
			s.element:setDisabled(s.dependancy.state ~= state)
		end
	end

	if setting.dynamicTooltip and setting.element ~= nil then setting.element.elements[1]:setText(g_i18n:getText("rl_settings_" .. name .. "_tooltip_" .. setting.state)) end

	if g_server ~= nil then

		RLSettings.saveToXMLFile(name, state)

	else

		--RL_BroadcastSettingsEvent.sendEvent(name)

	end

end


function RLSettings.applyDefaultSettings()

	if g_server == nil then

		--RL_BroadcastSettingsEvent.sendEvent()

	else

		for name, setting in pairs(RLSettings.SETTINGS) do
		
			if setting.ignore then continue end

			if setting.callback ~= nil then setting.callback(name, setting.values[setting.state]) end

			if setting.dynamicTooltip and setting.element ~= nil then setting.element.elements[1]:setText(g_i18n:getText("rl_settings_" .. name .. "_tooltip_" .. setting.state)) end

			for _, s in pairs(RLSettings.SETTINGS) do
				if s.dependancy and s.dependancy.name == name and s.element ~= nil then
					s.element:setDisabled(s.dependancy.state ~= state)
				end
			end
		end

	end
end


RLSettings.initialize()