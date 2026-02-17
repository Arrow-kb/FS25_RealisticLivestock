local modDirectory = g_currentModDirectory
local fallbackDependencies = {
	["FS25_FontLibrary"] = "1.0.0.6"
}


local function getAreVersionsCompatible(version, minVersion)

	local versionParts = string.split(version, ".")
	local minVersionParts = string.split(minVersion, ".")

	for i, versionNumber in pairs(versionParts) do

		if #minVersionParts < i or versionNumber < minVersionParts[i] then return false end

		if versionNumber > minVersionParts[i] then return true end

	end

	return true

end


function MPLoadingScreen:verifyDependencies(directory)

	local xmlFile = XMLFile.load("tempModDesc", modDirectory .. "modDesc.xml")
	local hasIncompatibleDependency = false
	local dependencies = {}

	xmlFile:iterate("modDesc.dependencies.dependency", function(_, key)

		table.insert(dependencies, {
			["name"] = xmlFile:getString(key),
			["minVersion"] = xmlFile:getString(key .. "#version", "1.0.0.0"),
			["incompatible"] = false,
			["installed"] = false
		})

	end)

	xmlFile:delete()

	local hasTamperedWithDependencies = false

	for name, version in pairs(fallbackDependencies) do

		local hasDependencyInXMLFile = false

		for _, dependency in pairs(dependencies) do
			if dependency.name == name then
				hasDependencyInXMLFile = true
				break
			end
		end

		if not hasDependencyInXMLFile then
			hasTamperedWithDependencies = true
			table.insert(dependencies, {
				["name"] = name,
				["minVersion"] = version,
				["incompatible"] = false,
				["installed"] = false
			})
		end

	end

	for _, dependency in pairs(dependencies) do

		dependency.installed = g_modIsLoaded[dependency.name]

		if dependency.installed then
			local modXmlFile = XMLFile.load("tempDependencyModDesc", g_modNameToDirectory[dependency.name] .. "modDesc.xml")
			local version = modXmlFile:getString("modDesc.version", "1.0.0.0")
			modXmlFile:delete()

			dependency.version = version

			if not getAreVersionsCompatible(version, dependency.minVersion) then
				hasIncompatibleDependency = true
				dependency.incompatible = true
			end
		else
			hasIncompatibleDependency = true
		end

	end

	return dependencies, hasIncompatibleDependency, hasTamperedWithDependencies

end


function MPLoadingScreen:dependencyProblemOnQuitOk()

	doRestart(false, "")

end


MPLoadingScreen.update = Utils.overwrittenFunction(MPLoadingScreen.update, function(self, superFunc, dT)

	if not self.verifiedDependencies then

		local dependencies, isIncompatible, hasTamperedWithDependencies = self:verifyDependencies(modDirectory)

		self.verifiedDependencies = true

		if isIncompatible then

			local text = g_i18n:getText("rl_ui_dependencies_missing") .. "\n"

			for _, dependency in pairs(dependencies) do
				if not dependency.installed then
					text = text .. "\n" .. string.format(g_i18n:getText("rl_ui_dependency_missing_notInstalled"), dependency.name)
				elseif dependency.incompatible then
					text = text .. "\n" .. string.format(g_i18n:getText("rl_ui_dependency_missing_installed"), dependency.name, dependency.version, dependency.minVersion)
				end
			end

			if hasTamperedWithDependencies then text = text .. "\n\n" .. g_i18n:getText("rl_ui_dependencies_tampered") end

			OnInGameMenuMenu()
			InfoDialog.show(text, self.dependencyProblemOnQuitOk, self)
			return

		end

	end

	superFunc(self, dT)

end)