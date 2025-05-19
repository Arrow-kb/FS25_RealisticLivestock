RL_HandToolHorseBrush = {}


function RL_HandToolHorseBrush:getHusbandryAndClusterFromNode(superFunc, node)

    if node == nil or not entityExists(node) then return nil, nil end

	local husbandryId, animalId = getAnimalFromCollisionNode(node)

	if husbandryId ~= nil and husbandryId ~= 0 then

		local clusterHusbandry = g_currentMission.husbandrySystem:getClusterHusbandryById(husbandryId)

		if clusterHusbandry ~= nil then

			local placeable = clusterHusbandry:getPlaceable()
			local animal = clusterHusbandry:getClusterByAnimalId(animalId, husbandryId)

			if animal ~= nil and (g_currentMission.accessHandler:canFarmAccess(self.farmId, placeable) and (animal.changeDirt ~= nil and animal.getName ~= nil)) then return placeable, animal end

		end

	end

	return nil, nil

end

HandToolHorseBrush.getHusbandryAndClusterFromNode = Utils.overwrittenFunction(HandToolHorseBrush.getHusbandryAndClusterFromNode, RL_HandToolHorseBrush.getHusbandryAndClusterFromNode)