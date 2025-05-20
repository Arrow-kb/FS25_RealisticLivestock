RealisticLivestock_PlayerHUDUpdater = {}

function RealisticLivestock_PlayerHUDUpdater:updateRaycastObject()

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

        end

    end

end

PlayerHUDUpdater.updateRaycastObject = Utils.appendedFunction(PlayerHUDUpdater.updateRaycastObject, RealisticLivestock_PlayerHUDUpdater.updateRaycastObject)


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

end

PlayerHUDUpdater.showAnimalInfo = Utils.appendedFunction(PlayerHUDUpdater.showAnimalInfo, RealisticLivestock_PlayerHUDUpdater.showAnimalInfo)


function RealisticLivestock_PlayerHUDUpdater:delete()

    if self.geneticsBox ~= nil then g_currentMission.hud.infoDisplay:destroyBox(self.geneticsBox) end

end

PlayerHUDUpdater.delete = Utils.appendedFunction(PlayerHUDUpdater.delete, RealisticLivestock_PlayerHUDUpdater.delete)