AuctionDigitalDisplay = {}

AuctionDigitalDisplay.OFFSET = {
	["xs"] = -1.39,
	["xe"] = 1.321,
	["z"] = -0.001,
	["ry"] = math.rad(90)
}


AuctionDigitalDisplay_mt = Class(AuctionDigitalDisplay)


function AuctionDigitalDisplay.new(parent, node)

	local self = setmetatable({}, AuctionDigitalDisplay_mt)

	self.parent = parent
	self.node = node
	self.isActive = false
	self.text = ""
	self.textLength = 0
	self.characters = {}
	self.screen = getChild(node, "screen")
	self.trailQueue = {}
	self.forceTimer = 0

	return self

end


function AuctionDigitalDisplay:setActive(isActive)

	self.isActive = isActive

end


function AuctionDigitalDisplay:clear()

	self.text = ""
	self.textLength = 0
	for _, character in pairs(self.characters) do delete3DLinkedText(character.node) end
	self.characters = {}
	self.trailQueue = {}

end


function AuctionDigitalDisplay:setText(text)

	self:clear()

	self.text = text or ""
	self.textLength = utf8Strlen(self.text)

end


function AuctionDigitalDisplay:update(dT)

	if not self.isActive or #self.text == 0 then return end

	local characters = self.characters

	if #characters == 0 then

		setTextColor(1, 1, 1, 1)
		setTextBold(true)

		local character = utf8Substr(self.text, 0, 1)
		local node = create3DLinkedText(self.screen, AuctionDigitalDisplay.OFFSET.xs, 0, AuctionDigitalDisplay.OFFSET.z, 0, AuctionDigitalDisplay.OFFSET.ry, 0, 0.2, character)
		local width = getTextWidth(0.15, character, nil, true, true, false) + 0.025
		
		setTextBold(false)
		setScale(node, 0.2, 0.25, 0)

		table.insert(characters, {
			["node"] = node,
			["width"] = width,
			["x"] = AuctionDigitalDisplay.OFFSET.xs,
			["visible"] = true
		})

	elseif #characters < self.textLength then

		local lastCharacter = characters[#characters]

		if lastCharacter.x - lastCharacter.width > AuctionDigitalDisplay.OFFSET.xs - 0.015 and lastCharacter.x - lastCharacter.width < AuctionDigitalDisplay.OFFSET.xs + 0.015 then

			setTextColor(1, 1, 1, 1)
			setTextBold(true)

			local character = utf8Substr(self.text, #characters, 1)
			local node = create3DLinkedText(self.screen, AuctionDigitalDisplay.OFFSET.xs, 0, AuctionDigitalDisplay.OFFSET.z, 0, AuctionDigitalDisplay.OFFSET.ry, 0, 0.2, character)
			local width = getTextWidth(0.15, character, nil, true, true, false) + 0.025
			
			setTextBold(false)
			setScale(node, 0.2, 0.25, 0)

			table.insert(characters, {
				["node"] = node,
				["width"] = width,
				["x"] = AuctionDigitalDisplay.OFFSET.xs,
				["visible"] = true,
				["time"] = 0
			})

		end

	end

	for i, character in ipairs(characters) do

		if not character.visible then continue end

		character.x = character.x + dT * 0.0005
		setTranslation(character.node, character.x, 0, AuctionDigitalDisplay.OFFSET.z)

		if character.x >= AuctionDigitalDisplay.OFFSET.xe then
		
			table.insert(self.trailQueue, i)
			character.visible = false
			setVisibility(character.node, false)

		end

	end

	if #self.trailQueue > 0 then

		local index = self.trailQueue[1]
		local character, previousCharacter = characters[index], characters[index - 1] or characters[self.textLength]
		self.forceTimer = self.forceTimer + dT

		if previousCharacter ~= nil and ((previousCharacter.visible and ((index == 1 and previousCharacter.x >= AuctionDigitalDisplay.OFFSET.xs * 0.5) or (index ~= 1 and previousCharacter.x - previousCharacter.width > AuctionDigitalDisplay.OFFSET.xs - 0.01 and previousCharacter.x - previousCharacter.width < AuctionDigitalDisplay.OFFSET.xs + 0.01))) or self.forceTimer > 10000) then

			self.forceTimer = 0
			character.x = AuctionDigitalDisplay.OFFSET.xs
			character.visible = true
			setVisibility(character.node, true)
			table.remove(self.trailQueue, 1)

		end

	end

end