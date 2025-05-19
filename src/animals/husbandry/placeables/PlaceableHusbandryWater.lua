RL_PlaceableHusbandryWater = {}


function RL_PlaceableHusbandryWater.registerOverwrittenFunctions(placeable)
	SpecializationUtil.registerOverwrittenFunction(placeable, "updateInputAndOutput", PlaceableHusbandryWater.updateInputAndOutput)
end

PlaceableHusbandryWater.registerOverwrittenFunctions = Utils.appendedFunction(PlaceableHusbandryWater.registerOverwrittenFunctions, RL_PlaceableHusbandryWater.registerOverwrittenFunctions)


function RL_PlaceableHusbandryWater:onHusbandryAnimalsUpdate(_, _) end

PlaceableHusbandryWater.onHusbandryAnimalsUpdate = Utils.overwrittenFunction(PlaceableHusbandryWater.onHusbandryAnimalsUpdate, RL_PlaceableHusbandryWater.onHusbandryAnimalsUpdate)


function PlaceableHusbandryWater:updateInputAndOutput(superFunc, animals)

	superFunc(self, animals)

    local spec = self.spec_husbandryWater

    for _, animal in pairs(animals) do

        local subType = animal:getSubType()

        if subType ~= nil then

            local water = subType.input.water

            if water ~= nil then

                spec.litersPerHour = spec.litersPerHour + animal:getInput("water")

            end

        end

    end

end