RL_AnimalScreenTrailer = {}

function RL_AnimalScreenTrailer:initTargetItems(_)

    self.targetItems = {}
    local animals = self.trailer:getClusters()

    if animals ~= nil then
        for _, animal in pairs(animals) do
            local item = AnimalItemStock.new(animal)
            table.insert(self.targetItems, item)
        end
    end

    table.sort(self.targetItems, RL_AnimalScreenBase.sortAnimals)

end

AnimalScreenTrailer.initTargetItems = Utils.overwrittenFunction(AnimalScreenTrailer.initTargetItems, RL_AnimalScreenTrailer.initTargetItems)


function RL_AnimalScreenTrailer:getApplySourceConfirmationText(_, animalTypeIndex, index, numAnimals)

    --local text = numAnimals == 1 and g_i18n:getText(AnimalScreenTrailer.L10N_SYMBOL.CONFIRM_MOVE_TO_TRAILER_SINGULAR) or g_i18n:getText(AnimalScreenTrailer.L10N_SYMBOL.CONFIRM_MOVE_TO_TRAILER)
    local text = "Do you want to move %d animals to the trailer?"

	return string.format(text, numAnimals)

end

AnimalScreenTrailer.getApplySourceConfirmationText = Utils.overwrittenFunction(AnimalScreenTrailer.getApplySourceConfirmationText, RL_AnimalScreenTrailer.getApplySourceConfirmationText)