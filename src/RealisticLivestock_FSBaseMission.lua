RealisticLivestock_FSBaseMission = {}
local modDirectory = g_currentModDirectory
local modSettingsDirectory = g_currentModSettingsDirectory


local function fixInGameMenu(frame, pageName, uvs, position, predicateFunc)

	local inGameMenu = g_gui.screenControllers[InGameMenu]
	position = position or #inGameMenu.pagingElement.pages + 1

	for k, v in pairs({pageName}) do
		inGameMenu.controlIDs[v] = nil
	end

	for i = 1, #inGameMenu.pagingElement.elements do
		local child = inGameMenu.pagingElement.elements[i]
		if child == inGameMenu.pageAnimals then
			position = i
            break
		end
	end
	
	inGameMenu[pageName] = frame
	inGameMenu.pagingElement:addElement(inGameMenu[pageName])

	inGameMenu:exposeControlsAsFields(pageName)

	for i = 1, #inGameMenu.pagingElement.elements do
		local child = inGameMenu.pagingElement.elements[i]
		if child == inGameMenu[pageName] then
			table.remove(inGameMenu.pagingElement.elements, i)
			table.insert(inGameMenu.pagingElement.elements, position, child)
			break
		end
	end

	for i = 1, #inGameMenu.pagingElement.pages do
		local child = inGameMenu.pagingElement.pages[i]
		if child.element == inGameMenu[pageName] then
			table.remove(inGameMenu.pagingElement.pages, i)
			table.insert(inGameMenu.pagingElement.pages, position, child)
			break
		end
	end

	inGameMenu.pagingElement:updateAbsolutePosition()
	inGameMenu.pagingElement:updatePageMapping()
	
	inGameMenu:registerPage(inGameMenu[pageName], position, predicateFunc)
	inGameMenu:addPageTab(inGameMenu[pageName], modDirectory .. "gui/icons.dds", GuiUtils.getUVs(uvs))

	for i = 1, #inGameMenu.pageFrames do
		local child = inGameMenu.pageFrames[i]
		if child == inGameMenu[pageName] then
			table.remove(inGameMenu.pageFrames, i)
			table.insert(inGameMenu.pageFrames, position, child)
			break
		end
	end

	inGameMenu:rebuildTabList()

end


function RealisticLivestock_FSBaseMission:onStartMission()

    g_gui.guis.AnimalScreen:delete()
    g_gui:loadGui(modDirectory .. "gui/AnimalScreen.xml", "AnimalScreen", g_animalScreen)

    local xmlFile = XMLFile.loadIfExists("RealisticLivestock", modSettingsDirectory .. "Settings.xml")
    if xmlFile ~= nil then
        local maxHusbandries = xmlFile:getInt("Settings.setting(0)#maxHusbandries", 2)
        RealisticLivestock_AnimalClusterHusbandry.MAX_HUSBANDRIES = maxHusbandries
        xmlFile:delete()
    end

    AnimalInfoDialog.register()
    NameInputDialog.register()
    EarTagColourPickerDialog.register()
    AnimalFilterDialog.register()

	RLSettings.applyDefaultSettings()

    local temp = self.environment.weather.temperatureUpdater.currentMin or 20

    for _, placeable in pairs(self.husbandrySystem.placeables) do

        local animals = placeable:getClusters()

        for _, animal in pairs(animals) do
            animal:updateInput()
            animal:updateOutput(temp)
        end

        if self.isServer then placeable:updateInputAndOutput(animals) end

    end

    g_overlayManager:addTextureConfigFile(modDirectory .. "gui/icons.xml", "realistic_livestock")

    local realisticLivestockFrame = RealisticLivestockFrame.new() 
	g_gui:loadGui(modDirectory .. "gui/RealisticLivestockFrame.xml", "RealisticLivestockFrame", realisticLivestockFrame, true)

    fixInGameMenu(realisticLivestockFrame, "realisticLivestockFrame", {260,0,256,256}, 4, function() return true end)

    realisticLivestockFrame:initialize()

end

FSBaseMission.onStartMission = Utils.prependedFunction(FSBaseMission.onStartMission, RealisticLivestock_FSBaseMission.onStartMission)


function RealisticLivestock_FSBaseMission:leaveCurrentGame()

    print("RealisticLivestock: beginning destruction")
    local placeables = g_currentMission.placeableSystem.placeables

    for _, placeable in ipairs(placeables) do

        if placeable.spec_husbandryAnimals == nil and placeable.spec_livestockTrailer == nil then continue end

        local clusterSystem = nil

        if placeable.spec_husbandryAnimals ~= nil then
            clusterSystem = placeable.spec_husbandryAnimals.clusterSystem
        elseif placeable.spec_livestockTrailer ~= nil then
            clusterSystem = placeable.spec_livestockTrailer.clusterSystem
        end
        if clusterSystem == nil then continue end

        clusterSystem.animals = {}

        if placeable.spec_husbandryAnimals == nil then continue end

        local husbandry = (placeable.spec_husbandryAnimals ~= nil and placeable.spec_husbandryAnimals.clusterHusbandry) or (placeable.spec_livestockTrailer ~= nil and placeable.spec_livestockTrailer.clusterHusbandry) or nil

        if husbandry ~= nil then husbandry:deleteHusbandry() end

    end

    print("RealisticLivestock: destruction completed")

end

InGameMenu.leaveCurrentGame = Utils.prependedFunction(InGameMenu.leaveCurrentGame, RealisticLivestock_FSBaseMission.leaveCurrentGame)