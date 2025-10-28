AnimalItemNew = {}
local animalItemNew_mt = Class(AnimalItemNew)


function AnimalItemNew.new(animal)

	local self = setmetatable({}, animalItemNew_mt)

	local animalSystem = g_currentMission.animalSystem

	self.animal = animal
	self.visual = animalSystem:getVisualByAge(animal.subTypeIndex, animal.age)

	local subType = animal:getSubType()
	local countryIndex = animal.birthday.country

	local breederQuality = animalSystem:getFarmQuality(countryIndex, animal.farmId)
	local breederQualityString

	if breederQuality >= 1.65 then
		breederQualityString = g_i18n:getText("rl_ui_genetics_extremelyGood")
	elseif breederQuality >= 1.4 then
		breederQualityString = g_i18n:getText("rl_ui_genetics_veryGood")
	elseif breederQuality >= 1.1 then
		breederQualityString = g_i18n:getText("rl_ui_genetics_good")
	elseif breederQuality >= 0.9 then
		breederQualityString = g_i18n:getText("rl_ui_genetics_average")
	elseif breederQuality >= 0.7 then
		breederQualityString = g_i18n:getText("rl_ui_genetics_bad")
	elseif breederQuality >= 0.35 then
		breederQualityString = g_i18n:getText("rl_ui_genetics_veryBad")
	else
		breederQualityString = g_i18n:getText("rl_ui_genetics_extremelyBad")
	end

	self.title = g_fillTypeManager:getFillTypeTitleByIndex(subType.fillTypeIndex)
	self.infos = {
		{
			["title"] = g_i18n:getText("rl_ui_breederQuality"),
			["value"] = breederQualityString
		},
		{
			["title"] = g_i18n:getText("rl_ui_animalOrigin"),
			["value"] = RealisticLivestock.AREA_CODES[countryIndex].country
		},
		{
			["title"] = g_i18n:getText("ui_age"),
			["value"] = g_i18n:formatNumMonth(animal.age)
		},
		{
			["title"] = g_i18n:getText("rl_ui_weight"),
			["value"] = string.format("%.2fkg", animal.weight)
		}
	}

	if animal.isPregnant then table.insert(self.infos, { ["title"] = g_i18n:getText("rl_ui_pregnant"), ["value"] = g_i18n:getText("rl_ui_yes") }) end


	local genetics = animal:getGenetics()
	local totalGenetics = 0
	local totalGeneticsValues = 0

	for key, value in pairs(genetics) do

		if value == nil then continue end

		local qualityText

		if value >= 1.65 then
			qualityText = g_i18n:getText("rl_ui_genetics_extremelyHigh")
		elseif value >= 1.4 then
			qualityText = g_i18n:getText("rl_ui_genetics_veryHigh")
		elseif value >= 1.1 then
			qualityText = g_i18n:getText("rl_ui_genetics_high")
		elseif value >= 0.9 then
			qualityText = g_i18n:getText("rl_ui_genetics_average")
		elseif value >= 0.7 then
			qualityText = g_i18n:getText("rl_ui_genetics_low")
		elseif value >= 0.35 then
			qualityText = g_i18n:getText("rl_ui_genetics_veryLow")
		else
			qualityText = g_i18n:getText("rl_ui_genetics_extremelyLow")
		end

		local keyText = key

		if key == "productivity" then
			if animal.animalTypeIndex == AnimalType.COW then
				keyText = "milk"
			elseif animal.animalTypeIndex == AnimalType.SHEEP then
				keyText = "wool"
			elseif animal.animalTypeIndex == AnimalType.CHICKEN then
				keyText = "eggs"
			end
		elseif key == "quality" then
			keyText = "meat"
		end

		table.insert(self.infos, { ["title"] = g_i18n:getText("rl_ui_" .. keyText), ["value"] = qualityText, ["colour"] = { 1 - value / 1.75, value / 1.75, 0 } })
		totalGenetics = totalGenetics + 1
		totalGeneticsValues = totalGeneticsValues + value

	end


	local averageGenetics = totalGeneticsValues / totalGenetics

    if averageGenetics >= 1.65 then
		qualityText = g_i18n:getText("rl_ui_genetics_extremelyGood")
	elseif averageGenetics >= 1.4 then
		qualityText = g_i18n:getText("rl_ui_genetics_veryGood")
	elseif averageGenetics >= 1.1 then
		qualityText = g_i18n:getText("rl_ui_genetics_good")
	elseif averageGenetics >= 0.9 then
		qualityText = g_i18n:getText("rl_ui_genetics_average")
	elseif averageGenetics >= 0.7 then
		qualityText = g_i18n:getText("rl_ui_genetics_bad")
	elseif averageGenetics >= 0.35 then
		qualityText = g_i18n:getText("rl_ui_genetics_veryBad")
	else
		qualityText = g_i18n:getText("rl_ui_genetics_extremelyBad")
	end


	table.insert(self.infos, { ["title"] = g_i18n:getText("rl_ui_overall"), ["value"] = qualityText, ["colour"] = { 1 - averageGenetics / 1.75, averageGenetics / 1.75, 0 } })


	return self

end


function AnimalItemNew:getName()

	local animal = self.animal

	return animal.name or string.format("%s %s %s", RealisticLivestock.AREA_CODES[animal.birthday.country].code, animal.farmId, animal.uniqueId)

end


function AnimalItemNew:getTitle()

	return self.title

end


function AnimalItemNew:getPrice()

	return self.animal:getSellPrice() * 1.075

end


function AnimalItemNew:getTranportationFee(_)

	return g_currentMission.animalSystem:getAnimalTransportFee(self.animal.subTypeIndex, self.animal.age)

end


function AnimalItemNew:getSubTypeIndex()

	return self.animal.subTypeIndex

end


function AnimalItemNew:getAge()

	return self.animal.age

end


function AnimalItemNew:getDescription()

	return self.visual.store.description

end


function AnimalItemNew:getFilename()

	return self.visual.store.imageFilename

end


function AnimalItemNew:getInfos()

	return self.infos

end


function AnimalItemNew:getHasAnyDisease()

	return self.animal:getHasAnyDisease()

end