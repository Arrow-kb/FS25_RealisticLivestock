RealisticLivestock_PlayerInputComponent = {}

local modName = g_currentModName


function RealisticLivestock_PlayerInputComponent:update(_)

    self.dewar = nil

    if self.player.isOwner then

        if g_inputBinding:getContextName() == PlayerInputComponent.INPUT_CONTEXT_NAME then

            local currentMission = g_currentMission
            local accessHandler = currentMission.accessHandler
            local vehicleInRange = currentMission.interactiveVehicleInRange
            local canAccess

            if vehicleInRange == nil then
                canAccess = false
            else
                canAccess = accessHandler:canPlayerAccess(vehicleInRange, self.player)
            end

            local closestNode = self.player.targeter:getClosestTargetedNodeFromType(PlayerInputComponent)
            self.player.hudUpdater:setCurrentRaycastTarget(closestNode)

            if not canAccess and closestNode ~= nil then

                local husbandryId, animalId = getAnimalFromCollisionNode(closestNode)

                if husbandryId ~= nil and husbandryId ~= 0 then

                    local clusterHusbandry = currentMission.husbandrySystem:getClusterHusbandryById(husbandryId)
                    if clusterHusbandry ~= nil then
                        local placeable = clusterHusbandry:getPlaceable()
                        local animal = clusterHusbandry:getClusterByAnimalId(animalId, husbandryId)

                        if animal ~= nil and (accessHandler:canFarmAccess(self.player.farmId, placeable) and animal:getRidableFilename() ~= nil) then
                            self.rideablePlaceable = placeable
                            self.rideableCluster = animal

                            local name = animal.getName == nil and "" or animal:getName()
                            local text = string.format(g_i18n:getText("action_rideAnimal"), name)

                            g_inputBinding:setActionEventText(self.enterActionId, text)
                            g_inputBinding:setActionEventActive(self.enterActionId, true)
                        end

                    end

                else

                    local object = g_currentMission:getNodeObject(closestNode)

                    if object ~= nil and object:isa(Dewar) and object.straws > 0 then

                        self.dewar = object

                        g_inputBinding:setActionEventText(self.enterActionId, g_i18n:getText("rl_ui_takeStraw"))
                        g_inputBinding:setActionEventActive(self.enterActionId, true)        

                    end

                end

            end

        end

    end

end

PlayerInputComponent.update = Utils.appendedFunction(PlayerInputComponent.update, RealisticLivestock_PlayerInputComponent.update)


function RealisticLivestock_PlayerInputComponent:onInputEnter()

    if g_time <= g_currentMission.lastInteractionTime + 200 or g_currentMission.interactiveVehicleInRange ~= nil or self.rideablePlaceable ~= nil or self.dewar == nil or HandToolAIStraw.numHeldStraws > 10 then return end

    local strawType = g_handToolTypeManager:getTypeByName(modName .. ".aiStraw")
    local handTool = _G[strawType.className].new(g_currentMission:getIsServer(), g_currentMission:getIsClient())

    handTool:setType(strawType)
    handTool:setLoadCallback(self.onFinishedLoadStraw, self, { ["animal"] = self.dewar:getAnimal(), ["dewarUniqueId"] = self.dewar:getUniqueId() })
    handTool:loadNonStoreItem({ ["ownerFarmId"] = g_localPlayer.farmId, ["isRegistered"] = false, ["holder"] = g_localPlayer }, RLHandTools.xmlPaths.aiStraw)

    self.dewar:changeStraws(-1)

end

PlayerInputComponent.onInputEnter = Utils.appendedFunction(PlayerInputComponent.onInputEnter, RealisticLivestock_PlayerInputComponent.onInputEnter)


function PlayerInputComponent:onFinishedLoadStraw(handTool, loadingState, args)

    if loadingState == HandToolLoadingState.OK then
        handTool:setAnimal(args.animal)
        handTool:setDewarUniqueId(args.dewarUniqueId)
    end

end


function RealisticLivestock_PlayerInputComponent:registerGlobalPlayerActionEvents()

    VisualAnimalsDialog.register()

    g_inputBinding:registerActionEvent(InputAction.VisualAnimalsDialog, VisualAnimalsDialog, VisualAnimalsDialog.show, false, true, false, true, nil, true)

end


PlayerInputComponent.registerGlobalPlayerActionEvents = Utils.appendedFunction(PlayerInputComponent.registerGlobalPlayerActionEvents, RealisticLivestock_PlayerInputComponent.registerGlobalPlayerActionEvents)


function RealisticLivestock_PlayerInputComponent.onFinishedRideBlending(superFunc, _, args)
    local placeable = args[1]
    placeable:startRiding(args[2].farmId .. " " .. args[2].uniqueId, args[3])
end

PlayerInputComponent.onFinishedRideBlending = Utils.overwrittenFunction(PlayerInputComponent.onFinishedRideBlending, RealisticLivestock_PlayerInputComponent.onFinishedRideBlending)