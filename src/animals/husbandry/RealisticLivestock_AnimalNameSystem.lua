RealisticLivestock_AnimalNameSystem = {}
local modDirectory = g_currentModDirectory

function RealisticLivestock_AnimalNameSystem:loadMapData(_, _, missionInfo)

    self.names = {}
    self.femaleNames = {}
    self.maleNames = {}
    self.descriptions = {}

    local xmlFile = XMLFile.loadIfExists("animalNames", modDirectory .. "xml/animalNames.xml")
    if xmlFile == nil then return false end

    xmlFile:iterate("animalNames.name", function(_, key)

        local name = xmlFile:getString(key .. "#value")
        if name == nil then return false end

        local gender = xmlFile:getString(key .. "#gender", nil)

        if gender == "male" then
            table.insert(self.maleNames, name)
        elseif gender == "female" then
            table.insert(self.femaleNames, name)
        else
            table.insert(self.femaleNames, name)
            table.insert(self.maleNames, name)
        end

    end)

    xmlFile:iterate("animalNames.description", function(_, key)
        local description = xmlFile:getString(key .. "#value")
        table.insert(self.descriptions, description)
    end)

    xmlFile:delete()
    return true

end

AnimalNameSystem.loadMapData = Utils.overwrittenFunction(AnimalNameSystem.loadMapData, RealisticLivestock_AnimalNameSystem.loadMapData)


function RealisticLivestock_AnimalNameSystem:getRandomName(_, gender)

    if gender == nil then gender = "female" end
    local names = gender == "male" and self.maleNames or self.femaleNames

    if names == nil or #names == 0 then return nil end
    local description = ""

    if self.descriptions ~= nil and #self.descriptions > 0 and math.random() >= 0.65 then description = self.descriptions[math.random(1, #self.descriptions)] .. " " end

    return description .. names[math.random(1, #names)]

end

AnimalNameSystem.getRandomName = Utils.overwrittenFunction(AnimalNameSystem.getRandomName, RealisticLivestock_AnimalNameSystem.getRandomName)


function AnimalNameSystem:getNamesAlphabetical(gender)

    local names = table.clone(gender == "female" and self.femaleNames or self.maleNames)

    table.sort(names, function(a, b) return a < b end)

    return names

end