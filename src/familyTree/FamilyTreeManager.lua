FamilyTreeManager = {}


local FamilyTreeManager_mt = Class(FamilyTreeManager)
local modDirectory = g_currentModDirectory

source(modDirectory .. "src/familyTree/FamilyTree.lua")
source(modDirectory .. "src/familyTree/FamilyTreeMember.lua")


function FamilyTreeManager.new()

	local self = setmetatable({}, FamilyTreeManager_mt)

	self.trees = {}
	self.nextTreeId = 1
	self.nextAnimalId = 1
	self.offMapFathers = {}
	self.animals = {}

	return self

end


function FamilyTreeManager:load()

	if g_currentMission.missionInfo == nil or g_currentMission.missionInfo.savegameDirectory == nil then return end

    local xmlFile = XMLFile.loadIfExists("familyTreesXML", g_currentMission.missionInfo.savegameDirectory .. "/familyTrees.xml")

    if xmlFile == nil then return end

	self.nextTreeId = xmlFile:getInt("familyTrees#nextTreeId", 1)
	self.nextAnimalId = xmlFile:getInt("familyTrees#nextAnimalId", 1)

	xmlFile:iterate("familyTrees.trees.tree", function(_, key)
	
		local id = xmlFile:getInt(key .. "#id")
		local tree = FamilyTree.new(id)
		tree:loadFromXMLFile(xmlFile, key)
		self.trees[id] = tree
	
	end)

	xmlFile:iterate("familyTrees.offMapFathers.animal", function(_, key)
	
		local id = xmlFile:getInt(key .. "#id")
		local animal = FamilyTreeMember.new(id)
		animal:loadFromXMLFile(xmlFile, key)
		self.offMapFathers[id] = animal
	
	end)

	xmlFile:iterate("familyTrees.animals.animal", function(_, key)
	
		local id = xmlFile:getInt(key .. "#id")
		local animal = FamilyTreeMember.new(id)
		animal:loadFromXMLFile(xmlFile, key)
		self.animals[id] = animal
	
	end)

	xmlFile:delete()

end


function FamilyTreeManager:save(xmlFilename)

	local xmlFile = XMLFile.create("familyTreesXML", xmlFilename, "familyTrees")

	xmlFile:setInt("familyTrees#nextTreeId", self.nextTreeId)
	xmlFile:setInt("familyTrees#nextAnimalId", self.nextAnimalId)

	local i = 0

	for _, tree in ipairs(self.trees) do

		tree:saveToXMLFile(xmlFile, string.format("familyTrees.trees.tree(%s)", i))
		i = i + 1

	end
	
	i = 0

	for _, animal in ipairs(self.offMapFathers) do

		animal:saveToXMLFile(xmlFile, string.format("familyTrees.offMapFathers.animal(%s)", i))
		i = i + 1

	end
	
	i = 0

	for _, animal in ipairs(self.animals) do

		animal:saveToXMLFile(xmlFile, string.format("familyTrees.animals.animal(%s)", i))
		i = i + 1

	end

	xmlFile:save(false, true)
	xmlFile:delete()

end


function FamilyTreeManager:getNextTreeId()

	local id = self.nextTreeId
	self.nextTreeId = self.nextTreeId + 1

	return id

end


function FamilyTreeManager:getNextAnimalId()

	local id = self.nextAnimalId
	self.nextAnimalId = self.nextAnimalId + 1

	return id

end


function FamilyTreeManager:createAnimal(animal)

	local animalId = self:getNextAnimalId()
	local animalObj = FamilyTreeMember.new(animalId)
	animalObj:loadFromAnimal(animal)
	self.animals[animalId] = animalObj

	return animalObj

end


function FamilyTreeManager:createTree(animal)

	local animalObj = self:createAnimal(animal)
	local id = self:getNextTreeId()
	local tree = FamilyTree.new(id)
	tree:addAnimalToGeneration(1, animalObj:getId())
	self.trees[id] = tree
	animal:setFamilyTreeData(animalObj:getId(), id, 1)

end


function FamilyTreeManager:addChildToTree(child, mother, father)

	local motherMemberId = mother:getFamilyTreeMemberId()

	local motherMotherTreeId = mother:getMotherFamilyTreeId()
	local motherMotherGeneration = mother:getMotherFamilyTreeGeneration()

	local motherFatherTreeId = mother:getFatherFamilyTreeId()
	local motherFatherGeneration = mother:getFatherFamilyTreeGeneration()

	local fatherTreeId, fatherGeneration

	local childObj = self:createAnimal(child)
	local motherObj = self:getAnimalById(motherMemberId)
	local fatherObj

	if father ~= nil and father.data.member ~= 0 then

		if father.isOffMap then
			fatherObj = self:getOffMapFatherData(father.data.member)
			childObj:setFather(true, father.data.member)
		else
			fatherObj = self:getAnimalById(father.data.member)
			childObj:setFather(false, father.data.member)

			self.trees[father.data.motherTree]:addAnimalToGeneration(father.data.motherGeneration + 1, childObj:getId())
			if self.trees[father.data.fatherTree] ~= nil then self.trees[father.data.fatherTree]:addAnimalToGeneration(father.data.fatherGeneration + 1, childObj:getId()) end
			
			fatherTreeId, fatherGeneration = father.data.motherTree, father.data.motherGeneration + 1
		end

	end

	if motherObj ~= nil then

		childObj:setMother(motherMemberId)
		motherObj:addChild(childObj:getId())

		self.trees[motherMotherTreeId]:addAnimalToGeneration(motherMotherGeneration + 1, childObj:getId())
		if self.trees[motherFatherTreeId] ~= nil then self.trees[motherFatherTreeId]:addAnimalToGeneration(motherFatherGeneration + 1, childObj:getId()) end

	end

	if fatherObj ~= nil then

		fatherObj:addChild(childObj:getId())

	end

	child:setFamilyTreeData(childObj:getId(), motherMotherTreeId, motherMotherGeneration, fatherTreeId or 0, fatherGeneration or 0)
	print(string.format("Child (%s) added to (mother (%s), father (%s)), tree (mother=%s father=%s), generation (mother=%s father=%s)", child:getIdentifiers(), mother:getIdentifiers(), "_", motherMotherTreeId, fatherTreeId, motherMotherGeneration, fatherGeneration))

end


function FamilyTreeManager:getTree(id)

	return self.trees[id]

end


function FamilyTreeManager:getFamilyTreeFromAnimal(animal)

	return self.trees[animal:getMotherFamilyTreeId()]

end


function FamilyTreeManager:getAnimalById(id)

	return self.animals[id]

end


function FamilyTreeManager:getOffMapFatherData(id)

	return self.offMapFathers[id]

end


function FamilyTreeManager:setOffMapFatherData(animal)

	local data = FamilyTreeMember.new(#self.offMapFathers + 1)
	data:loadFromAnimal(animal)

	table.insert(self.offMapFathers, data)
	return #self.offMapFathers

end


g_familyTreeManager = FamilyTreeManager.new()