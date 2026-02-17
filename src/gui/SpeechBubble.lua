SpeechBubble = {}


SpeechBubble.INACTIVE = 1
SpeechBubble.GROWING = 2
SpeechBubble.STATIC = 3
SpeechBubble.SHRINKING = 4


local modDirectory = g_currentModDirectory
local SpeechBubble_mt = Class(SpeechBubble)


function SpeechBubble.new()

	local self = setmetatable({}, SpeechBubble_mt)

	self.text = ""
	self.timer = {
		["active"] = false,
		["time"] = 0
	}
	self.state = SpeechBubble.INACTIVE
	self.size = 0

	self.ref = { ["x"] = 0, ["y"] = 0, ["z"] = 0 }

	return self

end


function SpeechBubble:delete()
	self:clear()
	delete(self.node)
end


function SpeechBubble:createFromHeadNode(headNode)

	self.node = g_i3DManager:loadI3DFile(modDirectory .. "gui/speech.i3d")
	link(headNode, self.node)

	setTranslation(self.node, 0.1, 0, 0)
	setVisibility(self.node, false)

end


function SpeechBubble:clear()

	if self.textNode ~= nil and self.textNode ~= 0 then delete3DLinkedText(self.textNode) end
	self.textNode = nil
	self.text = ""
	self.characters = {}
	setVisibility(self.node, false)
	self.timer = {
		["active"] = false,
		["time"] = 0
	}

	self.state = SpeechBubble.INACTIVE
	self.size = 0

end


function SpeechBubble:setText(text, duration)

	local state, size = self.state, self.size

	self:clear()
	self.text = text or ""
	
	duration = duration or 3000
	self.timer.active = duration ~= nil and duration > 0
	self.timer.time = duration

	setTextColor(0, 0, 0, 1)
	setTextAlignment(RenderText.ALIGN_CENTER)
	setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
	set3DTextWrapWidth(1.7)
	setTextLineHeightScale(0.75)

	self.textNode = create3DLinkedText(self.node, 0, 0.8, 0.1, 0, math.rad(-90), math.rad(1.75), 0.2, self.text)

	setTextColor(1, 1, 1, 1)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
	set3DTextWrapWidth(0)
	setTextLineHeightScale(1.1)
	
	setVisibility(self.node, true)

	if state == SpeechBubble.INACTIVE or state == SpeechBubble.SHRINKING then
		self.state = SpeechBubble.GROWING
	else
		self.state = state
	end

	self.size = size

end


function SpeechBubble:update(dT)

	if self.state == SpeechBubble.INACTIVE then return end

	local state = self.state

	if state ~= SpeechBubble.STATIC then

		self.size = self.size + (state == SpeechBubble.GROWING and 1 or -1) * dT * 0.001

		if state == SpeechBubble.GROWING and self.size >= 1 then self.size, self.state = 1, SpeechBubble.STATIC end

		if state == SpeechBubble.SHRINKING and self.size <= 0 then
			self:clear()
			return
		end

		setScale(self.node, self.size, self.size, 1)

	end

	local timer = self.timer

	if timer.active and state == SpeechBubble.STATIC then

		timer.time = timer.time - dT
		if timer.time < 0 then
			timer.active = false
			self.state = SpeechBubble.SHRINKING
		end

	end

	local x, y, z = getWorldTranslation(self.node)
	local dx, _, dz = MathUtil.vector3Normalize(self.ref.x - x, self.ref.y - y, self.ref.z - z)
	setWorldRotation(self.node, 0, MathUtil.getYRotationFromDirection(dx, dz), 0)

end


function SpeechBubble:setReferencePosition(x, y, z)

	self.ref.x, self.ref.y, self.ref.z = x, y, z

end