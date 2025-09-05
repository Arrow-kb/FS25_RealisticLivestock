RealisticLivestock_PlayerHUDUpdater = {}


function PlayerHUDUpdater:setCarriedItem(item)

    self.currentlyCarriedItem = item

end


function PlayerHUDUpdater:getCarriedItem()

    return self.currentlyCarriedItem

end


function RealisticLivestock_PlayerHUDUpdater:update()

	if Platform.playerInfo.showVehicleInfo and self.isDewar then self:showDewarInfo(self.object) end
	if Platform.playerInfo.showVehicleInfo and self.currentlyCarriedItem ~= nil then self:showHandToolInfo(self.currentlyCarriedItem) end

end

PlayerHUDUpdater.update = Utils.appendedFunction(PlayerHUDUpdater.update, RealisticLivestock_PlayerHUDUpdater.update)


function RealisticLivestock_PlayerHUDUpdater:updateRaycastObject()

    self.isDewar = false

    if self.isAnimal == false and self.currentRaycastTarget ~= nil and entityExists(self.currentRaycastTarget) then

        local object = g_currentMission:getNodeObject(self.currentRaycastTarget)

        if object == nil then

            if not getHasClassId(self.currentRaycastTarget, ClassIds.MESH_SPLIT_SHAPE) then

                local husbandryId, animalId = getAnimalFromCollisionNode(self.currentRaycastTarget)
                if husbandryId ~= nil and husbandryId ~= 0 then

                    local clusterHusbandry = g_currentMission.husbandrySystem:getClusterHusbandryById(husbandryId)
                    if clusterHusbandry ~= nil then
                        local animal = clusterHusbandry:getClusterByAnimalId(animalId, husbandryId)
                        if animal ~= nil then
                            self.isAnimal = true
                            self.object = animal
                            return
                        end
                    end

                end

            end

        elseif object:isa(Dewar) then

            self.isDewar = true

        end

    end

end

PlayerHUDUpdater.updateRaycastObject = Utils.appendedFunction(PlayerHUDUpdater.updateRaycastObject, RealisticLivestock_PlayerHUDUpdater.updateRaycastObject)


function PlayerHUDUpdater:showDewarInfo(object)

    if object == nil then return end
	
	local farmId = object:getOwnerFarmId()
	if farmId == FarmManager.SPECTATOR_FARM_ID then return end

	local box = self.objectBox

	box:clear()
	box:setTitle(g_i18n:getText("rl_ui_dewar"))

	local farm = g_farmManager:getFarmById(farmId)

	box:addLine(g_i18n:getText("fieldInfo_ownedBy"), self:convertFarmToName(farm))
	object:showInfo(box)

	box:showNextFrame()

end


function PlayerHUDUpdater:showHandToolInfo(object)

    if object == nil then return end

    if self.handToolBox == nil then self.handToolBox = g_currentMission.hud.infoDisplay:createBox(InfoDisplayKeyValueBox) end

	local box = self.handToolBox

	box:clear()
	box:setTitle(g_i18n:getText("rl_ui_strawSingle"))

	object:showInfo(box)

	box:showNextFrame()

end


function RealisticLivestock_PlayerHUDUpdater:showAnimalInfo(animal)

    if self.monitorBox == nil then self.monitorBox = g_currentMission.hud.infoDisplay:createBox(InfoDisplayKeyValueBox) end

    if animal.monitor.active or animal.monitor.removed then

        local box = self.monitorBox
        box:clear()
        box:setTitle(g_i18n:getText("rl_ui_monitor"))
        animal:showMonitorInfo(box)
        box:showNextFrame()

    end

    if self.geneticsBox == nil then self.geneticsBox = g_currentMission.hud.infoDisplay:createBox(RL_InfoDisplayKeyValueBox) end

    local box = self.geneticsBox
    box:clear()
    box:setTitle(g_i18n:getText("rl_ui_genetics"))
    animal:showGeneticsInfo(box)
    box:showNextFrame()

    if self.diseaseBox == nil then self.diseaseBox = g_currentMission.hud.infoDisplay:createBox(InfoDisplayKeyValueBox) end

    local box = self.diseaseBox
    box:clear()

    if animal.diseases ~= nil and #animal.diseases > 0 then
        box:setTitle(g_i18n:getText("rl_diseases"))
        animal:showDiseasesInfo(box)
        box:showNextFrame()
    end

end

PlayerHUDUpdater.showAnimalInfo = Utils.appendedFunction(PlayerHUDUpdater.showAnimalInfo, RealisticLivestock_PlayerHUDUpdater.showAnimalInfo)


function RealisticLivestock_PlayerHUDUpdater:delete()

    if self.geneticsBox ~= nil then g_currentMission.hud.infoDisplay:destroyBox(self.geneticsBox) end
    if self.diseaseBox ~= nil then g_currentMission.hud.infoDisplay:destroyBox(self.diseaseBox) end
    if self.monitorBox ~= nil then g_currentMission.hud.infoDisplay:destroyBox(self.monitorBox) end
    if self.handToolBox ~= nil then g_currentMission.hud.infoDisplay:destroyBox(self.handToolBox) end

end

PlayerHUDUpdater.delete = Utils.appendedFunction(PlayerHUDUpdater.delete, RealisticLivestock_PlayerHUDUpdater.delete)