RLPlaceables = {}


local modDirectory = g_currentModDirectory
local modName = g_currentModName
local path = modDirectory .. "xml/placeables.xml"
local xmlFile = XMLFile.loadIfExists("rlPlaceables", path)

if xmlFile ~= nil then

	xmlFile:iterate("placeables.specializations.specialization", function(_, key)

		local name = xmlFile:getString(key .. "#name")
		local className = xmlFile:getString(key .. "#className")
		local filename = xmlFile:getString(key .. "#filename")

		g_placeableSpecializationManager:addSpecialization(name, className, modDirectory .. filename)

	end)

	xmlFile:iterate("placeables.types.type", function(_, key)

		g_placeableTypeManager:loadTypeFromXML(xmlFile.handle, key, false, nil, modName)

	end)

end