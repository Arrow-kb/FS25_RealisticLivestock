FamilyTree = {}


local FamilyTree_mt = Class(FamilyTree)


function FamilyTree.new(id)

	local self = setmetatable({}, FamilyTree_mt)

	self.id = id
	self.generations = {}

	return self

end


function FamilyTree:loadFromXMLFile(xmlFile, key)

	self.id = xmlFile:getInt(key .. "#id")

	xmlFile:iterate(key .. ".generation", function(i, gKey)

		local generation = {}
	
		xmlFile:iterate(gKey .. ".member", function(_, mKey)
		
			local id = xmlFile:getInt(mKey)
			table.insert(generation, id)
		
		end)

		table.insert(self.generations, generation)
	
	end)

end


function FamilyTree:saveToXMLFile(xmlFile, key)

	xmlFile:setInt(key .. "#id", self.id)

	for i, generation in ipairs(self.generations) do

		for j, member in ipairs(generation) do

			xmlFile:setInt(string.format("%s.generation(%s).member(%s)", key, i - 1, j - 1), member)

		end

	end

end


function FamilyTree:addAnimalToGeneration(generationId, childId)

	if self.generations[generationId] == nil then self.generations[generationId] = {} end

	table.insert(self.generations[generationId], childId)

end


function FamilyTree:getMemberByGeneration(generation, index)

	local id = self.generations[generation][index]
	return g_familyTreeManager:getAnimalById(id)

end


function FamilyTree:getNumOfGenerations()

	return #self.generations

end


function FamilyTree:getNumOfAnimalsInGeneration(generation)

	return #self.generations[generation]

end