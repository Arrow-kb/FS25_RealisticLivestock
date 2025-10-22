HandToolAIStraw = {}

HandToolAIStraw.numHeldStraws = 0
local specName = "spec_FS25_RealisticLivestock.aiStraw"


function HandToolAIStraw.registerFunctions(handTool)

	SpecializationUtil.registerFunction(handTool, "setAnimal", HandToolAIStraw.setAnimal)
	SpecializationUtil.registerFunction(handTool, "setDewarUniqueId", HandToolAIStraw.setDewarUniqueId)
	SpecializationUtil.registerFunction(handTool, "showInfo", HandToolAIStraw.showInfo)
	SpecializationUtil.registerFunction(handTool, "updateStraw", HandToolAIStraw.updateStraw)
	SpecializationUtil.registerFunction(handTool, "renderErrorText", HandToolAIStraw.renderErrorText)
	SpecializationUtil.registerFunction(handTool, "getBelongsToDewar", HandToolAIStraw.getBelongsToDewar)
	SpecializationUtil.registerFunction(handTool, "onInseminate", HandToolAIStraw.onInseminate)
	SpecializationUtil.registerFunction(handTool, "onReturnToDewar", HandToolAIStraw.onReturnToDewar)

end


function HandToolAIStraw.registerOverwrittenFunctions(handTool)
	SpecializationUtil.registerOverwrittenFunction(handTool, "getShowInHandToolsOverview", HandToolAIStraw.getShowInHandToolsOverview)
end


function HandToolAIStraw.registerEventListeners(handTool)
	SpecializationUtil.registerEventListener(handTool, "onPostLoad", HandToolAIStraw)
	SpecializationUtil.registerEventListener(handTool, "onDelete", HandToolAIStraw)
	SpecializationUtil.registerEventListener(handTool, "onDraw", HandToolAIStraw)
	SpecializationUtil.registerEventListener(handTool, "onHeldStart", HandToolAIStraw)
	SpecializationUtil.registerEventListener(handTool, "onHeldEnd", HandToolAIStraw)
	SpecializationUtil.registerEventListener(handTool, "onRegisterActionEvents", HandToolAIStraw)
	SpecializationUtil.registerEventListener(handTool, "onReadStream", HandToolAIStraw)
	SpecializationUtil.registerEventListener(handTool, "onWriteStream", HandToolAIStraw)
end


function HandToolAIStraw.prerequisitesPresent()

	print("Loaded handTool: HandToolAIStraw")

	return true

end


function HandToolAIStraw:onPostLoad(savegame)

	HandToolAIStraw.numHeldStraws = HandToolAIStraw.numHeldStraws + 1

	local spec = self[specName]

	if self.isClient then spec.defaultCrosshair = self:createCrosshairOverlay("gui.crosshairDefault") end

	spec.inseminateText = g_i18n:getText("rl_ui_inseminateAnimal")
	spec.returnText = "Return straw"
	spec.isEmpty = false
	spec.textAlpha = 1
	spec.textAlphaReverse = false

	if savegame == nil or savegame.xmlFile == nil then return end

	local xmlFile, key = savegame.xmlFile, savegame.key
	local animalKey = key .. ".FS25_RealisticLivestock.aiStraw.animal"

	spec.isEmpty = xmlFile:getBool(key .. ".FS25_RealisticLivestock.aiStraw#isEmpty", false)
	spec.dewarUniqueId = xmlFile:getString(key .. ".FS25_RealisticLivestock.aiStraw#dewarUniqueId")

	if xmlFile:hasProperty(animalKey) then

		local animal = {}
		
		animal.country = xmlFile:getInt(animalKey .. "#country")
		animal.farmId = xmlFile:getString(animalKey .. "#farmId")
		animal.uniqueId = xmlFile:getString(animalKey .. "#uniqueId")
		animal.name = xmlFile:getString(animalKey .. "#name")
		animal.typeIndex = xmlFile:getInt(animalKey .. "#typeIndex")
		animal.subTypeIndex = xmlFile:getInt(animalKey .. "#subTypeIndex")
		animal.success = xmlFile:getFloat(animalKey .. "#success")
		
		animal.genetics = {
			["metabolism"] = xmlFile:getFloat(animalKey .. ".genetics#metabolism"),
			["fertility"] = xmlFile:getFloat(animalKey .. ".genetics#fertility"),
			["health"] = xmlFile:getFloat(animalKey .. ".genetics#health"),
			["quality"] = xmlFile:getFloat(animalKey .. ".genetics#quality"),
			["productivity"] = xmlFile:getFloat(animalKey .. ".genetics#productivity")
		}
		
		self.animal = animal

	end

end


function HandToolAIStraw:onDelete()

	HandToolAIStraw.numHeldStraws = HandToolAIStraw.numHeldStraws - 1
	
	local spec = self[specName]

	if spec.defaultCrosshair ~= nil then
		spec.defaultCrosshair:delete()
		spec.defaultCrosshair = nil
	end

end


function HandToolAIStraw:saveToXMLFile(xmlFile, key)

	local animal = self[specName].animal

	xmlFile:setBool(key .. "#isEmpty", self[specName].isEmpty or false)
	xmlFile:setString(key .. "#dewarUniqueId", self[specName].dewarUniqueId or "")

	if animal ~= nil then

		xmlFile:setInt(key .. ".animal#country", animal.country)
		xmlFile:setString(key .. ".animal#farmId", animal.farmId)
		xmlFile:setString(key .. ".animal#uniqueId", animal.uniqueId)
		xmlFile:setString(key .. ".animal#name", animal.name)
		xmlFile:setInt(key .. ".animal#typeIndex", animal.typeIndex)
		xmlFile:setInt(key .. ".animal#subTypeIndex", animal.subTypeIndex)
		xmlFile:setFloat(key .. ".animal#success", animal.success)
		
		for type, value in pairs(animal.genetics) do
			xmlFile:setFloat(key .. ".animal.genetics#" .. type, value)
		end

	end

end


function HandToolAIStraw:onReadStream(streamId, connection)

	local spec = self[specName]

	spec.isEmpty = streamReadBool(streamId)
	spec.dewarUniqueId = streamReadString(streamId)

	local hasAnimal = streamReadBool(streamId)
	local animal

	if hasAnimal then

		local animal = { ["genetics"] = {} }

		animal.country = streamReadUInt8(streamId)
		animal.farmId = streamReadString(streamId)
		animal.uniqueId = streamReadString(streamId)
		animal.name = streamReadString(streamId)
		animal.typeIndex = streamReadUInt8(streamId)
		animal.subTypeIndex = streamReadUInt8(streamId)
		animal.success = streamReadFloat32(streamId)

		animal.genetics.metabolism = streamReadFloat32(streamId)
		animal.genetics.fertility = streamReadFloat32(streamId)
		animal.genetics.health = streamReadFloat32(streamId)
		animal.genetics.quality = streamReadFloat32(streamId)
		animal.genetics.productivity = streamReadFloat32(streamId)

		if animal.genetics.productivity < 0 then animal.genetics.productivity = nil end

	end

	spec.animal = animal

end


function HandToolAIStraw:onWriteStream(streamId, connection)

	local spec = self[specName]

	streamWriteBool(streamId, spec.isEmpty or false)
	streamWriteString(streamId, spec.dewarUniqueId or "")

	streamWriteBool(streamId, spec.animal ~= nil)

	if spec.animal ~= nil then

		local animal = spec.animal

		streamWriteUInt8(streamId, animal.country)
		streamWriteString(streamId, animal.farmId)
		streamWriteString(streamId, animal.uniqueId)
		streamWriteString(streamId, animal.name or "")
		streamWriteUInt8(streamId, animal.typeIndex)
		streamWriteUInt8(streamId, animal.subTypeIndex)
		streamWriteFloat32(streamId, animal.success)

		streamWriteFloat32(streamId, animal.genetics.metabolism)
		streamWriteFloat32(streamId, animal.genetics.fertility)
		streamWriteFloat32(streamId, animal.genetics.health)
		streamWriteFloat32(streamId, animal.genetics.quality)
		streamWriteFloat32(streamId, animal.genetics.productivity or -1)

	end

end


function HandToolAIStraw:updateStraw(dT)

	local player = self:getCarryingPlayer()

	if player == nil then
		spec.textAlpha = 1
		g_inputBinding:setActionEventActive(spec.activateActionEventId, false)
		return
	end

	local spec = self[specName]

	spec.targetedPlaceable, spec.targetedAnimal, spec.targetedDewar = nil, nil, nil

	if not player.isOwner then
		spec.textAlpha = 1
		spec.textAlphaReverse = false
		g_inputBinding:setActionEventActive(spec.activateActionEventId, false)
		return 
	end

	local node = player.targeter:getClosestTargetedNodeFromType(HandToolAIStraw)

	if node == nil or node == 0 then
		spec.textAlpha = 1
		spec.textAlphaReverse = false
		g_inputBinding:setActionEventActive(spec.activateActionEventId, false)
		return
	end

	local placeable, animal = HandToolAIStraw.getHusbandryAndClusterFromNode(player, node)

	if placeable == nil or animal == nil then

		local object = g_currentMission:getNodeObject(node)

        if object ~= nil and object:isa(Dewar) then

			if self:getBelongsToDewar(object) then
				
				spec.targetedDewar = object
				spec.actionContext = "return"
				g_inputBinding:setActionEventActive(spec.activateActionEventId, true)
				g_inputBinding:setActionEventText(spec.activateActionEventId, spec.returnText)

			else

				g_inputBinding:setActionEventActive(spec.activateActionEventId, false)

				self:renderErrorText("This straw can not be returned to this dewar")

			end

		else

			g_inputBinding:setActionEventActive(spec.activateActionEventId, false)
			spec.textAlpha = 1
			spec.textAlphaReverse = false

		end

		return

	end

	local canBeInseminated, error = animal:getCanBeInseminatedByAnimal(spec.animal)

	if spec.isEmpty or not canBeInseminated then

		if spec.isEmpty then error = g_i18n:getText("rl_ui_strawEmpty") end

		g_inputBinding:setActionEventActive(spec.activateActionEventId, false)

		self:renderErrorText(error)

		return

	end

	spec.targetedPlaceable, spec.targetedAnimal = placeable, animal
	
				
	spec.actionContext = "inseminate"
	g_inputBinding:setActionEventActive(spec.activateActionEventId, true)
	g_inputBinding:setActionEventText(spec.activateActionEventId, string.format(spec.inseminateText, animal:getIdentifiers()))

end


function HandToolAIStraw:onHeldStart()

	if g_localPlayer == nil or self:getCarryingPlayer() ~= g_localPlayer or not g_localPlayer.isOwner then return end
	
	g_localPlayer.targeter:addTargetType(HandToolAIStraw, CollisionFlag.ANIMAL + CollisionFlag.DYNAMIC_OBJECT, 0.5, 3)
	g_localPlayer.hudUpdater:setCarriedItem(self)
	g_aiStrawUpdater:setStraw(self)
	g_currentMission:addUpdateable(g_aiStrawUpdater)

	local spec = self[specName]
	spec.textAlpha = 1
	spec.textAlphaReverse = false

end


function HandToolAIStraw:onHeldEnd()

	if g_localPlayer == nil or g_localPlayer.hudUpdater:getCarriedItem() ~= self then return end

	if g_localPlayer.isOwner then g_localPlayer.targeter:removeTargetType(HandToolAIStraw) end

	g_localPlayer.hudUpdater:setCarriedItem()
	g_aiStrawUpdater:setStraw()
	g_currentMission:removeUpdateable(g_aiStrawUpdater)

end


function HandToolAIStraw:onRegisterActionEvents()

	if self:getIsActiveForInput(true) then

		local _, eventId = self:addActionEvent(InputAction.ACTIVATE_HANDTOOL, self, HandToolAIStraw.onActionFired, false, true, false, true, nil)
		self[specName].activateActionEventId = eventId
		g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_VERY_HIGH)
		g_inputBinding:setActionEventText(eventId, "")
		g_inputBinding:setActionEventActive(eventId, false)

	end

end


function HandToolAIStraw:setAnimal(animal)

	self[specName].animal = animal

end


function HandToolAIStraw:setDewarUniqueId(dewarUniqueId)

	self[specName].dewarUniqueId = dewarUniqueId

end


function HandToolAIStraw:showInfo(box)

	local animal = self[specName].animal

	if animal == nil then return end

	local animalSystem = g_currentMission.animalSystem
	local subType = animalSystem:getSubTypeByIndex(animal.subTypeIndex)
	
    box:addLine(g_i18n:getText("rl_ui_averageSuccess"), string.format("%s%%", tostring(math.round(animal.success * 100))))
    box:addLine(g_i18n:getText("rl_ui_species"), animalSystem:getTypeByIndex(animal.typeIndex).groupTitle)
    box:addLine(g_i18n:getText("infohud_type"), g_fillTypeManager:getFillTypeTitleByIndex(subType.fillTypeIndex))
	box:addLine(g_i18n:getText("infohud_name"), animal.name)
	box:addLine(g_i18n:getText("rl_ui_earTag"), string.format("%s %s %s", RealisticLivestock.AREA_CODES[animal.country].code, animal.farmId, animal.uniqueId))

	for type, value in pairs(animal.genetics) do

		local valueText

		if value >= 1.65 then
            valueText = "extremelyHigh"
        elseif value >= 1.4 then
            valueText = "veryHigh"
        elseif value >= 1.1 then
            valueText = "high"
        elseif value >= 0.9 then
            valueText = "average"
        elseif value >= 0.7 then
            valueText = "low"
        elseif value >= 0.35 then
            valueText = "veryLow"
        else
            valueText = "extremelyLow"
        end

		box:addLine(g_i18n:getText("rl_ui_" .. type), g_i18n:getText("rl_ui_genetics_" .. valueText))

	end

end


function HandToolAIStraw.getHusbandryAndClusterFromNode(player, node)

    if node == nil or not entityExists(node) then return nil, nil end

	local husbandryId, animalId = getAnimalFromCollisionNode(node)

	if husbandryId ~= nil and husbandryId ~= 0 then

		local clusterHusbandry = g_currentMission.husbandrySystem:getClusterHusbandryById(husbandryId)

		if clusterHusbandry ~= nil then

			local placeable = clusterHusbandry:getPlaceable()
			local animal = clusterHusbandry:getClusterByAnimalId(animalId, husbandryId)

			if animal ~= nil and (g_currentMission.accessHandler:canFarmAccess(player.farmId, placeable) and (animal.changeDirt ~= nil and animal.getName ~= nil)) then return placeable, animal end

		end

	end

	return nil, nil

end


function HandToolAIStraw:onActionFired()

	local spec = self[specName]

	if spec.actionContext == "inseminate" then
		self:onInseminate()
	elseif spec.actionContext == "return" then
		self:onReturnToDewar()
	end

end


function HandToolAIStraw:onInseminate()

	local spec = self[specName]

	local husbandry, animal = spec.targetedPlaceable, spec.targetedAnimal

	animal:setInsemination(spec.animal)

	if g_server ~= nil then
		g_server:broadcastEvent(AnimalInseminationEvent.new(husbandry, animal, spec.animal))
	elseif g_client ~= nil then
		g_client:getServerConnection():sendEvent(AnimalInseminationEvent.new(husbandry, animal, spec.animal))
	end

	spec.isEmpty = true
	g_inputBinding:setActionEventActive(spec.activateActionEventId, false)

	if self.isServer then g_currentMission.handToolSystem:markHandToolForDeletion(self) end

end


function HandToolAIStraw:onReturnToDewar()

	local spec = self[specName]

	local dewar = spec.targetedDewar

	if g_server ~= nil then
		g_server:broadcastEvent(ReturnStrawEvent.new(dewar))
	elseif g_client ~= nil then
		g_client:getServerConnection():sendEvent(ReturnStrawEvent.new(dewar))
	end

	dewar:changeStraws(1)
	spec.isEmpty = true
	g_inputBinding:setActionEventActive(spec.activateActionEventId, false)

	if self.isServer then g_currentMission.handToolSystem:markHandToolForDeletion(self) end

end


function HandToolAIStraw:getShowInHandToolsOverview()

	return false

end


function HandToolAIStraw:renderErrorText(text)

	local spec = self[specName]

	setTextAlignment(RenderText.ALIGN_CENTER)
	setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
	setTextColor(1, 0, 0, spec.textAlpha)
	renderText(0.5, 0.6, 0.023, text)

	spec.textAlpha = spec.textAlpha + (spec.textAlphaReverse and 0.015 or -0.015)

	if spec.textAlpha <= 0 or spec.textAlpha >= 1 then spec.textAlphaReverse = not spec.textAlphaReverse end

end


function HandToolAIStraw:getBelongsToDewar(dewar)

	local spec = self[specName]

	return dewar:getUniqueId() == spec.dewarUniqueId

end


function HandToolAIStraw:onDraw()

	self[specName].defaultCrosshair:render()

end