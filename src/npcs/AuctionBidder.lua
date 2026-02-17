AuctionBidder = {}
AuctionBidder.FONTS = {
	"ink_free",
	"toms_handwritten"
}

AuctionBidder.NEXT_ID = 1


local AuctionBidder_mt = Class(AuctionBidder, AuctionNPC)


function AuctionBidder.new(placeable, parent, navigationNode, path)

	local self = AuctionNPC.new(placeable, parent, AuctionBidder_mt)

	self.navigationNode = navigationNode
	self.path = path
	self.type = "bidder"
	self.bidding = {
		["money"] = math.random(250, 25000),
		["chance"] = math.random(50, 500) / 1000
	}

	self:setTarget(1)

	self.x, self.y, self.z, self.rx, self.ry, self.rz = self.target.x, self.target.y, self.target.z, 0, self.target.ry, 0

	self.isIdle = false

	self.font = {
		["name"] = AuctionBidder.FONTS[math.random(1, #AuctionBidder.FONTS)],
		["size"] = math.random(5, 15) / 10
	}

	return self

end


function AuctionBidder:saveToXMLFile(xmlFile, key)

	AuctionBidder:superClass().saveToXMLFile(self, xmlFile, key)

	xmlFile:setString(key .. ".font#name", self.font.name)
	xmlFile:setFloat(key .. ".font#size", self.font.size)

	xmlFile:setString(key .. "#name", self.name)
	self.playerStyle:saveToXMLFile(xmlFile, key .. ".playerStyle")

	xmlFile:setFloat(key .. ".bidding#money", self.bidding.money)
	xmlFile:setFloat(key .. ".bidding#chance", self.bidding.chance)

	xmlFile:setInt(key .. "#id", self.id)

end


function AuctionBidder:loadFromXMLFile(xmlFile, key)

	AuctionBidder:superClass().loadFromXMLFile(self, xmlFile, key)

	self.font = {
		["name"] = xmlFile:getString(key .. ".font#name"),
		["size"] = xmlFile:getFloat(key .. ".font#size")
	}

	self.name = xmlFile:getString(key .. "#name")
	self.playerStyle = PlayerStyle.new()
	self.playerStyle:loadFromXMLFile(xmlFile, key .. ".playerStyle")

	self.bidding = {
		["money"] = xmlFile:getFloat(key .. ".bidding#money", math.random(250, 25000)),
		["chance"] = xmlFile:getFloat(key .. ".bidding#chance", math.random(50, 500) / 1000)
	}

	self.id = xmlFile:getInt(key .. "#id")

	if AuctionBidder.NEXT_ID <= self.id then AuctionBidder.NEXT_ID = self.id + 1 end

end


function AuctionBidder:getFontName()

	return self.font.name

end


function AuctionBidder:getFontSize()

	return self.font.size

end


function AuctionBidder:calculateBid(animal, value, nextBid)

	local bidding = self.bidding

	if nextBid <= bidding.money then

		local chance = bidding.chance * (value / nextBid) * (bidding.money / nextBid) * 0.005

		if math.random() < chance then

			self:speak(string.format("%s!", g_i18n:formatMoney(nextBid, 2, true, true)))
			return true

		end

	end

	return false

end


function AuctionBidder:changeMoney(delta)

	self.bidding.money = math.max(0, self.bidding.money + delta)

end


function AuctionBidder:changeChance(delta)

	self.bidding.chance = math.max(0, self.bidding.chance + delta)

end