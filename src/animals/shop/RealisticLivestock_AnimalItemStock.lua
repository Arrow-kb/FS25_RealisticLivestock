RealisticLivestock_AnimalItemStock = {}
local mt = Class(AnimalItemStock)

function RealisticLivestock_AnimalItemStock:getClusterId(_)
    return self.cluster.isIndividual == nil and self.cluster.id or (self.cluster.farmId .. " " .. self.cluster.uniqueId .. " " .. self.cluster.birthday.country)
end

AnimalItemStock.getClusterId = Utils.overwrittenFunction(AnimalItemStock.getClusterId, RealisticLivestock_AnimalItemStock.getClusterId)


function RealisticLivestock_AnimalItemStock.new(animal)

    local self = setmetatable({}, mt)

    self.cluster = animal
	self.visual = g_currentMission.animalSystem:getVisualByAge(animal.subTypeIndex, animal:getAge())
	local subType = g_currentMission.animalSystem:getSubTypeByIndex(animal.subTypeIndex)
	self.title = g_fillTypeManager:getFillTypeTitleByIndex(subType.fillTypeIndex)

	local hasMonitor = animal.monitor.active or animal.monitor.removed
	
	self.infos = {
		{
			title = g_i18n:getText("ui_age"),
			value = g_i18n:formatNumMonth(animal:getAge())
		}
	}

	if hasMonitor then

		table.insert(self.infos, {
			title = g_i18n:getText("ui_horseHealth"),
			value = string.format("%.f%%", animal:getHealthFactor() * 100)
		})

	end
	
	if subType.supportsReproduction and animal.reproduction > 0 and animal:getAge() >= subType.reproductionMinAgeMonth then
		local newInfo = {
			title = g_i18n:getText("infohud_reproductionStatus"),
			value = string.format("%.f%%", animal:getReproductionFactor() * 100)
		}
		table.insert(self.infos, newInfo)
	end

	if animal.isIndividual then

		local yes = g_i18n:getText("rl_ui_yes")
		local no = g_i18n:getText("rl_ui_no")

		if subType.supportsReproduction and animal.reproduction <= 0 then

			local valueText = nil
			local healthFactor = animal:getHealthFactor()

            if animal.age < subType.reproductionMinAgeMonth then
                valueText = g_i18n:getText("rl_ui_tooYoung")
            elseif animal.isParent and animal.monthsSinceLastBirth <= 2 then
                valueText = g_i18n:getText("rl_ui_recoveringLastBirth")
            elseif not RealisticLivestock.hasMaleAnimalInPen(animal.clusterSystem, animal.subType, animal) then
                valueText = g_i18n:getText("rl_ui_noMaleAnimal")
            elseif healthFactor < subType.reproductionMinHealth then
                valueText = g_i18n:getText("rl_ui_unhealthy")
            end

            if valueText ~= nil then
				table.insert(self.infos, {
					title = g_i18n:getText("rl_ui_canReproduce"),
					value = valueText
				})
			end

		end


		local pregnancy = animal.pregnancy

        if pregnancy ~= nil and pregnancy.pregnancies and #pregnancy.pregnancies > 0 then

            table.insert(self.infos, { ["title"] = g_i18n:getText("rl_ui_pregnancyExpecting"), ["value"] = string.format("%s %s", #pregnancy.pregnancies, g_i18n:getText("rl_ui_pregnancy" .. (#pregnancy.pregnancies == 1 and "Baby" or "Babies"))) })
            table.insert(self.infos, { ["title"] = g_i18n:getText("rl_ui_pregnancyExpected"), ["value"] = string.format("%s/%s/%s", pregnancy.expected.day, pregnancy.expected.month, pregnancy.expected.year + RealisticLivestock.START_YEAR.FULL) })         

		end

		if hasMonitor then

			table.insert(self.infos, {
				title = g_i18n:getText("rl_ui_weight"),
				value = string.format("%.2f", animal.weight or 50) .. "kg"
			})
		
			table.insert(self.infos, {
				title = g_i18n:getText("rl_ui_targetWeight"),
				value = string.format("%.2f", animal.targetWeight or 50) .. "kg"
			})
		
			if animal.animalTypeIndex == AnimalType.COW and animal.gender == "female" and animal:getAge() >= subType.reproductionMinAgeMonth then
		
				table.insert(self.infos, {
					title = g_i18n:getText("rl_ui_lactating"),
					value = animal.isLactating and yes or no
				})

			end

		end

		if animal.gender == "male" and animal:getAge() >= subType.reproductionMinAgeMonth then
			
			table.insert(self.infos, {
				title = g_i18n:getText("rl_ui_maleNumImpregnatable"),
				value = animal:getNumberOfImpregnatableFemalesForMale() or 0
			})

		end

	end

	if animal.animalTypeIndex == AnimalType.HORSE then

		table.insert(self.infos, { ["title"] = g_i18n:getText("ui_horseFitness"), ["value"] = string.format("%.f%%", animal:getFitnessFactor() * 100) })
		table.insert(self.infos, { ["title"] = g_i18n:getText("ui_horseDailyRiding"), ["value"] = string.format("%.f%%", animal:getRidingFactor() * 100) })
	
		if Platform.gameplay.needHorseCleaning then table.insert(self.infos, { ["title"] = g_i18n:getText("statistic_cleanliness"), ["value"] = string.format("%.f%%", (1 - animal:getDirtFactor()) * 100) }) end

	end
	
	return self
end

AnimalItemStock.new = RealisticLivestock_AnimalItemStock.new