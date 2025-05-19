RL_PlaceableHusbandryLiquidManure = {}


function RL_PlaceableHusbandryLiquidManure.registerOverwrittenFunctions(placeable)
	SpecializationUtil.registerOverwrittenFunction(placeable, "updateInputAndOutput", PlaceableHusbandryLiquidManure.updateInputAndOutput)
end

PlaceableHusbandryLiquidManure.registerOverwrittenFunctions = Utils.appendedFunction(PlaceableHusbandryLiquidManure.registerOverwrittenFunctions, RL_PlaceableHusbandryLiquidManure.registerOverwrittenFunctions)


function RL_PlaceableHusbandryLiquidManure:onHusbandryAnimalsUpdate(_, _) end

PlaceableHusbandryLiquidManure.onHusbandryAnimalsUpdate = Utils.overwrittenFunction(PlaceableHusbandryLiquidManure.onHusbandryAnimalsUpdate, RL_PlaceableHusbandryLiquidManure.onHusbandryAnimalsUpdate)


function PlaceableHusbandryLiquidManure:updateInputAndOutput(superFunc, animals)

	superFunc(self, animals)

    local spec = self.spec_husbandryLiquidManure

    for _, animal in pairs(animals) do

        local subType = animal:getSubType()

        if subType ~= nil then

            local liquidManure = subType.output.liquidManure

            if liquidManure ~= nil then

                spec.litersPerHour = spec.litersPerHour + animal:getInput("liquidManure")

            end

        end

    end

end