RL_HandTool = {}

local modDirectory = g_currentModDirectory
local modName = g_currentModName


function RL_HandTool:load(superFunc, data)

	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)

	if not string.contains(self.type.name, modName) or storeItem ~= nil then return superFunc(self, data) end

	self:loadNonStoreItem(data, self.configFileName)

end

HandTool.load = Utils.overwrittenFunction(HandTool.load, RL_HandTool.load)


function HandTool:loadNonStoreItem(data, xmlFile)

	self.isRL = true

	local handToolSystem = g_currentMission.handToolSystem

	self.handToolLoadingData = data
	self.savegame = data.savegameData
	self.xmlFile = XMLFile.loadIfExists("handTool", xmlFile, HandTool.xmlSchema)
	self.configFileName = xmlFile

	SpecializationUtil.copyTypeFunctionsInto(self.type, self)
	SpecializationUtil.createSpecializationEnvironments(self, function(specialization, variable)
		self:setLoadingState(HandToolLoadingState.ERROR)
	end)

	SpecializationUtil.raiseEvent(self, "onPreLoad", self.savegame)

	if self.loadingState ~= HandToolLoadingState.OK then

		printWarning("Handtool pre-loading failed!")
		return false

	end

	self.i3dFilename = modDirectory .. self.xmlFile:getValue("handTool.base.filename")
		
	if self.i3dFilename == nil then
		self:loadFinishedNonStoreItem()
	else

		self:setLoadingStep(SpecializationLoadStep.AWAIT_I3D)
		self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.i3dFilename, true, false, self.i3dFileLoadedNonStoreItem, self)

	end

	return nil

end


function HandTool:loadFinishedNonStoreItem()

	self:setLoadingState(HandToolLoadingState.OK)
	self:setLoadingStep(SpecializationLoadStep.LOAD)
	self.age = 0
	self:setOwnerFarmId(self.handToolLoadingData.ownerFarmId, true)
	self.mass = self.xmlFile:getValue("handTool.base#mass", 0)

	local savegame = self.savegame

	if savegame ~= nil then

		local uniqueId = savegame.xmlFile:getValue(savegame.key .. "#uniqueId", nil)

		if uniqueId ~= nil then self:setUniqueId(uniqueId) end

		local farmId = savegame.xmlFile:getValue(savegame.key .. "#farmId", AccessHandler.EVERYONE)

		if g_farmManager.mergedFarms ~= nil and g_farmManager.mergedFarms[farmId] ~= nil then farmId = g_farmManager.mergedFarms[farmId] end

		self:setOwnerFarmId(farmId, true)

	end

	self.typeDesc = self.xmlFile:getValue("handTool.base.typeDesc", "TypeDescription", self.customEnvironment, true)
	self.activateText = self.xmlFile:getValue("handTool.base.actions#activate", "Activate", self.customEnvironment, true)
	
	if self.i3dNode ~= nil then

		self.rootNode = getChildAt(self.i3dNode, 0)
		self.components = {}
		I3DUtil.loadI3DComponents(self.i3dNode, self.components)

		self.i3dMappings = {}
		I3DUtil.loadI3DMapping(self.xmlFile, "handTool", self.rootLevelNodes, self.i3dMappings)

		for _, component in ipairs(self.components) do
			link(getRootNode(), component.node)
		end

		delete(self.i3dNode)
		self.i3dNode = nil
		self.graphicalNode = self.xmlFile:getValue("handTool.base.graphics#node", nil, self.components, self.i3dMappings)

		if self.graphicalNode == nil then

			Logging.xmlError(self.xmlFile, "Handtool is missing graphical node! Graphics will not work as intended!")
			self:setLoadingState(HandToolLoadingState.ERROR)
			self:loadCallback()
			return

		end

		self.graphicalNodeParent = getParent(self.graphicalNode)
		self.handNode = self.xmlFile:getValue("handTool.base.handNode#node", nil, self.components, self.i3dMappings)
		self.useLeftHand = self.xmlFile:getValue("handTool.base.handNode#useLeftHand", self.useLeftHand)
		self.firstPersonNode = self.xmlFile:getValue("handTool.base.firstPersonNode#node", nil, self.components, self.i3dMappings)

	end

	self.shouldLockFirstPerson = self.xmlFile:getValue("handTool.base.graphics#lockFirstPerson", nil)
	self.runMultiplier = self.xmlFile:getValue("handTool.base#runMultiplier", 1)
	self.walkMultiplier = self.xmlFile:getValue("handTool.base#walkMultiplier", 1)
	self.canCrouch = self.xmlFile:getValue("handTool.base#canCrouch", true)
	self.mustBeHeld = self.xmlFile:getValue("handTool.base#mustBeHeld", false)
	self.canBeSaved = self.xmlFile:getValue("handTool.base#canBeSaved", true)
	self.canBeDropped = self.xmlFile:getValue("handTool.base#canBeDropped", true)

	SpecializationUtil.raiseEvent(self, "onLoad", self.xmlFile, self.baseDirectory)

	if self.loadingState == HandToolLoadingState.OK then

		self:setLoadingStep(SpecializationLoadStep.POST_LOAD)
		SpecializationUtil.raiseEvent(self, "onPostLoad", self.savegame)

		if self.loadingState == HandToolLoadingState.OK then

			if savegame ~= nil then
				self.age = savegame.xmlFile:getValue(savegame.key .. "#age", 0)
				self.price = savegame.xmlFile:getValue(savegame.key .. "#price", self.price)
			end
			local v43 = g_currentMission

			if v43 ~= nil and v43.environment ~= nil then
				g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.periodChanged, self)
			end

			if #self.loadingTasks == 0 then
				self:onFinishedLoadingNonStoreItem()
			else
				self.readyForFinishLoading = true
				self:setLoadingStep(SpecializationLoadStep.AWAIT_SUB_I3D)
			end

		else

			Logging.xmlError(self.xmlFile, "HandTool post-loading failed!")
			self:loadCallback()
			return

		end

	else

		Logging.xmlError(self.xmlFile, "HandTool loading failed!")
		self:loadCallback()
		return

	end

end


function HandTool:i3dFileLoadedNonStoreItem(node)

	if node == 0 then

		self:setLoadingState(HandToolLoadingState.ERROR)
		printError("Handtool i3d loading failed!")
		self:loadCallback()

	else

		self.i3dNode = node
		setVisibility(node, false)
		self:loadFinishedNonStoreItem()

	end

end


function HandTool:onFinishedLoadingNonStoreItem()

	self:setLoadingStep(SpecializationLoadStep.FINISHED)
	SpecializationUtil.raiseEvent(self, "onLoadFinished", self.savegame)

	if self.isServer then
		self:setLoadingStep(SpecializationLoadStep.SYNCHRONIZED)
	end

	self.finishedLoading = true

	if g_currentMission.handToolSystem:addHandTool(self) then

		if self.handToolLoadingData.isRegistered then
			self:register()
		end

		local holder = self.handToolLoadingData.holder

		if holder == nil then
			if self.savegame ~= nil then
				self.pendingHolderUniqueId = self.savegame.xmlFile:getValue(self.savegame.key .. ".holder#uniqueId", nil)
			end
		elseif holder:getCanPickupHandTool(self) then
			self.pendingHolder = holder
			self:setHolder(holder)
		end

		g_currentMission:addOwnedItem(self)
		self.savegame = nil
		self.handToolLoadingData = nil
		self.xmlFile:delete()
		self.xmlFile = nil

		if self.externalSoundsFile ~= nil then
			self.externalSoundsFile:delete()
			self.externalSoundsFile = nil
		end

		self:loadCallback()

	else

		Logging.xmlError(self.xmlFile, "Failed to register handTool!")
		self:setLoadingState(HandToolLoadingState.ERROR)
		self:loadCallback()

	end

end