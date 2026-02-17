CatalogUpdater = {}

local CatalogUpdater_mt = Class(CatalogUpdater)

function CatalogUpdater.new()

	local self = setmetatable({}, CatalogUpdater_mt)

	return self

end


function CatalogUpdater:update(dT)

	if self.catalog == nil then return end

	self.catalog:updateCatalog(dT)

end


function CatalogUpdater:setCatalog(catalog)

	self.catalog = catalog

end

g_catalogUpdater = CatalogUpdater.new()