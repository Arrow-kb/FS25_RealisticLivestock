AuctionHerdsman = {}


local AuctionHerdsman_mt = Class(AuctionHerdsman, AuctionNPC)


function AuctionHerdsman.new(placeable, parent, navigationNode, paths, pathName)

	local self = AuctionNPC.new(placeable, parent, AuctionHerdsman_mt)

	self.navigationNode = navigationNode
	self.paths = paths
	self.path = paths[pathName]
	self.pathName = pathName
	self.type = "herdsman"

	self:setTarget(1)

	self.x, self.y, self.z, self.rx, self.ry, self.rz = self.target.x, self.target.y, self.target.z, 0, self.target.ry, 0

	self.numLoops = 0
	self.isIdle = PlaceableAuctionMart.INSTANCE:getState() == PlaceableAuctionMart.PREPARING
	self.hasAnimal = false

	return self

end


function AuctionHerdsman:delete()

	self:deleteAnimal()

	AuctionHerdsman:superClass().delete(self)

end


function AuctionHerdsman:loadTemplate()

	self.gender = "playerM"
	self.head = "head01"
	self.jacket = "tShirt02"
	self.pants = "waterProof"
	self.hair = "hair02"
	self.beard = "trimmedBeard_head01"
	self.hairColour = 15
	self.hat = "derbyTweedHat"
	self.shoes = "galoshes"

end


function AuctionHerdsman:onI3DFileLoaded(node, state)

	AuctionHerdsman:superClass().onI3DFileLoaded(self, node, state)

	if state == LoadI3DFailedReason.NONE and self.hasAnimal then self:loadAnimal() end

end


function AuctionHerdsman:update(dT)

	AuctionHerdsman:superClass().update(self, dT)

	if self:getIsAuctionActive() and self.isIdle and self.target.index == #self.path then

		if self.pathName == "path3" then

			self.pathName = "path1"
			self.path = self.paths.path1
			self:setTarget(1)
			self:loadAnimal()
			self.isIdle = false

		end
	
	end

	if self.animal ~= nil then

		self.animal:update(dT)
		self.animal:updatePosition()

	end

end


function AuctionHerdsman:saveToXMLFile(xmlFile, key)

	AuctionHerdsman:superClass().saveToXMLFile(self, xmlFile, key)

	xmlFile:setString(key .. ".target#path", self.pathName)
	xmlFile:setInt(key .. ".target#numLoops", self.numLoops)
	xmlFile:setBool(key .. "#hasAnimal", self.hasAnimal)

end


function AuctionHerdsman:loadFromXMLFile(xmlFile, key)

	AuctionHerdsman:superClass().loadFromXMLFile(self, xmlFile, key)

	self.numLoops = xmlFile:getInt(key .. ".target#numLoops", 0)
	self.hasAnimal = xmlFile:getBool(key .. "#hasAnimal", false)

end


function AuctionHerdsman:setTarget(target)

	if self.pathName == "path1" then

		if target >= #self.path then

			self.isIdle = true
			self.isWalking = false

			if self.animal ~= nil then self.animal:setIdle() end
			self.placeable:startBidding()

		end

	end

	AuctionHerdsman:superClass().setTarget(self, target)

end


function AuctionHerdsman:onBiddingEnded(winner, price)

	AuctionHerdsman:superClass().onBiddingEnded(self, winner, price)

	self.pathName = "path3"
	self.path = self.paths.path3
	self:setTarget(1)
	self.isIdle = false

end


function AuctionHerdsman:onAuctionStarted()

	AuctionHerdsman:superClass().onAuctionStarted(self)

	self.isIdle = false
	self:loadAnimal()

end


function AuctionHerdsman:loadAnimal()

	self:deleteAnimal()
	self.animal = AuctionAnimal.new(self)
	self.animal:load()
	self.hasAnimal = true
	self.placeable:onAnimalLoaded()

end


function AuctionHerdsman:deleteAnimal()

	if self.animal ~= nil then self.animal:delete() end

end


function AuctionHerdsman:getAnimalData()

	local animal = g_auctionMart:getCurrentAnimal()
	local subTypeIndex, age = animal:getSubTypeIndex(), animal:getAge()

	local visualData = g_currentMission.animalSystem:getVisualByAge(subTypeIndex, age)

	local variation = visualData.visualAnimal.variations[animal.variation or 1]

	return animal.animalTypeIndex, visualData.visualAnimalIndex, variation.tileUIndex, variation.tileVIndex, variation.numTilesU, variation.numTilesV, subTypeIndex, age

end


function AuctionHerdsman:onTargetReached(targetIndex)

	AuctionHerdsman:superClass().onTargetReached(self, targetIndex)

	if self:getIsAuctionActive() and self.pathName == "path1" and targetIndex == #self.path then
		self:setTarget(1)
		self.isIdle = false
		self:loadAnimal()
	end

end


function AuctionHerdsman:setSpeed(speed)

	self.speed = math.max(speed or 1, 2)

end