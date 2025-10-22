Dewar = {}


Dewar.CAPACITY = 1000
Dewar.PRICE_PER_STRAW = 0.85


local dewar_mt = Class(Dewar, PhysicsObject)
local modDirectory = g_currentModDirectory


function Dewar.new(isServer, isClient)

	local self = PhysicsObject.new(isServer, isClient, dewar_mt)

	registerObjectClassName(self, "Dewar")

	self.uniqueId = nil
	self.position = nil
	self.rotation = nil
	self.sharedRequestId = nil
	self.mass = 0.1
	self.isAddedToItemSystem = false
	self.straws = 0

	return self

end


function Dewar:delete()

	g_dewarManager:removeDewar(self:getOwnerFarmId(), self)

	if self.sharedRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedRequestId)
		self.sharedRequestId = nil
	end
	
	unregisterObjectClassName(self)
	if self.isAddedToItemSystem then g_currentMission.itemSystem:removeItem(self) end
	Dewar:superClass().delete(self)

end


function Dewar:register(position, rotation, animal, quantity)

	--if self.isServer then Dewar:superClass().register(self, true) end

	print(self.uniqueId .. " = " .. self.id)

	self.position = self.position or position
	self.rotation = self.rotation or rotation
	self.mass = 0.1

	if self.nodeId == nil or self.nodeId == 0 then self:createNode(modDirectory .. "objects/dewar/dewar.i3d") end

	local x, y, z = unpack(self.position)
	local rx, ry, rz = unpack(self.rotation)

	local node = self.nodeId
    link(getRootNode(), node)
	setWorldTranslation(node, unpack(self.position))
	setWorldRotation(node, unpack(self.rotation))

	local sx, sy, sz = getWorldTranslation(self.shapeNode)
	local srx, sry, srz = getWorldRotation(self.shapeNode)

	self.ox, self.oy, self.oz = x - sx, y - sy, z - sz
	self.orx, self.ory, self.orz = rx - srx, ry - sry, rz - srz

	if not self.isAddedToItemSystem then
		g_currentMission.itemSystem:addItem(self)
		self.isAddedToItemSystem = true
	end

	if animal ~= nil then self:setAnimal(animal) end
	if quantity ~= nil then self:setStraws(quantity) end

	g_dewarManager:addDewar(self:getOwnerFarmId(), self)

	self:updateStrawVisuals()
	self:updateAnimalVisuals()

	--if g_server ~= nil then
		--g_server:addObject(self, string.format("dewar_%s", self.uniqueId))
	--elseif g_client ~= nil then
		--g_client:addObject(self, string.format("dewar_%s", self.uniqueId))
	--end

end


function Dewar:saveToXMLFile(xmlFile, key)

	local x, y, z = getWorldTranslation(self.shapeNode)
	local rx, ry, rz = getWorldRotation(self.shapeNode)

	xmlFile:setString(key .. "#uniqueId", self.uniqueId)
	xmlFile:setVector(key .. "#position", table.pack(x + self.ox, y + self.oy, z + self.oz))
	xmlFile:setVector(key .. "#rotation", table.pack(rx + self.orx, ry + self.ory, rz + self.orz))
	xmlFile:setInt(key .. "#farmId", self:getOwnerFarmId())
	xmlFile:setInt(key .. "#straws", self.straws)

	local animalKey = key .. ".animal"
	local animal = self.animal

	if animal ~= nil then

		xmlFile:setInt(animalKey .. "#country", animal.country)
		xmlFile:setString(animalKey .. "#farmId", animal.farmId)
		xmlFile:setString(animalKey .. "#uniqueId", animal.uniqueId)
		xmlFile:setString(animalKey .. "#name", animal.name)
		xmlFile:setInt(animalKey .. "#typeIndex", animal.typeIndex)
		xmlFile:setInt(animalKey .. "#subTypeIndex", animal.subTypeIndex)
		xmlFile:setFloat(animalKey .. "#success", animal.success)
		
		for type, value in pairs(animal.genetics) do
			xmlFile:setFloat(animalKey .. ".genetics#" .. type, value)
		end
	end

end


function Dewar:loadFromXMLFile(xmlFile, key)

	self.uniqueId = xmlFile:getString(key .. "#uniqueId")
	self.position = xmlFile:getVector(key .. "#position")
	self.rotation = xmlFile:getVector(key .. "#rotation")
	self:setOwnerFarmId(xmlFile:getInt(key .. "#farmId"))
	self.straws = xmlFile:getInt(key .. "#straws")

	local animalKey = key .. ".animal"

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

	self.isAddedToItemSystem = true

	return true

end


function Dewar:readStream(streamId, connection)

	self.uniqueId = streamReadString(streamId)

	self.position = {
		streamReadFloat32(streamId),
		streamReadFloat32(streamId),
		streamReadFloat32(streamId)
	}

	self.rotation = {
		streamReadFloat32(streamId),
		streamReadFloat32(streamId),
		streamReadFloat32(streamId)
	}

	self:setOwnerFarmId(streamReadUInt8(streamId))
	self.straws = streamReadUInt16(streamId)

	local hasAnimal = streamReadBool(streamId)
	local animal
	
	if hasAnimal then

		animal = { ["genetics"] = {} }

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

	self.animal = animal

	Dewar:superClass().readStream(self, streamId, connection)

end


function Dewar:writeStream(streamId, connection)

	streamWriteString(streamId, self.uniqueId)
	
	streamWriteFloat32(streamId, self.position[1])
	streamWriteFloat32(streamId, self.position[2])
	streamWriteFloat32(streamId, self.position[3])
	
	streamWriteFloat32(streamId, self.rotation[1])
	streamWriteFloat32(streamId, self.rotation[2])
	streamWriteFloat32(streamId, self.rotation[3])

	streamWriteUInt8(streamId, self:getOwnerFarmId())
	streamWriteUInt16(streamId, self.straws)

	streamWriteBool(streamId, self.animal ~= nil)

	if self.animal ~= nil then

		local animal = self.animal

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

	Dewar:superClass().writeStream(self, streamId, connection)

end


function Dewar:createNode(filename)

	local node, sharedRequestId = g_i3DManager:loadSharedI3DFile(filename, true, true, true)
    setVisibility(node, true)

	self.sharedRequestId = sharedRequestId
	self:setNodeId(node)

	local shapeNode = getChildAt(node, 0)
	setMass(shapeNode, self.mass)
	self.shapeNode = shapeNode

end


function Dewar:getUniqueId()

	return self.uniqueId

end


function Dewar:setUniqueId(uniqueId)

	self.uniqueId = uniqueId

end


function Dewar:setVisibility(visibility)

	setVisibility(self.nodeId, visibility)

end


function Dewar:setAnimal(animal)

	self.animal = 
	{
		["country"] = animal.birthday.country,
		["farmId"] = animal.farmId,
		["uniqueId"] = animal.uniqueId,
		["name"] = animal:getName(),
		["typeIndex"] = animal.animalTypeIndex,
		["subTypeIndex"] = animal.subTypeIndex,
		["genetics"] = table.clone(animal.genetics, 3),
		["success"] = animal.success
	}

	self:updateAnimalVisuals()

end


function Dewar:getAnimal()

	return self.animal

end


function Dewar:showInfo(box)

	if self.animal == nil then return end

	local animal = self.animal
	local animalSystem = g_currentMission.animalSystem
	local subType = animalSystem:getSubTypeByIndex(animal.subTypeIndex)

    box:addLine(g_i18n:getText("rl_ui_strawMultiple"), tostring(self.straws))
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


function Dewar:getTotalMass()

	return self.mass

end


function Dewar:getCanBePickedUp(player)

	return true

end


function Dewar:setStraws(value)

	self.straws = value or 0

	self:updateStrawVisuals()

end


function Dewar:changeStraws(delta)

	self.straws = math.clamp(self.straws + delta, 0, Dewar.CAPACITY)

	if self.straws <= 0 then
		self:delete()
		return
	end

	self:updateStrawVisuals()

end


function Dewar:updateStrawVisuals()

	local parent = I3DUtil.indexToObject(self.shapeNode, "0|1")

	local straws = tostring(self.straws)
	local characterIndex = 1
	local numCharacters = RealisticLivestock.NUM_CHARACTERS

	for i = 1, 4 do

		local child = getChild(parent, "strawAmount" .. i)
		
		if #straws == 1 and i ~= 2 then
			setVisibility(child, false)
			continue
		end

		if #straws == 2 and (i == 1 or i == 4) then
			setVisibility(child, false)
			continue
		end

		if #straws == 3 and i == 4 then
			setVisibility(child, false)
			continue
		end

		setVisibility(child, true)
		setShaderParameter(child, "playScale", tonumber(string.sub(straws, characterIndex, characterIndex)), 0, numCharacters, 1, false)

		characterIndex = characterIndex + 1

	end

end


function Dewar:updateAnimalVisuals()

	if self.animal == nil then return end

	local parent = I3DUtil.indexToObject(self.shapeNode, "0|0")

	local country = RealisticLivestock.AREA_CODES[self.animal.country].code
	local farmId = self.animal.farmId
	local uniqueId = self.animal.uniqueId

	local numCharacters = RealisticLivestock.NUM_CHARACTERS

	for i = 1, 2 do

		local child = getChild(parent, "animalCountry" .. i)

		local character = string.sub(country, i, i)
		local characterIndex = RealisticLivestock.ALPHABET[character:upper()]
		setShaderParameter(child, "playScale", characterIndex, 0, numCharacters, 1, false)

	end

	for i = 1, 6 do

		local child = getChild(parent, "animalFarm" .. i)

		setShaderParameter(child, "playScale", tonumber(string.sub(farmId, i, i)), 0, numCharacters, 1, false)

	end

	for i = 1, 6 do

		local child = getChild(parent, "animalId" .. i)

		setShaderParameter(child, "playScale", tonumber(string.sub(uniqueId, i, i)), 0, numCharacters, 1, false)

	end

end


function Dewar:getTensionBeltNodeId()

	return self.shapeNode

end


function Dewar:getSupportsTensionBelts()

	return true

end


function Dewar:getMeshNodes()

	return { self.shapeNode }

end