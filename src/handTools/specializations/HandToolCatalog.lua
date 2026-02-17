HandToolCatalog = {}

HandToolCatalog.numHeldCatalogs = 0
local specName = "spec_FS25_RealisticLivestock.catalog"

HandToolCatalog.OFFSET = {
	["LEFT"] = {
		["x"] = 0.134,
		["y"] = 2.359,
		["z"] = 0.476,
		["ry"] = math.rad(15)
	},
	["RIGHT"] = {
		["x"] = -0.134,
		["y"] = 2.359,
		["z"] = -0.637,
		["ry"] = math.rad(-15)
	}
}


function HandToolCatalog.registerFunctions(handTool)
	SpecializationUtil.registerFunction(handTool, "loadTexts", HandToolCatalog.loadTexts)
	SpecializationUtil.registerFunction(handTool, "resetZoom", HandToolCatalog.resetZoom)
	SpecializationUtil.registerFunction(handTool, "updateCatalog", HandToolCatalog.updateCatalog)
	SpecializationUtil.registerFunction(handTool, "changePage", HandToolCatalog.changePage)
	SpecializationUtil.registerFunction(handTool, "setAuctionActive", HandToolCatalog.setAuctionActive)
	SpecializationUtil.registerFunction(handTool, "registerMouseInput", HandToolCatalog.registerMouseInput)
	SpecializationUtil.registerFunction(handTool, "onClickPage", HandToolCatalog.onClickPage)
	SpecializationUtil.registerFunction(handTool, "createBaseTexts", HandToolCatalog.createBaseTexts)
end


function HandToolCatalog.registerOverwrittenFunctions(handTool)
	SpecializationUtil.registerOverwrittenFunction(handTool, "getShowInHandToolsOverview", HandToolCatalog.getShowInHandToolsOverview)
end


function HandToolCatalog.registerEventListeners(handTool)
	SpecializationUtil.registerEventListener(handTool, "onPostLoad", HandToolCatalog)
	SpecializationUtil.registerEventListener(handTool, "onDelete", HandToolCatalog)
	SpecializationUtil.registerEventListener(handTool, "onDraw", HandToolCatalog)
	SpecializationUtil.registerEventListener(handTool, "onRegisterActionEvents", HandToolCatalog)
	SpecializationUtil.registerEventListener(handTool, "onHeldStart", HandToolCatalog)
	SpecializationUtil.registerEventListener(handTool, "onHeldEnd", HandToolCatalog)
end


function HandToolCatalog.prerequisitesPresent()

	print("Loaded handTool: HandToolCatalog")

	return true

end


function HandToolCatalog:onPostLoad(savegame)

	if g_server ~= nil and (PlaceableAuctionMart.INSTANCE == nil or not PlaceableAuctionMart.INSTANCE:getIsAuctionOpen()) then
		g_currentMission.handToolSystem:markHandToolForDeletion(self)
		return
	end

	HandToolCatalog.numHeldCatalogs = HandToolCatalog.numHeldCatalogs + 1

	local spec = self[specName]

	spec.texts = {
		["base"] = {
			["nodes"] = {},
			["active"] = false
		}
	}

	spec.pageLeft = I3DUtil.indexToObject(self.rootNode, "0|1")
	spec.pageRight = I3DUtil.indexToObject(self.rootNode, "0|2")

	self:createBaseTexts()

	spec.zoom = {
		["level"] = 1,
		["active"] = false
	}

	spec.buttons = {}

	spec.mouseInputActive = false
	spec.mousePosX, spec.mousePosY = 0, 0

	spec.currentPage = 1
	spec.currentSection = 0

	spec.boundaries = {
		["start"] = I3DUtil.indexToObject(self.rootNode, "0|3|0"),
		["width"] = I3DUtil.indexToObject(self.rootNode, "0|3|1"),
		["height"] = I3DUtil.indexToObject(self.rootNode, "0|3|2")
	}

	local uiScale = g_gameSettings:getValue("uiScale")
	local sizeX, sizeY = getNormalizedScreenValues(HandTool.DEFAULT_CROSSHAIR_SIZE_PIXELS * uiScale, HandTool.DEFAULT_CROSSHAIR_SIZE_PIXELS * uiScale)

	spec.mouseOffsetX, spec.mouseOffsetY = sizeX / 2, sizeY / 2

	spec.crosshair = {
		["normal"] = self:createCrosshairOverlay("realistic_livestock.mouse_point"),
		["click"] = self:createCrosshairOverlay("realistic_livestock.mouse_click")
	}

	spec.crosshair.normal:setColor(nil, nil, nil, 1)
	spec.crosshair.click:setColor(nil, nil, nil, 1)

	self:setAuctionActive(true)
	HandToolCatalog.INSTANCE = self

end


function HandToolCatalog:onDelete()

	local spec = self[specName]

	HandToolCatalog.numHeldCatalogs = HandToolCatalog.numHeldCatalogs - 1

	if spec.crosshair ~= nil then

		spec.crosshair.normal:delete()
		spec.crosshair.click:delete()

		spec.crosshair = nil

	end

end


function HandToolCatalog:onDraw()

	local spec = self[specName]
	
	if not spec.mouseInputActive then return end

	if spec.mouseIsPointing then
		spec.crosshair.click:setPosition(spec.mousePosX + spec.mouseOffsetX, spec.mousePosY - spec.mouseOffsetY)
		spec.crosshair.click:render()
	else
		spec.crosshair.normal:setPosition(spec.mousePosX + spec.mouseOffsetX, spec.mousePosY - spec.mouseOffsetY)
		spec.crosshair.normal:render()
	end

end


function HandToolCatalog:setAuctionActive(active)

	if not active then

		if g_server ~= nil then g_currentMission.handToolSystem:markHandToolForDeletion(self) end
		
		HandToolCatalog.INSTANCE = nil

		return

	end

	local spec = self[specName]
	spec.animalTypes = PlaceableAuctionMart.INSTANCE:getAnimalTypes()

end


function HandToolCatalog:onRegisterActionEvents()

	if self:getIsActiveForInput(true) then

		local _, eventIdZoom = self:addActionEvent(InputAction.HANDS_LEVEL, self, HandToolCatalog.onZoom, false, true, false, true, nil)
		self[specName].activateActionEventId = eventIdZoom
		g_inputBinding:setActionEventTextPriority(eventIdZoom, GS_PRIO_VERY_HIGH)
		g_inputBinding:setActionEventText(eventIdZoom, "Zoom In")
		g_inputBinding:setActionEventActive(eventIdZoom, true)

		local _, eventIdPrevious = self:addActionEvent(InputAction.ACTIVATE_HANDTOOL, self, HandToolCatalog.onPagePrevious, false, true, false, true, nil)
		self[specName].pagePreviousEventId = eventIdPrevious
		g_inputBinding:setActionEventTextPriority(eventIdPrevious, GS_PRIO_VERY_HIGH)
		g_inputBinding:setActionEventText(eventIdPrevious, "Previous Page")
		g_inputBinding:setActionEventActive(eventIdPrevious, true)

		local _, eventIdNext = self:addActionEvent(InputAction.ACTIVATE_HANDTOOL_SECONDARY, self, HandToolCatalog.onPageNext, false, true, false, true, nil)
		self[specName].pageNextEventId = eventIdNext
		g_inputBinding:setActionEventTextPriority(eventIdNext, GS_PRIO_VERY_HIGH)
		g_inputBinding:setActionEventText(eventIdNext, "Next Page")
		g_inputBinding:setActionEventActive(eventIdNext, true)

		local _, eventIdMouse = self:addActionEvent(InputAction.ANIMAL_PET, self, HandToolCatalog.toggleMouseInput, false, true, false, true, nil)
		self[specName].toggleMouseEventId = eventIdMouse
		g_inputBinding:setActionEventTextPriority(eventIdMouse, GS_PRIO_VERY_HIGH)
		g_inputBinding:setActionEventText(eventIdMouse, "Activate Mouse Input")
		g_inputBinding:setActionEventActive(eventIdMouse, true)

		self:resetZoom()

	end

end


function HandToolCatalog:toggleMouseInput()

	local spec = self[specName]

	spec.mouseLastPosX, spec.mouseLastPosY = 0, 0
	spec.mousePosX, spec.mousePosY = 0.5, 0.5

	spec.mouseInputActive = not spec.mouseInputActive
	g_inputBinding:setShowMouseCursor(spec.mouseInputActive)
	setShowMouseCursor(false)
	g_currentMission.isPlayerFrozen = spec.mouseInputActive

	g_inputBinding:setActionEventText(spec.toggleMouseEventId, (spec.mouseInputActive and "Deactivate" or "Activate") .. " Mouse Input")
	g_inputBinding:setActionEventActive(spec.pagePreviousEventId, not spec.mouseInputActive)
	g_inputBinding:setActionEventActive(spec.pageNextEventId, not spec.mouseInputActive)

	if spec.mouseInputActive then
		addModEventListener(HandToolCatalog)
	else
		removeModEventListener(HandToolCatalog)	
	end

end


function HandToolCatalog:onPagePrevious()

	self:changePage(-1)

end


function HandToolCatalog:onPageNext()

	self:changePage(1)

end


function HandToolCatalog:changePage(delta)

	local spec = self[specName]
	local currentPage, currentSection, animalTypes = spec.currentPage, spec.currentSection, spec.animalTypes

	if currentSection == 0 and delta < 1 then return end

	local sectionToAnimalTypeIndex = {}

	for animalTypeIndex, animals in pairs(animalTypes) do table.insert(sectionToAnimalTypeIndex, animalTypeIndex) end

	if currentSection == #sectionToAnimalTypeIndex and delta > 0 and currentPage == #animalTypes[sectionToAnimalTypeIndex[currentSection]] then return end

	if currentSection == 0 or (delta > 0 and currentPage == #animalTypes[sectionToAnimalTypeIndex[currentSection]]) or (delta < 0 and currentPage == 0) then

		currentSection = currentSection + delta
		currentPage = (delta > 0 or currentSection == 0) and 0 or #animalTypes[sectionToAnimalTypeIndex[currentSection]]

	else

		currentPage = currentPage + delta

	end

	spec.currentPage, spec.currentSection = currentPage, currentSection

	self:loadTexts()

end


function HandToolCatalog:onZoom()

	local node = I3DUtil.indexToObject(self.rootNode, "0")
	local faceNode = I3DUtil.indexToObject(self.rootNode, "2")
	local spec = self[specName]
	
	local x, y = getTranslation(node)
	local _, _, z = getRotation(node)

	if spec.zoom.level == 1 then

		local tx, ty = getTranslation(faceNode)

		spec.zoom.level = 2
		spec.zoom.target = { tx / 16, ty / 2, math.rad(-25) }
		
		g_inputBinding:setActionEventText(spec.activateActionEventId, "Zoom Out")

	else

		spec.zoom.level = 1
		spec.zoom.target = { 0, 0, 0 }
		
		g_inputBinding:setActionEventText(spec.activateActionEventId, "Zoom In")

	end

	spec.zoom.active = true
	spec.zoom.current = { x, y, z }
	
	local dx, dy, dz = spec.zoom.target[1] - spec.zoom.current[1], spec.zoom.target[2] - spec.zoom.current[2], spec.zoom.target[3] - spec.zoom.current[3]
	spec.zoom.steps = { dx / (math.abs(dx) + math.abs(dy) + math.abs(dz)), dy / (math.abs(dx) + math.abs(dy) + math.abs(dz)), dz / (math.abs(dx) + math.abs(dy) + math.abs(dz)) }

	g_catalogUpdater:setCatalog(self)
	g_currentMission:addUpdateable(g_catalogUpdater)

end


function HandToolCatalog:resetZoom()

	local node = I3DUtil.indexToObject(self.rootNode, "0")
	setRotation(node, 0, 0, 0)
	setTranslation(node, 0, 0, 0)
	
	local spec = self[specName]

	spec.zoom.level = 1
	spec.zoom.current = { 0, 0, 0 }
	spec.zoom.active = false

end


function HandToolCatalog:onHeldStart()

	if self[specName].mouseInputActive then
		removeModEventListener(HandToolCatalog)
	end

	self[specName].mouseInputActive = false

	g_inputBinding:setShowMouseCursor(false)
	g_currentMission.isPlayerFrozen = false

	self:loadTexts()

end


function HandToolCatalog:onHeldEnd()

	if self[specName].mouseInputActive then
		removeModEventListener(HandToolCatalog)
	end

	self[specName].mouseInputActive = false

	g_inputBinding:setShowMouseCursor(false)
	g_currentMission.isPlayerFrozen = false

end


function HandToolCatalog:updateCatalog(dT)

	local spec = self[specName]
	local zoom = spec.zoom

	if not zoom.active then
		g_currentMission:removeUpdateable(g_catalogUpdater)
		return
	end

	local node = I3DUtil.indexToObject(self.rootNode, "0")

	if zoom.current[1] >= zoom.target[1] - 0.01 and zoom.current[1] <= zoom.target[1] + 0.01 then zoom.current[1] = zoom.target[1] end
	if zoom.current[2] >= zoom.target[2] - 0.01 and zoom.current[2] <= zoom.target[2] + 0.01 then zoom.current[2] = zoom.target[2] end
	if zoom.current[3] >= zoom.target[3] - 0.01 and zoom.current[3] <= zoom.target[3] + 0.01 then zoom.current[3] = zoom.target[3] end

	if zoom.current[1] ~= zoom.target[1] then zoom.current[1] = zoom.current[1] + zoom.steps[1] * dT * 0.001 end
	if zoom.current[2] ~= zoom.target[2] then zoom.current[2] = zoom.current[2] + zoom.steps[2] * dT * 0.001 end
	if zoom.current[3] ~= zoom.target[3] then zoom.current[3] = zoom.current[3] + zoom.steps[3] * dT * 0.001 end

	setTranslation(node, zoom.current[1], zoom.current[2], 0)
	setRotation(node, 0, 0, zoom.current[3])

	if zoom.current[1] == zoom.target[1] and zoom.current[2] == zoom.target[2] and zoom.current[3] == zoom.target[3] then

		zoom.active = false
		g_currentMission:removeUpdateable(g_catalogUpdater)

	end

end


function HandToolCatalog:saveToXMLFile(xmlFile, key)

	local spec = self[specName]

end


function HandToolCatalog:getShowInHandToolsOverview()

	return false

end


local function writeText(template, word, xOffset, yOffset, zOffset)

	local nodes = {}

	for index = 1, #word do

		local character = string.sub(word, index, index)
		local characterIndex = RealisticLivestock.getCharacterIndex(character) or RealisticLivestock.getCharacterIndex(character:upper())
		local characterOffset = math.floor(characterIndex / 64)

		local node = clone(template, true, false, false)
		setVisibility(node, true)
		setMaterial(node, getMaterial(node, characterOffset), 0)
		setShaderParameter(node, "playScale", characterIndex - 64 * characterOffset, 0, 64, 1, false)

		setTranslation(node, 0.187 + xOffset, yOffset, 0.65 + zOffset)
		setName(node, "clone")

		xOffset = xOffset - 0.007
		zOffset = zOffset - 0.03

		table.insert(nodes, node)

	end

	yOffset = yOffset - 0.1

	return xOffset, yOffset, zOffset, nodes

end


function HandToolCatalog:createBaseTexts()
	
	local spec = self[specName]
	local x, y, z, ry = HandToolCatalog.OFFSET.LEFT.x, HandToolCatalog.OFFSET.LEFT.y, HandToolCatalog.OFFSET.LEFT.z, HandToolCatalog.OFFSET.LEFT.ry
	local texts = { "infohud_name", "rl_ui_earTag", "rl_ui_animalOrigin", "rl_ui_breed", "infohud_age", "rl_ui_value" }
	local pageLeft = spec.pageLeft
	local nodes = spec.texts.base.nodes

	setTextColor(0, 0, 0, 1)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextBold(true)

	for _, text in pairs(texts) do

		local translatedText = g_i18n:getText(text) .. ": "
		local node = create3DLinkedText(pageLeft, x, y, z, 0, ry, 0, 0.1, translatedText)

		setVisibility(node, false)

		table.insert(nodes, {
			["width"] = getTextWidth(0.1, translatedText, nil, true, false, false),
			["type"] = text,
			["node"] = node
		})

		y = y - 0.1

	end

	setTextBold(false)

end


function HandToolCatalog:loadTexts()

	local animalTypes = PlaceableAuctionMart.INSTANCE:getAnimalTypes()
	local spec = self[specName]

	local texts = spec.texts

	spec.isReadyForMouseInput = false
	spec.buttons = {}

	local pageLeft = spec.pageLeft
	local pageRight = spec.pageRight
	local animalSystem = g_currentMission.animalSystem
	local currentSection, currentPage = spec.currentSection, spec.currentPage
	local textIndex = string.format("%s-%s", currentSection, currentPage)

	local sectionToAnimalTypeIndex = {}

	for animalTypeIndex, animals in pairs(animalTypes) do table.insert(sectionToAnimalTypeIndex, animalTypeIndex) end

	if currentSection == 0 then


		-- MAIN CONTENTS PAGE

		if texts[textIndex] == nil then
			-- Create texts and store in cache

			setTextColor(0, 0, 0, 1)

			local buttons = {}
			local nodes = {}

			if pageLeft ~= 0 then

				local x, y, z, ry = HandToolCatalog.OFFSET.LEFT.x, HandToolCatalog.OFFSET.LEFT.y, HandToolCatalog.OFFSET.LEFT.z, HandToolCatalog.OFFSET.LEFT.ry
				
				setTextAlignment(RenderText.ALIGN_LEFT)
				local pageNode = create3DLinkedText(pageLeft, 0.158, 2.654, 0.538, 0, ry, 0, 0.05, "01")

				table.insert(nodes, pageNode)

			end

			if pageRight ~= 0 then

				local x, y, z, ry = HandToolCatalog.OFFSET.RIGHT.x, HandToolCatalog.OFFSET.RIGHT.y, HandToolCatalog.OFFSET.RIGHT.z, HandToolCatalog.OFFSET.RIGHT.ry
				
				setTextAlignment(RenderText.ALIGN_RIGHT)
				local pageNode = create3DLinkedText(pageRight, 0.162, 2.655, -1.723, 0, ry, 0, 0.05, "02")

				table.insert(nodes, pageNode)

				local numAnimals = 2
				local yOffset = 0
				setTextBold(true)
				setTextAlignment(RenderText.ALIGN_CENTER)

				local titleNode = create3DLinkedText(pageRight, 0.006, 2.58, -1.14, 0, ry, 0, 0.15, "Contents")

				table.insert(nodes, titleNode)

				setTextBold(false)
				setTextAlignment(RenderText.ALIGN_LEFT)
				setTextIsButton(true)

				local highestTextWidth = 0
				local sepTextWidth = getTextWidth(0.1, ".", nil, true, false, false)
				local animalTypeIndexToWidth = {}

				for animalTypeIndex, animals in pairs(animalTypes) do

					local textWidth = getTextWidth(0.1, string.format("%s", 1 + numAnimals), nil, true, false, false)
					animalTypeIndexToWidth[animalTypeIndex] = textWidth

					if textWidth > highestTextWidth then highestTextWidth = textWidth end

					numAnimals = numAnimals + 2 + #animals * 2

				end

				numAnimals = 2

				for animalTypeIndex, animals in pairs(animalTypes) do

					local title = animalSystem.types[animalTypeIndex].groupTitle
					local sep = "...................."

					local textWidth = animalTypeIndexToWidth[animalTypeIndex]
				
					for i = 1, math.floor((highestTextWidth - textWidth) / sepTextWidth) do sep = sep .. "." end

					local textNode = create3DLinkedText(pageRight, x, y + yOffset, z, 0, ry, 0, 0.1, string.format("%s%s%s", 1 + numAnimals, sep, title))

					table.insert(nodes, textNode)
					yOffset = yOffset - 0.1

					local button = {
						["start"] = getChild(textNode, "start"),
						["width"] = getChild(textNode, "width"),
						["height"] = getChild(textNode, "height"),
						["callback"] = HandToolCatalog.onClickPage,
						["args"] = 1 + numAnimals
					}

					numAnimals = numAnimals + 2 + #animals * 2

					table.insert(buttons, button)

				end

				setTextIsButton(false)

			end

			texts[textIndex] = {
				["nodes"] = nodes,
				["active"] = true,
				["buttons"] = buttons
			}

		else
			-- Load stored texts from cache

			for _, node in pairs(texts[textIndex].nodes) do setVisibility(node, true) end

			texts[textIndex].active = true

		end

		for index, data in pairs(texts) do

			if index ~= textIndex and data.active then

				data.active = false
				for _, node in pairs(data.nodes) do setVisibility(index == "base" and node.node or node, false) end

			end

		end

		spec.buttons = texts[textIndex].buttons

	elseif currentPage == 0 then


		-- ANIMAL TYPE CONTENTS PAGE

		if texts[textIndex] == nil then
			-- Create texts and store in cache
			
			local buttons = {}
			local nodes = {}
			local pageNumber = 3

			for i = 1, currentSection - 1 do pageNumber = pageNumber + 2 + #animalTypes[sectionToAnimalTypeIndex[i]] * 2 end

			setTextColor(0, 0, 0, 1)

			if pageLeft ~= 0 then

				local x, y, z, ry = HandToolCatalog.OFFSET.LEFT.x, HandToolCatalog.OFFSET.LEFT.y, HandToolCatalog.OFFSET.LEFT.z, HandToolCatalog.OFFSET.LEFT.ry
				
				setTextAlignment(RenderText.ALIGN_LEFT)
				local pageNode = create3DLinkedText(pageLeft, 0.158, 2.654, 0.538, 0, ry, 0, 0.05, string.format("%s%s", pageNumber < 10 and "0" or "", pageNumber))

				table.insert(nodes, pageNode)

			end

			if pageRight ~= 0 then

				local x, y, z, ry = HandToolCatalog.OFFSET.RIGHT.x, HandToolCatalog.OFFSET.RIGHT.y, HandToolCatalog.OFFSET.RIGHT.z, HandToolCatalog.OFFSET.RIGHT.ry
				
				setTextAlignment(RenderText.ALIGN_RIGHT)
				local pageNode = create3DLinkedText(pageRight, 0.162, 2.655, -1.723, 0, ry, 0, 0.05, string.format("%s%s", (pageNumber + 1) < 10 and "0" or "", pageNumber + 1))

				table.insert(nodes, pageNode)

				setTextBold(true)
				setTextAlignment(RenderText.ALIGN_CENTER)

				local titleNode = create3DLinkedText(pageRight, 0.006, 2.58, -1.14, 0, ry, 0, 0.15, animalSystem.types[sectionToAnimalTypeIndex[currentSection]].groupTitle)

				table.insert(nodes, titleNode)

				setTextBold(false)
				setTextAlignment(RenderText.ALIGN_LEFT)
				setTextIsButton(true)

				local highestTextWidth = 0
				local sepTextWidth = getTextWidth(0.1, ".", nil, true, false, false)
				local animalIndexToWidth = {}
				local yOffset = 0

				for i, animal in pairs(animalTypes[sectionToAnimalTypeIndex[currentSection]]) do

					local textWidth = getTextWidth(0.1, string.format("%s", pageNumber + i * 2), nil, true, false, false)
					animalIndexToWidth[i] = textWidth

					if textWidth > highestTextWidth then highestTextWidth = textWidth end

				end

				for i, animal in pairs(animalTypes[sectionToAnimalTypeIndex[currentSection]]) do
					
					local sep = "...................."
					local textWidth = animalIndexToWidth[i]
				
					for i = 1, math.floor((highestTextWidth - textWidth) / sepTextWidth) do sep = sep .. "." end

					local textNode = create3DLinkedText(pageRight, x, y + yOffset, z, 0, ry, 0, 0.1, string.format("%s%s%s", pageNumber + i * 2, sep, animal:getIdentifiers()))

					table.insert(nodes, textNode)
					yOffset = yOffset - 0.1

					local button = {
						["start"] = getChild(textNode, "start"),
						["width"] = getChild(textNode, "width"),
						["height"] = getChild(textNode, "height"),
						["callback"] = HandToolCatalog.onClickPage,
						["args"] = pageNumber + i * 2
					}

					table.insert(buttons, button)
				
				end

				setTextIsButton(false)

			end

			texts[textIndex] = {
				["nodes"] = nodes,
				["active"] = true,
				["buttons"] = buttons
			}

		else
			-- Load stored texts from cache

			for _, node in pairs(texts[textIndex].nodes) do setVisibility(node, true) end

			texts[textIndex].active = true

		end

		for index, data in pairs(texts) do

			if index ~= textIndex and data.active then

				data.active = false
				for _, node in pairs(data.nodes) do setVisibility(index == "base" and node.node or node, false) end

			end

		end
		
		spec.buttons = texts[textIndex].buttons

	else


		-- ANIMAL PAGE

		if texts[textIndex] == nil then
			-- Create texts and store in cache

			local nodes = {}

			local currentAnimal = animalTypes[sectionToAnimalTypeIndex[currentSection]][currentPage]
			local pageNumber = 3

			for i = 1, currentSection - 1 do pageNumber = pageNumber + 2 + #animalTypes[sectionToAnimalTypeIndex[i]] * 2 end

			pageNumber = pageNumber + currentPage * 2

			local title = animalSystem.types[currentAnimal.animalTypeIndex].groupTitle

			setTextColor(0, 0, 0, 1)

			if pageLeft ~= nil and pageLeft ~= 0 then

				local x, y, z, ry = HandToolCatalog.OFFSET.LEFT.x, HandToolCatalog.OFFSET.LEFT.y, HandToolCatalog.OFFSET.LEFT.z, HandToolCatalog.OFFSET.LEFT.ry
				
				setTextAlignment(RenderText.ALIGN_LEFT)
				local pageNode = create3DLinkedText(pageLeft, 0.158, 2.654, 0.538, 0, ry, 0, 0.05, string.format("%s%s", pageNumber < 10 and "0" or "", pageNumber))

				table.insert(nodes, pageNode)

				setTextBold(true)
				setTextAlignment(RenderText.ALIGN_CENTER)

				local titleNode = create3DLinkedText(pageLeft, 0.017, 2.58, 0.031, 0, ry, 0, 0.15, title)

				table.insert(nodes, titleNode)

				setTextBold(false)
				setTextAlignment(RenderText.ALIGN_LEFT)

				local yOffset = 0
				local subType = currentAnimal:getSubType()
				local baseTexts = texts.base.nodes

				for _, baseText in pairs(baseTexts) do

					local text

					if baseText.type == "infohud_name" then
						text = currentAnimal.name or "N/A"
					elseif baseText.type == "rl_ui_earTag" then
						text = currentAnimal:getIdentifiers()
					elseif baseText.type == "rl_ui_animalOrigin" then
						text = RealisticLivestock.AREA_CODES[currentAnimal.birthday.country].country
					elseif baseText.type == "rl_ui_breed" then
						text = g_fillTypeManager:getFillTypeTitleByIndex(subType.fillTypeIndex)
					elseif baseText.type == "infohud_age" then
						text = RealisticLivestock.formatAge(currentAnimal.age)
					elseif baseText.type == "rl_ui_value" then
						text = g_i18n:formatMoney(currentAnimal:getSellPrice(), 2, true, true)
					end

					local textNode = create3DLinkedText(pageLeft, x - baseText.width / 4, y + yOffset, z - baseText.width, 0, ry, 0, 0.1, text)
					table.insert(nodes, textNode)

					yOffset = yOffset - 0.1

				end

			end

			if pageRight ~= nil and pageRight ~= 0 then

				local x, y, z, ry = HandToolCatalog.OFFSET.RIGHT.x, HandToolCatalog.OFFSET.RIGHT.y, HandToolCatalog.OFFSET.RIGHT.z, HandToolCatalog.OFFSET.RIGHT.ry
				
				setTextAlignment(RenderText.ALIGN_RIGHT)
				pageNumber  = pageNumber + 1
				local pageNode = create3DLinkedText(pageRight, 0.162, 2.655, -1.723, 0, ry, 0, 0.05, string.format("%s%s", pageNumber < 10 and "0" or "", pageNumber))

				table.insert(nodes, pageNode)

				setTextBold(true)
				setTextAlignment(RenderText.ALIGN_CENTER)

				local titleNode = create3DLinkedText(pageRight, 0.006, 2.58, -1.14, 0, ry, 0, 0.15, title)

				table.insert(nodes, titleNode)

				setTextBold(false)
				setTextAlignment(RenderText.ALIGN_LEFT)

			end

			texts[textIndex] = {
				["nodes"] = nodes,
				["active"] = true
			}

		else
			-- Load stored texts from cache

			for _, node in pairs(texts[textIndex].nodes) do setVisibility(node, true) end

			texts[textIndex].active = true

		end

		for index, data in pairs(texts) do

			if index == "base" and not data.active then

				data.active = true
				for _, node in pairs(data.nodes) do setVisibility(node.node, true) end

			elseif index ~= textIndex and index ~= "base" and data.active then

				data.active = false
				for _, node in pairs(data.nodes) do setVisibility(node, false) end

			end

		end

	end

	spec.isReadyForMouseInput = #spec.buttons > 0

end


function HandToolCatalog:registerMouseInput(posX, posY, isDown, isUp)

	local spec = self[specName]
	
	spec.mouseIsPointing = false

	if spec.mouseLastPosX == nil or spec.mouseLastPosY == nil then
		spec.mouseLastPosX, spec.mouseLastPosY = posX, posY
		return
	end

	local dx, dy = math.abs(posX - spec.mouseLastPosX), math.abs(posY - spec.mouseLastPosY)

	local stepX, stepY = 0, 0
	
	if dx + dy ~= 0 then stepX, stepY = (posX - spec.mouseLastPosX) / (dx + dy), (posY - spec.mouseLastPosY) / (dx + dy) end

	spec.mousePosX = spec.mousePosX + stepX * 0.002
	spec.mousePosY = spec.mousePosY + stepY * 0.002

	spec.mouseLastPosX, spec.mouseLastPosY = posX, posY

	spec.mousePosX = math.clamp(spec.mousePosX, 0, 1)
	spec.mousePosY = math.clamp(spec.mousePosY, 0, 1)

	local x, y = spec.mousePosX, spec.mousePosY

	--spec.mousePosX, spec.mousePosY = math.clamp(posX, 0, 1), math.clamp(posY, 0, 1)

	if not spec.isReadyForMouseInput or #spec.buttons == 0 then return end

	local sx, sy, sz = getWorldTranslation(spec.boundaries.start)
	local wx, wy, wz = getWorldTranslation(spec.boundaries.width)
	local hx, hy, hz = getWorldTranslation(spec.boundaries.height)

	local spx, spy = project(sx, sy, sz)
	local wpx, wpy = project(wx, wy, wz)
	local hpx, hpy = project(hx, hy, hz)

	if x < spx or x > wpx or y < spy or y > hpy then return end

	for _, button in pairs(spec.buttons) do

		local bsx, bsy, bsz = getWorldTranslation(button.start)
		local bwx, bwy, bwz = getWorldTranslation(button.width)
		local bhx, bhy, bhz = getWorldTranslation(button.height)

		local bspx, bspy = project(bsx, bsy, bsz)
		local bwpx, bwpy = project(bwx, bwy, bwz)
		local bhpx, bhpy = project(bhx, bhy, bhz)

		if x < bspx or x > bwpx or y < bspy or y > bhpy then continue end

		spec.mouseIsPointing = true

		if isUp then button.callback(self, button.args) end
	
		return

	end

end


function HandToolCatalog:onClickPage(page)

	local spec = self[specName]

	spec.buttons = {}

	local currentPage = 1
	local currentSection = 0
	local index = 0

	for animalTypeIndex, animals in pairs(spec.animalTypes) do

		index = 0

		currentPage = currentPage + 2
		currentSection = currentSection + 1

		if currentPage == page then break end

		if page >= currentPage + #animals * 2 then
			currentPage = currentPage + #animals * 2
			continue
		end

		local correctPage = false

		for _, animal in pairs(animals) do

			index = index + 1
			currentPage = currentPage + 2

			if currentPage ~= page then continue end

			correctPage = true
			break

		end

		if correctPage then break end

	end

	spec.currentSection, spec.currentPage, spec.isReadyForMouseInput = currentSection, index, false
	self:loadTexts()

end


function HandToolCatalog.mouseEvent(_, posX, posY, isDown, isUp)

	HandToolCatalog.INSTANCE:registerMouseInput(posX, posY, isDown, isUp)

end