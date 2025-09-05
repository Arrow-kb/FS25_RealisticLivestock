AIAnimalManager = {}

local AIAnimalManager_mt = Class(AIAnimalManager)


function AIAnimalManager.new(husbandry, isServer)

	local self = setmetatable({}, AIAnimalManager_mt)

	self.husbandry = husbandry
	self.isServer = isServer
	self.wage = 0
	self.isProfile = false

	self.ANIMAL_TYPE_TO_WAGE = {
		[AnimalType.COW] = 20,
		[AnimalType.SHEEP] = 12.5,
		[AnimalType.PIG] = 10,
		[AnimalType.HORSE] = 25,
		[AnimalType.CHICKEN] = 2
	}

	self.settings = {
		["buy"] = {
			["enabled"] = false,
			["budget"] = {
				["type"] = "fixed",
				["fixed"] = 5000,
				["percentage"] = 1
			},
			["maxAnimals"] = 5,
			["breed"] = "any",
			["diseases"] = false,
			["gender"] = "any",
			["age"] = {
				["min"] = 0,
				["max"] = 999
			},
			["quality"] = {
				["min"] = 25,
				["max"] = 175
			},
			["health"] = {
				["min"] = 25,
				["max"] = 175
			},
			["fertility"] = {
				["min"] = 0,
				["max"] = 175
			},
			["productivity"] = {
				["min"] = 25,
				["max"] = 175
			},
			["metabolism"] = {
				["min"] = 25,
				["max"] = 175
			}
		},
		["sell"] = {
			["enabled"] = false,
			["maxAnimals"] = 5,
			["mark"] = false,
			["diseases"] = false,
			["gender"] = "any",
			["age"] = {
				["min"] = 0,
				["max"] = 999
			},
			["quality"] = {
				["min"] = 25,
				["max"] = 175
			},
			["health"] = {
				["min"] = 25,
				["max"] = 175
			},
			["fertility"] = {
				["min"] = 0,
				["max"] = 175
			},
			["productivity"] = {
				["min"] = 25,
				["max"] = 175
			},
			["metabolism"] = {
				["min"] = 25,
				["max"] = 175
			}
		},
		["castrate"] = {
			["enabled"] = false,
			["mark"] = false,
			["diseases"] = false,
			["age"] = {
				["min"] = 0,
				["max"] = 0
			},
			["quality"] = {
				["min"] = 25,
				["max"] = 175
			},
			["health"] = {
				["min"] = 25,
				["max"] = 175
			},
			["fertility"] = {
				["min"] = 0,
				["max"] = 175
			},
			["productivity"] = {
				["min"] = 25,
				["max"] = 175
			},
			["metabolism"] = {
				["min"] = 25,
				["max"] = 175
			}
		},
		["naming"] = {
			["enabled"] = false,
			["convention"] = "random",
			["previous"] = nil
		},
		["ai"] = {
			["enabled"] = false,
			["maxAnimals"] = 5,
			["mark"] = false,
			["diseases"] = false,
			["semen"] = "any",
			["age"] = {
				["min"] = 0,
				["max"] = 999
			},
			["quality"] = {
				["min"] = 25,
				["max"] = 175
			},
			["health"] = {
				["min"] = 25,
				["max"] = 175
			},
			["fertility"] = {
				["min"] = 0,
				["max"] = 175
			},
			["productivity"] = {
				["min"] = 25,
				["max"] = 175
			},
			["metabolism"] = {
				["min"] = 25,
				["max"] = 175
			}
		}
	}

	return self

end


function AIAnimalManager:saveToXMLFile(xmlFile, baseKey)

	local key = self.isProfile and baseKey or (baseKey .. ".AIAnimalManager")
	local settings = self.settings


	if not self.isProfile then xmlFile:setFloat(key .. "#wage", self.wage) end


	-- BUY SETTINGS


	xmlFile:setBool(key .. ".buy#enabled", settings.buy.enabled)
	xmlFile:setString(key .. ".buy.budget#type", settings.buy.budget.type)
	xmlFile:setInt(key .. ".buy.budget#fixed", settings.buy.budget.fixed)
	xmlFile:setFloat(key .. ".buy.budget#percentage", settings.buy.budget.percentage)
	xmlFile:setInt(key .. ".buy#maxAnimals", settings.buy.maxAnimals)
	xmlFile:setString(key .. ".buy#breed", settings.buy.breed)
	xmlFile:setBool(key .. ".buy#diseases", settings.buy.diseases)
	xmlFile:setString(key .. ".buy#gender", settings.buy.gender)
	xmlFile:setInt(key .. ".buy.age#min", settings.buy.age.min)
	xmlFile:setInt(key .. ".buy.age#max", settings.buy.age.max)
	xmlFile:setInt(key .. ".buy.quality#min", settings.buy.quality.min)
	xmlFile:setInt(key .. ".buy.quality#max", settings.buy.quality.max)
	xmlFile:setInt(key .. ".buy.health#min", settings.buy.health.min)
	xmlFile:setInt(key .. ".buy.health#max", settings.buy.health.max)
	xmlFile:setInt(key .. ".buy.fertility#min", settings.buy.fertility.min)
	xmlFile:setInt(key .. ".buy.fertility#max", settings.buy.fertility.max)
	xmlFile:setInt(key .. ".buy.productivity#min", settings.buy.productivity.min)
	xmlFile:setInt(key .. ".buy.productivity#max", settings.buy.productivity.max)
	xmlFile:setInt(key .. ".buy.metabolism#min", settings.buy.metabolism.min)
	xmlFile:setInt(key .. ".buy.metabolism#max", settings.buy.metabolism.max)


	-- SELL SETTINGS


	xmlFile:setBool(key .. ".sell#enabled", settings.sell.enabled)
	xmlFile:setInt(key .. ".sell#maxAnimals", settings.sell.maxAnimals)
	xmlFile:setBool(key .. ".sell#mark", settings.sell.mark)
	xmlFile:setBool(key .. ".sell#diseases", settings.sell.diseases)
	xmlFile:setString(key .. ".sell#gender", settings.sell.gender)
	xmlFile:setInt(key .. ".sell.age#min", settings.sell.age.min)
	xmlFile:setInt(key .. ".sell.age#max", settings.sell.age.max)
	xmlFile:setInt(key .. ".sell.quality#min", settings.sell.quality.min)
	xmlFile:setInt(key .. ".sell.quality#max", settings.sell.quality.max)
	xmlFile:setInt(key .. ".sell.health#min", settings.sell.health.min)
	xmlFile:setInt(key .. ".sell.health#max", settings.sell.health.max)
	xmlFile:setInt(key .. ".sell.fertility#min", settings.sell.fertility.min)
	xmlFile:setInt(key .. ".sell.fertility#max", settings.sell.fertility.max)
	xmlFile:setInt(key .. ".sell.productivity#min", settings.sell.productivity.min)
	xmlFile:setInt(key .. ".sell.productivity#max", settings.sell.productivity.max)
	xmlFile:setInt(key .. ".sell.metabolism#min", settings.sell.metabolism.min)
	xmlFile:setInt(key .. ".sell.metabolism#max", settings.sell.metabolism.max)


	-- CASTRATE SETTINGS


	xmlFile:setBool(key .. ".castrate#enabled", settings.castrate.enabled)
	xmlFile:setBool(key .. ".castrate#mark", settings.castrate.mark)
	xmlFile:setBool(key .. ".castrate#diseases", settings.castrate.diseases)
	xmlFile:setInt(key .. ".castrate.age#min", settings.castrate.age.min)
	xmlFile:setInt(key .. ".castrate.age#max", settings.castrate.age.max)
	xmlFile:setInt(key .. ".castrate.quality#min", settings.castrate.quality.min)
	xmlFile:setInt(key .. ".castrate.quality#max", settings.castrate.quality.max)
	xmlFile:setInt(key .. ".castrate.health#min", settings.castrate.health.min)
	xmlFile:setInt(key .. ".castrate.health#max", settings.castrate.health.max)
	xmlFile:setInt(key .. ".castrate.fertility#min", settings.castrate.fertility.min)
	xmlFile:setInt(key .. ".castrate.fertility#max", settings.castrate.fertility.max)
	xmlFile:setInt(key .. ".castrate.productivity#min", settings.castrate.productivity.min)
	xmlFile:setInt(key .. ".castrate.productivity#max", settings.castrate.productivity.max)
	xmlFile:setInt(key .. ".castrate.metabolism#min", settings.castrate.metabolism.min)
	xmlFile:setInt(key .. ".castrate.metabolism#max", settings.castrate.metabolism.max)


	-- NAMING SETTINGS


	xmlFile:setBool(key .. ".naming#enabled", settings.naming.enabled)
	xmlFile:setString(key .. ".naming#convention", settings.naming.convention)
	if not self.isProfile and settings.naming.previous ~= nil and settings.naming.convention == "alphabetical" then xmlFile:setString(key .. ".naming#previous", settings.naming.previous) end


	-- AI SETTINGS


	xmlFile:setBool(key .. ".ai#enabled", settings.ai.enabled)
	xmlFile:setInt(key .. ".ai#maxAnimals", settings.ai.maxAnimals)
	xmlFile:setBool(key .. ".ai#mark", settings.ai.mark)
	xmlFile:setBool(key .. ".ai#diseases", settings.ai.diseases)
	xmlFile:setString(key .. ".ai#semen", settings.ai.semen)
	xmlFile:setInt(key .. ".ai.age#min", settings.ai.age.min)
	xmlFile:setInt(key .. ".ai.age#max", settings.ai.age.max)
	xmlFile:setInt(key .. ".ai.quality#min", settings.ai.quality.min)
	xmlFile:setInt(key .. ".ai.quality#max", settings.ai.quality.max)
	xmlFile:setInt(key .. ".ai.health#min", settings.ai.health.min)
	xmlFile:setInt(key .. ".ai.health#max", settings.ai.health.max)
	xmlFile:setInt(key .. ".ai.fertility#min", settings.ai.fertility.min)
	xmlFile:setInt(key .. ".ai.fertility#max", settings.ai.fertility.max)
	xmlFile:setInt(key .. ".ai.productivity#min", settings.ai.productivity.min)
	xmlFile:setInt(key .. ".ai.productivity#max", settings.ai.productivity.max)
	xmlFile:setInt(key .. ".ai.metabolism#min", settings.ai.metabolism.min)
	xmlFile:setInt(key .. ".ai.metabolism#max", settings.ai.metabolism.max)

end


function AIAnimalManager:loadFromXMLFile(xmlFile, baseKey)

	local key = self.isProfile and basekey or (baseKey .. ".AIAnimalManager")
	local settings = self.settings


	self.wage = xmlFile:getFloat(key .. "#wage", 0)


	-- BUY SETTINGS


	settings.buy.enabled = xmlFile:getBool(key .. ".buy#enabled", settings.buy.enabled)
	settings.buy.budget.type = xmlFile:getString(key .. ".buy.budget#type", settings.buy.budget.type)
	settings.buy.budget.fixed = xmlFile:getInt(key .. ".buy.budget#fixed", settings.buy.budget.fixed)
	settings.buy.budget.percentage = xmlFile:getFloat(key .. ".buy.budget#percentage", settings.buy.budget.percentage)
	settings.buy.maxAnimals = xmlFile:getInt(key .. ".buy#maxAnimals", settings.buy.maxAnimals)
	settings.buy.breed = xmlFile:getString(key .. ".buy#breed", settings.buy.breed)
	settings.buy.diseases = xmlFile:getBool(key .. ".buy#diseases", settings.buy.diseases)
	settings.buy.gender = xmlFile:getString(key .. ".buy#gender", settings.buy.gender)
	settings.buy.age.min = xmlFile:getInt(key .. ".buy.age#min", settings.buy.age.min)
	settings.buy.age.max = xmlFile:getInt(key .. ".buy.age#max", settings.buy.age.max)
	settings.buy.quality.min = xmlFile:getInt(key .. ".buy.quality#min", settings.buy.quality.min)
	settings.buy.quality.max = xmlFile:getInt(key .. ".buy.quality#max", settings.buy.quality.max)
	settings.buy.health.min = xmlFile:getInt(key .. ".buy.health#min", settings.buy.health.min)
	settings.buy.health.max = xmlFile:getInt(key .. ".buy.health#max", settings.buy.health.max)
	settings.buy.fertility.min = xmlFile:getInt(key .. ".buy.fertility#min", settings.buy.fertility.min)
	settings.buy.fertility.max = xmlFile:getInt(key .. ".buy.fertility#max", settings.buy.fertility.max)
	settings.buy.productivity.min = xmlFile:getInt(key .. ".buy.productivity#min", settings.buy.productivity.min)
	settings.buy.productivity.max = xmlFile:getInt(key .. ".buy.productivity#max", settings.buy.productivity.max)
	settings.buy.metabolism.min = xmlFile:getInt(key .. ".buy.metabolism#min", settings.buy.metabolism.min)
	settings.buy.metabolism.max = xmlFile:getInt(key .. ".buy.metabolism#max", settings.buy.metabolism.max)


	-- SELL SETTINGS


	settings.sell.enabled = xmlFile:getBool(key .. ".sell#enabled", settings.sell.enabled)
	settings.sell.maxAnimals = xmlFile:getInt(key .. ".sell#maxAnimals", settings.sell.maxAnimals)
	settings.sell.mark = xmlFile:getBool(key .. ".sell#mark", settings.sell.mark)
	settings.sell.diseases = xmlFile:getBool(key .. ".sell#diseases", settings.sell.diseases)
	settings.sell.gender = xmlFile:getString(key .. ".sell#gender", settings.sell.gender)
	settings.sell.age.min = xmlFile:getInt(key .. ".sell.age#min", settings.sell.age.min)
	settings.sell.age.max = xmlFile:getInt(key .. ".sell.age#max", settings.sell.age.max)
	settings.sell.quality.min = xmlFile:getInt(key .. ".sell.quality#min", settings.sell.quality.min)
	settings.sell.quality.max = xmlFile:getInt(key .. ".sell.quality#max", settings.sell.quality.max)
	settings.sell.health.min = xmlFile:getInt(key .. ".sell.health#min", settings.sell.health.min)
	settings.sell.health.max = xmlFile:getInt(key .. ".sell.health#max", settings.sell.health.max)
	settings.sell.fertility.min = xmlFile:getInt(key .. ".sell.fertility#min", settings.sell.fertility.min)
	settings.sell.fertility.max = xmlFile:getInt(key .. ".sell.fertility#max", settings.sell.fertility.max)
	settings.sell.productivity.min = xmlFile:getInt(key .. ".sell.productivity#min", settings.sell.productivity.min)
	settings.sell.productivity.max = xmlFile:getInt(key .. ".sell.productivity#max", settings.sell.productivity.max)
	settings.sell.metabolism.min = xmlFile:getInt(key .. ".sell.metabolism#min", settings.sell.metabolism.min)
	settings.sell.metabolism.max = xmlFile:getInt(key .. ".sell.metabolism#max", settings.sell.metabolism.max)


	-- CASTRATE SETTINGS


	settings.castrate.enabled = xmlFile:getBool(key .. ".castrate#enabled", settings.castrate.enabled)
	settings.castrate.mark = xmlFile:getBool(key .. ".castrate#mark", settings.castrate.mark)
	settings.castrate.diseases = xmlFile:getBool(key .. ".castrate#diseases", settings.castrate.diseases)
	settings.castrate.age.min = xmlFile:getInt(key .. ".castrate.age#min", settings.castrate.age.min)
	settings.castrate.age.max = xmlFile:getInt(key .. ".castrate.age#max", settings.castrate.age.max)
	settings.castrate.quality.min = xmlFile:getInt(key .. ".castrate.quality#min", settings.castrate.quality.min)
	settings.castrate.quality.max = xmlFile:getInt(key .. ".castrate.quality#max", settings.castrate.quality.max)
	settings.castrate.health.min = xmlFile:getInt(key .. ".castrate.health#min", settings.castrate.health.min)
	settings.castrate.health.max = xmlFile:getInt(key .. ".castrate.health#max", settings.castrate.health.max)
	settings.castrate.fertility.min = xmlFile:getInt(key .. ".castrate.fertility#min", settings.castrate.fertility.min)
	settings.castrate.fertility.max = xmlFile:getInt(key .. ".castrate.fertility#max", settings.castrate.fertility.max)
	settings.castrate.productivity.min = xmlFile:getInt(key .. ".castrate.productivity#min", settings.castrate.productivity.min)
	settings.castrate.productivity.max = xmlFile:getInt(key .. ".castrate.productivity#max", settings.castrate.productivity.max)
	settings.castrate.metabolism.min = xmlFile:getInt(key .. ".castrate.metabolism#min", settings.castrate.metabolism.min)
	settings.castrate.metabolism.max = xmlFile:getInt(key .. ".castrate.metabolism#max", settings.castrate.metabolism.max)


	-- NAMING SETTINGS


	settings.naming.enabled = xmlFile:getBool(key .. ".naming#enabled", settings.naming.enabled)
	settings.naming.convention = xmlFile:getString(key .. ".naming#convention", settings.naming.convention)
	settings.naming.previous = xmlFile:getString(key .. ".naming#previous", settings.naming.previous)


	-- AI SETTINGS


	settings.ai.enabled = xmlFile:getBool(key .. ".ai#enabled", settings.ai.enabled)
	settings.ai.maxAnimals = xmlFile:getInt(key .. ".ai#maxAnimals", settings.ai.maxAnimals)
	settings.ai.mark = xmlFile:getBool(key .. ".ai#mark", settings.ai.mark)
	settings.ai.diseases = xmlFile:getBool(key .. ".ai#diseases", settings.ai.diseases)
	settings.ai.semen = xmlFile:getString(key .. ".ai#semen", settings.ai.semen)
	settings.ai.age.min = xmlFile:getInt(key .. ".ai.age#min", settings.ai.age.min)
	settings.ai.age.max = xmlFile:getInt(key .. ".ai.age#max", settings.ai.age.max)
	settings.ai.quality.min = xmlFile:getInt(key .. ".ai.quality#min", settings.ai.quality.min)
	settings.ai.quality.max = xmlFile:getInt(key .. ".ai.quality#max", settings.ai.quality.max)
	settings.ai.health.min = xmlFile:getInt(key .. ".ai.health#min", settings.ai.health.min)
	settings.ai.health.max = xmlFile:getInt(key .. ".ai.health#max", settings.ai.health.max)
	settings.ai.fertility.min = xmlFile:getInt(key .. ".ai.fertility#min", settings.ai.fertility.min)
	settings.ai.fertility.max = xmlFile:getInt(key .. ".ai.fertility#max", settings.ai.fertility.max)
	settings.ai.productivity.min = xmlFile:getInt(key .. ".ai.productivity#min", settings.ai.productivity.min)
	settings.ai.productivity.max = xmlFile:getInt(key .. ".ai.productivity#max", settings.ai.productivity.max)
	settings.ai.metabolism.min = xmlFile:getInt(key .. ".ai.metabolism#min", settings.ai.metabolism.min)
	settings.ai.metabolism.max = xmlFile:getInt(key .. ".ai.metabolism#max", settings.ai.metabolism.max)

end


function AIAnimalManager:getSettings(type)

	return type == nil and self.settings or self.settings[type]

end


function AIAnimalManager:setSettings(settings, type)

	if type == nil then 
		self.settings = settings
	else
		self.settings[type] = settings
	end

end


function AIAnimalManager:onDayChanged()

	if not self.isServer then return end

	local buy, sell, castrate, naming, ai = self.settings.buy, self.settings.sell, self.settings.castrate, self.settings.naming, self.settings.ai

	self.wage = 0

	if not buy.enabled and not sell.enabled and not castrate.enabled and not naming.enabled and not ai.enabled then return end

	local farmId = self.husbandry:getOwnerFarmId()
	local farm = g_farmManager:getFarmById(farmId)
	local animalSystem = g_currentMission.animalSystem
	local animalTypeIndex = self.husbandry:getAnimalTypeIndex()
	local animalTypeToWage = self.ANIMAL_TYPE_TO_WAGE[animalTypeIndex] or 5


	-- ####################### SELL #######################


	if sell.enabled and sell.maxAnimals > 0 then

		local soldAnimals = 0
		local animals = self.husbandry:getClusters()
		local shortlist = {}

		local qualityMin, qualityMax = sell.quality.min / 100, sell.quality.max / 100
		local fertilityMin, fertilityMax = sell.fertility.min / 100, sell.fertility.max / 100
		local healthMin, healthMax = sell.health.min / 100, sell.health.max / 100
		local metabolismMin, metabolismMax = sell.metabolism.min / 100, sell.metabolism.max / 100
		local productivityMin, productivityMax = sell.productivity.min / 100, sell.productivity.max / 100

		for _, animal in pairs(animals) do

			if animal:getMarked("AI_MANAGER_SELL") then animal:setMarked("AI_MANAGER_SELL", false) end

			if sell.gender ~= "any" and animal.gender ~= sell.gender then continue end

			if animal.age < sell.age.min or animal.age > sell.age.max then continue end

			if sell.diseases and (animal.diseases == nil or #animal.diseases == 0) then continue end

			if animal.genetics.metabolism < metabolismMin or animal.genetics.metabolism > metabolismMax then continue end
			if animal.genetics.quality < qualityMin or animal.genetics.quality > qualityMax then continue end
			if animal.genetics.fertility < fertilityMin or animal.genetics.fertility > fertilityMax then continue end
			if animal.genetics.health < healthMin or animal.genetics.health > healthMax then continue end
			if animal.genetics.productivity ~= nil and (animal.genetics.productivity < productivityMin or animal.genetics.productivity > productivityMax) then continue end

			local price = animal:getSellPrice() + animalSystem:getAnimalTransportFee(animal.subTypeIndex, animal.age)

			table.insert(shortlist, { ["animal"] = animal, ["price"] = price })

		end

		local soldAnimals, amountGained = {}, 0

		table.sort(shortlist, function(a, b) return a.price > b.price end)

		local mark = sell.mark

		for _, item in ipairs(shortlist) do

			if #soldAnimals >= sell.maxAnimals then break end

			amountGained = amountGained + item.price

			table.insert(soldAnimals, item.animal)

			if mark then item.animal:setMarked("AI_MANAGER_SELL", true) end

		end

		local mark = sell.mark

		self.wage = self.wage + animalTypeToWage * #soldAnimals * (mark and 0.35 or 1) + animalTypeToWage * math.min(#shortlist, #soldAnimals * 5) * 0.15 * (mark and 0.35 or 1)

		if #soldAnimals > 0 and not mark then

			local errorCode = AIAnimalSellEvent.validate(self.husbandry, #soldAnimals, amountGained, farmId)

			if errorCode == nil then
				
				g_server:broadcastEvent(AIAnimalSellEvent.new(self.husbandry, soldAnimals, amountGained), true)

				if #soldAnimals == 1 then
					self.husbandry:addRLMessage("AI_MANAGER_SOLD_SINGLE", nil, { g_i18n:formatMoney(amountGained, 2, true, true) })
				else
					self.husbandry:addRLMessage("AI_MANAGER_SOLD_MULTIPLE", nil, { #soldAnimals, g_i18n:formatMoney(amountGained, 2, true, true) })
				end

			end

		elseif #soldAnimals > 0 then

			if #soldAnimals == 1 then
				self.husbandry:addRLMessage("AI_MANAGER_MARK_SELL_SINGLE")
			else
				self.husbandry:addRLMessage("AI_MANAGER_MARK_SELL_MULTIPLE", nil, { #soldAnimals })
			end

		end

	end


	-- ####################### BUY #######################


	if buy.enabled and buy.maxAnimals > 0 then

		local budget = buy.budget.fixed

		if buy.budget.type == "percentage" then budget = math.floor(farm:getBalance() * (buy.budget.percentage / 100)) end

		budget = math.clamp(budget, 0, farm:getBalance())

		if budget > 0 then

			local animals = animalSystem:getSaleAnimalsByTypeIndex(animalTypeIndex)
			local shortlist = {}

			local qualityMin, qualityMax = buy.quality.min / 100, buy.quality.max / 100
			local fertilityMin, fertilityMax = buy.fertility.min / 100, buy.fertility.max / 100
			local healthMin, healthMax = buy.health.min / 100, buy.health.max / 100
			local metabolismMin, metabolismMax = buy.metabolism.min / 100, buy.metabolism.max / 100
			local productivityMin, productivityMax = buy.productivity.min / 100, buy.productivity.max / 100

			for _, animal in pairs(animals) do

				if animal.reserved then continue end

				if buy.gender ~= "any" and animal.gender ~= buy.gender then continue end

				if buy.breed ~= "any" and animal.breed ~= buy.breed then continue end

				if animal.age < buy.age.min or animal.age > buy.age.max then continue end

				if not buy.diseases and #animal.diseases > 0 then continue end

				if animal.genetics.metabolism < metabolismMin or animal.genetics.metabolism > metabolismMax then continue end
				if animal.genetics.quality < qualityMin or animal.genetics.quality > qualityMax then continue end
				if animal.genetics.fertility < fertilityMin or animal.genetics.fertility > fertilityMax then continue end
				if animal.genetics.health < healthMin or animal.genetics.health > healthMax then continue end
				if animal.genetics.productivity ~= nil and (animal.genetics.productivity < productivityMin or animal.genetics.productivity > productivityMax) then continue end

				local price = animal:getSellPrice() * 1.075 + animalSystem:getAnimalTransportFee(animal.subTypeIndex, animal.age)

				if price > budget then continue end

				table.insert(shortlist, { ["animal"] = animal, ["price"] = price })

			end

			local boughtAnimals, amountSpent = {}, 0

			table.sort(shortlist, function(a, b) return a.price < b.price end)

			for _, item in ipairs(shortlist) do

				if item.price > budget or #boughtAnimals >= buy.maxAnimals then break end

				amountSpent = amountSpent + item.price
				budget = budget - item.price
				item.animal.reserved = true

				table.insert(boughtAnimals, item.animal)

			end

			if #boughtAnimals > 0 then

				local errorCode = AIAnimalBuyEvent.validate(self.husbandry, #boughtAnimals, amountSpent, farmId)

				if errorCode == nil then
				
					g_server:broadcastEvent(AIAnimalBuyEvent.new(self.husbandry, boughtAnimals, amountSpent), true)

					if #boughtAnimals == 1 then
						self.husbandry:addRLMessage("AI_MANAGER_BOUGHT_SINGLE", nil, { g_i18n:formatMoney(amountSpent, 2, true, true) })
					else
						self.husbandry:addRLMessage("AI_MANAGER_BOUGHT_MULTIPLE", nil, { #boughtAnimals, g_i18n:formatMoney(amountSpent, 2, true, true) })
					end

				end

			end

			self.wage = self.wage + animalTypeToWage * #boughtAnimals + animalTypeToWage * math.min(#shortlist, #boughtAnimals * 5) * 0.15

		end

	end


	-- ####################### CASTRATE #######################


	if castrate.enabled and animalTypeIndex ~= AnimalType.CHICKEN then

		local animals = self.husbandry:getClusters()
		local numCastrated = 0

		local qualityMin, qualityMax = castrate.quality.min / 100, castrate.quality.max / 100
		local fertilityMin, fertilityMax = castrate.fertility.min / 100, castrate.fertility.max / 100
		local healthMin, healthMax = castrate.health.min / 100, castrate.health.max / 100
		local metabolismMin, metabolismMax = castrate.metabolism.min / 100, castrate.metabolism.max / 100
		local productivityMin, productivityMax = castrate.productivity.min / 100, castrate.productivity.max / 100

		for _, animal in pairs(animals) do

			if animal:getMarked("AI_MANAGER_CASTRATE") then animal:setMarked("AI_MANAGER_CASTRATE", false) end

			if animal.gender == "female" or animal.isCastrated or animal.genetics.fertility == 0 then continue end

			if animal.age < castrate.age.min or animal.age > castrate.age.max then continue end

			if castrate.diseases and (animal.diseases == nil or #animal.diseases == 0) then continue end

			if animal.genetics.metabolism < metabolismMin or animal.genetics.metabolism > metabolismMax then continue end
			if animal.genetics.quality < qualityMin or animal.genetics.quality > qualityMax then continue end
			if animal.genetics.fertility < fertilityMin or animal.genetics.fertility > fertilityMax then continue end
			if animal.genetics.health < healthMin or animal.genetics.health > healthMax then continue end
			if animal.genetics.productivity ~= nil and (animal.genetics.productivity < productivityMin or animal.genetics.productivity > productivityMax) then continue end

			if not castrate.mark then

				animal.isCastrated = true
				animal.genetics.fertility = 0

			else

				animal:setMarked("AI_MANAGER_CASTRATE", true)

			end

			self.wage = self.wage + animalTypeToWage * 0.5 * (castrate.mark and 0.35 or 1)
			numCastrated = numCastrated + 1

		end

		if castrate.mark then
			if numCastrated == 1 then
				self.husbandry:addRLMessage("AI_MANAGER_MARK_CASTRATE_SINGLE")
			elseif numCastrated > 0 then
				self.husbandry:addRLMessage("AI_MANAGER_MARK_CASTRATE_MULTIPLE", nil, { numCastrated })
			end
		else
			if numCastrated == 1 then
				self.husbandry:addRLMessage("AI_MANAGER_MARK_CASTRATE_SINGLE")
			elseif numCastrated > 0 then
				self.husbandry:addRLMessage("AI_MANAGER_MARK_CASTRATE_MULTIPLE", nil, { numCastrated })
			end
		end

	end


	-- ####################### NAMING #######################


	if naming.enabled then

		local animals = self.husbandry:getClusters()
		local animalNameSystem = g_currentMission.animalNameSystem
		local femaleNames = animalNameSystem:getNamesAlphabetical("female")
		local maleNames = animalNameSystem:getNamesAlphabetical("male")
		local numNamed = 0

		for _, animal in pairs(animals) do

			if animal.name ~= nil and animal.name ~= "" then continue end

			if naming.convention == "random" then

				animal.name = animalNameSystem:getRandomName(animal.gender)
				self.wage = self.wage + animalTypeToWage * 0.15
				numNamed = numNamed + 1

			else

				local names = animal.gender == "female" and femaleNames or maleNames

				for i, name in ipairs(names) do

					if naming.previous == nil or (name ~= naming.previous and name >= naming.previous) or i == #names then

						if i == #names and naming.previous == name then
							animal.name = names[1] .. ""
							naming.previous = names[1] .. ""
						else
							animal.name = name .. ""
							naming.previous = name .. ""
						end

						self.wage = self.wage + animalTypeToWage * 0.15
						numNamed = numNamed + 1
						break

					end

				end

			end

		end

		if numNamed == 1 then
			self.husbandry:addRLMessage("AI_MANAGER_NAMED_SINGLE")
		elseif numNamed > 0 then
			self.husbandry:addRLMessage("AI_MANAGER_NAMED_MULTIPLE", nil, { numNamed })
		end

	end


	-- ####################### AI #######################


	if ai.enabled and ai.maxAnimals > 0 then

		local farmDewars = g_dewarManager:getDewarsByFarm(farmId)
		local dewars

		if ai.semen ~= "any" and farmDewars ~= nil then

			for _, dewar in pairs(farmDewars[animalTypeIndex] or {}) do

				if dewar:getUniqueId() == ai.semen then
					dewars = { dewar }
					break
				end

			end

		elseif farmDewars ~= nil then

			dewars = farmDewars[animalTypeIndex]

		end

		local inseminatedAnimals = 0
		local animals = self.husbandry:getClusters()
		local shortlist = {}
		local dewarToStrawDelta = {}

		local qualityMin, qualityMax = ai.quality.min / 100, ai.quality.max / 100
		local fertilityMin, fertilityMax = ai.fertility.min / 100, ai.fertility.max / 100
		local healthMin, healthMax = ai.health.min / 100, ai.health.max / 100
		local metabolismMin, metabolismMax = ai.metabolism.min / 100, sell.metabolism.max / 100
		local productivityMin, productivityMax = ai.productivity.min / 100, ai.productivity.max / 100

		for _, animal in pairs(animals) do

			if animal:getMarked("AI_MANAGER_INSEMINATE") then animal:setMarked("AI_MANAGER_INSEMINATE", false) end

			if dewars == nil or #dewars == 0 then continue end

			if animal.age < ai.age.min or animal.age > ai.age.max then continue end

			if ai.diseases and (animal.diseases == nil or #animal.diseases == 0) then continue end

			if animal.genetics.metabolism < metabolismMin or animal.genetics.metabolism > metabolismMax then continue end
			if animal.genetics.quality < qualityMin or animal.genetics.quality > qualityMax then continue end
			if animal.genetics.fertility < fertilityMin or animal.genetics.fertility > fertilityMax then continue end
			if animal.genetics.health < healthMin or animal.genetics.health > healthMax then continue end
			if animal.genetics.productivity ~= nil and (animal.genetics.productivity < productivityMin or animal.genetics.productivity > productivityMax) then continue end
			

			local canBeInseminated = false
			local usedDewar

			for _, dewar in pairs(dewars) do

				if dewar.animal == nil or dewar.straws <= 0 then continue end

				if dewarToStrawDelta[dewar] ~= nil and dewar.straws - dewarToStrawDelta[dewar] <= 0 then continue end

				canBeInseminated = animal:getCanBeInseminatedByAnimal(dewar.animal)

				if canBeInseminated then
					usedDewar = dewar
					if dewarToStrawDelta[dewar] == nil then dewarToStrawDelta[dewar] = 0 end
					dewarToStrawDelta[dewar] = dewarToStrawDelta[dewar] + 1
					break
				end

			end

			if not canBeInseminated then continue end

			local genetics = animal.genetics.metabolism + animal.genetics.quality + animal.genetics.fertility + animal.genetics.health + (animal.genetics.productivity or 0)

			table.insert(shortlist, { ["animal"] = animal, ["genetics"] = genetics, ["dewar"] = usedDewar })

		end

		local inseminatedAnimals = {}

		table.sort(shortlist, function(a, b) return a.genetics > b.genetics end)

		local mark = ai.mark

		for _, item in ipairs(shortlist) do

			if #inseminatedAnimals >= ai.maxAnimals then break end

			table.insert(inseminatedAnimals, { ["animal"] = item.animal, ["dewar"] = item.dewar:getUniqueId() })

			if mark then item.animal:setMarked("AI_MANAGER_INSEMINATE", true) end

		end

		local mark = ai.mark

		self.wage = self.wage + animalTypeToWage * #inseminatedAnimals * (mark and 0.45 or 1.2) + animalTypeToWage * math.min(#shortlist, #inseminatedAnimals * 5) * 0.2 * (mark and 0.35 or 1)

		if #inseminatedAnimals > 0 and not mark then
				
			g_server:broadcastEvent(AIAnimalInseminationEvent.new(self.husbandry, inseminatedAnimals), true)

			if #inseminatedAnimals == 1 then
				self.husbandry:addRLMessage("AI_MANAGER_INSEMINATED_SINGLE")
			else
				self.husbandry:addRLMessage("AI_MANAGER_INSEMINATED_MULTIPLE", nil, { #inseminatedAnimals })
			end

		elseif #inseminatedAnimals > 0 then

			if #inseminatedAnimals == 1 then
				self.husbandry:addRLMessage("AI_MANAGER_MARK_INSEMINATED_SINGLE")
			else
				self.husbandry:addRLMessage("AI_MANAGER_MARK_INSEMINATED_MULTIPLE", nil, { #inseminatedAnimals })
			end

		end

	end

end


function AIAnimalManager:createProfile()

	local profile = AIAnimalManager.new(self.isServer)

	profile.settings = table.clone(self.settings, 10)
	profile.isProfile = true

	return profile

end


function AIAnimalManager:copyProfile(profile)

	self.settings = table.clone(profile.settings, 10)

end



function InGameMenuStatisticsFrame:updateViewHandTools()

	local sortByColumnHandTools = self.sortByColumnHandTools
	local sortOrderHandTools = self.sortOrderHandTools

	for v156, v157 in pairs(self.sortIconsHandTools) do

		local v158 = v156 == sortByColumnHandTools
		local v159 = v157[InGameMenuStatisticsFrame.SORT_ORDER_DESC]
		local v160

		if v158 then
			v160 = sortOrderHandTools == InGameMenuStatisticsFrame.SORT_ORDER_DESC
		else
			v160 = v158
		end

		v159:setVisible(v160)

		local v161 = v157[InGameMenuStatisticsFrame.SORT_ORDER_ASC]

		if v158 then v158 = sortOrderHandTools == InGameMenuStatisticsFrame.SORT_ORDER_ASC end

		v161:setVisible(v158)

	end

	table.sort(self.handTools, function(a, b)

		local aValue = a.columns[sortByColumnHandTools].value
		local bValue = b.columns[sortByColumnHandTools].value

		print("a")

		DebugUtil.printTableRecursively(a.columns[sortByColumnHandTools], " - ", 0, 1)

		print("b")

		DebugUtil.printTableRecursively(b.columns[sortByColumnHandTools], " - ", 0, 1)

		print("------------")

		if aValue == bValue then

			aValue = a.columns[InGameMenuStatisticsFrame.COLUMN_NAME].value
			bValue = b.columns[InGameMenuStatisticsFrame.COLUMN_NAME].value

			if aValue == bValue then

				aValue = a.columns[InGameMenuStatisticsFrame.COLUMN_HOLDER].value
				bValue = b.columns[InGameMenuStatisticsFrame.COLUMN_HOLDER].value

			end

		end

		if sortOrderHandTools == InGameMenuStatisticsFrame.SORT_ORDER_DESC then return bValue < aValue end

		return aValue < bValue

	end)

	self.handToolsList:reloadData()

end