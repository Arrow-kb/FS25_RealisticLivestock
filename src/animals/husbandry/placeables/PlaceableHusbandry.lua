RL_PlaceableHusbandry = {}


function RL_PlaceableHusbandry.registerFunctions(placeable)
	SpecializationUtil.registerFunction(placeable, "updateInputAndOutput", PlaceableHusbandry.updateInputAndOutput)
end

PlaceableHusbandry.registerFunctions = Utils.appendedFunction(PlaceableHusbandry.registerFunctions, RL_PlaceableHusbandry.registerFunctions)


function RL_PlaceableHusbandry:onHourChanged()

	local animals = self.spec_husbandryAnimals:getClusters()
	local temp = g_currentMission.environment.weather.temperatureUpdater.currentMin or 20

	for _, animal in pairs(animals) do
		animal:updateInput()
		animal:updateOutput(temp)
	end

	if self.isServer then self:updateInputAndOutput(animals) end

end

PlaceableHusbandry.onHourChanged = Utils.appendedFunction(PlaceableHusbandry.onHourChanged, RL_PlaceableHusbandry.onHourChanged)


function PlaceableHusbandry:updateInputAndOutput(animals) end