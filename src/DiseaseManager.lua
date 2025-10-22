DiseaseManager = {}

local modDirectory = g_currentModDirectory
local diseaseManager_mt = Class(DiseaseManager)

function DiseaseManager.new()

    local self = setmetatable({}, diseaseManager_mt)

	self.diseases = {}
	self.diseasesEnabled = true
	self.diseasesChance = 1

	self:loadDiseases()

	return self

end


function DiseaseManager:loadDiseases()

	local xmlFile = XMLFile.loadIfExists("diseases", modDirectory .. "xml/diseases.xml")

	if xmlFile == nil then return end

	xmlFile:iterate("diseases.disease", function(_, key)
	
		local title = xmlFile:getString(key .. "#title")
		local translationKey = "rl_disease_" .. title
		local name = g_i18n:getText(translationKey)

		local animals = {}
		local animalTitles = string.split(xmlFile:getString(key .. "#animals"), " ")

		for _, animalTitle in pairs(animalTitles) do animals[AnimalType[animalTitle]] = true end

		local valueModifier = xmlFile:getFloat(key .. "#value", 1.0)
		local transmission = xmlFile:getFloat(key .. "#transmission", 0)
		local immunity = xmlFile:getInt(key .. "#immunity", 12)

		local prerequisites = {}

		xmlFile:iterate(key .. ".prerequisites.prerequisite", function(_, prerequisiteKey)

			local valueType = xmlFile:getString(prerequisiteKey .. "#valueType", "Int")
		
			table.insert(prerequisites, {
				["path"] = string.split(xmlFile:getString(prerequisiteKey .. "#path"), "."),
				["value"] = XMLFile["get" .. valueType](xmlFile, prerequisiteKey .. "#value")
			})
		
		end)

		local probability = {}

		xmlFile:iterate(key .. ".probability.key", function(_, probabilityKey)

			table.insert(probability, {
				["age"] = xmlFile:getInt(probabilityKey .. "#age"),
				["value"] = xmlFile:getFloat(probabilityKey .. "#value")
			})
		
		end)

		local fatality = {}

		xmlFile:iterate(key .. ".fatality.key", function(_, fatalityKey)

			table.insert(fatality, {
				["time"] = xmlFile:getInt(fatalityKey .. "#time"),
				["value"] = xmlFile:getFloat(fatalityKey .. "#value")
			})
		
		end)

		local output = {}

		xmlFile:iterate(key .. ".output.fillType", function(_, outputKey)

			output[xmlFile:getString(outputKey .. "#type")] = xmlFile:getFloat(outputKey .. "#modifier")
		
		end)

		local treatment = {
			["cost"] = xmlFile:getFloat(key .. ".treatment#cost"),
			["duration"] = xmlFile:getInt(key .. ".treatment#duration")
		}

		if treatment.cost == nil or treatment.duration == nil then treatment = nil end

		local recovery = xmlFile:getFloat(key .. "#recovery")

		local disease = {
			["title"] = title,
			["key"] = translationKey,
			["name"] = name,
			["animals"] = animals,
			["value"] = valueModifier,
			["transmission"] = transmission,
			["immunity"] = immunity,
			["prerequisites"] = prerequisites,
			["probability"] = probability,
			["fatality"] = fatality,
			["output"] = output,
			["treatment"] = treatment,
			["recovery"] = recovery
		}

		if xmlFile:hasProperty(key .. ".carrier") then

			local carrier = {}

			if xmlFile:hasProperty(key .. ".carrier.output") then

				local carrierOutput = {}

				xmlFile:iterate(key .. ".output.fillType", function(_, outputKey)

					carrierOutput[xmlFile:getString(outputKey .. "#type")] = xmlFile:getFloat(outputKey .. "#modifier")
		
				end)

				carrier.output = carrierOutput

			end

			disease.carrier = carrier

		end

		if xmlFile:hasProperty(key .. ".genetic") then

			disease.genetic = {
				["recessive"] = xmlFile:getBool(key .. ".genetic#recessive", false),
				["dominant"] = xmlFile:getBool(key .. ".genetic#dominant", false),
				["saleChance"] = xmlFile:getFloat(key .. ".genetic#saleChance", 0)
			}

		end

		table.insert(self.diseases, disease)
	
	end)

	xmlFile:delete()

end


function DiseaseManager:getDiseaseByTitle(title)

	for _, disease in pairs(self.diseases) do
		if disease.title == title then return disease end
	end

	return nil

end


function DiseaseManager:onDayChanged(animal)

	if not self.diseasesEnabled then return end

	for _, disease in pairs(self.diseases) do

		if not disease.animals[animal.animalTypeIndex] then continue end

		local eligible = true

		for _, existingDisease in pairs(animal.diseases) do

			if existingDisease.type.title == disease.title then
				eligible = false
				break
			end

		end

		if not eligible then continue end

		for _, prerequisite in pairs(disease.prerequisites) do

			local currentValue = animal

			for _, path in pairs(prerequisite.path) do

				currentValue = currentValue[path]

			end

			if currentValue ~= prerequisite.value then
				eligible = false
				break
			end

		end

		if not eligible then continue end

		local probability = 0

		for i = 1, #disease.probability do

			if animal.age <= disease.probability[i].age or i == #disease.probability then
				probability = disease.probability[i].value
				break
			end

		end

		if math.random() >= probability * self.diseasesChance then continue end

		animal:addDisease(disease)

	end

end


function DiseaseManager:setGeneticDiseasesForSaleAnimal(animal)

	for _, disease in pairs(self.diseases) do

		if not disease.animals[animal.animalTypeIndex] or disease.genetic == nil or disease.probability[1].value ~= 0 or #disease.probability > 1 then continue end

		local eligible = true

		for _, existingDisease in pairs(animal.diseases) do

			if existingDisease.type.title == disease.title then
				eligible = false
				break
			end

		end

		if not eligible then continue end

		if math.random() < disease.genetic.saleChance then

			local numGenes = 1

			if math.random() <= 0.25 then numGenes = 2 end

			animal:addDisease(disease, disease.genetic.recessive and numGenes == 1, numGenes)

		end

	end

end


function DiseaseManager:calculateTransmission(animals)

	if not self.diseasesEnabled then return end

	local diseases = {}
	local hasDiseases = false

	for _, animal in pairs(animals) do

		for _, disease in pairs(animal.diseases) do

			local type = disease.type

			if type.transmission == nil or type.transmission <= 0 then continue end

			if diseases[type.title] == nil then
				diseases[type.title] = { ["type"] = type, ["amount"] = 0 }
				hasDiseases = true
			end

			diseases[type.title].amount = diseases[type.title].amount + 1

		end

	end


	if not hasDiseases then return end


	for _, animal in pairs(animals) do

		for title, disease in pairs(diseases) do

			local eligible = true

			for _, existingDisease in pairs(animal.diseases) do

				if existingDisease.type.title == title then
					eligible = false
					break
				end

			end

			if not eligible then continue end

			for _, prerequisite in pairs(disease.type.prerequisites) do

				local currentValue = animal

				for _, path in pairs(prerequisite.path) do

					currentValue = currentValue[path]

				end

				if currentValue ~= prerequisite.value then
					eligible = false
					break
				end

			end

			if not eligible then continue end

			if math.random() <= disease.type.transmission * (disease.amount / #animals) then
				animal:addDisease(disease.type)
			end

		end

	end


end


function DiseaseManager.onSettingChanged(name, state)

	if g_diseaseManager ~= nil then g_diseaseManager[name] = state end

end