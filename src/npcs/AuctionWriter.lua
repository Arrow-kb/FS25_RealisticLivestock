AuctionWriter = {}


local AuctionWriter_mt = Class(AuctionWriter, AuctionNPC)


function AuctionWriter.new(placeable, parent, navigationNode, path, whiteboardNode)

	local self = AuctionNPC.new(placeable, parent, AuctionWriter_mt)

	self.type = "writer"
	self.textNodes = {}
	self.isIdle = true
	self.navigationNode = navigationNode
	self.path = path
	self:setTarget(1)
	self.whiteboardNode = whiteboardNode
	self.textOffsetY = 0.77

	return self

end


function AuctionWriter:loadTemplate()

	self.gender = "playerM"
	self.head = "head01"
	self.jacket = "topVest"
	self.pants = "jeans"
	self.hair = "hair12"
	self.beard = "stubble_head01"
	self.hairColour = 18
	self.shoes = "galoshes"

end


function AuctionWriter:addText(text)

	setTextColor(0, 0, 0, 1)
	setTextBold(true)

	local node = create3DLinkedText(self.whiteboardNode, 1.426, self.textOffsetY, 0.806, 0, 0, 0, 0.2, text, RealisticLivestock.FONTS.ink_free)

	setTextColor(1, 1, 1, 1)
	setTextBold(false)

	self.textOffsetY = self.textOffsetY - 0.125
	table.insert(self.textNodes, node)

end


function AuctionWriter:clearText()

	for _, node in pairs(self.textNodes) do delete3DLinkedText(node) end

	self.textNodes = {}
	self.textOffsetY = 0.77

end