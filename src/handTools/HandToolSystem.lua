RL_HandToolSystem = {}

local modName = g_currentModName


function RL_HandToolSystem:loadHandToolFromXML(superFunc, xmlFile, key)

	local returnValue = superFunc(self, xmlFile, key)

	if returnValue then return true end

	local filename = NetworkUtil.convertFromNetworkFilename(xmlFile:getValue(key .. "#filename"))

	if not string.contains(filename, modName) then return false end

	local tempXml = XMLFile.loadIfExists("tempHandTool", filename, HandTool.xmlSchema)
	if tempXml == nil then return false end

	local typeName = tempXml:getValue("handTool#type")

	tempXml:delete()

	self.handToolsToLoad = self.handToolsToLoad + 1

    local type = g_handToolTypeManager:getTypeByName(modName .. "." .. typeName)
    local handTool = _G[type.className].new(g_currentMission:getIsServer(), g_currentMission:getIsClient())

    handTool:setType(type)
    handTool:setLoadCallback(self.loadHandToolFinished, self)
    handTool:loadNonStoreItem({ ["savegameData"] = { ["xmlFile"] = xmlFile, ["key"] = key } }, filename)

	return true

end

HandToolSystem.loadHandToolFromXML = Utils.overwrittenFunction(HandToolSystem.loadHandToolFromXML, RL_HandToolSystem.loadHandToolFromXML)