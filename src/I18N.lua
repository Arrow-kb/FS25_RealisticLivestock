RL_I18N = {}
local modName = g_currentModName
local isGithubVersion = true

function RL_I18N:getText(superFunc, text, modEnv)

    if (text == "rl_ui_monitorSubscriptions" or text == "finance_monitorSubscriptions" or text == "rl_ui_herdsmanWages" or text == "finance_herdsmanWages" or text == "rl_ui_semenPurchase" or text == "finance_semenPurchase" or text == "finance_medicine") and modEnv == nil then
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


function RL_I18N:formatNumber(superFunc, number, precision, forcePrecision)

    local formattedNumber = superFunc(self, number, precision, forcePrecision)

    precision = precision or 0

    if precision == 0 or forcePrecision or formattedNumber == nil or formattedNumber == "inf" or formattedNumber == "-inf" then return formattedNumber end

    local parts = string.split(formattedNumber, self.decimalSeparator)

    if #parts == 1 then parts[2] = "" end

    for i = #parts[2] + 1, precision do parts[2] = parts[2] .. "0" end

    return table.concat(parts, self.decimalSeparator)

end

I18N.formatNumber = Utils.overwrittenFunction(I18N.formatNumber, RL_I18N.formatNumber)