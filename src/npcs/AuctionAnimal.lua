AuctionAnimal = {}

local AuctionAnimal_mt = Class(AuctionAnimal)
local modDirectory = g_currentModDirectory


function AuctionAnimal.new(parent)

	local self = setmetatable({}, AuctionAnimal_mt)

	self.parent = parent
	self.x, self.y, self.z = parent.x, parent.y, parent.z
	self.rx, self.ry, self.rz = parent.rx, parent.ry, parent.rz

	self.isWalking = false
	self.isIdle = false

	return self

end


function AuctionAnimal:delete()

	delete(self.node)

end


function AuctionAnimal:load()

	local animalTypeIndex, visualAnimalIndex, tileU, tileV, numTilesU, numTilesV, subTypeIndex, age = self.parent:getAnimalData()

	local cache = g_currentMission.animalSystem:getVisualAnimalCache(animalTypeIndex, visualAnimalIndex)

	local node = clone(cache.root, false, false, false)
	link(self.parent.node, node)
	self.node = node


	setClipDistance(node, 300)
	setVisibility(node, true)

	local shaderNode = I3DUtil.indexToObject(node, cache.shader)
	local meshNode = I3DUtil.indexToObject(node, cache.mesh)
	local skeletonNode = I3DUtil.indexToObject(node, cache.skeleton)
	local skinNode = getChildAt(skeletonNode, 0)
	local animationSet = getAnimCharacterSet(skinNode)

	self.skeletonNode = skeletonNode

	local tilesX, tilesY = 1 / numTilesU, 1 / numTilesV

	I3DUtil.setShaderParameterRec(meshNode, "atlasInvSizeAndOffsetUV", tilesX, tilesY, 1 - tilesX * tileU, 1 - tilesY * tileV, false)

	self.animationSet = animationSet
	self.isLoaded = true
		
	local walkL = cache.animation.clips.walkLeft
	local walkR = cache.animation.clips.walkRight
	local idle = cache.animation.clips.idle

	assignAnimTrackClip(animationSet, 0, walkL)
	assignAnimTrackClip(animationSet, 1, walkR)
	assignAnimTrackClip(animationSet, 2, idle)

	setAnimTrackLoopState(animationSet, 0, true)
	setAnimTrackLoopState(animationSet, 1, true)
	setAnimTrackLoopState(animationSet, 2, true)

	setAnimTrackBlendWeight(animationSet, 0, 0.5)
	setAnimTrackBlendWeight(animationSet, 1, 0.5)
	setAnimTrackBlendWeight(animationSet, 2, 1)

	self.speed = cache.animation.speed
	self.parent:setSpeed(self.speed)
	
	self:setWalking()

end


function AuctionAnimal:setPosition(x, y, z)

	self.x, self.y, self.z = x, y, z

end


function AuctionAnimal:updatePosition()

	self.isActive = true
	
	if self.isActive then

		if self.node ~= nil then
			setTranslation(self.node, -0.75, 0, -1.75)
			setWorldRotation(self.node, self.parent.rz, self.parent.ry, self.parent.rz)
		end

	end

end


function AuctionAnimal:update(dT)



end


function AuctionAnimal:setWalking()

	if self.isWalking or not self.isLoaded then return end

	self.isWalking = true
	self.isIdle = false

	enableAnimTrack(self.animationSet, 0)
	enableAnimTrack(self.animationSet, 1)
	disableAnimTrack(self.animationSet, 2)

end


function AuctionAnimal:setIdle()

	if self.isIdle or not self.isLoaded then return end

	self.isIdle = true
	self.isWalking = false

	disableAnimTrack(self.animationSet, 0)
	disableAnimTrack(self.animationSet, 1)
	enableAnimTrack(self.animationSet, 2)

end