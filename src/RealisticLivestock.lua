RealisticLivestock = {}

local modDirectory = g_currentModDirectory
local hasLoaded = false



RealisticLivestock.MAP_TO_AREA_CODE = {
    ["Riverbend Springs"] = 2,
    ["Hutan Pantai"] = 3,
    ["Zielonka"] = 5,
    ["Zacieczki"] = 5,
    ["Szpakowo"] = 5,
    ["Pallegney"] = 4,
    ["Oberschwaben"] = 6,
    ["Starowies"] = 5,
    ["Lipinki"] = 5,
    ["Rhönplateu"] = 6,
    ["Schwesing Bahnhof"] = 6,
    ["Riverview"] = 1,
    ["Sobolewo"] = 5,
    ["Tässi Farm"] = 8,
    ["HORSCH AgroVation"] = 10,
    ["New Bartelshagenn"] = 6,
    ["HermannsHausen"] = 5,
    ["Oak Bridge Farm"] = 1,
    ["Calmsden Farm"] = 1,
    ["Frankenmuth Farming Map"] = 2,
    ["North Frisian 25"] = 6,
    ["Alma, Missouri"] = 2,
    ["Michigan Map"] = 2,
}

RealisticLivestock.AREA_CODES = {
    [1] = {
        ["code"] = "UK",
        ["country"] = "United Kingdom"
    },
    [2] = {
        ["code"] = "US",
        ["country"] = "United States"
    },
    [3] = {
        ["code"] = "CH",
        ["country"] = "China"
    },
    [4] = {
        ["code"] = "FR",
        ["country"] = "France"
    },
    [5] = {
        ["code"] = "PL",
        ["country"] = "Poland"
    },
    [6] = {
        ["code"] = "DE",
        ["country"] = "Germany"
    },
    [7] = {
        ["code"] = "CA",
        ["country"] = "Canada"
    },
    [8] = {
        ["code"] = "EE",
        ["country"] = "Estonia"
    },
    [9] = {
        ["code"] = "IT",
        ["country"] = "Italy"
    },
    [10] = {
        ["code"] = "CZ",
        ["country"] = "Czech Republic"
    },
    [11] = {
        ["code"] = "RU",
        ["country"] = "Russia"
    },
    [12] = {
        ["code"] = "SW",
        ["country"] = "Sweden"
    },
    [13] = {
        ["code"] = "NO",
        ["country"] = "Norway"
    },
    [14] = {
        ["code"] = "FI",
        ["country"] = "Finland"
    },
    [15] = {
        ["code"] = "JP",
        ["country"] = "Japan"
    },
    [16] = {
        ["code"] = "SP",
        ["country"] = "Spain"
    }
}


RealisticLivestock.ALPHABET = {
    ["0"] = 0,
    ["1"] = 1,
    ["2"] = 2,
    ["3"] = 3,
    ["4"] = 4,
    ["5"] = 5,
    ["6"] = 6,
    ["7"] = 7,
    ["8"] = 8,
    ["9"] = 9,
    ["A"] = 10,
    ["B"] = 11,
    ["C"] = 12,
    ["D"] = 13,
    ["E"] = 14,
    ["F"] = 15,
    ["G"] = 16,
    ["H"] = 17,
    ["I"] = 18,
    ["J"] = 19,
    ["K"] = 20,
    ["L"] = 21,
    ["M"] = 22,
    ["N"] = 23,
    ["O"] = 24,
    ["P"] = 25,
    ["Q"] = 26,
    ["R"] = 27,
    ["S"] = 28,
    ["T"] = 29,
    ["U"] = 30,
    ["V"] = 31,
    ["W"] = 32,
    ["X"] = 33,
    ["Y"] = 34,
    ["Z"] = 35,
    ["/"] = 36,
    ["-"] = 37
}


RealisticLivestock.NUM_CHARACTERS = 38


RealisticLivestock.DAYS_PER_MONTH = {
    [1] = 31,
    [2] = 28,
    [3] = 31,
    [4] = 30,
    [5] = 31,
    [6] = 30,
    [7] = 31,
    [8] = 31,
    [9] = 30,
    [10] = 31,
    [11] = 30,
    [12] = 31
}


RealisticLivestock.START_YEAR = {
    ["FULL"] = 2024,
    ["PARTIAL"] = 24
}



function RealisticLivestock.loadMap()
    
    RealisticLivestock.mapAreaCode = RealisticLivestock.MAP_TO_AREA_CODE[g_currentMission.missionInfo.mapTitle] or 1

end



addModEventListener(RealisticLivestock)


function RealisticLivestock.getMapCountryCode()
    
    local areaCode = RealisticLivestock.AREA_CODES[RealisticLivestock.mapAreaCode]

    if areaCode ~= nil then return areaCode.code end

    return "UK"

end


function RealisticLivestock.getMapCountryIndex()

    return RealisticLivestock.mapAreaCode or 1

end


function RealisticLivestock.formatAge(age)

    local years = math.floor(age / 12)
    local months = age % 12

    local monthsString = months == 1 and g_i18n:getText("rl_ui_month") or g_i18n:getText("rl_ui_months")

    if years > 0 then return string.format("%s %s, %s %s", years, years == 1 and g_i18n:getText("rl_ui_year") or g_i18n:getText("rl_ui_years"), months, monthsString) end

    return string.format("%s %s", months, monthsString)

end



-- #################################################
-- THE MAJORITY OF THIS FILE IS LEGACY AND IS UNUSED
-- #################################################




function RealisticLivestock:updateReproduction(spec, cluster, numNewAnimals, freeSlots, isServer)

    local totalOffspring = 0
    local totalParents = cluster.numAnimals
    local parentAge = cluster.age
    local parentHealth = cluster.health
    local animalType = spec.animalTypeIndex
    local lactatingAnimals = 0
    local isParent = cluster.isParent

    for i = 1, totalParents do
        local childNumProb = 500
        local childNum = 1
        local noChildProb = 50
        local deathChance = 10
        local parentDied = false
        local deathChanceProb = math.random(1, 1000)

        if parentHealth <= 60 then
            childNumProb = math.random(0, 250)
            deathChance = 135
        elseif parentHealth <= 75 then
            childNumProb = math.random(10, 500)
            deathChance = 60
        elseif parentHealth <= 90 then
            childNumProb = math.random(50, 900)
            deathChance = 15
        else
            childNumProb = math.random(70, 1000)
            deathChance = 3
        end

        if animalType == AnimalType.COW then
            if parentAge <= 28 then
                noChildProb = 40
                deathChance = deathChance + 4
            elseif parentAge <= 36 then
                noChildProb = 32
                deathChance = deathChance - 10
            elseif parentAge <= 48 then
                noChildProb = 24
                deathChance = deathChance -8
            elseif parentAge <= 60 then
                noChildProb = 21
                deathChance = deathChance - 2
            elseif parentAge <= 84 then
                noChildProb = 70
                deathChance = deathChance + 4
            elseif parentAge <= 108 then
                noChildProb = 220
                deathChance = deathChance + 8
            elseif parentAge <= 132 then
                noChildProb = 460
                deathChance = deathChance + 20
            else
                noChildProb = 1000
            end

            if deathChanceProb <= deathChance then
                noChildProb = noChildProb * (1.1 + math.random())
                parentDied = true
            end

            if childNumProb <= noChildProb then
                childNum = 0
                if not parentDied and math.random() <= 0.08 then lactatingAnimals = lactatingAnimals + 1 end
            elseif childNumProb >= 950 and childNumProb <= 997 then
                childNum = 2
                lactatingAnimals = lactatingAnimals + 1
            elseif childNumProb >= 997 then
                childNum = 3
                lactatingAnimals = lactatingAnimals + 1
            else
                lactatingAnimals = lactatingAnimals + 1
            end
        elseif animalType == AnimalType.PIG then
            if parentAge <= 12 then
                noChildProb = 60
                deathChance = deathChance + 3
            elseif parentAge <= 36 then
                noChildProb = 40
                deathChance = deathChance - 4
            elseif parentAge <= 60 then
                noChildProb = 0130
                deathChance = deathChance - 3
            elseif parentAge <= 80 then
                noChildProb = 250
                deathChance = deathChance + 2
            elseif parentAge <= 96 then
                noChildProb = 460
                deathChance = deathChance + 10
            else
                noChildProb = 1000
            end

            if deathChanceProb <= deathChance then
                noChildProb = noChildProb * (1.1 + math.random())
                parentDied = true
            end

            if childNumProb <= noChildProb then
                childNum = 0
            elseif childNumProb <= 90 then
                childNum = math.random(1, 6)
            elseif childNumProb <= 240 then
                childNum = math.random(7, 10)
            elseif childNumProb <= 850 then
                childNum = math.random(11, 13)
            else
                childNum = math.random(14, 16)
            end
        elseif animalType == AnimalType.HORSE then
            if parentAge <= 12 then
                noChildProb = 60
                deathChance = deathChance - 7
            elseif parentAge <= 48 then
                noChildProb = 50
                deathChance = deathChance - 6
            elseif parentAge <= 60 then
                noChildProb = 65
                deathChance = deathChance - 4
            elseif parentAge <= 84 then
                noChildProb = 85
                deathChance = deathChance - 1
            elseif parentAge <= 108 then
                noChildProb = 120
                deathChance = deathChance + 1
            elseif parentAge <= 132 then
                noChildProb = 160
                deathChance = deathChance + 3
            elseif parentAge <= 156 then
                noChildProb = 220
                deathChance = deathChance + 6
            elseif parentAge <= 180 then
                noChildProb = 290
                deathChance = deathChance + 8
            elseif parentAge <= 216 then
                noChildProb = 460
                deathChance = deathChance + 10
            elseif parentAge <= 240 then
                noChildProb = 630
                deathChance = deathChance + 15
            elseif parentAge <= 264 then
                noChildProb = 850
                deathChance = deathChance + 20
            else
                noChildProb = 1000
            end

            if deathChanceProb <= deathChance then
                noChildProb = noChildProb * (1.1 + math.random())
                parentDied = true
            end

            if childNumProb <= noChildProb then
                childNum = 0
            elseif childNumProb >= 955 and childNumProb <= 997 then
                childNum = 2
            elseif childNumProb >= 997 then
                childNum = 3
            end
        elseif animalType == AnimalType.CHICKEN then
            if parentAge <= 12 then
                noChildProb = 400
            elseif parentAge <= 24 then
                noChildProb = 440
            elseif parentAge <= 36 then
                noChildProb = 500
            elseif parentAge <= 48 then
                noChildProb = 580
            elseif parentAge <= 60 then
                noChildProb = 675
            elseif parentAge <= 84 then
                noChildProb = 820
            elseif parentAge <= 120 then
                noChildProb = 960
            else
                noChildProb = 1000
            end

            if childNumProb <= noChildProb then
                childNum = 0
            elseif childNumProb <= 480 then
                childNum = math.random(1, 5)
            elseif childNumProb <= 760 then
                childNum = math.random(5, 7)
            elseif childNumProb <= 920 then
                childNum = math.random(7, 9)
            else
                childNum = math.random(10, 12)
            end
        elseif animalType == AnimalType.SHEEP then
            if parentAge <= 18 then
                noChildProb = 280
                deathChance = deathChance - 1
            elseif parentAge <= 24 then
                noChildProb = 220
                deathChance = deathChance - 3
            elseif parentAge <= 36 then
                noChildProb = 180
                deathChance = deathChance - 5
            elseif parentAge <= 72 then
                noChildProb = 140
                deathChance = deathChance - 7
            elseif parentAge <= 84 then
                noChildProb = 320
                deathChance = deathChance - 1
            elseif parentAge <= 108 then
                noChildProb = 600
                deathChance = deathChance + 5
            elseif parentAge <= 120 then
                noChildProb = 870
                deathChance = deathChance + 10
            else
                noChildProb = 1000
            end

            if deathChanceProb <= deathChance then
                noChildProb = noChildProb * (1.1 + math.random())
                parentDied = true
            end

            if childNumProb <= noChildProb then
                childNum = 0
            elseif not isParent and childNumProb <= 870 then
                childNum = 1
            elseif parentAge < 36 and childNumProb >= 500 and childNumProb <= 965 then
                childNum = 2
            elseif parentAge >= 36 and parentAge < 72 and childNumProb >= 350 and childNumProb <= 920 then
                childNum = 2
            elseif parentAge >= 72 and childNumProb <= 980 then
                childNum = 2
            elseif parentAge < 36 and childNumProb >= 965 then
                childNum = 3
            elseif parentAge >= 36 and parentAge < 72 and childNumProb >= 920 then
                childNum = 3
            elseif parentAge >= 72 and childNumProb >= 980 then
                childNum = 3
            end
        end

        print("parent #" .. (i + 1) .. ": ".. childNum .. " children")
        totalOffspring = totalOffspring + childNum

        if parentDied == true then
            RealisticLivestock.KillAnimals(spec, cluster, 1)
            print("animal died in childbirth")
        end
    end

    local animalTypeText = ""

    print(" --- ")
    if animalType == AnimalType.PIG then
        animalTypeText = "piglets"
        if totalOffspring == 1 then animalTypeText = "piglet" end
        print("PIGS")
    elseif cluster.subType == "COW_WATERBUFFALO" then
        animalTypeText = "buffalos"
        if totalOffspring == 1 then animalTypeText = "buffalo" end
        print("WATER BUFFALOS")
    elseif animalType == AnimalType.COW then
        animalTypeText = "calves"
        if totalOffspring == 1 then animalTypeText = "calf" end
        print("CATTLE")
    elseif cluster.subType == "GOAT" then
        animalTypeText = "goats"
        if totalOffspring == 1 then animalTypeText = "goat" end
        print("GOATS")
    elseif animalType == AnimalType.SHEEP then
        animalTypeText = "lambs"
        if totalOffspring == 1 then animalTypeText = "lamb" end
        print("SHEEP")
    elseif animalType == AnimalType.HORSE then
        animalTypeText = "foals"
        if totalOffspring == 1 then animalTypeText = "foal" end
        print("HORSES")
    elseif animalType == AnimalType.CHICKEN then
        animalTypeText = "chicks"
        if totalOffspring == 1 then animalTypeText = "chick" end
        print("CHICKEN")
    end
    print(totalParents .. " total parents")
    print(totalOffspring .. " total offspring")
    print(lactatingAnimals .. " lactating animals")

    cluster.lactatingAnimals = lactatingAnimals

    local animalsToSell = 0
    local subType = g_currentMission.animalSystem:getSubTypeByIndex(cluster:getSubTypeIndex())
    local farmIndex = spec:getOwnerFarmId()

    if freeSlots - totalOffspring < 0 then
        animalsToSell = totalOffspring - freeSlots
    end

        cluster.monthsSinceLastBirth = 0

    if totalOffspring > 0 then cluster.isParent = true end

    local msgText = totalOffspring .. " " .. animalTypeText .. " born"

    totalOffspring = totalOffspring - animalsToSell

    if animalsToSell > 0 then
        local animalPrice = subType.sellPrice:get(0) * 0.4
        local totalAnimalPrice = animalPrice * animalsToSell
        local farm = g_farmManager:getFarmById(farmIndex)
        msgText = msgText .. ", " .. animalsToSell .. " sold due to overcrowding for £" .. math.floor(totalAnimalPrice)

        if isServer then
            g_currentMission:addMoneyChange(totalAnimalPrice, farmIndex, MoneyType.SOLD_ANIMALS, true)
        else
            g_client:getServerConnection():sendEvent(MoneyChangeEvent.new(totalAnimalPrice, MoneyType.SOLD_ANIMALS, farmIndex))
        end

        if farm ~= nil then
            farm:changeBalance(totalAnimalPrice, MoneyType.SOLD_ANIMALS)
        end

        print(animalsToSell .. " for £" .. animalPrice .. " each.")
    end

    if totalOffspring >= 1 then

        local numMale = math.random(0, totalOffspring)

        if numMale >= 1 then
            local maleCluster = g_currentMission.animalSystem:createClusterFromSubTypeIndex(cluster:getSubTypeIndex() + 1)
            maleCluster.numAnimals = numMale
            maleCluster.monthsSinceLastBirth = 0
            maleCluster.isParent = false
            maleCluster.lactatingAnimals = 0
            maleCluster.gender = "male"
            spec.clusterSystem:addPendingAddCluster(maleCluster)
        end

        if totalOffspring - numMale >= 1 then

            local femaleCluster = g_currentMission.animalSystem:createClusterFromSubTypeIndex(cluster:getSubTypeIndex())
            femaleCluster.numAnimals = totalOffspring - numMale
            femaleCluster.monthsSinceLastBirth = 0
            femaleCluster.isParent = false
            femaleCluster.lactatingAnimals = 0
            femaleCluster.gender = "female"
            spec.clusterSystem:addPendingAddCluster(femaleCluster)

        end

        local animalTypeReal = g_currentMission.animalSystem:getTypeByIndex(subType.typeIndex)
        if animalTypeReal.statsBreedingName ~= nil then
            local stats = g_currentMission:farmStats(farmIndex)
            stats:updateStats(animalTypeReal.statsBreedingName, totalOffspring)
        end

    end

    if totalOffspring > 0 or animalsToSell > 0 then g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, msgText) end

end

function RealisticLivestock.KillAnimals(spec, cluster, amount)

    cluster.numAnimals = cluster.numAnimals - amount

    if cluster.numAnimals <= 0 then
        local husbandryAnimals = spec.spec_husbandryAnimals

        for i, selectedCluster in ipairs(husbandryAnimals.clusterSystem.clusters) do
            if selectedCluster == cluster then
                table.remove(husbandryAnimals.clusterSystem.clusters, i)
                break
            end
        end
    end

    spec:updateVisualAnimals()

end

-- Animals can die from low health

function RealisticLivestock.CalculateLowHealthMonthlyAnimalDeaths(spec, cluster)

    if cluster.numAnimals <= 0 then
        return
    end

    local numAnimalsToDispose = 0
    local numAnimals = cluster.numAnimals
    local deathChance = 0.01
    local health = cluster.health

    if health >= 80 then
        return
    end

    deathChance = 0.8 - (health / 100)

    if math.random() <= deathChance then
    if cluster.age < 6 then health = health - 10 end
        numAnimalsToDispose = math.random(math.max(1, (0.8 - (health / 100)) * numAnimals))
        if numAnimalsToDispose < 1 then
            numAnimalsToDispose = 1
        end

        if numAnimalsToDispose > numAnimals then
            numAnimalsToDispose = numAnimals
        end

        RealisticLivestock.KillAnimals(spec, cluster, numAnimalsToDispose)

        local animalTypeText = ""
        local animalType = spec.animalTypeIndex

        if animalType == AnimalType.PIG and cluster.age < 6 then
            animalTypeText = "piglets"
            if numAnimalsToDispose == 1 then animalTypeText = "piglet" end
        elseif animalType == AnimalType.PIG then
            animalTypeText = "pigs"
            if numAnimalsToDispose == 1 then animalTypeText = "pig" end
        end


        if cluster.subType == "COW_WATERBUFFALO" then
            animalTypeText = "buffalos"
            if numAnimalsToDispose == 1 then animalTypeText = "buffalo" end
        elseif animalType == AnimalType.COW and cluster.age < 12 then
            animalTypeText = "calves"
            if numAnimalsToDispose == 1 then animalTypeText = "calf" end
        elseif animalType == AnimalType.COW then
            animalTypeText = "cows"
            if numAnimalsToDispose == 1 then animalTypeText = "cow" end
        end


        if cluster.subType == "GOAT" then
            animalTypeText = "goats"
            if numAnimalsToDispose == 1 then animalTypeText = "goat" end
        elseif animalType == AnimalType.SHEEP and cluster.age < 6 then
            animalTypeText = "lambs"
            if numAnimalsToDispose == 1 then animalTypeText = "lamb" end
        elseif animalType == AnimalType.SHEEP then
            animalTypeText = "sheep"
        end

        if animalType == AnimalType.HORSE and cluster.age < 12 then
            animalTypeText = "foals"
            if numAnimalsToDispose == 1 then animalTypeText = "foal" end
        elseif animalType == AnimalType.HORSE then
            animalTypeText = "horses"
            if numAnimalsToDispose == 1 then animalTypeText = "horse" end
        end

        if animalType == AnimalType.CHICKEN and cluster.age < 6 then
            animalTypeText = "chicks"
            if numAnimalsToDispose == 1 then animalTypeText = "chick" end
        elseif animalType == AnimalType.CHICKEN then
            animalTypeText = "chickens"
            if numAnimalsToDispose == 1 then animalTypeText = "chicken" end
        end

        msgText = numAnimalsToDispose .. " " .. animalTypeText .. " died due to low health"

        if numAnimalsToDispose >= 1 then g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, msgText) end
    end

end


-- Animals can die from old age

function RealisticLivestock.CalculateOldAgeMonthlyAnimalDeaths(spec, cluster)

    if cluster.numAnimals <= 0 then
        return
    end

    local animalType = spec.animalTypeIndex
    local numAnimalsToDispose = 0
    local numAnimals = cluster.numAnimals
    local deathChance = 0.01
    local age = cluster.age

    local minAge = 20000
    local maxAge = 30000

    if animalType == AnimalType.COW then
        -- cattle old age min: 15y (180m)
        -- cattle old age max: 20y (240m)
        minAge = 180
        maxAge = 240
    elseif animalType == AnimalType.SHEEP then
        -- sheep old age min: 10y (120m)
        -- sheep old age max: 12y (144m)
        minAge = 120
        maxAge = 144
    elseif animalType == AnimalType.HORSE then
        -- horse old age min: 25y (300m)
        -- horse old age max: 30y (360m)
        minAge = 300
        maxAge = 360
    elseif animalType == AnimalType.PIG then
        -- pig old age min: 15y (180m)
        -- pig old age max: 20y (240m)
        minAge = 180
        maxAge = 240
    elseif animalType == AnimalType.CHICKEN then
        -- chicken old age min: 5y (60m)
        -- chicken old age max: 8y (96m)
        minAge = 60
        maxAge = 96
    end

    if age < minAge then
        return
    end

    deathChance = 0.7 - ((maxAge - age) / 100)
    if math.random() <= deathChance then
        numAnimalsToDispose = math.random((0.61 - ((maxAge - age) / 100)) * numAnimals)
        if numAnimalsToDispose < 1 then
            numAnimalsToDispose = 1
        end

        if numAnimalsToDispose > numAnimals then
            numAnimalsToDispose = numAnimals
        end

        RealisticLivestock.KillAnimals(spec, cluster, numAnimalsToDispose)

        local animalTypeText = ""
        local animalType = spec.animalTypeIndex

        if animalType == AnimalType.PIG then
            animalTypeText = "pigs"
            if numAnimalsToDispose == 1 then animalTypeText = "pig" end
        end


        if cluster.subType == "COW_WATERBUFFALO" then
            animalTypeText = "buffalos"
            if numAnimalsToDispose == 1 then animalTypeText = "buffalo" end
        elseif animalType == AnimalType.COW then
            animalTypeText = "cows"
            if numAnimalsToDispose == 1 then animalTypeText = "cow" end
        end


        if cluster.subType == "GOAT" then
            animalTypeText = "goats"
            if numAnimalsToDispose == 1 then animalTypeText = "goat" end
        elseif animalType == AnimalType.SHEEP then
            animalTypeText = "sheep"
        end

        if animalType == AnimalType.HORSE then
            animalTypeText = "horses"
            if numAnimalsToDispose == 1 then animalTypeText = "horse" end
        end

        if animalType == AnimalType.CHICKEN then
            animalTypeText = "chickens"
            if numAnimalsToDispose == 1 then animalTypeText = "chicken" end
        end

        msgText = numAnimalsToDispose .. " " .. animalTypeText .. " died due to old age"

        if numAnimalsToDispose >= 1 then g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, msgText) end
    end

end


-- Animals can die randomly regardless of health such as due to broken legs - will be sold at a reduced price (lower quality meat)

function RealisticLivestock.CalculateRandomMonthlyAnimalDeaths(spec, cluster, isServer)

    if cluster.numAnimals <= 0 then
        return
    end

    local animalType = spec.animalTypeIndex
    local numAnimalsToDispose = 0
    local animalsCanBeSold = true
    local numAnimals = cluster.numAnimals
    local deathChance = 0.01
    local temp = spec.minTemp

    if animalType == AnimalType.COW then
        deathChance = 0.018
        if cluster.age < 6 then
            deathChance = 0.028
        elseif cluster.age < 18 then
            deathChance = 0.02
        end
    elseif animalType == AnimalType.SHEEP then
        deathChance = 0.012
        if cluster.age < 3 then
            deathChance = 0.023
        elseif cluster.age < 8 then
            deathChance = 0.015
        end
    elseif animalType == AnimalType.HORSE then
        deathChance = 0.013
    elseif animalType == AnimalType.PIG then
        deathChance = 0.005
        if cluster.age < 3 then
            deathChance = 0.038
        elseif cluster.age < 6 then
            deathChance = 0.012
        end
    elseif animalType == AnimalType.CHICKEN then
        if cluster.age < 6 then
            deathChance = 0.003
        else
            deathChance = 0.004
        end
        animalsCanBeSold = false
    end

    -- animals are more likely to die in cold weather, especially young animals due to ice, pneumonia etc

    if temp ~= nil and temp < 10 and temp >= 0 then
        deathChance = deathChance * (1 + (1 - (temp / 10)))
    elseif temp ~= nil and temp < 0 then
        deathChance = deathChance * (1 + (1 - (temp / 8)))
    end

    if math.random() <= deathChance then
        numAnimalsToDispose = 1
        if numAnimals >= 10 and math.random() >= 0.92 then
            numAnimalsToDispose = math.max(math.random(2, math.floor(numAnimals / 3)), 4)
        end
    end

    if numAnimalsToDispose >= 1 then
        RealisticLivestock.KillAnimals(spec, cluster, numAnimalsToDispose)
        local totalAnimalPrice = 0
        if animalsCanBeSold then
            local subType = g_currentMission.animalSystem:getSubTypeByIndex(cluster:getSubTypeIndex())
            local farmIndex = spec:getOwnerFarmId()
            local animalPrice = subType.sellPrice:get(cluster.age) * 0.2
            totalAnimalPrice = animalPrice * numAnimalsToDispose
            local farm = g_farmManager:getFarmById(farmIndex)

            if isServer then
                g_currentMission:addMoneyChange(totalAnimalPrice, farmIndex, MoneyType.SOLD_ANIMALS, true)
            else
                g_client:getServerConnection():sendEvent(MoneyChangeEvent.new(totalAnimalPrice, MoneyType.SOLD_ANIMALS, farmIndex))
            end

            if farm ~= nil then
                farm:changeBalance(totalAnimalPrice, MoneyType.SOLD_ANIMALS)
            end

            print(numAnimalsToDispose .. " for £" .. animalPrice .. " each.")
        end

        local animalTypeText = ""
        local animalType = spec.animalTypeIndex

        if animalType == AnimalType.PIG and cluster.age < 6 then
            animalTypeText = "piglets"
            if numAnimalsToDispose == 1 then animalTypeText = "piglet" end
        elseif animalType == AnimalType.PIG then
            animalTypeText = "pigs"
            if numAnimalsToDispose == 1 then animalTypeText = "pig" end
        end


        if cluster.subType == "COW_WATERBUFFALO" then
            animalTypeText = "buffalos"
            if numAnimalsToDispose == 1 then animalTypeText = "buffalo" end
        elseif animalType == AnimalType.COW and cluster.age < 12 then
            animalTypeText = "calves"
            if numAnimalsToDispose == 1 then animalTypeText = "calf" end
        elseif animalType == AnimalType.COW then
            animalTypeText = "cows"
            if numAnimalsToDispose == 1 then animalTypeText = "cow" end
        end


        if cluster.subType == "GOAT" then
            animalTypeText = "goats"
            if numAnimalsToDispose == 1 then animalTypeText = "goat" end
        elseif animalType == AnimalType.SHEEP and cluster.age < 6 then
            animalTypeText = "lambs"
            if numAnimalsToDispose == 1 then animalTypeText = "lamb" end
        elseif animalType == AnimalType.SHEEP then
            animalTypeText = "sheep"
        end

        if animalType == AnimalType.HORSE and cluster.age < 12 then
            animalTypeText = "foals"
            if numAnimalsToDispose == 1 then animalTypeText = "foal" end
        elseif animalType == AnimalType.HORSE then
            animalTypeText = "horses"
            if numAnimalsToDispose == 1 then animalTypeText = "horse" end
        end

        if animalType == AnimalType.CHICKEN and cluster.age < 6 then
            animalTypeText = "chicks"
            if numAnimalsToDispose == 1 then animalTypeText = "chick" end
        elseif animalType == AnimalType.CHICKEN then
            animalTypeText = "chickens"
            if numAnimalsToDispose == 1 then animalTypeText = "chicken" end
        end

        msgText = numAnimalsToDispose .. " " .. animalTypeText .. " died due to accidents"
        if animalsCanBeSold then msgText = msgText .. ", sold for £" .. math.floor(totalAnimalPrice) end

        if numAnimalsToDispose >= 1 then g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, msgText) end

    end

end


-- check if given animal pen has a viable male animal for reproduction

function RealisticLivestock.hasMaleAnimalInPen(spec, subT, female)

    if spec == nil then return false end

    local clusterSystem = spec.clusterSystem or spec
    if clusterSystem == nil or clusterSystem.getAnimals == nil or clusterSystem:getAnimals() == nil then return false end

    local animals = clusterSystem:getAnimals()
    local animalSystem = g_currentMission.animalSystem
    local animalType = female == nil and spec.animalTypeIndex or female.animalTypeIndex
    local fatherId = (female ~= nil and female.fatherId ~= "-1") and female.fatherId or "-2"

    for _, animal in pairs(animals) do
        local s = animalSystem:getSubTypeByIndex(animal:getSubTypeIndex())
        if s.reproductionMinAgeMonth == nil or s.reproductionMinAgeMonth > animal.age then continue end

        if animal.farmId .. " " .. animal.uniqueId == fatherId then continue end

        if subT == "COW_WATERBUFFALO" then
            if s.name == "BULL_WATERBUFFALO" and animal.age < 132 then return true end
        elseif subT == "GOAT" then
            if s.name == "RAM_GOAT" and animal.age < 72 then return true end
        elseif s.name ~= "RAM_GOAT" and s.name ~= "BULL_WATERBUFFALO" then
            if animal.gender == "male" and ((animalType == AnimalType.COW and animal.age < 132) or (animalType == AnimalType.SHEEP and animal.age < 72) or (animalType == AnimalType.HORSE and animal.age < 300) or animalType == AnimalType.CHICKEN or (animalType == AnimalType.PIG and animal.age < 48)) then return true end
        end

    end

    return false

end


-- Monthly Animal Update Call


function RealisticLivestock.onPeriodChanged(self, func)

    if self.isServer then

        local minTemp =  math.floor(g_currentMission.environment.weather.temperatureUpdater.currentMin)

        local spec = self.spec_husbandryAnimals
        local clusters = spec.clusterSystem:getClusters()
        local totalNumAnimals = self:getNumOfAnimals()
        local freeSlots = math.max(spec.maxNumAnimals - totalNumAnimals, 0)
        local animalSystem = g_currentMission.animalSystem

        for _, cluster in ipairs(clusters) do

            if cluster.monthsSinceLastBirth == nil then
                cluster.monthsSinceLastBirth = 0
            end

            if cluster.isParent == nil then
                cluster.isParent = false
            end

            cluster:onPeriodChanged()
            cluster.monthsSinceLastBirth = cluster.monthsSinceLastBirth + 1

            local numNewAnimals = cluster:updateReproduction()

            if cluster.monthsSinceLastBirth <= 2 then cluster.reproduction = 0 end


            local index = cluster:getSubTypeIndex()

            local subTypeFull = animalSystem:getSubTypeByIndex(index)
            local reproductionDuration = subTypeFull.reproductionDurationMonth

            if cluster.gender == "female" and reproductionDuration ~= nil then
                if cluster.reproduction > 0 and cluster.reproduction <= 100 / reproductionDuration and not RealisticLivestock.hasMaleAnimalInPen(spec, subTypeFull.name) then cluster.reproduction = 0 end
            end

            if numNewAnimals > 0 then
                numNewAnimals = math.min(freeSlots, numNewAnimals)

                if numNewAnimals > 0 then
                    RealisticLivestock:updateReproduction(spec, cluster, numNewAnimals, freeSlots, self.isServer)
                end

            end

            RealisticLivestock.CalculateRandomMonthlyAnimalDeaths(spec, cluster, self.isServer)
            RealisticLivestock.CalculateOldAgeMonthlyAnimalDeaths(spec, cluster)
            RealisticLivestock.CalculateLowHealthMonthlyAnimalDeaths(spec, cluster)

        end

        spec.minTemp = minTemp

        self:raiseActive()
    end

end


--PlaceableHusbandryAnimals.onPeriodChanged = Utils.overwrittenFunction(PlaceableHusbandryAnimals.onPeriodChanged, RealisticLivestock.onPeriodChanged)


function RealisticLivestock:updateInfo(superFunc, infoTable)
    --superFunc(self, infoTable)

    local spec = self.spec_husbandryAnimals
    --local health = 0
    --local numAnimals = 0
    local lactatingAnimals = 0
    local clusters = spec.clusterSystem:getClusters()
    local numClusters = #clusters
    if numClusters > 0 then
        for _, cluster in ipairs(clusters) do
            --health = health + cluster.health
            --numAnimals = numAnimals + cluster.numAnimals
            if spec.animalTypeIndex == AnimalType.COW and cluster.isLactating ~= nil and cluster.isLactating then
                lactatingAnimals = lactatingAnimals + cluster.numAnimals
            end
        end

        --health = health / numClusters
    end

    --spec.infoNumAnimals.text = string.format("%d", numAnimals)
    --spec.infoHealth.text = string.format("%d %%", health)
    --table.insert(infoTable, spec.infoNumAnimals)
    --table.insert(infoTable, spec.infoHealth)

    local milkSpec = self.spec_husbandryMilk

    if spec.animalTypeIndex == AnimalType.COW and milkSpec ~= nil then
        if spec.infoLactatingAnimals == nil then
            spec.infoLactatingAnimals = {title="Lactating animals", text=""}
        end
        spec.infoLactatingAnimals.text = string.format("%d", lactatingAnimals)
        table.insert(infoTable, spec.infoLactatingAnimals)
    end
end

PlaceableHusbandryAnimals.updateInfo = Utils.appendedFunction(PlaceableHusbandryAnimals.updateInfo, RealisticLivestock.updateInfo)


function RealisticLivestock.addAnimals(self, superFunc, subTypeIndex, numAnimals, age)
    local mission = g_currentMission
    local animalSystem = mission.animalSystem
    local cluster = animalSystem:createClusterFromSubTypeIndex(subTypeIndex)
    cluster.gender = animalSystem.subTypes[subTypeIndex].gender
    cluster.lactatingAnimals = 0
    cluster.monthsSinceLastBirth = 0
    cluster.isParent = false
    local puberty = animalSystem.subTypes[subTypeIndex].reproductionMinAgeMonth

    if puberty ~= nil then
        if age >= puberty then
            cluster.health = 100
        else
            cluster.health = (age / puberty) * 100
        end
    end

    if cluster:getSupportsMerging() then
        cluster.numAnimals = numAnimals
        cluster.age = age
        cluster.subTypeIndex = subTypeIndex
        self:addCluster(cluster)
    else
        for i=1, numAnimals do
            cluster = animalSystem:createClusterFromSubTypeIndex(subTypeIndex)
            cluster.numAnimals = 1
            cluster.age = age
            self:addCluster(cluster)
        end
    end
end

--PlaceableHusbandryAnimals.addAnimals = Utils.overwrittenFunction(PlaceableHusbandryAnimals.addAnimals, RealisticLivestock.addAnimals)


-- Saving and Loading


function RealisticLivestock:saveHusbandryToXMLFile(superFunc, xmlFile, key, usedModNames)
    superFunc(self, xmlFile, key, usedModNames)
    if self.spec_husbandryAnimals.minTemp == nil then self.spec_husbandryAnimals.minTemp = 15 end
    xmlFile:setInt(key .. "#minTemp", self.spec_husbandryAnimals.minTemp)
end

PlaceableHusbandryAnimals.saveToXMLFile = Utils.overwrittenFunction(PlaceableHusbandryAnimals.saveToXMLFile, RealisticLivestock.saveHusbandryToXMLFile)

function RealisticLivestock:loadHusbandryFromXMLFile(superFunc, xmlFile, key)
    local r = superFunc(self, xmlFile, key)

    self.minTemp = xmlFile:getInt(key .. "#minTemp")

    if self.minTemp == nil then
        self.minTemp = 15
    end

    return r
end

PlaceableHusbandryAnimals.loadFromXMLFile = Utils.overwrittenFunction(PlaceableHusbandryAnimals.loadFromXMLFile, RealisticLivestock.loadHusbandryFromXMLFile)