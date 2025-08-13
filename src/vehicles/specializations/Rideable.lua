RL_Rideable = {}


function RL_Rideable:onLoad(save)

	if save == nil then return end

	local animal = Animal.loadFromXMLFile(save.xmlFile, save.key .. ".rideable.animal")

	self:setCluster(animal)

end

Rideable.onLoad = Utils.appendedFunction(Rideable.onLoad, RL_Rideable.onLoad)