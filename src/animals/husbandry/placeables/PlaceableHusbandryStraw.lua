RL_PlaceableHusbandryStraw = {}


function RL_PlaceableHusbandryStraw.registerOverwrittenFunctions(placeable)
	SpecializationUtil.registerOverwrittenFunction(placeable, "updateInputAndOutput", PlaceableHusbandryStraw.updateInputAndOutput)
end

PlaceableHusbandryStraw.registerOverwrittenFunctions = Utils.appendedFunction(PlaceableHusbandryStraw.registerOverwrittenFunctions, RL_PlaceableHusbandryStraw.registerOverwrittenFunctions)


function RL_PlaceableHusbandryStraw:onHusbandryAnimalsUpdate(_, _) end

PlaceableHusbandryStraw.onHusbandryAnimalsUpdate = Utils.overwrittenFunction(PlaceableHusbandryStraw.onHusbandryAnimalsUpdate, RL_PlaceableHusbandryStraw.onHusbandryAnimalsUpdate)


function PlaceableHusbandryStraw:updateInputAndOutput(superFunc, animals)

	superFunc(self, animals)

    local spec = self.spec_husbandryStraw
	spec.inputLitersPerHour = 0
	spec.outputLitersPerHour = 0

    for _, animal in pairs(animals) do

        local subType = animal:getSubType()

        if subType ~= nil then

            local straw = subType.input.straw

            if straw ~= nil then

                spec.inputLitersPerHour = spec.inputLitersPerHour + animal:getInput("straw")

            end

            local manure = subType.output.manure

            if manure ~= nil then

                spec.outputLitersPerHour = spec.outputLitersPerHour + animal:getInput("manure")

            end

        end

    end

end