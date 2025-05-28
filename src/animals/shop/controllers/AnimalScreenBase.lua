RL_AnimalScreenBase = {}

function RL_AnimalScreenBase:getTargetItems(_)
    return self.targetItems
end

AnimalScreenBase.getTargetItems = Utils.overwrittenFunction(AnimalScreenBase.getTargetItems, RL_AnimalScreenBase.getTargetItems)


function RL_AnimalScreenBase.sortAnimals(a, b)

    if a.cluster == nil or b.cluster == nil then return a end

    if a.cluster.subTypeIndex == b.cluster.subTypeIndex then return a.cluster.age < b.cluster.age end

    return a.cluster.subTypeIndex < b.cluster.subTypeIndex

end


function RL_AnimalScreenBase.sortSaleAnimals(a, b)

    if a.animal == nil or b.animal == nil then return a end

    local aValue = a.animal:getSellPrice()
    local bValue = b.animal:getSellPrice()

    if a.animal.subTypeIndex == b.animal.subTypeIndex then

        if aValue == bValue then return a.animal.age < b.animal.age end
        
        return aValue > bValue

    end

    return a.animal.subTypeIndex < b.animal.subTypeIndex

end


function RL_AnimalScreenBase:onAnimalsChanged(_)
    if self.trailer == nil then return end
    self:initItems()
    self.animalsChangedCallback()
    self.trailer:updateAnimals()
end

AnimalScreenTrailerFarm.onAnimalMovedToTrailer = Utils.appendedFunction(AnimalScreenTrailerFarm.onAnimalMovedToTrailer, RL_AnimalScreenBase.onAnimalsChanged)
AnimalScreenTrailerFarm.onAnimalMovedToFarm = Utils.appendedFunction(AnimalScreenTrailerFarm.onAnimalMovedToFarm, RL_AnimalScreenBase.onAnimalsChanged)
AnimalScreenTrailerFarm.onAnimalsChanged = Utils.appendedFunction(AnimalScreenTrailerFarm.onAnimalsChanged, RL_AnimalScreenBase.onAnimalsChanged)
AnimalScreenDealerTrailer.onAnimalBought = Utils.appendedFunction(AnimalScreenDealerTrailer.onAnimalBought, RL_AnimalScreenBase.onAnimalsChanged)
AnimalScreenDealerTrailer.onAnimalSold = Utils.appendedFunction(AnimalScreenDealerTrailer.onAnimalSold, RL_AnimalScreenBase.onAnimalsChanged)
AnimalScreenDealerTrailer.onAnimalsChanged = Utils.appendedFunction(AnimalScreenDealerTrailer.onAnimalsChanged, RL_AnimalScreenBase.onAnimalsChanged)
AnimalScreenTrailer.onAnimalLoadedToTrailer = Utils.appendedFunction(AnimalScreenTrailer.onAnimalLoadedToTrailer, RL_AnimalScreenBase.onAnimalsChanged)
AnimalScreenTrailer.onAnimalsChanged = Utils.appendedFunction(AnimalScreenTrailer.onAnimalsChanged, RL_AnimalScreenBase.onAnimalsChanged)


function AnimalScreenBase:setSourceBulkActionFinishedCallback(callback, target)

    function self.sourceBulkActionFinished(error, text, indexes)

        callback(target, error, text, indexes)

    end

end


function AnimalScreenBase:setTargetBulkActionFinishedCallback(callback, target)

    function self.targetBulkActionFinished(error, text, indexes)

        callback(target, error, text, indexes)

    end

end