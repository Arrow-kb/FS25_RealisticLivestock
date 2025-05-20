RL_I18N = {}
local modName = g_currentModName

function RL_I18N:getText(superFunc, text, modEnv)

    if (text == "rl_ui_monitorSubscriptions" or text == "finance_monitorSubscriptions") and modEnv == nil then
        return superFunc(self, text, modName)
    end

    return superFunc(self, text, modEnv)

end

I18N.getText = Utils.overwrittenFunction(I18N.getText, RL_I18N.getText)