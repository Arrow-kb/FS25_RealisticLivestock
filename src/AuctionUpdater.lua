AuctionUpdater = {}

local AuctionUpdater_mt = Class(AuctionUpdater)

function AuctionUpdater.new()

	local self = setmetatable({}, AuctionUpdater_mt)

	return self

end


function AuctionUpdater:update(dT)

	if self.placeable == nil then return end

	self.placeable:updateAuction(dT)

end


function AuctionUpdater:setPlaceable(placeable)

	self.placeable = placeable

end

g_auctionUpdater = AuctionUpdater.new()