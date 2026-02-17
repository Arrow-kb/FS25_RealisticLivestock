PlaceableAuctionMart = {}


PlaceableAuctionMart.INACTIVE = 1
PlaceableAuctionMart.PREPARING = 2
PlaceableAuctionMart.ACTIVE = 3
PlaceableAuctionMart.FINISHED = 4

PlaceableAuctionMart.DISPLAY_NEW = 1
PlaceableAuctionMart.DISPLAY_RESULT = 2


MessageType.ANIMAL_AUCTION_STARTED = nextMessageTypeId()
MessageType.ANIMAL_AUCTION_FINISHED = nextMessageTypeId()
MessageType.ANIMAL_BIDDING_STARTED = nextMessageTypeId()
MessageType.ANIMAL_BIDDING_ENDED = nextMessageTypeId()


local specName = "spec_FS25_RealisticLivestock.auctionMart"
local npcPath = "0|7"
local modDirectory = g_currentModDirectory

g_xmlManager:addInitSchemaFunction(function()
	PlayerStyle.registerSavegameXMLPaths(Placeable.xmlSchemaSavegame, "playerStyle")
end)


function PlaceableAuctionMart.registerXMLPaths(schema, basePath)
	PlayerStyle.registerSavegameXMLPaths(Placeable.xmlSchemaSavegame, "placeables.placeable(?).FS25_RealisticLivestock.auctionMart.npcs.npc(?).playerStyle")
end


function PlaceableAuctionMart.registerEventListeners(placeable)
	SpecializationUtil.registerEventListener(placeable, "onPostLoad", PlaceableAuctionMart)
	SpecializationUtil.registerEventListener(placeable, "onFinalizePlacement", PlaceableAuctionMart)
	SpecializationUtil.registerEventListener(placeable, "onMinuteChanged", PlaceableAuctionMart)
	SpecializationUtil.registerEventListener(placeable, "onHourChanged", PlaceableAuctionMart)
	SpecializationUtil.registerEventListener(placeable, "onDayChanged", PlaceableAuctionMart)
end


function PlaceableAuctionMart.registerFunctions(placeable)
	SpecializationUtil.registerFunction(placeable, "prepareAuction", PlaceableAuctionMart.prepareAuction)
	SpecializationUtil.registerFunction(placeable, "startAuction", PlaceableAuctionMart.startAuction)
	SpecializationUtil.registerFunction(placeable, "endAuction", PlaceableAuctionMart.endAuction)
	SpecializationUtil.registerFunction(placeable, "getAnimalTypes", PlaceableAuctionMart.getAnimalTypes)
	SpecializationUtil.registerFunction(placeable, "signIn", PlaceableAuctionMart.signIn)
	SpecializationUtil.registerFunction(placeable, "getRandomName", PlaceableAuctionMart.getRandomName)
	SpecializationUtil.registerFunction(placeable, "generateNPC", PlaceableAuctionMart.generateNPC)
	SpecializationUtil.registerFunction(placeable, "updateAuction", PlaceableAuctionMart.updateAuction)
	SpecializationUtil.registerFunction(placeable, "createNavigation", PlaceableAuctionMart.createNavigation)
	SpecializationUtil.registerFunction(placeable, "addNPCToSignInQueue", PlaceableAuctionMart.addNPCToSignInQueue)
	SpecializationUtil.registerFunction(placeable, "getIsAuctionOpen", PlaceableAuctionMart.getIsAuctionOpen)
	SpecializationUtil.registerFunction(placeable, "getCurrentAnimal", PlaceableAuctionMart.getCurrentAnimal)
	SpecializationUtil.registerFunction(placeable, "getState", PlaceableAuctionMart.getState)
	SpecializationUtil.registerFunction(placeable, "startBidding", PlaceableAuctionMart.startBidding)
	SpecializationUtil.registerFunction(placeable, "endBidding", PlaceableAuctionMart.endBidding)
	SpecializationUtil.registerFunction(placeable, "updateDigitalDisplay", PlaceableAuctionMart.updateDigitalDisplay)
	SpecializationUtil.registerFunction(placeable, "onAnimalLoaded", PlaceableAuctionMart.onAnimalLoaded)
	SpecializationUtil.registerFunction(placeable, "onBid", PlaceableAuctionMart.onBid)
	SpecializationUtil.registerFunction(placeable, "getIsBiddingAllowed", PlaceableAuctionMart.getIsBiddingAllowed)
	SpecializationUtil.registerFunction(placeable, "getPlayerPosition", PlaceableAuctionMart.getPlayerPosition)
	SpecializationUtil.registerFunction(placeable, "getNextBid", PlaceableAuctionMart.getNextBid)
	SpecializationUtil.registerFunction(placeable, "getBiddingWinner", PlaceableAuctionMart.getBiddingWinner)
end


function PlaceableAuctionMart.registerOverwrittenFunctions(placeable)
	SpecializationUtil.registerOverwrittenFunction(placeable, "getNeedMinuteChanged", PlaceableAuctionMart.getNeedMinuteChanged)
	SpecializationUtil.registerOverwrittenFunction(placeable, "getNeedHourChanged", PlaceableAuctionMart.getNeedHourChanged)
	SpecializationUtil.registerOverwrittenFunction(placeable, "getNeedDayChanged", PlaceableAuctionMart.getNeedDayChanged)
end


function PlaceableAuctionMart.prerequisitesPresent()

	print("Loaded placeable: PlaceableAuctionMart")

	return true

end


function PlaceableAuctionMart:onPostLoad(savegame)

	local spec = self[specName]

	g_auctionMart = self

	spec.playerCache = { ["x"] = 0, ["y"] = 0, ["z"] = 0 }
	spec.navigation = {}
	spec.signIn = { ["ready"] = false, ["queue"] = {}, ["queueTimer"] = 0, ["isQueueMoving"] = false, ["timeSinceLastSignIn"] = 0 }
	spec.state = PlaceableAuctionMart.INACTIVE
	spec.npcNodes = I3DUtil.indexToObject(self.rootNode, npcPath)
	spec.digitalDisplay = AuctionDigitalDisplay.new(self, I3DUtil.indexToObject(self.rootNode, "0|10"))
	spec.bidding = {
		["bidders"] = {}
	}
	spec.whiteboard = {
		["node"] = I3DUtil.indexToObject(self.rootNode, "0|11"),
		["text"] = {}
	}

	if spec.navigation.bidder == nil then self:createNavigation("bidder") end
	if spec.navigation.herdsman == nil then self:createNavigation("herdsman") end
	if spec.navigation.writer == nil then self:createNavigation("writer") end

	if savegame == nil or savegame.xmlFile == nil then return end

	PlaceableAuctionMart.INSTANCE = self

	local xmlFile, key = savegame.xmlFile, savegame.key .. ".FS25_RealisticLivestock.auctionMart"

	spec.state = xmlFile:getInt(key .. "#state", 1)

	if spec.state == PlaceableAuctionMart.PREPARING or spec.state == PlaceableAuctionMart.ACTIVE then

		local signIn = spec.signIn
		signIn.bidders = {}
		signIn.availableNPCNodes = {}

		signIn.numBidders = xmlFile:getInt(key .. "#numBidders")
		signIn.timeSinceLastSignIn = xmlFile:getInt(key .. "#timeSinceLastSignIn", 0)

		if self.rootNode ~= nil and self.rootNode ~= 0 then

			signIn.node = I3DUtil.indexToObject(self.rootNode, "0|9|0")
			spec.herdsmanNavigationNode = I3DUtil.indexToObject(self.rootNode, "0|8|0")
			spec.bidderNavigationNode = I3DUtil.indexToObject(self.rootNode, "0|8|1")
			
			local x, y, z = -0.553, 0.589, 0.52
			signIn.xOffset, signIn.yOffset, signIn.zOffset = x, y, z

		end

		xmlFile:iterate(key .. ".npcs.npc", function(_, npcKey)

			local type = xmlFile:getString(npcKey .. "#type")
			local parent = xmlFile:getString(npcKey .. "#parent")
			local npc
			
			if type == "auctioneer" then

				npc = Auctioneer.new(self, getChild(spec.npcNodes, parent))
				npc:loadTemplate()

				spec.auctioneer = npc

			elseif type == "herdsman" then

				local pathName = xmlFile:getString(npcKey .. ".target#path", "path1")

				npc = AuctionHerdsman.new(self, getChild(spec.npcNodes, parent), spec.navigation.herdsman.node, spec.navigation.herdsman.paths, pathName)
				npc:loadTemplate()

				spec.herdsman = npc

			elseif type == "writer" then

				npc = AuctionWriter.new(self, getChild(spec.npcNodes, parent), spec.navigation.writer.node, spec.navigation.writer.paths.path1, spec.whiteboard.node)
				npc:loadTemplate()

				spec.whiteboard.npc = npc

			elseif type == "bidder" then

				npc = AuctionBidder.new(self, getChild(spec.npcNodes, parent), spec.navigation.bidder.node, spec.navigation.bidder.paths[parent])

			end

			npc:loadFromXMLFile(xmlFile, npcKey)
			npc:load()

			if type == "bidder" then

				table.insert(signIn.bidders, npc)

				if npc.target.index == 1 then
					self:addNPCToSignInQueue(npc)
				else
					self:signIn(true, npc)
				end

			end

		end)

		xmlFile:iterate(key .. ".availableNPCNodes.node", function(_, nodeKey)
		
			table.insert(signIn.availableNPCNodes, xmlFile:getString(nodeKey .. "#value"))
		
		end)

		spec.animalTypes = {}

		xmlFile:iterate(key .. ".animals.type", function(_, animalTypeKey)
		
			local animalTypeIndex = xmlFile:getInt(animalTypeKey .. "#index")
			local animals = {}

			xmlFile:iterate(animalTypeKey .. ".animal", function(_, animalKey)
			
				local animal = Animal.loadFromXMLFile(xmlFile, animalKey)
				
				if animal ~= nil then table.insert(animals, animal) end
			
			end)

			spec.animalTypes[animalTypeIndex] = animals
		
		end)

		if HandToolCatalog.INSTANCE ~= nil then HandToolCatalog.INSTANCE:setAuctionActive(true) end

		spec.digitalDisplay:setActive(true)

		if spec.state == PlaceableAuctionMart.PREPARING then
			spec.digitalDisplay:setText("Auction starting soon...")
		elseif spec.state == PlaceableAuctionMart.ACTIVE then

			spec.currentAnimalTypeIndex = xmlFile:getInt(key .. "#currentAnimalTypeIndex")
			spec.currentAnimalIndex = xmlFile:getInt(key .. "#currentAnimalIndex")

			local animal = self:getCurrentAnimal()
			local subType = animal:getSubType()
			spec.digitalDisplay:setText(string.format("%s (%s): %s", animal:getIdentifiers(), g_fillTypeManager:getFillTypeTitleByIndex(subType.fillTypeIndex), g_i18n:formatMoney(animal:getSellPrice(), 2, true, true)))
		end

	end

end


function PlaceableAuctionMart:onFinalizePlacement()

	local spec = self[specName]

	if spec.navigation.bidder == nil then self:createNavigation("bidder") end
	if spec.navigation.herdsman == nil then self:createNavigation("herdsman") end
	if spec.navigation.writer == nil then self:createNavigation("writer") end

	if self.rootNode ~= nil and self.rootNode ~= 0 then

		spec.npcNodes = I3DUtil.indexToObject(self.rootNode, npcPath)
		spec.signIn.node = I3DUtil.indexToObject(self.rootNode, "0|9|0")
		spec.herdsmanNavigationNode = I3DUtil.indexToObject(self.rootNode, "0|8|0")

	end

	local xmlFile = XMLFile.loadIfExists("npcNames", modDirectory .. "xml/npcNames.xml")

	spec.npcNames = { ["playerM"] = {}, ["playerF"] = {} }

	if xmlFile ~= nil then

		xmlFile:iterate("npcNames.male.name", function(_, key)

			table.insert(spec.npcNames.playerM, xmlFile:getString(key .. "#value"))

		end)

		xmlFile:iterate("npcNames.female.name", function(_, key)

			table.insert(spec.npcNames.playerF, xmlFile:getString(key .. "#value"))

		end)

		xmlFile:delete()

	end

	PlaceableAuctionMart.INSTANCE = self
	g_auctionUpdater:setPlaceable(self)
	g_currentMission:addUpdateable(g_auctionUpdater)

end


function PlaceableAuctionMart:saveToXMLFile(xmlFile, key)

	local spec = self[specName]

	spec.state = spec.state or PlaceableAuctionMart.INACTIVE

	xmlFile:setInt(key .. "#state", spec.state)

	local signIn = spec.signIn

	if spec.state == PlaceableAuctionMart.PREPARING or spec.state == PlaceableAuctionMart.ACTIVE then

		xmlFile:setInt(key .. "#timeSinceLastSignIn", signIn.timeSinceLastSignIn)

		for i, npc in pairs(signIn.bidders) do npc:saveToXMLFile(xmlFile, string.format("%s.npcs.npc(%s)", key, i - 1)) end

		spec.auctioneer:saveToXMLFile(xmlFile, string.format("%s.npcs.npc(%s)", key, #signIn.bidders))
		spec.herdsman:saveToXMLFile(xmlFile, string.format("%s.npcs.npc(%s)", key, #signIn.bidders + 1))
		spec.whiteboard.npc:saveToXMLFile(xmlFile, string.format("%s.npcs.npc(%s)", key, #signIn.bidders + 2))

		xmlFile:setSortedTable(string.format("%s.availableNPCNodes.node", key), signIn.availableNPCNodes, function(nodeKey, node)
		
			xmlFile:setString(nodeKey .. "#value", node)
		
		end)

		xmlFile:setInt(key .. "#numBidders", signIn.numBidders)

		local index = 0

		for animalTypeIndex, animals in pairs(spec.animalTypes) do

			local animalTypeKey = string.format("%s.animals.type(%s)", key, index)
			xmlFile:setInt(animalTypeKey .. "#index", animalTypeIndex)

			for i, animal in pairs(animals) do

				animal:saveToXMLFile(xmlFile, string.format("%s.animal(%s)", animalTypeKey, i - 1))

			end

			index = index + 1

		end

		if spec.state == PlaceableAuctionMart.ACTIVE then

			xmlFile:setInt(key .. "#currentAnimalTypeIndex", spec.currentAnimalTypeIndex)
			xmlFile:setInt(key .. "#currentAnimalIndex", spec.currentAnimalIndex)

			local bidding = spec.bidding

			if bidding.active then

				xmlFile:setBool(key .. ".bidding#active", true)
				xmlFile:setFloat(key .. ".bidding#timer", bidding.timer)
				xmlFile:setFloat(key .. ".bidding#timeSinceLastBid", bidding.timeSinceLastBid)
				xmlFile:setFloat(key .. ".bidding#nextBid", bidding.nextBid)
				xmlFile:setInt(key .. ".bidding#announcement", bidding.announcement)

				if bidding.winner.id ~= nil then
					xmlFile:setInt(key .. ".bidding.winner#id", bidding.winner.id)
					xmlFile:setFloat(key .. ".bidding.winner#price", bidding.winner.price)
				end

			end

		end

	end

end


function PlaceableAuctionMart:getNeedMinuteChanged()

	return true

end


function PlaceableAuctionMart:getNeedHourChanged()

	return true

end


function PlaceableAuctionMart:getNeedDayChanged()

	return true

end


function PlaceableAuctionMart:onMinuteChanged()

	local spec = self[specName]
	local signIn = spec.signIn

	if spec.state == PlaceableAuctionMart.PREPARING then

		if #signIn.bidders < signIn.numBidders and signIn.timeSinceLastSignIn >= math.random(1, 8) then

			signIn.timeSinceLastSignIn = 0
			self:generateNPC()
		
		else

			signIn.timeSinceLastSignIn = signIn.timeSinceLastSignIn + 1

		end

	end

end


function PlaceableAuctionMart:onHourChanged(hour)

	local spec = self[specName]

	if spec.state == PlaceableAuctionMart.INACTIVE and hour >= 7 and hour <= 9 then

		--self:prepareAuction()

	elseif spec.state == PlaceableAuctionMart.PREPARING and hour >= 10 and hour <= 12 then

		--self:startAuction()

	elseif spec.state == PlaceableAuctionMart.ACTIVE and hour >= 19 then

		--self:endAuction()

	end

end


function PlaceableAuctionMart:onDayChanged()

	local spec = self[specName]

	if spec.state == PlaceableAuctionMart.FINISHED then spec.state = PlaceableAuctionMart.INACTIVE end

end


function PlaceableAuctionMart:generateNPC()

	local spec = self[specName]
	local npcNodes = spec.npcNodes
	local signIn = spec.signIn

	if #signIn.availableNPCNodes == 0 then return end

	local index = math.random(1, #signIn.availableNPCNodes)
	local node = getChild(spec.npcNodes, signIn.availableNPCNodes[index])
	local name = getName(node)

	local npc = AuctionBidder.new(self, node, spec.navigation.bidder.node, spec.navigation.bidder.paths[name])
	npc.id = AuctionBidder.NEXT_ID
	AuctionBidder.NEXT_ID = AuctionBidder.NEXT_ID + 1
	npc:randomiseCustomisation()
	npc:setName(self:getRandomName(npc.gender))
	npc:load()

	table.remove(signIn.availableNPCNodes, index)
	table.insert(signIn.bidders, npc)

	self:addNPCToSignInQueue(npc)

end


function PlaceableAuctionMart:getRandomName(gender)

	local spec = self[specName]

	return spec.npcNames[gender][math.random(1, #spec.npcNames[gender])]

end


function PlaceableAuctionMart:addNPCToSignInQueue(npc)

	local spec = self[specName]
	local signIn = spec.signIn

	table.insert(signIn.queue, npc)

	npc:setTarget(1)
	npc.z = npc.z - 2 - #signIn.queue * 0.8
	npc.isIdle = true

end


function PlaceableAuctionMart:signIn(isNpc, npc)

	local spec = self[specName]

	if spec.state ~= PlaceableAuctionMart.PREPARING then return false end

	local signIn = spec.signIn

	signIn.ready = false

	setTextFont(RealisticLivestock.FONTS[isNpc and npc:getFontName() or "ink_free"])
	setTextColor(0, 0, 0, 1)

	create3DLinkedText(signIn.node, signIn.xOffset, signIn.yOffset, signIn.zOffset, 0, 0, math.pi / 2, 0.05 * (isNpc and npc:getFontSize() or 1), isNpc and npc:getName() or npc:getNickname())

	setTextFont()
	setTextColor(1, 1, 1, 1)

	table.insert(spec.bidding.bidders, npc)

	signIn.xOffset = signIn.xOffset + 0.098
	signIn.ready = true

	return true

end


function PlaceableAuctionMart:prepareAuction()

	local spec = self[specName]
	spec.state = PlaceableAuctionMart.PREPARING

	local animalTypes = g_currentMission.animalSystem:createAuctionAnimals()
	local hasAnimals = false

	for _, animals in pairs(animalTypes) do
		if #animals > 0 then
			hasAnimals = true
			break
		end
	end

	if not hasAnimals then return end

	spec.animalTypes = animalTypes

	local maxNumBidders = getNumOfChildren(spec.npcNodes) - 2
	
	local signIn = spec.signIn

	signIn.numBidders = math.random(4, maxNumBidders)
	signIn.bidders = {}

	local x, y, z = -0.553, 0.589, 0.52
	signIn.xOffset, signIn.yOffset, signIn.zOffset = x, y, z

	for i = getNumOfChildren(signIn.node), 1, -1 do

		local node = getChildAt(signIn.node, i - 1)
		if getName(node) == "clone" then delete(node) end

	end

	
	local availableNPCNodes = {}

	for i = 1, getNumOfChildren(spec.npcNodes) do

		local node = getChildAt(spec.npcNodes, i - 1)
		local name = getName(node)
		local npc

		if name == "auctioneer" then

			npc = Auctioneer.new(self, node)
			npc:loadTemplate()

			spec.auctioneer = npc

		elseif name == "auctionHerdsman" then

			npc = AuctionHerdsman.new(self, node, spec.navigation.herdsman.node, spec.navigation.herdsman.paths, "path1")
			npc:loadTemplate()

			spec.herdsman = npc

		elseif name == "auctionWriter" then

			npc = AuctionWriter.new(self, node, spec.navigation.writer.node, spec.navigation.writer.paths.path1, spec.whiteboard.node)
			npc:loadTemplate()

			spec.whiteboard.npc = npc
		
		else

			table.insert(availableNPCNodes, name)
			continue

		end

		npc:load()
		spec[name] = npc

	end


	signIn.availableNPCNodes = availableNPCNodes
	signIn.timeSinceLastSignIn = 0
	signIn.ready = true

	spec.digitalDisplay:setText("Auction starting soon...")
	spec.digitalDisplay:setActive(true)

end


function PlaceableAuctionMart:startAuction()

	local spec = self[specName]
	local animalTypes = spec.animalTypes

	spec.state = PlaceableAuctionMart.ACTIVE

	spec.currentAnimalTypeIndex, spec.currentAnimalIndex = 1, 1

	for i, _ in pairs(animalTypes) do
		spec.currentAnimalTypeIndex = i
		break
	end

	g_messageCenter:publish(MessageType.ANIMAL_AUCTION_STARTED)

end


function PlaceableAuctionMart:endAuction()

	local spec = self[specName]
	
	spec.digitalDisplay:clear()
	spec.digitalDisplay:setActive(false)
	spec.state = PlaceableAuctionMart.FINISHED

	local signIn = spec.signIn

	signIn.ready = false

	for _, npc in pairs(signIn.bidders) do npc:delete() end

	if spec.auctioneer ~= nil then spec.auctioneer:delete() end
	if spec.herdsman ~= nil then spec.herdsman:delete() end
	if spec.whiteboard.npc ~= nil then spec.whiteboard.npc:delete() end

	signIn.bidders, spec.auctioneer, spec.herdsman, spec.whiteboard.npc = {}, nil, nil, nil

	local book = spec.signIn.node

	if HandToolCatalog.INSTANCE ~= nil then HandToolCatalog.INSTANCE:setAuctionActive(false) end

	g_messageCenter:publish(MessageType.ANIMAL_AUCTION_FINISHED)

end


function PlaceableAuctionMart:getAnimalTypes()

	return self[specName].animalTypes

end


function PlaceableAuctionMart:updateAuction(dT)

	local spec = self[specName]

	if spec.state ~= PlaceableAuctionMart.PREPARING and spec.state ~= PlaceableAuctionMart.ACTIVE then return end

	spec.playerCache.x, spec.playerCache.y, spec.playerCache.z = getWorldTranslation(g_cameraManager:getActiveCamera())

	local signIn = spec.signIn

	if signIn ~= nil and spec.state == PlaceableAuctionMart.PREPARING then

		if signIn.queueTimer >= 533 and signIn.isQueueMoving then

			for _, npc in pairs(signIn.queue) do
				npc.isIdle = true 
				npc.isWalking = false
			end

			signIn.isQueueMoving = false

		end

		if signIn.queueTimer >= 6000 then

			signIn.queueTimer = 0

			if #signIn.queue >= 1 then

				signIn.isQueueMoving = true

				for i = 2, #signIn.queue do

					signIn.queue[i].target.z = signIn.queue[i].target.z + 0.08
					signIn.queue[i].isIdle = false

				end

				self:signIn(true, signIn.queue[1])

				signIn.queue[1]:setTarget(1)
				signIn.queue[1].isIdle = false

				table.remove(signIn.queue, 1)

			end

		end

		signIn.queueTimer = signIn.queueTimer + dT

	end

	spec.digitalDisplay:update(dT)

	if spec.state == PlaceableAuctionMart.ACTIVE and spec.bidding.active then

		local bidding = spec.bidding

		if bidding.winner.id ~= nil then bidding.timer = bidding.timer + dT end
			
		if bidding.timer >= 5000 then
			self:endBidding()
		else

			if bidding.announcement < 5 and bidding.timer >= bidding.announcement - 50 and bidding.timer <= bidding.announcement + 50 then

				if bidding.announcement >= 3 then spec.auctioneer:speak(g_i18n:getText("rl_auction_going_" .. (bidding.announcement - 2))) end
				bidding.announcement = bidding.announcement + 1

			end

			bidding.allowed = true
			local animal = self:getCurrentAnimal()
			local value = animal:getSellPrice()
			local nextBid = self:getNextBid()
			bidding.timeSinceLastBid = bidding.timeSinceLastBid + dT

			if bidding.timeSinceLastBid >= math.random(500, 4000) then

				bidding.timeSinceLastBid = 0

				for _, npc in pairs(bidding.bidders) do

					if npc == g_localPlayer or bidding.winner.id == npc.id then continue end

					local willBid = npc:calculateBid(animal, value, nextBid)

					if willBid then
						self:onBid(true, npc, nextBid)
						break
					end

				end

			end

		end

	end

end


function PlaceableAuctionMart:createNavigation(type)

	local baseNode = I3DUtil.indexToObject(self.rootNode, "0|8")

	local navigation = { ["node"] = getChild(baseNode, type), ["paths"] = {} }
	local spec = self[specName]

	if type == "bidder" then

		for i = 1, getNumOfChildren(spec.npcNodes) do

			local node = getChildAt(spec.npcNodes, i - 1)
			local name = getName(node)

			if not string.contains(getName(node), "npc") then continue end

			local pathLiteral = string.split(getUserAttribute(node, "path"), "|")
			local path = { getChild(navigation.node, "signIn"), getChild(navigation.node, "signInFinished") }

			for j = 1, #pathLiteral do

				table.insert(path, getChild(navigation.node, pathLiteral[j]))

			end

			table.insert(path, node)

			navigation.paths[name] = path

		end

	elseif type == "herdsman" then

		for i = 1, getNumOfChildren(navigation.node) do

			local node = getChildAt(navigation.node, i - 1)
			local name = getName(node)

			if not string.contains(name, "path") then continue end

			local pathLiteral = string.split(getUserAttribute(node, "path"), "|")
			local path = {}

			for j = 1, #pathLiteral do

				table.insert(path, getChild(navigation.node, pathLiteral[j]))

			end

			table.insert(path, node)

			navigation.paths[name] = path

		end

	elseif type == "writer" then

		for i = 1, getNumOfChildren(navigation.node) do

			local node = getChildAt(navigation.node, i - 1)
			local name = getName(node)

			if not string.contains(name, "path") then continue end

			local pathLiteral = string.split(getUserAttribute(node, "path"), "|")
			local path = {}

			for j = 1, #pathLiteral do

				table.insert(path, getChild(navigation.node, pathLiteral[j]))

			end

			table.insert(path, node)

			navigation.paths[name] = path

		end

	end

	spec.navigation[type] = navigation

end


function PlaceableAuctionMart:getIsAuctionOpen()

	return self[specName].state == PlaceableAuctionMart.PREPARING or self[specName].state == PlaceableAuctionMart.ACTIVE

end


function PlaceableAuctionMart:getCurrentAnimal()

	local spec = self[specName]

	return spec.animalTypes[spec.currentAnimalTypeIndex][spec.currentAnimalIndex]

end


function PlaceableAuctionMart:getState()

	return self[specName].state

end


function PlaceableAuctionMart:startBidding()

	local spec = self[specName]
	local animal = self:getCurrentAnimal()
	local value = animal:getSellPrice()

	spec.bidding.active = true
	spec.bidding.timer = 0
	spec.bidding.timeSinceLastBid = 0
	spec.bidding.announcement = 1
	spec.bidding.nextBid = value * 0.1
	spec.bidding.allowed = true
	spec.bidding.winner = {}

	g_messageCenter:publish(MessageType.ANIMAL_BIDDING_STARTED, animal, spec.bidding.nextBid)

end


function PlaceableAuctionMart:getNextBid()

	return self[specName].bidding.nextBid

end


function PlaceableAuctionMart:endBidding()

	local spec = self[specName]

	spec.bidding.active = false

	spec.currentAnimalIndex = spec.currentAnimalIndex + 1

	if spec.currentAnimalIndex > #spec.animalTypes[spec.currentAnimalTypeIndex] then
		spec.currentAnimalIndex = 1
		local isNextAnimalType, isValid = false, false

		for animalTypeIndex, animals in pairs(spec.animalTypes) do
			if isNextAnimalType then
				spec.currentAnimalTypeIndex = animalTypeIndex
				isValid = true
				break
			end
			if animalTypeIndex == spec.currentAnimalTypeIndex then isNextAnimalType = true end
		end

		if not isValid then

			self:endAuction()
			return

		end

	end

	self:updateDigitalDisplay(PlaceableAuctionMart.DISPLAY_RESULT)

	local name

	if spec.bidding.winner.id ~= 0 then
		local npc = self:getBiddingWinner()
		npc:changeMoney(-spec.bidding.winner.price)
		npc:changeChance(-math.random(50, 250) / 10000)
		name = npc:getName()
	else
		name = g_localPlayer:getNickname()
	end

	spec.whiteboard.npc:addText(string.format("%s: %s", name, g_i18n:formatMoney(spec.bidding.winner.price, 2, true, true)))

	g_messageCenter:publish(MessageType.ANIMAL_BIDDING_ENDED, spec.bidding.winner.id, spec.bidding.winner.price)

end


function PlaceableAuctionMart:updateDigitalDisplay(displayType)

	local animal = self:getCurrentAnimal()
	local spec = self[specName]

	if displayType == PlaceableAuctionMart.DISPLAY_NEW then

		local subType = animal:getSubType()
		spec.digitalDisplay:setText(string.format("%s (%s): %s", animal:getIdentifiers(), g_fillTypeManager:getFillTypeTitleByIndex(subType.fillTypeIndex), g_i18n:formatMoney(animal:getSellPrice(), 2, true, true)))

	elseif displayType == PlaceableAuctionMart.DISPLAY_RESULT then

		local name

		if spec.bidding.winner.id == 0 then
			name = g_localPlayer:getNickname()
		else
			local winner = self:getBiddingWinner()
			name = winner:getName()
		end
		
		spec.digitalDisplay:setText(string.format("%s sold to %s for %s!", animal:getIdentifiers(), name, g_i18n:formatMoney(spec.bidding.winner.price, 2, true, true)))

	end

end


function PlaceableAuctionMart:onAnimalLoaded()

	self:updateDigitalDisplay(PlaceableAuctionMart.DISPLAY_NEW)

end


function PlaceableAuctionMart:onBid(isNpc, bidder, amount)

	local spec = self[specName]

	local value = self:getCurrentAnimal():getSellPrice()

	spec.bidding.winner.id = bidder.id
	spec.bidding.nextBid = amount + value * 0.05
	spec.bidding.winner.price = amount
	spec.bidding.timer = 0
	spec.bidding.allowed = false
	spec.bidding.announcement = 1

end


function PlaceableAuctionMart:getIsBiddingAllowed()

	return self[specName].state == PlaceableAuctionMart.ACTIVE and self[specName].bidding.allowed

end


function PlaceableAuctionMart:getBiddingWinner()

	local spec = self[specName]

	for _, npc in pairs(spec.bidding.bidders) do
		if npc.id == spec.bidding.winner.id then return npc end
	end

	return g_localPlayer

end


function PlaceableAuctionMart:getPlayerPosition()

	local cache = self[specName].playerCache

	return cache.x, cache.y, cache.z

end