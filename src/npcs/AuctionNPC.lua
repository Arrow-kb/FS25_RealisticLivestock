AuctionNPC = {}

local AuctionNPC_mt = Class(AuctionNPC)
local modDirectory = g_currentModDirectory
local modSettingsDirectory = g_currentModSettingsDirectory

g_xmlManager:addCreateSchemaFunction(function()
	AuctionNPC.xmlSchema = XMLSchema.new("auctionNPC")
end)

g_xmlManager:addInitSchemaFunction(function()
	PlayerStyle.registerSavegameXMLPaths(AuctionNPC.xmlSchema, "playerStyle")
end)

source(modDirectory .. "src/npcs/Auctioneer.lua")
source(modDirectory .. "src/npcs/AuctionHerdsman.lua")
source(modDirectory .. "src/npcs/AuctionAnimal.lua")
source(modDirectory .. "src/npcs/AuctionBidder.lua")
source(modDirectory .. "src/npcs/AuctionWriter.lua")

local npcCustomisations = {
	["playerM"] = {
		["heads"] = {
			"head01",
			"head02",
			"head03",
			"head04",
			"head05",
			"head06",
			"head07",
			"head08"
		},
		["jackets"] = {
			"aviatorJacket",
			"topDeck",
			"denimJacket",
			"topFarmJacketM",
			"leather",
			"puffJacket",
			"topVest",
			"topVestM",
			"windbreaker",
			"tweedFieldCoat",
			"tweedSportsJacket"
		},
		["shirts"] = {
			"collaredShirt",
			"topLightSweater",
			"topPlaidShirt",
			"topShirtLongSleeve",
			"tShirt01",
			"tShirt02",
			"zipNeckPullover"
		},
		["pants"] = {
			"cargo",
			"cargoShorts",
			"chinos",
			"equestrian",
			"jeans",
			"jeanShorts",
			"leather",
			"botSlacks",
			"waterProof",
			"tweedTrousers"
		},
		["hair"] = {
			"hair01",
			"hair02",
			"hair03",
			"hair04",
			"hair05",
			"hair06",
			"hair08",
			"hair09",
			"hair10",
			"hair11",
			"hair12",
			"hair13",
			"hair14",
			"hair15",
			"hair16"
		},
		["beards"] = {
			["head01"] = {
				"stubble_head01",
				"trimmedBeard_head01",
				"goatee01_head01",
				"goatee02_head01",
				"muttonChops01_head01",
				"muttonChops02_head01",
				"muttonChops03_head01",
				"fullBeard_head01",
				"trimmed_head01",
				"walrusTame_head01",
				"fullStash_head01",
				"upwardHandlebar_head01",
				"horseshoe_head01",
				"walrusFull_head01",
				"walrusXL_head01"
			},
			["head02"] = {
				"stubble_head02",
				"trimmedBeard_head02",
				"goatee01_head02",
				"goatee02_head02",
				"muttonChops01_head02",
				"muttonChops02_head02",
				"muttonChops03_head02",
				"fullBeard_head02",
				"trimmed_head02",
				"walrusTame_head02",
				"fullStash_head02",
				"upwardHandlebar_head02",
				"horseshoe_head02",
				"walrusFull_head02",
				"walrusXL_head02"
			},
			["head03"] = {
				"stubble_head03",
				"trimmedBeard_head03",
				"goatee01_head03",
				"goatee02_head03",
				"muttonChops01_head03",
				"muttonChops02_head03",
				"muttonChops03_head03",
				"fullBeard_head03",
				"trimmed_head03",
				"walrusTame_head03",
				"fullStash_head03",
				"upwardHandlebar_head03",
				"horseshoe_head03",
				"walrusFull_head03",
				"walrusXL_head03"
			},
			["head04"] = {
				"stubble_head04",
				"trimmedBeard_head04",
				"goatee01_head04",
				"goatee02_head04",
				"muttonChops01_head04",
				"muttonChops02_head04",
				"muttonChops03_head04",
				"fullBeard_head04",
				"trimmed_head04",
				"walrusTame_head04",
				"fullStash_head04",
				"upwardHandlebar_head04",
				"horseshoe_head04",
				"walrusFull_head04",
				"walrusXL_head04"
			},
			["head05"] = {
				"stubble_head05",
				"trimmedBeard_head05",
				"goatee01_head05",
				"goatee02_head05",
				"muttonChops01_head05",
				"muttonChops02_head05",
				"muttonChops03_head05",
				"fullBeard_head05",
				"trimmed_head05",
				"walrusTame_head05",
				"fullStash_head05",
				"upwardHandlebar_head05",
				"horseshoe_head05",
				"walrusFull_head05",
				"walrusXL_head05"
			},
			["head06"] = {
				"stubble_head06",
				"trimmedBeard_head06",
				"goatee01_head06",
				"goatee02_head06",
				"muttonChops01_head06",
				"muttonChops02_head06",
				"muttonChops03_head06",
				"fullBeard_head06",
				"trimmed_head06",
				"walrusTame_head06",
				"fullStash_head06",
				"upwardHandlebar_head06",
				"horseshoe_head06",
				"walrusFull_head06",
				"walrusXL_head06"
			},
			["head07"] = {
				"trimmedBeard_head07"
			}
		},
		["glasses"] = {
			"aviator",
			"classic",
			"reading",
			"sports1",
			"sports2",
			"vintage"
		},
		["hats"] = {
			"ballCapTweed",
			"caseih",
			"derbyTweedHat",
			"hatWoolen",
			"vintage",
			"JDBlack",
			"JDGreen",
			"MFhat"
		},
		["shoes"] = {
			"cowboy",
			"galoshes",
			"laceUpSneaker",
			"workBoots1",
			"workBoots2"
		}
	},
	["playerF"] = {
		["heads"] = {
			"head01",
			"head02",
			"head03",
			"head04",
			"head05",
			"head06",
		},
		["jackets"] = {
			"aviatorJacket",
			"topDeck",
			"denimJacket",
			"topFarmJacketM",
			"leather",
			"workJacket",
			"topVest",
			"topVestM",
			"windbreaker",
			"puffJacket",
			"winterVest",
			"tweedFieldCoat",
			"tweedSportsJacket"
		},
		["shirts"] = {
			"topShirtLongSleeve",
			"collaredShirt",
			"topLightSweater",
			"topPlaidShirt",
			"tankTop",
			"tShirt01",
			"tShirt02",
			"zipNeckPullover"
		},
		["pants"] = {
			"cargo",
			"cargoShorts",
			"chinos",
			"equestrian",
			"jeans",
			"jeanShorts",
			"leather",
			"botSlacks",
			"tweedTrousers"
		},
		["hair"] = {
			"hair01",
			"hair02",
			"hair03",
			"hair04",
			"hair05",
			"hair06",
			"hair08",
			"hair09",
			"hair10",
			"hair11",
			"hair12",
			"hair13",
			"hair14",
			"hair15",
			"hair16"
		},
		["glasses"] = {
			"aviator",
			"classic",
			"reading",
			"sports1",
			"sports2",
			"vintage"
		},
		["hats"] = {
			"ballCapTweed",
			"caseih",
			"derbyTweedHat",
			"hatWoolen",
			"vintage",
			"JDBlack",
			"JDGreen",
			"MFhat"
		},
		["shoes"] = {
			"cowboy",
			"galoshes",
			"laceUpSneaker",
			"workBoots1",
			"workBoots2"
		}
	}
}


function AuctionNPC.new(placeable, parent, customMt)

	local self = setmetatable({}, customMt or AuctionNPC_mt)

	self.placeable = placeable
	self.parent = parent
	self.playerGraphics = HumanGraphicsComponent.new()
	self.playerGraphics.defaultState.isNPC = true
	self.playerGraphics:setIsFacialAnimationEnabled(true)
	self.playerGraphics:setSoundsEnabled(false)
	self.speed = 1

	self.x, self.y, self.z = getWorldTranslation(parent)
	self.rx, self.ry, self.rz = getWorldRotation(parent)

	local level = getUserAttribute(parent, "level")

	if level ~= nil then

		local height = getTerrainHeightAtWorldPos(g_terrainNode, self.x, 0, self.z)

		if level == 0 then
			self.y = height
		elseif level == 1 then
			self.y = height + 0.75
		elseif level == 2 then
			self.y = height + 0.75
		elseif level == 3 then
			self.y = height + 1.95
		end

	end

	self.isWalking = false
	self.isIdle = true
	self.turning = false

	self.walkingState = HumanGraphicsComponentState.new()
	self.walkingState.isWalking = true
	self.walkingState.isIdling = false
	self.walkingState.absSpeed = 3
	self.walkingState.isNPC = true

	g_messageCenter:subscribe(MessageType.ANIMAL_AUCTION_STARTED, self.onAuctionStarted, self)
	g_messageCenter:subscribe(MessageType.ANIMAL_BIDDING_STARTED, self.onBiddingStarted, self)
	g_messageCenter:subscribe(MessageType.ANIMAL_BIDDING_ENDED, self.onBiddingEnded, self)

	return self

end


function AuctionNPC:randomiseCustomisation()

	local top = math.random() >= 0.5 and "jacket" or "shirt"

	self.gender = math.random() <= 0.8 and "playerM" or "playerF"
	self.head = npcCustomisations[self.gender].heads[math.random(1, #npcCustomisations[self.gender].heads)]

	if top == "jacket" then self.jacket = npcCustomisations[self.gender].jackets[math.random(1, #npcCustomisations[self.gender].jackets)] end

	if top == "shirt" then self.shirt = npcCustomisations[self.gender].shirts[math.random(1, #npcCustomisations[self.gender].shirts)] end

	self.pants = npcCustomisations[self.gender].pants[math.random(1, #npcCustomisations[self.gender].pants)]
	self.hair = npcCustomisations[self.gender].hair[math.random(1, #npcCustomisations[self.gender].hair)]

	if self.gender == "playerM" and npcCustomisations.playerM.beards[self.head] ~= nil and math.random() >= 0.75 then

		self.beard = npcCustomisations.playerM.beards[self.head][math.random(1, #npcCustomisations.playerM.beards[self.head])]

	end

	if math.random() >= 0.65 then
		self.hairColour = math.random(21, 24)
	elseif math.random() >= 0.25 then
		self.hairColour = math.random(13, 17)
	elseif math.random() >= 0.35 then
		self.hairColour = math.random(18, 20)
	else
		self.hairColour = math.random(1, 8)
	end

	self.shoes = npcCustomisations[self.gender].shoes[math.random(1, #npcCustomisations[self.gender].shoes)]

	if math.random() >= 0.67 then self.hat = npcCustomisations[self.gender].hats[math.random(1, #npcCustomisations[self.gender].hats)] end

	if math.random() >= 0.67 then self.glasses = npcCustomisations[self.gender].glasses[math.random(1, #npcCustomisations[self.gender].glasses)] end

end


function AuctionNPC:load()

	self.i3dFilename = Utils.getFilename("dataS/character/npc/npcBase.i3d")
	self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.i3dFilename, true, true, self.onI3DFileLoaded, self, nil)

	self.playerGraphics:initialize()
	link(getRootNode(), self.playerGraphics.graphicsRootNode)

	if self.playerStyle == nil then

		local playerStyle = PlayerStyle.new()

		local xmlFile = XMLFile.create("tempAuctionNPC", modSettingsDirectory .. "tempNPC.xml", "playerStyle", AuctionNPC.xmlSchema)

		xmlFile:setString("playerStyle#filename", string.format("dataS/character/%s/%s.xml", self.gender, self.gender))

		xmlFile:setInt("playerStyle.bottom#color", 1)
		xmlFile:setString("playerStyle.bottom#name", self.pants)

		xmlFile:setInt("playerStyle.face#color", 1)
		xmlFile:setString("playerStyle.face#name", self.head)

		xmlFile:setInt("playerStyle.top#color", 1)
		xmlFile:setString("playerStyle.top#name", self.jacket or self.shirt)

		xmlFile:setInt("playerStyle.hairStyle#color", self.hairColour)
		xmlFile:setString("playerStyle.hairStyle#name", self.hair)

		xmlFile:setInt("playerStyle.footwear#color", 1)
		xmlFile:setString("playerStyle.footwear#name", self.shoes)

		if self.beard ~= nil then

			xmlFile:setInt("playerStyle.beard#color", self.hairColour)
			xmlFile:setString("playerStyle.beard#name", self.beard)

		end

		if self.glasses ~= nil then

			xmlFile:setInt("playerStyle.glasses#color", 1)
			xmlFile:setString("playerStyle.glasses#name", self.glasses)

		end

		if self.hat ~= nil then

			xmlFile:setInt("playerStyle.headgear#color", 1)
			xmlFile:setString("playerStyle.headgear#name", self.hat)

		end

		xmlFile:save(false, true)

		playerStyle:loadFromXMLFile(xmlFile, "playerStyle")

		xmlFile:delete()

		self.playerStyle = playerStyle

	end

	self.playerGraphics:setStyleAsync(self.playerStyle, self.loadCharacterFinished, self, {})

end


function AuctionNPC:loadCharacterFinished(state)

	if state == HumanModelLoadingState.OK then

		self.playerGraphics:defaultAllParameters()
		self.speechBubble = SpeechBubble.new()
		self.speechBubble:createFromHeadNode(self.playerGraphics.model.thirdPersonHeadNode)
		self:updatePosition()

		g_currentMission:addUpdateable(self)

	else

		if state == HumanModelLoadingState.CANCELED then
			Logging.info("Loading player model canceled")
		else
			Logging.error("Loading player model failed")
		end

		self.playerGraphics:delete()
		self.playerGraphics = nil

	end

end


function AuctionNPC:updatePosition()

	self.isActive = true
	
	if self.isActive then

		addToPhysics(self.node)

		if self.node ~= nil then
			setWorldTranslation(self.node, self.x, self.y, self.z)
			setWorldRotation(self.node, self.rz, self.ry, self.rz)
		end

		if self.playerGraphics ~= nil then
			self.playerGraphics:setModelPosition(self.x, self.y, self.z)
			self.playerGraphics:setModelRotation(self.rx, self.ry, self.rz)
		end

	elseif self.node ~= nil then
		removeFromPhysics(self.node)
	end

end


function AuctionNPC:onI3DFileLoaded(node, state)

	if state == LoadI3DFailedReason.NONE then

		link(getRootNode(), node)
		self.node = node
		setClipDistance(node, 300)
		self:updatePosition()

	end

end


function AuctionNPC:update(dT)

	if not self.isIdle then

		local dx, dy, dz = self.target.x - self.x, self.target.y - self.y, self.target.z - self.z
		local distance = math.abs(dx) + math.abs(dy) + math.abs(dz)

		local stepX, stepY, stepZ = 0, 0, 0

		if distance > 0 then
	
			stepX, stepY, stepZ = dx / distance, dy / distance, dz / distance

			stepX, stepY, stepZ = stepX * self.speed, stepY * self.speed, stepZ * self.speed
	
			self.x = self.x + stepX * dT * 0.0025
			self.y = self.y + stepY * dT * 0.0025
			self.z = self.z + stepZ * dT * 0.0025

		end

		self.isWalking = stepX ~= 0 or stepY ~= 0 or stepZ ~= 0

		if self.isWalking then

			self.walkingState.movementDirX = stepX
			self.walkingState.movementDirZ = stepZ

		end

		if distance <= 2 and not self.turning then

			self.turning = true
			self.turnTarget = self.target.ry

		end

		if distance <= 0.25 then

			self:onTargetReached(self.target.index)

			if self.target.index == #self.path then
				self.isIdle = true
				self.isWalking = false
			else
				self:setTarget(self.target.index + 1)
			end

		end

	end

	if self.turning then

		local ry, turnTarget = math.deg(self.ry), math.deg(self.turnTarget)

		ry = ry % 360
		turnTarget = turnTarget % 360

		if ry < 0 then ry = ry + 180 end
		if turnTarget < 0 then turnTarget = turnTarget + 180 end

		if ry < turnTarget then

			if math.abs(ry - turnTarget) < 180 then
				ry = ry + dT * 0.05
			else
				ry = ry - dT * 0.05
			end

		else

			if math.abs(ry - turnTarget) < 180 then
				ry = ry - dT * 0.05
			else
				ry = ry + dT * 0.05
			end

		end

		if ry > 180 then ry = ry - 360 end
		self.ry = math.rad(ry)

		if self.ry <= self.turnTarget + 0.05 and self.ry >= self.turnTarget - 0.05 then
			self.turnTarget = nil
			self.turning = false
			self:onFinishedTurning(self.target.index)
		end

	end

	self:updatePosition()

	if self.playerGraphics ~= nil then

		if self.isWalking then
			self.playerGraphics:applyState(self.walkingState)
		else
			self.playerGraphics:defaultAllParameters()
		end

		self.playerGraphics:update(dT)

	end

	self.speechBubble:setReferencePosition(self.placeable:getPlayerPosition())
	self.speechBubble:update(dT)

end


function AuctionNPC:setName(name)

	self.name = name

end


function AuctionNPC:getName()

	return self.name

end


function AuctionNPC:delete()

	self.speechBubble:delete()
	self.playerGraphics:delete()
	g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
	g_currentMission:removeUpdateable(self)

end


function AuctionNPC:saveToXMLFile(xmlFile, key)

	xmlFile:setString(key .. "#parent", getName(self.parent))
	xmlFile:setString(key .. "#type", self.type)

	xmlFile:setFloat(key .. ".position#x", self.x)
	xmlFile:setFloat(key .. ".position#y", self.y)
	xmlFile:setFloat(key .. ".position#z", self.z)

	xmlFile:setFloat(key .. ".rotation#x", self.rx)
	xmlFile:setFloat(key .. ".rotation#y", self.ry)
	xmlFile:setFloat(key .. ".rotation#z", self.rz)

	if self.target ~= nil and self.path ~= nil then

		local target = self.target

		xmlFile:setInt(key .. ".target#index", target.index)

	end

end


function AuctionNPC:loadFromXMLFile(xmlFile, key)

	self.x = xmlFile:getFloat(key .. ".position#x", 0)
	self.y = xmlFile:getFloat(key .. ".position#y", 0)
	self.z = xmlFile:getFloat(key .. ".position#z", 0)

	self.rx = xmlFile:getFloat(key .. ".rotation#x", 0)
	self.ry = xmlFile:getFloat(key .. ".rotation#y", 0)
	self.rz = xmlFile:getFloat(key .. ".rotation#z", 0)

	local index = xmlFile:getInt(key .. ".target#index")

	if index ~= nil then self:setTarget(index) end

end


function AuctionNPC:setTarget(target)

	local tx, ty, tz = getWorldTranslation(self.path[target])

	local level = getUserAttribute(self.path[target], "level")

	local dx, dy, dz = localDirectionToWorld(self.path[target], 0, 0, 1)
	local _, yaw = MathUtil.directionToPitchYaw(dx, dy, dz)
	local ry = MathUtil.getValidLimit(yaw)

	
	if level ~= nil then

		local height = getTerrainHeightAtWorldPos(g_terrainNode, tx, 0, tz)

		if level == 1 then
			ty = height
		elseif level == 2 then
			ty = height + 0.75
		elseif level == 3 then
			ty = height + 1.95
		end

	end

	self.target = {
		["index"] = target,
		["x"] = tx,
		["y"] = ty,
		["z"] = tz,
		["ry"] = ry
	}

end


function AuctionNPC:onAuctionStarted()

	self.auctionActive = true

end


function AuctionNPC:getIsAuctionActive()

	return self.auctionActive or false

end


function AuctionNPC:onBiddingStarted(animal, startBid)

	

end


function AuctionNPC:onBiddingEnded(winner, price)

	

end


function AuctionNPC:onTargetReached(targetIndex)



end


function AuctionNPC:onFinishedTurning(targetIndex)



end


function AuctionNPC:speak(text)

	self.speechBubble:setText(text, math.clamp(utf8Strlen(text) * 100, 1000, 6000))

end