Auctioneer = {}


local Auctioneer_mt = Class(Auctioneer, AuctionNPC)


function Auctioneer.new(placeable, parent)

	local self = AuctionNPC.new(placeable, parent, Auctioneer_mt)

	self.type = "auctioneer"

	return self

end


function Auctioneer:loadTemplate()

	self.gender = "playerM"
	self.head = "head02"
	self.jacket = "topVest"
	self.pants = "jeans"
	self.hair = "hair13"
	self.beard = "stubble_head02"
	self.hairColour = 23
	self.hat = "vintage"
	self.glasses = "reading"
	self.shoes = "galoshes"

end


function Auctioneer:onAuctionStarted()

	Auctioneer:superClass().onAuctionStarted(self)

	self:speak("Auction started!")

end


function Auctioneer:onBiddingStarted(animal, startBid)

	Auctioneer:superClass().onBiddingStarted(self, animal, startBid)

	self:speak(string.format("Bidding for %s starts at %s!", animal:getIdentifiers(), g_i18n:formatMoney(startBid, 2, true, true)))

end


function Auctioneer:onBiddingEnded(winner, price)

	Auctioneer:superClass().onBiddingEnded(self, winner, price)

	local name

	if winner == 0 then
		name = g_localPlayer:getNickname()
	else
		local winner = self.placeable:getBiddingWinner()
		name = winner:getName()
	end

	self:speak(string.format("Sold to %s for %s!", name, g_i18n:formatMoney(price, 2, true, true)))

end