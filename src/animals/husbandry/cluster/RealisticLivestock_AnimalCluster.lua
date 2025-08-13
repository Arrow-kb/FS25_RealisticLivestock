RealisticLivestock_AnimalCluster = {}


function RealisticLivestock_AnimalCluster:saveToXMLFile(xmlFile, key, _)
    if self.monthsSinceLastBirth == nil then self.monthsSinceLastBirth = 0 end
    if self.lactatingAnimals == nil then self.lactatingAnimals = 0 end
    if self.isParent == nil then self.isParent = false end
    if self.gender == nil then self.gender = "female" end
    xmlFile:setInt(key .. "#monthsSinceLastBirth", self.monthsSinceLastBirth)
    xmlFile:setInt(key .. "#lactatingAnimals", self.lactatingAnimals)
    xmlFile:setBool(key .. "#isParent", self.isParent)
    xmlFile:setString(key .. "#gender", self.gender)
end

AnimalCluster.saveToXMLFile = Utils.appendedFunction(AnimalCluster.saveToXMLFile, RealisticLivestock_AnimalCluster.saveToXMLFile)

function RealisticLivestock_AnimalCluster:loadFromXMLFile(superFunc, xmlFile, key)

    local r = superFunc(self, xmlFile, key)

    self.isParent = xmlFile:getBool(key .. "#isParent")
    self.monthsSinceLastBirth = xmlFile:getInt(key .. "#monthsSinceLastBirth")
    self.lactatingAnimals = xmlFile:getInt(key .. "#lactatingAnimals")
    self.gender = xmlFile:getString(key .. "#gender")

    -- why is the age of animals clamped between 0 and 60 months?

    self.age = xmlFile:getInt(key .. "#age")

    if self.monthsSinceLastBirth == nil then
        self.monthsSinceLastBirth = 0
    end

    if self.lactatingAnimals == nil then
        self.lactatingAnimals = 0
    end

    if self.isParent == nil then
        self.isParent = false
    end

    if self.gender == nil and self.subType ~= nil and self.subType == "CHICKEN_ROOSTER" then
        self.gender = "male"
    elseif self.gender == nil then
        self.gender = "female"
    end

    return r
end

AnimalCluster.loadFromXMLFile = Utils.overwrittenFunction(AnimalCluster.loadFromXMLFile, RealisticLivestock_AnimalCluster.loadFromXMLFile)

function RealisticLivestock_AnimalCluster:showInfo(superFunc, box)

    local index = self:getSubTypeIndex()
    local subType = g_currentMission.animalSystem:getSubTypeByIndex(index)
    local name = subType.name

    local fillTypeTitle = g_fillTypeManager:getFillTypeTitleByIndex(subType.fillTypeIndex)

    box:addLine(g_i18n:getText("infohud_type"), fillTypeTitle)
    box:addLine(g_i18n:getText("infohud_age"), g_i18n:formatNumMonth(self.age))

    if self.numAnimals > 1 then
        box:addLine(g_i18n:getText("infohud_numAnimals"), tostring(self.numAnimals))
    end

    box:addLine(g_i18n:getText("infohud_health"), string.format("%d %%", self.health))

    if self.clusterSystem.owner.spec_husbandryMilk ~= nil and self.gender ~= nil and self.gender == "female" and self.age >= 12 then
        local lactatingAnimals = self.lactatingAnimals
        if lactatingAnimals ~= nil then box:addLine("Lactating animals", string.format("%d", lactatingAnimals)) end
    end

    if self.gender ~= nil and self.gender == "female" and subType.supportsReproduction then

        box:addLine(g_i18n:getText("infohud_reproduction"), string.format("%d %%", self.reproduction))

        local healthFactor = self:getHealthFactor()
        local text = "Yes"

        if self.age < subType.reproductionMinAgeMonth then
            text = "No (too young)"
        elseif not RealisticLivestock.hasMaleAnimalInPen(self.clusterSystem.owner.spec_husbandryAnimals, name) and self.reproduction < 100 / subType.reproductionDurationMonth then
            text = "No (no suitable male animal)"
        elseif healthFactor < subType.reproductionMinHealth then
            text = "No (too unhealthy)"
        end

        box:addLine("Can reproduce", text)

    end

end

AnimalCluster.showInfo = Utils.overwrittenFunction(AnimalCluster.showInfo, RealisticLivestock_AnimalCluster.showInfo)

function RealisticLivestock_AnimalCluster:addInfos(infos)

    if self.gender ~= nil and self.gender == "female" and self.lactatingAnimals ~= nil and self.age > 12 and self.clusterSystem.owner.spec_husbandryMilk ~= nil then

        if self.infoLactation == nil then
            self.infoLactation = {
                text = "Lactating animals",
                title = "Lactating animals"
            }
        end

        self.infoLactation.value = self.lactatingAnimals
        self.infoLactation.ratio = self.lactatingAnimals / self.numAnimals
        self.infoLactation.valueText = string.format("%d", self.lactatingAnimals)

        table.insert(infos, self.infoLactation)

    end

end

AnimalCluster.addInfos = Utils.appendedFunction(AnimalCluster.addInfos, RealisticLivestock_AnimalCluster.addInfos)

function RealisticLivestock_AnimalCluster:changeAge(superFunc, delta)
    -- whats even the point of having an aging system if animals dont age past 5 years old? animals die in real life, i get that you want your "E - Everyone" rating, but its not like 3 year olds are playing this £50 game. realistically your main audience is adult men, even moreso at this expensive price.
    self.age = self.age + delta
end

AnimalCluster.changeAge = Utils.overwrittenFunction(AnimalCluster.changeAge, RealisticLivestock_AnimalCluster.changeAge)