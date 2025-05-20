RealisticLivestock_PlaceableHusbandryFood = {}


function RealisticLivestock_PlaceableHusbandryFood.registerOverwrittenFunctions(placeable)
	SpecializationUtil.registerOverwrittenFunction(placeable, "updateInputAndOutput", PlaceableHusbandryFood.updateInputAndOutput)
end

PlaceableHusbandryFood.registerOverwrittenFunctions = Utils.appendedFunction(PlaceableHusbandryFood.registerOverwrittenFunctions, RealisticLivestock_PlaceableHusbandryFood.registerOverwrittenFunctions)


function RealisticLivestock_PlaceableHusbandryFood:onHusbandryAnimalsUpdate(superFunc, animals) end

PlaceableHusbandryFood.onHusbandryAnimalsUpdate = Utils.overwrittenFunction(PlaceableHusbandryFood.onHusbandryAnimalsUpdate, RealisticLivestock_PlaceableHusbandryFood.onHusbandryAnimalsUpdate)


function RealisticLivestock_PlaceableHusbandryFood.onSettingChanged(name, state)

    RealisticLivestock_PlaceableHusbandryFood[name] = state

end


function PlaceableHusbandryFood:updateInputAndOutput(superFunc, animals)

    superFunc(self, animals)

    local spec = self.spec_husbandryFood
    spec.litersPerHour = 0

    for _, animal in pairs(animals) do

        local subType = animal:getSubType()

        if subType ~= nil then

            local food = subType.input.food

            if food ~= nil then

                spec.litersPerHour = spec.litersPerHour + animal:getInput("food")

            end

        end

    end

end