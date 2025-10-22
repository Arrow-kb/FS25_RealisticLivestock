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

    AnimalAIDialog.register()
    AnimalInfoDialog.register()
    DiseaseDialog.register()
    FileExplorerDialog.register()
    ProfileDialog.register()
    NameInputDialog.register()
    EarTagColourPickerDialog.register()
    AnimalFilterDialog.register()

	RLSettings.applyDefaultSettings()

    local temp = self.environment.weather.temperatureUpdater.currentMin or 20
	local isServer = self:getIsServer() 

    for _, placeable in pairs(self.husbandrySystem.placeables) do

        local animals = placeable:getClusters()

        for _, animal in pairs(animals) do
            animal:updateInput()
            animal:updateOutput(temp)
        end

        if isServer then placeable:updateInputAndOutput(animals) end

    end

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


function RealisticLivestock_FSBaseMission:sendInitialClientState(connection, _, _)

    local animalSystem = g_currentMission.animalSystem

	for _, setting in pairs(RLSettings.SETTINGS) do
		if not setting.ignore then setting.state = setting.state or setting.default end
	end

    connection:sendEvent(RL_BroadcastSettingsEvent.new())
    connection:sendEvent(AnimalSystemStateEvent.new(animalSystem.countries, animalSystem.animals, animalSystem.aiAnimals))
    connection:sendEvent(DewarManagerStateEvent.new())
    connection:sendEvent(HusbandryMessageStateEvent.new(g_currentMission.husbandrySystem.placeables))

end

FSBaseMission.sendInitialClientState = Utils.prependedFunction(FSBaseMission.sendInitialClientState, RealisticLivestock_FSBaseMission.sendInitialClientState)


function RealisticLivestock_FSBaseMission:onDayChanged()

	if not self:getIsServer() then return end

	local husbandrySystem = self.husbandrySystem

	for _, farm in pairs(g_farmManager:getFarms()) do

		local husbandries = husbandrySystem:getPlaceablesByFarm(farm.farmId)
		local wages = 0

		for _, husbandry in pairs(husbandries) do

			local aiManager = husbandry:getAIManager()

			if aiManager ~= nil then wages = wages + (aiManager.wage or 0) end

		end

		if wages > 0 then self:addMoney(-wages, farm.farmId, MoneyType.HERDSMAN_WAGES, true, true) end

	end

end

FSBaseMission.onDayChanged = Utils.appendedFunction(FSBaseMission.onDayChanged, RealisticLivestock_FSBaseMission.onDayChanged)