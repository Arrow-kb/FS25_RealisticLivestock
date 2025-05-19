RealisticLivestock_FSBaseMission = {}
local modDirectory = g_currentModDirectory
local modSettingsDirectory = g_currentModSettingsDirectory


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