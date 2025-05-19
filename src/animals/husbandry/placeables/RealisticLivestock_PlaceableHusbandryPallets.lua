RealisticLivestock_PlaceableHusbandryPallets = {}


function RealisticLivestock_PlaceableHusbandryPallets.registerOverwrittenFunctions(placeable)
	SpecializationUtil.registerOverwrittenFunction(placeable, "updateInputAndOutput", PlaceableHusbandryPallets.updateInputAndOutput)
end

PlaceableHusbandryPallets.registerOverwrittenFunctions = Utils.appendedFunction(PlaceableHusbandryPallets.registerOverwrittenFunctions, RealisticLivestock_PlaceableHusbandryPallets.registerOverwrittenFunctions)


function RealisticLivestock_PlaceableHusbandryPallets:onHusbandryAnimalsUpdate(_, _) end

PlaceableHusbandryPallets.onHusbandryAnimalsUpdate = Utils.overwrittenFunction(PlaceableHusbandryPallets.onHusbandryAnimalsUpdate, RealisticLivestock_PlaceableHusbandryPallets.onHusbandryAnimalsUpdate)


function PlaceableHusbandryPallets:updateInputAndOutput(superFunc, animals)

    superFunc(self, animals)

    local spec = self.spec_husbandryPallets

    for fillType, _ in pairs(spec.litersPerHour) do
        spec.litersPerHour[fillType] = 0
    end

    spec.activeFillTypes = {}

    for _, animal in pairs(animals) do

        local subType = animal:getSubType()

        if subType ~= nil then

            local pallets = subType.output.pallets

            if pallets ~= nil then

                spec.litersPerHour[pallets.fillType] = spec.litersPerHour[pallets.fillType] + animal:getOutput("pallets")

                table.addElement(spec.activeFillTypes, pallets.fillType)

            end

        end

    end

end