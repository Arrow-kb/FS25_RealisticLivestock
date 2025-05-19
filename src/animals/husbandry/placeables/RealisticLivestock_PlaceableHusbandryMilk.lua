RealisticLivestock_PlaceableHusbandryMilk = {}


function RealisticLivestock_PlaceableHusbandryMilk.registerOverwrittenFunctions(placeable)
	SpecializationUtil.registerOverwrittenFunction(placeable, "updateInputAndOutput", PlaceableHusbandryMilk.updateInputAndOutput)
end

PlaceableHusbandryMilk.registerOverwrittenFunctions = Utils.appendedFunction(PlaceableHusbandryMilk.registerOverwrittenFunctions, RealisticLivestock_PlaceableHusbandryMilk.registerOverwrittenFunctions)


function RealisticLivestock_PlaceableHusbandryMilk:onHusbandryAnimalsUpdate(_, _) end

PlaceableHusbandryMilk.onHusbandryAnimalsUpdate = Utils.overwrittenFunction(PlaceableHusbandryMilk.onHusbandryAnimalsUpdate, RealisticLivestock_PlaceableHusbandryMilk.onHusbandryAnimalsUpdate)


function PlaceableHusbandryMilk:updateInputAndOutput(superFunc, animals)

    superFunc(self, animals)

    local spec = self.spec_husbandryMilk

    for fillType, _ in pairs(spec.litersPerHour) do
        spec.litersPerHour[fillType] = 0
    end

    spec.activeFillTypes = {}

    for _, animal in pairs(animals) do

        local subType = animal:getSubType()

        if subType ~= nil then

            local milk = subType.output.milk

            if milk ~= nil then

                spec.litersPerHour[milk.fillType] = spec.litersPerHour[milk.fillType] + animal:getOutput("milk")

                table.addElement(spec.activeFillTypes, milk.fillType)

            end

        end

    end

end