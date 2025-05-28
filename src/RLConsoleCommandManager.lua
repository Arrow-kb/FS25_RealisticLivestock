RLConsoleCommandManager = {}

local rlConsoleCommandManager_mt = Class(RLConsoleCommandManager)

function RLConsoleCommandManager.new()

	local self = setmetatable({}, rlConsoleCommandManager_mt)

	self.husbandrySystem = g_currentMission.husbandrySystem
	self.animalSystem = g_currentMission.animalSystem
	self.animal = nil
	self.placeable = nil

    if g_currentMission:getIsServer() and not g_currentMission.missionDynamicInfo.isMultiplayer then
        addConsoleCommand("rlSetTargetAnimal", "Set the target animal for future console commands", "setAnimal", self, "[type] [farmId] [uniqueId]")
        addConsoleCommand("rlSetAnimalGenetics", "Set the genetics of the targeted animal", "setGenetics", self, "[geneticType] [value]")
        addConsoleCommand("rlSetAnimalInput", "Set the input of the targeted animal", "setInput", self, "[inputType] [value]")
        addConsoleCommand("rlSetAnimalOutput", "Set the output of the targeted animal", "setOutput", self, "[outputType] [value]")
    end

	return self

end


function RLConsoleCommandManager:setAnimal(animalType, farmId, uniqueId)

	self.animal = nil
	self.placeable = nil

	if animalType == nil or type(animalType) ~= "string" then

		print("rlSetTargetAnimal: no animal type given, accepted types:")

		for name, index in pairs(AnimalType) do print("|--- " .. name) end

		return

	end

	if farmId == nil then return "rlSetTargetAnimal: no farmId given" end
	
	if uniqueId == nil then return "rlSetTargetAnimal: no uniqueId given" end

	local animalTypeIndex = AnimalType[animalType:upper()]

	for _, placeable in pairs(self.husbandrySystem.placeables) do

		if placeable:getAnimalTypeIndex() ~= animalTypeIndex then continue end

		local animals = placeable:getClusters()
		
		for _, animal in pairs(animals) do

			if animal.farmId == farmId and animal.uniqueId == uniqueId then

				self.animal = animal
				self.placeable = placeable

				return "rlSetTargetAnimal: animal set successfully"

			end

		end

	end


	for _, trailer in pairs(self.husbandrySystem.livestockTrailers) do

		local trailerType = trailer:getCurrentAnimalType()

		if trailerType == nil or trailerType.typeIndex ~= animalTypeIndex then continue end

		local animals = trailer:getClusters()
		
		for _, animal in pairs(animals) do

			if animal.farmId == farmId and animal.uniqueId == uniqueId then

				self.animal = animal

				return "rlSetTargetAnimal: animal set successfully"

			end

		end

	end

	return "rlSetTargetAnimal: animal not found"

end


function RLConsoleCommandManager:setGenetics(geneticType, value)

	if self.animal == nil then return "rlSetAnimalGenetics: no targeted animal" end

	if geneticType == nil or type(geneticType) ~= "string" or self.animal.genetics[geneticType] == nil then
		
		print("rlSetAnimalGenetics: invalid genetic type given, accepted types:")

		for key, _ in pairs(self.animal.genetics) do print("|--- " .. key) end

		return
		
	end

	if value == nil then return "rlSetAnimalGenetics: no value given" end

	value = tonumber(value)

	if value == nil then return "rlSetAnimalGenetics: invalid value given" end

	if value < 0.25 or value > 1.75 then return "rlSetAnimalGenetics: invalid value given, must be in range 0.25 - 1.75" end

	self.animal.genetics[geneticType] = value

	return "rlSetAnimalGenetics: animal genetics set successfully"

end


function RLConsoleCommandManager:setInput(inputType, value)

	if self.animal == nil then return "rlSetAnimalInput: no targeted animal" end

	if inputType == nil or type(inputType) ~= "string" or self.animal.input[inputType] == nil then
		
		print("rlSetAnimalInput: invalid input type given, accepted types:")

		for key, _ in pairs(self.animal.input) do print("|--- " .. key) end

		return
		
	end

	if value == nil then return "rlSetAnimalInput: no value given" end

	value = tonumber(value)

	if value == nil then return "rlSetAnimalInput: invalid value given" end

	if value < 0 then return "rlSetAnimalInput: invalid value given, must be higher than or equal to 0" end

	self.animal.input[inputType] = value
	if self.placeable ~= nil then self.placeable:updateInputAndOutput(self.placeable:getClusters()) end

	return "rlSetAnimalInput: animal input set successfully"

end


function RLConsoleCommandManager:setOutput(outputType, value)

	if self.animal == nil then return "rlSetAnimalOutput: no targeted animal" end

	if outputType == nil or type(outputType) ~= "string" or self.animal.output[outputType] == nil then
		
		print("rlSetAnimalOutput: invalid output type given, accepted types:")

		for key, _ in pairs(self.animal.output) do print("|--- " .. key) end

		return
		
	end

	if value == nil then return "rlSetAnimalOutput: no value given" end

	value = tonumber(value)

	if value == nil then return "rlSetAnimalOutput: invalid value given" end

	if value < 0 then return "rlSetAnimalOutput: invalid value given, must be higher than or equal to 0" end

	self.animal.output[outputType] = value
	if self.placeable ~= nil then self.placeable:updateInputAndOutput(self.placeable:getClusters()) end

	return "rlSetAnimalOutput: animal output set successfully"

end