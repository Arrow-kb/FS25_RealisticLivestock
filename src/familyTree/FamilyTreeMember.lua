FamilyTreeMember = {}


local FamilyTreeMember_mt = Class(FamilyTreeMember)


function FamilyTreeMember.new(id)

	local self = setmetatable({}, FamilyTreeMember_mt)

	self.id = id
	self.children = {}

	return self

end


function FamilyTreeMember:loadFromAnimal(animal)

	self.age = animal:getAge()
	self.name = animal:getName()
	self.subTypeIndex = animal:getSubTypeIndex()
	self.animalTypeIndex = animal.animalTypeIndex
	self.identifier = animal:getIdentifiers()

end


function FamilyTreeMember:loadFromXMLFile(xmlFile, key)

	self.id = xmlFile:getInt(key .. "#id")
	self.subTypeIndex = xmlFile:getInt(key .. "#subTypeIndex")
	self.animalTypeIndex = xmlFile:getInt(key .. "#animalTypeIndex")
	self.age = xmlFile:getInt(key .. "#age")
	self.name = xmlFile:getString(key .. "#name")
	self.identifier = xmlFile:getString(key .. "#identifier")

	if xmlFile:hasProperty(key .. ".mother") then

		self.mother = {
			["id"] = xmlFile:getInt(key .. ".mother#id")
		}

	end

	if xmlFile:hasProperty(key .. ".father") then

		self.father = {
			["isOffMap"] = xmlFile:getBool(key .. ".father#isOffMap", true),
			["id"] = xmlFile:getInt(key .. ".father#id")
		}

	end

	self.children = {}

	xmlFile:iterate(key .. ".children.child", function(_, childKey)
	
		table.insert(self.children, xmlFile:getInt(childKey .. "#id"))
	
	end)

end


function FamilyTreeMember:saveToXMLFile(xmlFile, key)

	xmlFile:setInt(key .. "#id", self.id)
	xmlFile:setInt(key .. "#subTypeIndex", self.subTypeIndex)
	xmlFile:setInt(key .. "#animalTypeIndex", self.animalTypeIndex)
	xmlFile:setInt(key .. "#age", self.age)
	xmlFile:setString(key .. "#identifier", self.identifier)
	
	if self.name ~= nil and self.name ~= "" then xmlFile:setString(key .. "#name", self.name) end

	if self.mother ~= nil then

		xmlFile:setInt(key .. ".mother#id", self.mother.id)

	end

	if self.father ~= nil then

		xmlFile:setBool(key .. ".father#isOffMap", self.father.isOffMap)
		xmlFile:setInt(key .. ".father#id", self.father.id)

	end

	if #self.children > 0 then
	
		for i, id in pairs(self.children) do xmlFile:setInt(string.format("%s.children.child(%s)#id", key, i - 1), id) end
	
	end

end


function FamilyTreeMember:getId()

	return self.id

end


function FamilyTreeMember:getAge()

	return self.age

end


function FamilyTreeMember:addChild(id)

	table.insert(self.children, id)

end


function FamilyTreeMember:getChildren()

	return self.children

end


function FamilyTreeMember:setMother(id)

	self.mother = {
		["id"] = id
	}

end


function FamilyTreeMember:getMother()

	if self.mother == nil or self.mother.id == 0 then return nil end

	return self.mother

end


function FamilyTreeMember:setFather(isOffMap, id)

	self.father = {
		["isOffMap"] = isOffMap,
		["id"] = id
	}

end


function FamilyTreeMember:getFather()

	if self.father == nil or self.father.id == 0 then return nil end

	return self.father

end


function FamilyTreeMember:getImage()

	if self.image == nil then self.image = g_currentMission.animalSystem:getVisualByAge(self.subTypeIndex, self.age).store.imageFilename end
	
	return self.image

end