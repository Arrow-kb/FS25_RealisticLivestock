RL_RenderElement = {}

local modDirectory = g_currentModDirectory


function RL_RenderElement:setScene(superFunc, filename)

	if filename == "animals/domesticated/earTagScene.i3d" then
        self.isRealisticLivestockAsset = true
        filename = modDirectory .. filename
    end

	superFunc(self, filename)

end

RenderElement.setScene = Utils.overwrittenFunction(RenderElement.setScene, RL_RenderElement.setScene)


function RL_RenderElement:onSceneLoaded(node, failedReason, _)

    if failedReason == LoadI3DFailedReason.NONE and self.isRealisticLivestockAsset then setVisibility(node, true) end

end

RenderElement.onSceneLoaded = Utils.appendedFunction(RenderElement.onSceneLoaded, RL_RenderElement.onSceneLoaded)