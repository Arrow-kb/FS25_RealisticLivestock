RL_FSCareerMissionInfo = {}

function RL_FSCareerMissionInfo:saveToXMLFile()
    if self.xmlFile ~= nil and g_currentMission ~= nil and g_currentMission.animalSystem ~= nil then
        g_currentMission.animalSystem:saveToXMLFile(self.savegameDirectory .. "/animalSystem.xml")
        RLSettings.saveToXMLFile()
        g_familyTreeManager:save(self.savegameDirectory .. "/familyTrees.xml")
    end
end

FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, RL_FSCareerMissionInfo.saveToXMLFile)