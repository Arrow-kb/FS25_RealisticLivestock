RealisticLivestock_AnimalSystem = {}

local modName = g_currentModName
local modDirectory = g_currentModDirectory


table.insert(FinanceStats.statNames, "monitorSubscriptions")
FinanceStats.statNameToIndex["monitorSubscriptions"] = #FinanceStats.statNames



AnimalSystem.BREED_TO_NAME = {
    ["HOLSTEIN"] = "Holstein",
    ["SWISS_BROWN"] = "Swiss Brown",
    ["ANGUS"] = "Angus",
    ["LIMOUSIN"] = "Limousin",
    ["HEREFORD"] = "Hereford",
    ["WATER_BUFFALO"] = "Water Buffalo",
    ["LANDRACE"] = "Landrace",
    ["BLACK_PIED"] = "Black Pied",
    ["BERKSHIRE"] = "Berkshire",
    ["STEINSCHAF"] = "Steinschaf",
    ["SWISS_MOUNTAIN"] = "Swiss Mountain",
    ["BLACK_WELSH"] = "Black Welsh",
    ["GOAT"] = "Goat",
    ["GRAY"] = "Gray",
    ["PINTO"] = "Pinto",
    ["PALOMINO"] = "Palomino",
    ["CHESTNUT"] = "Chestnut",
    ["BAY"] = "Bay",
    ["BLACK"] = "Black",
    ["SEAL_BROWN"] = "Seal Brown",
    ["DUN"] = "Dun",
    ["CHICKEN"] = "Chicken",
    ["OTHER"] = "Unknown"
}


AnimalSystem.BREED_TO_MARKER_COLOUR = {
    ["HOLSTEIN"] = { 1, 0, 0 },
    ["SWISS_BROWN"] = { 1, 1, 0 },
    ["ANGUS"] = { 1, 1, 1 },
    ["LIMOUSIN"] = { 0, 0, 1 },
    ["HEREFORD"] = { 0, 0, 1 },
    ["WATER_BUFFALO"] = { 1, 1, 1 }
}


function RealisticLivestock_AnimalSystem:loadMapData(_, mapXml, mission, baseDirectory)

    RLSettings.initialize()

    self.customEnvironment = modName

    self.baseColours = {
        ["earTagLeft"] = { 0.8, 0.7, 0 },
        ["earTagRight"] = { 0.8, 0.7, 0 },
        ["earTagLeft_text"] = { 0, 0, 0 },
        ["earTagRight_text"] = { 0, 0, 0 }
    }

    local path = modDirectory .. "xml/animals.xml"
    local xmlFile = XMLFile.load("animals", path)

    if xmlFile ~= nil then

        self:loadAnimals(xmlFile, modDirectory)
        xmlFile:delete()

    end

    self.customEnvironment = mission.customEnvironment

    local baseFilename = getXMLString(mapXml, "map.animals#filename")

	if baseFilename == nil or baseFilename == "" then

		Logging.xmlInfo(mapXml, "No animals xml given at \'map.animals#filename\'")

    else

	    local baseXmlFile = XMLFile.load("animals", Utils.getFilename(baseFilename, baseDirectory))

	    if baseXmlFile ~= nil then
		
            self:loadAnimals(baseXmlFile, baseDirectory)
            baseXmlFile:delete()

	    end

    end

    self.customEnvironment = modName

    print("--------", string.format("RealisticLivestock - loaded %s animals:", #self.types))

    for _, type in pairs(self.types) do
        
        print("", string.format("- Animal Type: %s (%s subTypes)", type.name, #type.subTypes))

        for i, subTypeIndex in pairs(type.subTypes) do

            print(string.format("|--- SubType (%s): %s (%s)", i, self.subTypes[subTypeIndex].name, self.subTypes[subTypeIndex].gender))

        end

    end

    print("", "--------")

    self:loadColourConfigurations()

	return #self.types > 0

end

AnimalSystem.loadMapData = Utils.overwrittenFunction(AnimalSystem.loadMapData, RealisticLivestock_AnimalSystem.loadMapData)


function RealisticLivestock_AnimalSystem:loadAnimals(_, xmlFile, directory)

	for _, key in xmlFile:iterator("animals.animal") do

		if #self.types >= 2 ^ AnimalSystem.SEND_NUM_BITS - 1 then
			Logging.xmlWarning(xmlFile, "Maximum number of supported animal types reached. Ignoring remaining types")
			return
		end

		local rawName = xmlFile:getString(key .. "#type")

		if rawName == nil then
			Logging.xmlError(xmlFile, "Missing animal type. \'%s\'", key)
			return
		end

		local name = rawName:upper()
        local rawConfigFilename = xmlFile:getString(key .. ".configFilename")

		if rawConfigFilename == nil then
			Logging.xmlError(xmlFile, "Missing config file for animal type \'%s\'. \'%s\'", name, key)
			return
		end

        local configFilename = Utils.getFilename(rawConfigFilename, directory)
        local animalType

		if self.nameToTypeIndex[name] ~= nil then

			animalType = self.nameToType[name]

        else

            local clusterClass = xmlFile:getString(key .. "#clusterClass")

		    if clusterClass == nil then
			    Logging.xmlError(xmlFile, "Missing animal clusterClass for \'%s\'!", key)
			    return
		    end

		    local statsBreedingName = xmlFile:getString(key .. "#statsBreeding")
		    local title = g_i18n:convertText(xmlFile:getString(key .. "#groupTitle"), self.customEnvironment)
		    local height = xmlFile:getFloat(key .. ".navMeshAgent#height")
		    local radius = xmlFile:getFloat(key .. ".navMeshAgent#radius")
		    local maxClimbMeters = xmlFile:getFloat(key .. ".navMeshAgent#maxClimbMeters")
		    local maxSlope = math.rad(xmlFile:getFloat(key .. ".navMeshAgent#maxSlope") or 15)
		    local sqmPerAnimal = xmlFile:getFloat(key .. ".pasture#sqmPerAnimal", 100)
            local averageBuyAge = xmlFile:getInt(key .. "#averageBuyAge", 12)
            local maxBuyAge = xmlFile:getInt(key .. "#maxBuyAge", 60)

            local averageChildren = xmlFile:getInt(key .. ".pregnancy#average", 1)
            local maxChildren = xmlFile:getInt(key .. ".pregnancy#max", 3)

            local pregnancy = {}
            local totalChance = 0

            for i = 0, averageChildren - 1 do

                totalChance = totalChance + (i / averageChildren) / maxChildren

                table.insert(pregnancy, totalChance)

            end

            totalChance = totalChance + 0.5
            table.insert(pregnancy, totalChance)

            for i = averageChildren + 1, maxChildren - 1 do

                totalChance = totalChance + (1 - totalChance) * 0.8

                table.insert(pregnancy, totalChance)

            end

            table.insert(pregnancy, 1)

            local function pregnancyFunction(value)

                for i = 0, #pregnancy - 1 do

                    if pregnancy[i + 1] > value then return i end

                end

                return 0

            end

            local fertility = self:loadAnimCurve(xmlFile, key .. ".fertility")

		    animalType = {
			    ["name"] = name,
			    ["groupTitle"] = title,
			    ["typeIndex"] = #self.types + 1,
			    ["configFilename"] = configFilename,
			    ["clusterClass"] = clusterClass == "AnimalCluster" and AnimalCluster or AnimalClusterHorse,
			    ["statsBreedingName"] = statsBreedingName,
			    ["navMeshAgentAttributes"] = {
				    ["height"] = height,
				    ["radius"] = radius,
				    ["maxClimbMeters"] = maxClimbMeters,
				    ["maxSlope"] = maxSlope
			    },
                ["sqmPerAnimal"] = sqmPerAnimal,
			    ["subTypes"] = {},
                ["animals"] = {},
                ["averageBuyAge"] = averageBuyAge,
                ["maxBuyAge"] = maxBuyAge,
                ["colours"] = {
                    ["earTagLeft"] = { 0.8, 0.7, 0 },
                    ["earTagRight"] = { 0.8, 0.7, 0 },
                    ["earTagLeft_text"] = { 0, 0, 0 },
                    ["earTagRight_text"] = { 0, 0, 0 }
                },
                ["pregnancy"] = {
                    ["get"] = pregnancyFunction,
                    ["average"] = averageChildren
                },
                ["fertility"] = fertility,
                ["breeds"] = {}
		    }
            
		end

		if self:loadAnimalConfig(animalType, directory, configFilename) then

		    if self:loadSubTypes(animalType, xmlFile, key, directory) then

			    if self.nameToType[name] == nil then

                    table.insert(self.types, animalType)
			        self.nameToType[name] = animalType
			        self.nameToTypeIndex[name] = animalType.typeIndex
			        self.typeIndexToName[animalType.typeIndex] = name

                end

		    end

        end

	end

end

AnimalSystem.loadAnimals = Utils.overwrittenFunction(AnimalSystem.loadAnimals, RealisticLivestock_AnimalSystem.loadAnimals)


function RealisticLivestock_AnimalSystem:loadAnimalConfig(_, animalType, directory, configFilename)

    local xmlFile = XMLFile.load("animalsConfig", configFilename)

	if xmlFile == nil then return false end

	for _, key in xmlFile:iterator("animalHusbandry.animals.animal") do

        local filename = xmlFile:getString(key .. ".assets#filename")

		local animal = {
			["filename"] = Utils.getFilename(filename, directory),
			["filenamePosed"] = Utils.getFilename(xmlFile:getString(key .. ".assets#filenamePosed"), directory)
		}

        if directory ~= modDirectory and string.contains(filename, "$dataS") then continue end

		if animal.filenamePosed == nil then
			Logging.xmlError(xmlFile, "Missing \'filenamePosed\' for animal \'%s\'", key)
			animal.filenamePosed = animal.filename
		end

		animal.variations = {}

		for _, variationKey in xmlFile:iterator(key .. ".assets.texture") do

			local variation = {}

			local numTilesU = xmlFile:getInt(variationKey .. "#numTilesU", 1)
			variation.numTilesU = math.max(numTilesU, 1)

			local tileUIndex = xmlFile:getInt(variationKey .. "#tileUIndex", 0)
			variation.tileUIndex = math.clamp(tileUIndex, 0, variation.numTilesU - 1)

			local numTilesV = xmlFile:getInt(variationKey .. "#numTilesV", 1)
			variation.numTilesV = math.max(numTilesV, 1)

			local tileVIndex = xmlFile:getInt(variationKey .. "#tileVIndex", 0)
			variation.tileVIndex = math.clamp(tileVIndex, 0, variation.numTilesV - 1)

			variation.mirrorV = xmlFile:getBool(variationKey .. "#mirrorV", false)
			variation.multi = xmlFile:getBool(variationKey .. "#multi", true)

			table.insert(animal.variations, variation)

		end

		table.insert(animalType.animals, animal)

	end

	xmlFile:delete()

	return true

end

AnimalSystem.loadAnimalConfig = Utils.overwrittenFunction(AnimalSystem.loadAnimalConfig, RealisticLivestock_AnimalSystem.loadAnimalConfig)


function RealisticLivestock_AnimalSystem:loadSubTypes(_, animalType, xmlFile, key, directory)

    for _, subTypeKey in xmlFile:iterator(key .. ".subType") do

		local rawName = xmlFile:getString(subTypeKey .. "#subType")

		if rawName == nil then
			Logging.xmlError(xmlFile, "Missing animal subtype. \'%s\'", subTypeKey)
			break
		end

		local name = rawName:upper()

		if self.nameToSubTypeIndex[name] ~= nil then continue end

		local fillTypeName = xmlFile:getString(subTypeKey .. "#fillTypeName")
		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

		if fillTypeIndex == nil then
			Logging.xmlError(xmlFile, "FillType \'%s\' for animal subtype \'%s\' not defined!", fillTypeName, subTypeKey)
			break
		end

		local subType = {
			["name"] = name,
			["subTypeIndex"] = #self.subTypes + 1,
			["fillTypeIndex"] = fillTypeIndex,
			["typeIndex"] = animalType.typeIndex,
			["statsBreedingName"] = xmlFile:getString(subTypeKey .. "#statsBreeding") or animalType.statsBreedingName
		}

		table.insert(animalType.subTypes, subType.subTypeIndex)

		if self:loadSubType(animalType, subType, xmlFile, subTypeKey, directory) then

			table.insert(self.subTypes, subType)
			self.nameToSubType[name] = subType
			self.nameToSubTypeIndex[name] = subType.subTypeIndex
			self.fillTypeIndexToSubType[fillTypeIndex] = subType

            local breed = xmlFile:getString(subTypeKey .. "#breed", "OTHER")
            subType.breed = breed

            if animalType.breeds[breed] == nil then animalType.breeds[breed] = {} end

            table.insert(animalType.breeds[breed], subType)

		end

	end

	return true

end

AnimalSystem.loadSubTypes = Utils.overwrittenFunction(AnimalSystem.loadSubTypes, RealisticLivestock_AnimalSystem.loadSubTypes)


function RealisticLivestock_AnimalSystem:loadSubType(superFunc, animalType, subType, xmlFile, key, directory)

    local returnValue = superFunc(self, animalType, subType, xmlFile, key, directory)

    local height, radius = animalType.navMeshAgentAttributes.height, animalType.navMeshAgentAttributes.radius

    subType.gender = xmlFile:getString(key .. "#gender", "female")

    if directory ~= modDirectory and subType.gender == "female" then subType.gender = string.contains(subType.name, "_MALE") and "male" or "female" end

    subType.maxWeight = xmlFile:getFloat(key .. "#maxWeight", height * radius * 750)
    subType.targetWeight = xmlFile:getFloat(key .. "#targetWeight", height * radius * 300)
    subType.minWeight = xmlFile:getFloat(key .. "#minWeight", height * radius * 50)

    return returnValue

end

AnimalSystem.loadSubType = Utils.overwrittenFunction(AnimalSystem.loadSubType, RealisticLivestock_AnimalSystem.loadSubType)


function RealisticLivestock_AnimalSystem:loadVisualData(superFunc, animalType, xmlFile, key, baseDirectory)

    local visualData = superFunc(self, animalType, xmlFile, key, baseDirectory)

    if visualData == nil then return nil end

    local earTagLeft = xmlFile:getString(key .. "#earTagLeft", nil)
    local earTagRight = xmlFile:getString(key .. "#earTagRight", nil)
    local noseRing = xmlFile:getString(key .. "#noseRing", nil)
    local bumId = xmlFile:getString(key .. "#bumId", nil)
    local monitor = xmlFile:getString(key .. "#monitor", nil)
    local marker = xmlFile:getString(key .. "#marker", nil)

    if earTagLeft ~= nil then visualData.earTagLeft = earTagLeft end
    if earTagRight ~= nil then visualData.earTagRight = earTagRight end
    if noseRing ~= nil then visualData.noseRing = noseRing end
    if bumId ~= nil then visualData.bumId = bumId end
    if monitor ~= nil then visualData.monitor = monitor end
    if marker ~= nil then visualData.marker = marker end

    return visualData

end

AnimalSystem.loadVisualData = Utils.overwrittenFunction(AnimalSystem.loadVisualData, RealisticLivestock_AnimalSystem.loadVisualData)


function AnimalSystem:initialiseCountries()

    self.maxDealerAnimals = self.maxDealerAnimals or 40
    self.countries = {}
    self.animals = {}
    self.aiAnimals = {}

    for _, animalType in pairs(self.types) do
        self.animals[animalType.typeIndex] = {}
        self.aiAnimals[animalType.typeIndex] = {}
    end


    for countryIndex, country in pairs(RealisticLivestock.AREA_CODES) do

        self.countries[countryIndex] = {
            ["index"] = countryIndex,
            ["farms"] = {}
        }

    end

    MoneyType.MONITOR_SUBSCRIPTIONS = MoneyType.register("monitorSubscriptions", "rl_ui_monitorSubscriptions")
    MoneyType.LAST_ID = MoneyType.LAST_ID + 1

    if self.isServer then g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self) end
    g_messageCenter:subscribe(MessageType.DAY_CHANGED, self.onDayChanged, self)
    g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.onPeriodChanged, self)

end


function AnimalSystem:validateFarms(hasData)

    if self.countries == nil then self.countries = {} end

    local animalTypeIndexes = {}

    for _, animalType in pairs(self.types) do table.insert(animalTypeIndexes, animalType.typeIndex) end

    
    -- validate every country exists


    for countryIndex, info in pairs(RealisticLivestock.AREA_CODES) do

        if self.countries[countryIndex] == nil then

            self.countries[countryIndex] = {
                ["index"] = countryIndex,
                ["farms"] = {}
            }

        end

    end


    -- validate all countries have at least 20 unique farms

    local mapCountryIndex = RealisticLivestock.getMapCountryIndex()


    for _, country in pairs(self.countries) do

        local farmIds = {}
        local farmsRequireId = {}

        if country.index == mapCountryIndex then

            for i, farm in pairs(g_farmManager.farms) do

                local statistics = farm.stats.statistics

                if statistics.farmId ~= nil then table.insert(farmIds, statistics.farmId) end

            end

        end

        local isFirstCreation = #country.farms == 0

        if #country.farms < 20 then

            for i = #country.farms + 1, 20 do

                local farm = { ["quality"] = math.random(250, 1750) / 1000, ["ids"] = {} }

                farm.semenPrice = (math.random(75, 125) / 100) * farm.quality

                for i = 0, math.random(0, math.min(3, #animalTypeIndexes)) do

                    --local randomProduce = math.random()
                    --local baseChance = 1 / (5 - i)

                    --if farm.cowId == nil and randomProduce <= baseChance then
                    --    farm.cowId = 0
                    --elseif farm.pigId == nil and randomProduce <= baseChance * (farm.cowId == nil and 2 or 1) then
                    --    farm.pigId = 0
                    --elseif farm.sheepId == nil and randomProduce <= baseChance * ((farm.cowId == nil and farm.pigId == nil and 3) or ((farm.cowId == nil or farm.pigId == nil) and 2) or 1) then
                    --    farm.sheepId = 0
                    --elseif farm.chickenId == nil and randomProduce <= baseChance * ((farm.cowId == nil and farm.pigId == nil and farm.sheepId == nil and 4) or (i == 1 and farm.horseId == nil and 3) or 2) then
                    --    farm.chickenId = 0
                    --else
                    --    farm.horseId = 0
                    --end

                    local randomAnimalTypeIndex = animalTypeIndexes[math.random(1, #animalTypeIndexes)]
                    local attempts = 0

                    while farm.ids[randomAnimalTypeIndex] ~= nil do

                        randomAnimalTypeIndex = animalTypeIndexes[math.random(1, #animalTypeIndexes)]
                        attempts = attempts + 1

                        if attempts > 20 then break end

                    end

                    farm.ids[randomAnimalTypeIndex] = 0

                end

                table.insert(country.farms, farm)

            end

            if isFirstCreation and country.index == mapCountryIndex then
                
                -- validate there is at least 1 farm that produces each animal type

                for i = 1, #animalTypeIndexes do

                    local randomFarmIndex = math.random(1, #country.farms)
                    country.farms[randomFarmIndex].ids[i] = country.farms[randomFarmIndex].ids[i] or 0
        
                    --if i == 1 then country.farms[randomFarmIndex].cowId = country.farms[randomFarmIndex].cowId or 0 end
                    --if i == 2 then country.farms[randomFarmIndex].pigId = country.farms[randomFarmIndex].pigId or 0 end
                    --if i == 3 then country.farms[randomFarmIndex].sheepId = country.farms[randomFarmIndex].sheepId or 0 end
                    --if i == 4 then country.farms[randomFarmIndex].chickenId = country.farms[randomFarmIndex].chickenId or 0 end
                    --if i == 5 then country.farms[randomFarmIndex].horseId = country.farms[randomFarmIndex].horseId or 0 end

                end

            end

        end


        for i, farm in pairs(country.farms) do
            if farm.id ~= nil then
                table.insert(farmIds, farm.id) 
            else
                table.insert(farmsRequireId, i) 
            end
        end


        for _, farmIndex in pairs(farmsRequireId) do

            local farmId = math.random(100000, 999999)

            while table.find(farmIds, farmId) ~= nil do farmId = math.random(100000, 999999) end

            country.farms[farmIndex].id = farmId
            table.insert(farmIds, farmId)

        end

    end



    -- validate there are at least 25 animals of each type for sale

    if not hasData then
    
        for animalTypeIndex, animals in pairs(self.animals) do

            if #animals < self.maxDealerAnimals then

                for i = #animals + 1, self.maxDealerAnimals do

                    local animal = self:createNewSaleAnimal(animalTypeIndex)

                    if animal ~= nil then table.insert(animals, animal) end

                end

            end

            self.animals[animalTypeIndex] = animals

        end
    
        for animalTypeIndex, animals in pairs(self.aiAnimals) do

            if #animals < 15 then

                for i = #animals + 1, 15 do

                    local animal = self:createNewAIAnimal(animalTypeIndex)

                    if animal ~= nil then table.insert(animals, animal) end

                end

            end

            self.aiAnimals[animalTypeIndex] = animals

        end
   
    end

end


function AnimalSystem:loadColourConfigurations()

    local savegameIndex = g_careerScreen.savegameList.selectedIndex
    local savegame = g_savegameController:getSavegame(savegameIndex)

    if savegame == nil or savegame.savegameDirectory == nil then return false end

    local xmlFile = XMLFile.loadIfExists("animalSystem", savegame.savegameDirectory .. "/animalSystem.xml")

    if xmlFile == nil then return false end

    xmlFile:iterate("animalSystem.animalTypes.type", function(_, key)

        local name = xmlFile:getString(key .. "#name")
        local earTagLeft = xmlFile:getVector(key .. "#earTagLeft", { 0.8, 0.7, 0 })
        local earTagRight = xmlFile:getVector(key .. "#earTagRight", { 0.8, 0.7, 0 })
        local earTagLeftText = xmlFile:getVector(key .. "#earTagLeftText", { 0, 0, 0 })
        local earTagRightText = xmlFile:getVector(key .. "#earTagRightText", { 0, 0, 0 })

        if self.nameToType[name] ~= nil then
            self.nameToType[name].colours.earTagLeft = earTagLeft
            self.nameToType[name].colours.earTagRight = earTagRight
            self.nameToType[name].colours.earTagLeft_text = earTagLeftText
            self.nameToType[name].colours.earTagRight_text = earTagRightText
        end

    end)

    xmlFile:delete()

end


function AnimalSystem:loadFromXMLFile()

    if g_currentMission.missionInfo == nil or g_currentMission.missionInfo.savegameDirectory == nil then return end

    local xmlFile = XMLFile.loadIfExists("animalSystem", g_currentMission.missionInfo.savegameDirectory .. "/animalSystem.xml")

    if xmlFile == nil then return false end


    local hasData = false


    xmlFile:iterate("animalSystem.countries.country", function(_, key)

        local countryIndex = xmlFile:getInt(key .. "#index")
        
        local farms = self.countries[countryIndex].farms

        xmlFile:iterate(key .. ".farm", function(_, farmKey)

            hasData = true

            local farmId = xmlFile:getInt(farmKey .. "#id")
            local cowId = xmlFile:getInt(farmKey .. "#cowId", nil)
            local pigId = xmlFile:getInt(farmKey .. "#pigId", nil)
            local sheepId = xmlFile:getInt(farmKey .. "#sheepId", nil)
            local horseId = xmlFile:getInt(farmKey .. "#horseId", nil)
            local chickenId = xmlFile:getInt(farmKey .. "#chickenId", nil)
            local quality = xmlFile:getFloat(farmKey .. "#quality", math.random(250, 1750) / 1000)
            local semenPrice = xmlFile:getFloat(farmKey .. "#semenPrice", (math.random(75, 125) / 100) * quality)
            
            local ids = {}

            -- compatibility with previous builds

            if cowId ~= nil then ids[1] = cowId end
            if pigId ~= nil then ids[2] = pigId end
            if sheepId ~= nil then ids[3] = sheepId end
            if horseId ~= nil then ids[4] = horseId end
            if chickenId ~= nil then ids[5] = chickenId end

            xmlFile:iterate(farmKey .. ".id", function(_, idKey)
            
                local animalTypeIndex = xmlFile:getInt(idKey .. "#type", 1)
                local lastId = xmlFile:getInt(idKey .. "#id", 0)

                ids[animalTypeIndex] = lastId
            
            end)
            
            --table.insert(farms, { ["id"] = farmId, ["quality"] = quality, ["cowId"] = cowId, ["pigId"] = pigId, ["sheepId"] = sheepId, ["horseId"] = horseId, ["chickenId"] = chickenId })
            table.insert(farms, { ["id"] = farmId, ["quality"] = quality, ["ids"] = ids, ["semenPrice"] = semenPrice })

        end)

        self.countries[countryIndex].farms = farms

    end)


    xmlFile:iterate("animalSystem.animals.animal", function(_, key)

        local animal = Animal.loadFromXMLFile(xmlFile, key)

        if animal ~= nil then
            local animalTypeIndex = animal.animalTypeIndex

            animal.sale = {
                ["day"] = xmlFile:getInt(key .. ".sale#day", 1),
                --["month"] = xmlFile:getInt(key .. ".sale#month"),
                --["year"] = xmlFile:getInt(key .. ".sale#year")
            }

            table.insert(self.animals[animalTypeIndex], animal)
        end

    end)


    xmlFile:iterate("animalSystem.aiAnimals.animal", function(_, key)

        local animal = Animal.loadFromXMLFile(xmlFile, key)

        if animal ~= nil then

            animal.favouritedBy = {}
            animal.success = xmlFile:getFloat(key .. "#success", 0.65)
            animal.isAIAnimal = true

            xmlFile:iterate(key .. ".favourites.player", function(_, favKey)
                local userId = xmlFile:getString(favKey .. "#userId", nil)
                local value = xmlFile:getBool(favKey .. "#value", false)
                if userId ~= nil then animal.favouritedBy[userId] = value end
            end)

            local animalTypeIndex = animal.animalTypeIndex
            table.insert(self.aiAnimals[animalTypeIndex], animal)

        end

    end)


    xmlFile:delete()

    return hasData

end


function AnimalSystem:saveToXMLFile(path)

	if path == nil then return end

    local xmlFile = XMLFile.create("animalSystem", path, "animalSystem")
    if xmlFile == nil then return end


    xmlFile:setSortedTable("animalSystem.animalTypes.type", self.types, function (key, type)

        xmlFile:setString(key .. "#name", type.name)
        xmlFile:setVector(key .. "#earTagLeft", type.colours.earTagLeft)
        xmlFile:setVector(key .. "#earTagLeftText", type.colours.earTagLeft_text)
        xmlFile:setVector(key .. "#earTagRight", type.colours.earTagRight)
        xmlFile:setVector(key .. "#earTagRightText", type.colours.earTagRight_text)

    end)

    
    xmlFile:setSortedTable("animalSystem.countries.country", self.countries, function (key, country)

        xmlFile:setInt(key .. "#index", country.index)

        for i = 1, #country.farms do

            local farmKey = string.format("%s.farm(%d)", key, i - 1)
            local farm = country.farms[i]
            
            xmlFile:setInt(farmKey .. "#id", farm.id)
            xmlFile:setFloat(farmKey .. "#quality", farm.quality)
            xmlFile:setFloat(farmKey .. "#semenPrice", farm.semenPrice)

            local j = 0

            for animalTypeIndex, id in pairs(farm.ids) do

                local idKey = farmKey .. ".id( " .. j .. ")"

                xmlFile:setInt(idKey .. "#type", animalTypeIndex)
                xmlFile:setInt(idKey .. "#id", id)

                j = j + 1

            end

        end

    end)


    local allAnimals = {}

    for _, animals in pairs(self.animals) do

        for _, animal in pairs(animals) do
            if animal.sale ~= nil and animal.sale.day ~= nil then table.insert(allAnimals, animal) end
        end
        
    end

    
    xmlFile:setSortedTable("animalSystem.animals.animal", allAnimals, function (key, animal)

        animal:saveToXMLFile(xmlFile, key)
        xmlFile:setInt(key .. ".sale#day", animal.sale.day)
        --xmlFile:setInt(key .. ".sale#month", animal.sale.month)
        --xmlFile:setInt(key .. ".sale#year", animal.sale.year)

    end)


    local allAIAnimals = {}

    for _, animals in pairs(self.aiAnimals) do

        for _, animal in pairs(animals) do table.insert(allAIAnimals, animal) end
        
    end

    
    xmlFile:setSortedTable("animalSystem.aiAnimals.animal", allAIAnimals, function (key, animal)

        animal:saveToXMLFile(xmlFile, key)

        xmlFile:setFloat(key .. "#success", animal.success or 0.65)
        
        local i = 0

        for userId, value in pairs(animal.favouritedBy) do
            
            if not value then continue end

            local favKey = string.format("%s.favourites.player(%s)", key, i)
            xmlFile:setString(favKey .. "#userId", userId)
            xmlFile:setBool(favKey .. "#value", true)

            i = i + 1

        end

    end)

    xmlFile:save(false, true)
    xmlFile:delete()

end


function AnimalSystem:createNewSaleAnimal(animalTypeIndex)

    local animalType = self:getTypeByIndex(animalTypeIndex)

    if animalType == nil then return nil end

    local subTypeIndex = animalType.subTypes[math.random(1, #animalType.subTypes)]
    local subType = self:getSubTypeByIndex(subTypeIndex)
    
    local farmId, farmQuality, farmCountryIndex, lastAnimalId
    local attemptedCountryIndexes = {}

    
    while farmId == nil do

        if #attemptedCountryIndexes == #self.countries then return nil end

        local countryIndex

        if #attemptedCountryIndexes == 0 and math.random() >= 0.12 then
            countryIndex = RealisticLivestock.getMapCountryIndex()
        else
            countryIndex = math.random(1, #self.countries)
            while table.find(attemptedCountryIndexes, countryIndex) ~= nil do
                countryIndex = math.random(1, #self.countries)
            end
        end

        table.insert(attemptedCountryIndexes, countryIndex)

        local country = self.countries[countryIndex]
        local validFarms = {}

        for i = 1, #country.farms do
        
            local farm = country.farms[i]

            --if animalTypeIndex == AnimalType.COW and farm.cowId ~= nil then
            --    table.insert(validFarms, i)
            --    continue
            --end

            --if animalTypeIndex == AnimalType.PIG and farm.pigId ~= nil then
            --    table.insert(validFarms, i)
            --    continue
            --end

            --if animalTypeIndex == AnimalType.SHEEP and farm.sheepId ~= nil then
            --    table.insert(validFarms, i)
            --    continue
            --end

            --if animalTypeIndex == AnimalType.CHICKEN and farm.chickenId ~= nil then
            --    table.insert(validFarms, i)
            --    continue
            --end

            --if animalTypeIndex == AnimalType.HORSE and farm.horseId ~= nil then
            --    table.insert(validFarms, i)
            --end

            if farm.ids[animalTypeIndex] ~= nil then table.insert(validFarms, i) end

        end

        if #validFarms == 0 then continue end

        local farmIndex = validFarms[math.random(1, #validFarms)]
        local farm = country.farms[farmIndex]

        farmId = farm.id
        farmQuality = farm.quality
        farmCountryIndex = countryIndex
        
        --if animalTypeIndex == AnimalType.COW then
        --    country.farms[farmIndex].cowId = farm.cowId + 1
        --    lastAnimalId = country.farms[farmIndex].cowId
        --elseif animalTypeIndex == AnimalType.PIG then
        --    country.farms[farmIndex].pigId = farm.pigId + 1
        --    lastAnimalId = country.farms[farmIndex].pigId
        --elseif animalTypeIndex == AnimalType.SHEEP then
        --    country.farms[farmIndex].sheepId = farm.sheepId + 1
        --    lastAnimalId = country.farms[farmIndex].sheepId
        --elseif animalTypeIndex == AnimalType.CHICKEN then
        --    country.farms[farmIndex].chickenId = farm.chickenId + 1
        --    lastAnimalId = country.farms[farmIndex].chickenId
        --elseif animalTypeIndex == AnimalType.HORSE then
        --    country.farms[farmIndex].horseId = farm.horseId + 1
        --    lastAnimalId = country.farms[farmIndex].horseId
        --end

        farm.ids[animalTypeIndex] = (farm.ids[animalTypeIndex] or 0) + 1
        lastAnimalId = farm.ids[animalTypeIndex]

    end


    local averageBuyAge = animalType.averageBuyAge or 12
    local maxBuyAge = animalType.maxBuyAge or 60
    local age

    if math.random() >= 0.5 then

        age = math.random(averageBuyAge * 0.85, averageBuyAge * 1.15)

    elseif math.random() >= 0.25 then

        age = math.random(0, averageBuyAge * 0.85)

    else

        age = math.random(averageBuyAge * 1.15, maxBuyAge)

    end

    age = math.clamp(age, 0, maxBuyAge)
    local viableReproductionMonths = age - (subType.reproductionMinAgeMonth + subType.reproductionDurationMonth)
    local isParent, isPregnant, monthsSinceLastBirth = false, false, 12
    local animalGender = subType.gender


    if viableReproductionMonths >= 0 and math.random(0, 100) <= viableReproductionMonths then
        isParent = true
        monthsSinceLastBirth = math.random(0, viableReproductionMonths)
    end

    if animalGender == "female" and age - subType.reproductionMinAgeMonth >= 0 and math.random() >= 0.95 then isPregnant = true end



    local uniqueId = tostring(lastAnimalId)
    local idLen = string.len(uniqueId)

    if idLen < 5 then
        if idLen == 1 then
            uniqueId = "1000" .. uniqueId
        elseif idLen == 2 then
            uniqueId = "100" .. uniqueId
        elseif idLen == 3 then
            uniqueId = "10" .. uniqueId
        elseif idLen == 4 then
            uniqueId = "1" .. uniqueId
        end
    end

    local concatenatedId = farmId .. uniqueId
    local checkDigit = (tonumber(concatenatedId)::number % 7) + 1
    uniqueId = checkDigit .. uniqueId


    local geneticsModifier = farmQuality * 1000
    local genetics = {
        ["metabolism"] = math.clamp(math.random(geneticsModifier - 300, geneticsModifier + 300) / 1000, 0.25, 1.75),
        ["quality"] = math.clamp(math.random(geneticsModifier - 300, geneticsModifier + 300) / 1000, 0.25, 1.75),
        ["fertility"] = math.clamp(math.random(geneticsModifier - 300, geneticsModifier + 300) / 1000, 0.25, 1.75),
        ["health"] = math.clamp(math.random(geneticsModifier - 300, geneticsModifier + 300) / 1000, 0.25, 1.75)
    }

    if animalTypeIndex == AnimalType.COW or animalTypeIndex == AnimalType.SHEEP or animalTypeIndex == AnimalType.CHICKEN then genetics.productivity = math.clamp(math.random(geneticsModifier - 300, geneticsModifier + 300) / 1000, 0.25, 1.75) end

  
    local name
    
    if math.random() >= 0.85 then name = g_currentMission.animalNameSystem:getRandomName(animalGender) end


    local animal = Animal.new(age, math.clamp((math.random(650, 1000) / 10) * genetics.health, 0, 100), monthsSinceLastBirth, animalGender, subTypeIndex, 0, isParent, isPregnant, animalTypeIndex == AnimalType.COW and animalGender == "female" and isParent and monthsSinceLastBirth < 10, nil, nil, nil, nil, nil, name, nil, nil, nil, nil, nil, genetics)

    animal.farmId = tostring(farmId)
    animal.uniqueId = uniqueId
    animal.birthday.country = farmCountryIndex

    local variations = self:getVisualByAge(subTypeIndex, age).visualAnimal.variations
    local variationIndex = 1

    if #variations > 1 then variationIndex = math.random(1, #variations) end

    animal.variation = variationIndex

    local environment = g_currentMission.environment
    local month = environment.currentPeriod + 2

    if month > 12 then month = month - 12 end

    local day = 1 + math.floor((environment.currentDayInPeriod - 1) * (RealisticLivestock.DAYS_PER_MONTH[month] / environment.daysPerPeriod))
    local year = environment.currentYear


    animal.diseases = {}

    g_diseaseManager:onDayChanged(animal)
    g_diseaseManager:setGeneticDiseasesForSaleAnimal(animal)


    if isPregnant then

        local childNum = animal:generateRandomOffspring()
        local children = {}

        local minMetabolism, maxMetabolism = genetics.metabolism * 0.9, genetics.metabolism * 1.1
        local minMeat, maxMeat = genetics.quality * 0.9, genetics.quality * 1.1
        local minHealth, maxHealth = genetics.health * 0.9, genetics.health * 1.1
        local minFertility, maxFertility = genetics.fertility * 0.9, genetics.fertility * 1.1
        local minProductivity, maxProductivity
        
        if genetics.productivity ~= nil then minProductivity, maxProductivity = genetics.productivity * 0.9, genetics.productivity * 1.1 end

        for i = 1, childNum do

            local gender = math.random() >= 0.5 and "male" or "female"
            local childSubTypeIndex = subTypeIndex + (gender == "male" and 1 or 0)


            local child = Animal.new(-1, 100, 0, gender, childSubTypeIndex, 0, false, false, false, nil, nil, animal.farmId .. " " .. animal.uniqueId)
                        
            local metabolism = math.random(minMetabolism * 100, maxMetabolism * 100) / 100
            local quality = math.random(minMeat * 100, maxMeat * 100) / 100
            local healthGenetics = math.random(minHealth * 100, maxHealth * 100) / 100
            local fertility = math.random(minFertility * 100, maxFertility * 100) / 100
            local productivity = nil
                        
            if genetics.productivity ~= nil then productivity = math.clamp(math.random(minProductivity * 100, maxProductivity * 100) / 100, 0.25, 1.75) end


            child:setGenetics({
                ["metabolism"] = math.clamp(metabolism, 0.25, 1.75),
                ["quality"] = math.clamp(quality, 0.25, 1.75),
                ["health"] = math.clamp(healthGenetics, 0.25, 1.75),
                ["fertility"] = math.clamp(fertility, 0.25, 1.75),
                ["productivity"] = productivity
            })
        
        
            for _, disease in pairs(animal.diseases) do

                disease:affectReproduction(child)

            end


            table.insert(children, child)

        end


        local reproductionDuration = subType.reproductionDurationMonth
                    
        if math.random() >= 0.99 then

            if math.random() >= 0.95 then
                reproductionDuration = reproductionDuration + math.random() >= 0.75 and -2 or 2
            else
                reproductionDuration = reproductionDuration + math.random() >= 0.85 and -1 or 1
            end

            reproductionDuration = math.max(reproductionDuration, 2)

        end

        local expectedYear = year + math.floor(reproductionDuration / 12)
        local expectedMonth = month + (reproductionDuration % 12)

        while expectedMonth > 12 do
            expectedMonth = expectedMonth - 12
            expectedYear = expectedYear + 1
        end

        local expectedDay = math.random(1, RealisticLivestock.DAYS_PER_MONTH[expectedMonth])

        if #children > 0 then

            animal.pregnancy = {
                ["duration"] = reproductionDuration,
                ["expected"] = {
                    ["day"] = expectedDay,
                    ["month"] = expectedMonth,
                    ["year"] = expectedYear
                },
                ["pregnancies"] = children
            }

        end

    end

    animal.sale = {
        --["day"] = day,
        --["month"] = month,
        --["year"] = year
        ["day"] = environment.currentMonotonicDay
    }

    if animal.reproduction > 0 and (animal.pregnancy == nil or #animal.pregnancy.pregnancies == 0) then
        animal.reproduction = 0
        animal.pregnancy = nil
    end

    return animal

end


function AnimalSystem:getSaleAnimalsByTypeIndex(animalTypeIndex)

    return self.animals[animalTypeIndex] or {}

end


function AnimalSystem:getAIAnimalsByTypeIndex(animalTypeIndex)

    return self.aiAnimals[animalTypeIndex] or {}

end


function AnimalSystem:getFarmQuality(country, farmId)

    if self.countries[country] ~= nil then

        local farms = self.countries[country].farms

        if type(farmId) == "string" then farmId = tonumber(farmId) end

        for _, farm in pairs(farms) do

            if farm.id == farmId then return farm.quality end

        end

    end

    return 1

end


function AnimalSystem:getFarmSemenPrice(country, farmId)

    if self.countries[country] ~= nil then

        local farms = self.countries[country].farms

        if type(farmId) == "string" then farmId = tonumber(farmId) end

        for _, farm in pairs(farms) do

            if farm.id == farmId then return farm.semenPrice end

        end

    end

    return 1

end


function AnimalSystem:getNextAnimalIdForFarm(countryIndex, animalTypeIndex, farmId)

    local country = self.countries[countryIndex]

    if country == nil then return 1 end

    local farms = country.farms

    if type(farmId) == "string" then farmId = tonumber(farmId) end

    for _, farm in pairs(farms) do

        if farm.id == farmId then

            --local index = "cowId"

            --if animalTypeIndex == AnimalType.PIG then
            --    index = "pigId"
            --elseif animalTypeIndex == AnimalType.SHEEP then
            --    index = "sheepId"
            --elseif animalTypeIndex == AnimalType.CHICKEN then
            --    index = "chickenId"
            --elseif animalTypeIndex == AnimalType.HORSE then
            --    index = "horseId"
            --end

            --if farm[index] ~= nil then
            --    farm[index] = farm[index] + 1
            --    return farm[index]
            --end

            if farm.ids[animalTypeIndex] ~= nil then

                farm.ids[animalTypeIndex] = farm.ids[animalTypeIndex] + 1
                return farm.ids[animalTypeIndex]

            end

            return 1

        end

    end

    return 1

end


function AnimalSystem:removeSaleAnimal(animalTypeIndex, countryIndex, farmId, uniqueId)

    for i, animal in pairs(self.animals[animalTypeIndex]) do

        if animal.birthday.country == countryIndex and animal.farmId == farmId and animal.uniqueId == uniqueId then
            table.remove(self.animals[animalTypeIndex], i)
            return
        end

    end

end


function AnimalSystem:removeAIAnimal(animalTypeIndex, countryIndex, farmId, uniqueId)

    for i, animal in pairs(self.aiAnimals[animalTypeIndex]) do

        if animal.birthday.country == countryIndex and animal.farmId == farmId and animal.uniqueId == uniqueId then
            table.remove(self.aiAnimals[animalTypeIndex], i)
            return
        end

    end

end


function AnimalSystem:onHourChanged()

    local day = g_currentMission.environment.currentMonotonicDay
    local hasChanges = false

    for animalTypeIndex, animals in pairs(self.animals) do

        local indexesToRemove = {}

        for i, animal in pairs(animals) do

            if animal.sale ~= nil then

                local saleDay = animal.sale.day

                if saleDay == day then continue end

                local geneticQuality = 0
                local totalGenetics = 0

                for _, value in pairs(animal.genetics) do
                    if value ~= nil then
                        totalGenetics = totalGenetics + 1
                        geneticQuality = geneticQuality + value
                    end
                end

                local averageGenetics = geneticQuality / totalGenetics

                if math.random() >= (saleDay / day) / (averageGenetics * 1.45) then
                    table.insert(indexesToRemove, i)
                    hasChanges = true
                end

            end

        end

        for i = #indexesToRemove, 1, -1 do
            table.remove(animals, indexesToRemove[i])
        end

        local threshold = math.random(10, self.maxDealerAnimals)

        if #animals < threshold then

            for i = #animals + 1, threshold do

                local animal = self:createNewSaleAnimal(animalTypeIndex)

                if animal ~= nil then
                    table.insert(animals, animal)
                    hasChanges = true
                end

            end

        end
    
    end

    for animalTypeIndex, animals in pairs(self.aiAnimals) do

        if #animals < 15 then

            for i = #animals + 1, 15 do

                local animal = self:createNewAIAnimal(animalTypeIndex)

                if animal ~= nil then
                    table.insert(animals, animal)
                    hasChanges = true
                end

            end

        end
    
    end

    if hasChanges then g_server:broadcastEvent(AnimalSystemStateEvent.new(self.countries, self.animals)) end

end


function AnimalSystem:onDayChanged()

    local environment = g_currentMission.environment
    local month = environment.currentPeriod + 2
    local currentDayInPeriod = environment.currentDayInPeriod

    if month > 12 then month = month - 12 end

    local daysPerPeriod = environment.daysPerPeriod
    local day = 1 + math.floor((currentDayInPeriod - 1) * (RealisticLivestock.DAYS_PER_MONTH[month] / daysPerPeriod))
    local year = environment.currentYear

    for _, animals in pairs(self.animals) do

        for _, animal in pairs(animals) do

            animal.reserved = false

            animal:onDayChanged(nil, self.isServer, day, month, year, currentDayInPeriod, daysPerPeriod, true)

        end

    end

    for _, animals in pairs(self.aiAnimals) do

        for _, animal in pairs(animals) do animal:onDayChanged(nil, self.isServer, day, month, year, currentDayInPeriod, daysPerPeriod, true) end

    end

end


function AnimalSystem:onPeriodChanged()

    for _, animals in pairs(self.animals) do

        for _, animal in pairs(animals) do

            animal:onPeriodChanged()

        end

    end

    for _, animals in pairs(self.aiAnimals) do

        for _, animal in pairs(animals) do

            animal:onPeriodChanged()

        end

    end

    if self.isServer then

        local monitorCosts = {}

        for _, placeable in pairs(g_currentMission.husbandrySystem.placeables) do

            local animals = placeable:getClusters()
            local ownerFarmId = placeable:getOwnerFarmId()

            for _, animal in pairs(animals) do

                if not animal.monitor.active and not animal.monitor.removed then continue end

                if animal.monitor.removed and not animal.monitor.active then

                    local visualData = self:getVisualByAge(animal.subTypeIndex, animal.age)

                    if visualData.monitor ~= nil and animal.idFull ~= nil and animal.idFull ~= "1-1" then

                        local sep = string.find(animal.idFull, "-")
                        local husbandry = tonumber(string.sub(animal.idFull, 1, sep - 1))
                        local animalId = tonumber(string.sub(animal.idFull, sep + 1))

                        if husbandry ~= 0 and animalId ~= 0 then

                            local rootNode = getAnimalRootNode(husbandry, animalId)

                            if rootNode ~= 0 then

                                local monitorNode = I3DUtil.indexToObject(rootNode, visualData.monitor)

                                if monitorNode ~= nil and monitorNode ~= 0 then setVisibility(monitorNode, false) end

                            end

                        end

                    end
                    
                    animal.monitor.removed = false

                end

                if monitorCosts[ownerFarmId] == nil then monitorCosts[ownerFarmId] = 0 end

                monitorCosts[ownerFarmId] = monitorCosts[ownerFarmId] + animal.monitor.fee

            end

        end

        for ownerFarmId, cost in pairs(monitorCosts) do

            local ownerFarm = g_farmManager:getFarmById(ownerFarmId)

            g_currentMission:addMoneyChange(0 - cost, ownerFarmId, MoneyType.MONITOR_SUBSCRIPTIONS, true)
            ownerFarm:changeBalance(0 - cost, MoneyType.MONITOR_SUBSCRIPTIONS)

        end

    end

end


function AnimalSystem:addExistingSaleAnimal(animal)

    local animalTypeIndex = animal.animalTypeIndex or 0

    if self.animals[animalTypeIndex] ~= nil then table.insert(self.animals[animalTypeIndex], animal) end

end


function AnimalSystem:removeAllSaleAnimals(animalTypeIndex)

    if animalTypeIndex == nil then

        for index, animals in pairs(self.animals) do self.animals[index] = {} end

    elseif self.animals[animalTypeIndex] ~= nil then

        self.animals[animalTypeIndex] = {}

    end

end


function AnimalSystem.onSettingChanged(name, state)

    g_currentMission.animalSystem[name] = state

end


function AnimalSystem.onClickResetDealer()

    local animalSystem = g_currentMission.animalSystem
    
    if not animalSystem.isServer then return end

    animalSystem:removeAllSaleAnimals()

    for animalTypeIndex, animals in pairs(animalSystem.animals) do

        for i = 1, animalSystem.maxDealerAnimals do

            local animal = animalSystem:createNewSaleAnimal(animalTypeIndex)

            if animal ~= nil then table.insert(animals, animal) end

        end

        animalSystem.animals[animalTypeIndex] = animals

    end

end


function AnimalSystem:getBreedsByAnimalTypeIndex(animalTypeIndex)

    return self.types[animalTypeIndex].breeds

end


function AnimalSystem:createNewAIAnimal(animalTypeIndex)

     local animalType = self:getTypeByIndex(animalTypeIndex)

    if animalType == nil then return nil end

    local subTypeIndex = animalType.subTypes[math.random(1, #animalType.subTypes)]

    if self:getSubTypeByIndex(subTypeIndex).gender == "female" then subTypeIndex = subTypeIndex + 1 end

    local subType = self:getSubTypeByIndex(subTypeIndex)
    
    local farmId, farmQuality, farmCountryIndex, lastAnimalId
    local attemptedCountryIndexes = {}
    
    while farmId == nil do

        if #attemptedCountryIndexes == #self.countries then return nil end

        local countryIndex

        if #attemptedCountryIndexes == 0 and math.random() >= 0.12 then
            countryIndex = RealisticLivestock.getMapCountryIndex()
        else
            countryIndex = math.random(1, #self.countries)
            while table.find(attemptedCountryIndexes, countryIndex) ~= nil do
                countryIndex = math.random(1, #self.countries)
            end
        end

        table.insert(attemptedCountryIndexes, countryIndex)

        local country = self.countries[countryIndex]
        local validFarms = {}

        for i = 1, #country.farms do
        
            local farm = country.farms[i]

            if farm.ids[animalTypeIndex] ~= nil and farm.quality >= 1.35 then table.insert(validFarms, i) end

        end

        if #validFarms == 0 then continue end

        local farmIndex = validFarms[math.random(1, #validFarms)]
        local farm = country.farms[farmIndex]

        farmId = farm.id
        farmQuality = farm.quality
        farmCountryIndex = countryIndex

        farm.ids[animalTypeIndex] = (farm.ids[animalTypeIndex] or 0) + 1
        lastAnimalId = farm.ids[animalTypeIndex]

    end

    local age = math.random(subType.reproductionMinAgeMonth, subType.reproductionMinAgeMonth * 3)

    local uniqueId = tostring(lastAnimalId)
    local idLen = string.len(uniqueId)

    if idLen < 5 then
        if idLen == 1 then
            uniqueId = "1000" .. uniqueId
        elseif idLen == 2 then
            uniqueId = "100" .. uniqueId
        elseif idLen == 3 then
            uniqueId = "10" .. uniqueId
        elseif idLen == 4 then
            uniqueId = "1" .. uniqueId
        end
    end

    local concatenatedId = farmId .. uniqueId
    local checkDigit = (tonumber(concatenatedId)::number % 7) + 1
    uniqueId = checkDigit .. uniqueId


    local geneticsModifier = farmQuality * 1000
    local genetics = {
        ["metabolism"] = math.clamp(math.random(geneticsModifier - 300, geneticsModifier + 300) / 1000, 1.15, 1.75),
        ["quality"] = math.clamp(math.random(geneticsModifier - 300, geneticsModifier + 300) / 1000, 1.15, 1.75),
        ["fertility"] = math.clamp(math.random(geneticsModifier - 300, geneticsModifier + 300) / 1000, 1.15, 1.75),
        ["health"] = math.clamp(math.random(geneticsModifier - 300, geneticsModifier + 300) / 1000, 1.15, 1.75)
    }

    if animalTypeIndex == AnimalType.COW or animalTypeIndex == AnimalType.SHEEP or animalTypeIndex == AnimalType.CHICKEN then genetics.productivity = math.clamp(math.random(geneticsModifier - 300, geneticsModifier + 300) / 1000, 1.15, 1.75) end

  
    local name = g_currentMission.animalNameSystem:getRandomName("male")


    local animal = Animal.new(age, math.clamp((math.random(650, 1000) / 10) * genetics.health, 75, 100), 0, "male", subTypeIndex, 0, false, false, false, nil, nil, nil, nil, nil, name, nil, nil, nil, nil, nil, genetics)

    animal.farmId = tostring(farmId)
    animal.uniqueId = uniqueId
    animal.birthday.country = farmCountryIndex

    local variations = self:getVisualByAge(subTypeIndex, age).visualAnimal.variations
    local variationIndex = 1

    if #variations > 1 then variationIndex = math.random(1, #variations) end

    animal.variation = variationIndex

    animal.favouritedBy = {}
    animal.success = math.clamp((math.random(35, 50) * genetics.fertility) / 100, 0.5, 1)
    animal.isAIAnimal = true

    return animal

end