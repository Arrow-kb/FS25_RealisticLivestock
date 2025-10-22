Disease = {}

local disease_mt = Class(Disease)

function Disease.new(type, isCarrier, genes)

	local self = setmetatable({}, disease_mt)

	self.type = type
	self.cured = false
	self.beingTreated = false
	self.treatmentDuration = 0
	self.immunity = 0
	self.time = -1
	self.isCarrier = isCarrier or false
	self.genes = genes or 0
	self.recovery = 0

	return self

end


function Disease:loadFromXMLFile(xmlFile, key)

	self.cured = xmlFile:getBool(key .. "#cured", false)
	self.beingTreated = xmlFile:getBool(key .. "#beingTreated", false)
	self.treatmentDuration = xmlFile:getInt(key .. "#treatmentDuration", 0)
	self.immunity = xmlFile:getInt(key .. "#immunity", 0)
	self.time = xmlFile:getInt(key .. "#time", 0)
	self.isCarrier = xmlFile:getBool(key .. "#isCarrier", false)
	self.genes = xmlFile:getInt(key .. "#genes", 0)
	self.recovery = xmlFile:getInt(key .. "#recovery", 0)

end


function Disease:saveToXMLFile(xmlFile, key)

	xmlFile:setString(key .. "#title", self.type.title)
	xmlFile:setBool(key .. "#cured", self.cured)
	xmlFile:setBool(key .. "#beingTreated", self.beingTreated)
	xmlFile:setInt(key .. "#treatmentDuration", self.treatmentDuration)
	xmlFile:setInt(key .. "#immunity", self.immunity)
	xmlFile:setInt(key .. "#time", self.time)
	xmlFile:setBool(key .. "#isCarrier", self.isCarrier)
	xmlFile:setInt(key .. "#genes", self.genes)
	xmlFile:setInt(key .. "#recovery", self.recovery)

end


function Disease:writeStream(streamId, connection)

	streamWriteString(streamId, self.type.title)
	streamWriteBool(streamId, self.cured)
	streamWriteBool(streamId, self.beingTreated)
	streamWriteUInt8(streamId, self.treatmentDuration)
	streamWriteUInt8(streamId, self.immunity)
	streamWriteUInt16(streamId, self.time)
	streamWriteBool(streamId, self.isCarrier)
	streamWriteUInt8(streamId, self.genes)
	streamWriteUInt8(streamId, self.recovery)

end


function Disease:readStream(streamId, connection)

	self.cured = streamReadBool(streamId)
	self.beingTreated = streamReadBool(streamId)
	self.treatmentDuration = streamReadUInt8(streamId)
	self.immunity = streamReadUInt8(streamId)
	self.time = streamReadUInt16(streamId)
	self.isCarrier = streamReadBool(streamId)
	self.genes = streamReadUInt8(streamId)
	self.recovery = streamReadUInt8(streamId)

end


function Disease:onPeriodChanged(animal, deathEnabled)

	if not g_diseaseManager.diseasesEnabled then return false, 0 end

	self.time = self.time + 1
	local treatmentCost = 0

	if self.cured then

		self.immunity = self.immunity - 1

		if self.immunity <= 0 then
			animal:removeDisease(self.type.title)
			return false, 0
		end

	elseif self.beingTreated and self.type.treatment ~= nil then

		self.treatmentDuration = math.max(self.treatmentDuration - 1, 0)

		treatmentCost = self.type.treatment.cost

		if self.treatmentDuration <= 0 then
			self.cured = true
			self.beingTreated = false
			self.immunity = self.type.immunity - 0
		end

	end

	if not self.cured and self.type.recovery ~= nil then

		self.recovery = self.recovery + 1

		if self.recovery >= self.type.recovery and math.random() >= 0.25 then

			self.cured = true
			self.immunity = self.type.immunity - 0
			self.beingTreated = false

		end

	end

	if not self.isCarrier and deathEnabled then

		local fatality = self.type.fatality
		local fatalityChance = 0

		for i = 1, #fatality do

			if self.time <= fatality[i].time or i == #fatality then
				fatalityChance = fatality[i].value
				break
			end

		end

		if math.random() < fatalityChance then
	
			animal:die(self.type.key)
			return true, treatmentCost

		end

	end

	return false, treatmentCost

end


function Disease:affectReproduction(child, otherParent)

	if not g_diseaseManager.diseasesEnabled then return end

	local genetic = self.type.genetic

	if genetic == nil or (not genetic.recessive and not genetic.dominant) then return end

	local pDisease = otherParent ~= nil and otherParent:getDisease(self.type.title) or nil
	
	local parents = {
		self.genes,
		pDisease ~= nil and pDisease.genes or 0
	}

	local numAffectedGenes = 0

	for _, genes in pairs(parents) do

		if genes == 2 then
			numAffectedGenes = numAffectedGenes + 1
		elseif genes == 1 then
			if math.random() <= 0.5 then numAffectedGenes = numAffectedGenes + 1 end
		end

	end

	if numAffectedGenes == 2 then

		child:addDisease(self.type, false, 2)

	elseif numAffectedGenes == 1 then

		if genetic.recessive then

			child:addDisease(self.type, true, 1)

		elseif genetic.dominant then

			child:addDisease(self.type, false, 1)

		end

	end

end


function Disease:modifyValue(value)

	return value * self.type.value

end


function Disease:modifyOutput(type, value)

	if self.cured or not g_diseaseManager.diseasesEnabled then return value end

	if self.isCarrier and self.type.carrier ~= nil and self.type.carrier.output ~= nil then return value * (self.type.carrier.output[type] or 1) end

	return value * (self.type.output[type] or 1)

end


function Disease:showInfo(box)

	local time
	local years = math.floor(self.time / 12)
	local months = self.time - years * 12

	if years == 0 then
		time = string.format("%d %s", months, months == 1 and g_i18n:getText("rl_ui_month") or g_i18n:getText("rl_ui_months"))
	elseif months == 0 then
		time = string.format("%d %s", years, years == 1 and g_i18n:getText("rl_ui_year") or g_i18n:getText("rl_ui_years"))
	else
		time = string.format("%d %s, %d %s", years, years == 1 and g_i18n:getText("rl_ui_year") or g_i18n:getText("rl_ui_years"), months, months == 1 and g_i18n:getText("rl_ui_month") or g_i18n:getText("rl_ui_months"))
	end

	box:addLine(string.format("%s (%s)", self.type.name, time), self:getStatus())

end


function Disease:getStatus()

	local status
	local years = math.floor(self.time / 12)
	local months = self.time - years * 12

	if self.beingTreated then
		status = g_i18n:getText("rl_ui_beingTreated")
	elseif self.cured then

		local immunityYears = math.floor(self.immunity / 12)
		local immunityMonths = self.immunity - immunityYears * 12
		local immuneTime

		if years == 0 then
			immuneTime = string.format("%d %s", months, months == 1 and g_i18n:getText("rl_ui_month") or g_i18n:getText("rl_ui_months"))
		elseif months == 0 then
			immuneTime = string.format("%d %s", years, years == 1 and g_i18n:getText("rl_ui_year") or g_i18n:getText("rl_ui_years"))
		else
			immuneTime = string.format("%d %s, %d %s", years, years == 1 and g_i18n:getText("rl_ui_year") or g_i18n:getText("rl_ui_years"), months, months == 1 and g_i18n:getText("rl_ui_month") or g_i18n:getText("rl_ui_months"))
		end

		status = string.format("%s (%s)", g_i18n:getText("rl_ui_immune"), immuneTime)

	elseif self.isCarrier then

		status = g_i18n:getText("rl_ui_carrier")

	else
		status = g_i18n:getText("rl_ui_notTreated")
	end

	return status

end