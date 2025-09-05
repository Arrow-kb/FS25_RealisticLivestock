RL_I18N = {}
local modName = g_currentModName
local isGithubVersion = true

function RL_I18N:getText(superFunc, text, modEnv)

    if (text == "rl_ui_monitorSubscriptions" or text == "finance_monitorSubscriptions" or text == "rl_ui_herdsmanWages" or text == "finance_herdsmanWages" or text == "rl_ui_semenPurchase" or text == "finance_semenPurchase") and modEnv == nil then
        return superFunc(self, text, modName)
    end

    if isGithubVersion and string.contains(text, "rl_") then

        local env = self.modEnvironments[modName]

        if env == nil then return superFunc(self, text, modEnv) end

        if env.texts[text .. "_github"] ~= nil then return env.texts[text .. "_github"] end

    end

    return superFunc(self, text, modEnv)

end

I18N.getText = Utils.overwrittenFunction(I18N.getText, RL_I18N.getText)