PieChartElement = {}

PieChartElement.NUM_SEGMENTS = 720
PieChartElement.RADIANS_PER_SEGMENT =  6.283185307179586 / PieChartElement.NUM_SEGMENTS

local PieChartElement_mt = Class(PieChartElement, GuiElement)
local modDirectory = g_currentModDirectory

Gui.registerGuiElement("PieChart", PieChartElement)
Gui.registerGuiElementProcFunction("PieChart", Gui.assignPlaySampleCallback)


function PieChartElement.new(target, customMt)

	local self = GuiElement.new(target, customMt or PieChartElement_mt)
	
	self.data = {}
	self.slices = {}
	self.texts = {}
	self.defaultTextProfile = "multiTextOptionText"

	return self

end


function PieChartElement:loadFromXML(xmlFile, key)

	PieChartElement:superClass().loadFromXML(self, xmlFile, key)

	self.defaultTextProfile = getXMLString(xmlFile, key .. "#defaultTextProfile") or self.defaultTextProfile

end


function PieChartElement:loadProfile(profile, applyProfile)

	PieChartElement:superClass().loadProfile(self, profile, applyProfile)

	self.defaultTextProfile = profile:getValue("defaultTextProfile", self.defaultTextProfile)

end


function PieChartElement:addDefaultElements()

	self.textTemplate = TextElement.new(self)
	self:addElement(self.textTemplate)
	self.textTemplate:applyProfile(self.defaultTextProfile)

end


function PieChartElement:onGuiSetupFinished()

	self:addDefaultElements()

	self.lineLength, self.lineWidth = getNormalizedScreenValues(75, 2)

    PieChartElement:superClass().onGuiSetupFinished(self)

	self:setData({
		{ ["percent"] = 0.45, ["colour"] = { 1, 0, 0 }, ["textColour"] = { 0, 0, 0 }, ["title"] = "Cows" },
		{ ["percent"] = 0.2, ["colour"] = { 0, 1, 0 }, ["textColour"] = { 0, 0, 0 }, ["title"] = "Pigs" },
		{ ["percent"] = 0.17, ["colour"] = { 0, 0, 1 }, ["textColour"] = { 1, 1, 1 }, ["title"] = "Sheep" },
		{ ["percent"] = 0.05, ["colour"] = { 0, 0.5, 0.5 }, ["textColour"] = { 0, 0, 0 }, ["title"] = "Horses" },
		{ ["percent"] = 0.13, ["colour"] = { 0.5, 0.5, 0 }, ["textColour"] = { 0, 0, 0 }, ["title"] = "Chickens" },
	})

end


function PieChartElement:setData(data)

	self.data = data
	self:validateData()

end


function PieChartElement:validateData()

	local totalPercent = 0

	for _, item in pairs(self.data) do totalPercent = totalPercent + item.percent end

	local percentModifier = 1 / totalPercent

	for _, item in pairs(self.data) do
		item.percent = item.percent * percentModifier
		item.textColour = item.textColour or { 0, 0, 0 }
	end

	table.sort(self.data, function(a, b)
		if a.percent == b.percent then return a.title < b.title end
		return a.percent > b.percent
	end)

	self:createTexts()

end


function PieChartElement:createTexts()

	for i = #self.texts, 1, -1 do self.texts[i]:delete() end

	self.texts = {}

	for _, item in pairs(self.data) do

		local percentTextElement = self.textTemplate:clone(self)
		local titleTextElement = self.textTemplate:clone(self)
		percentTextElement:setText(string.format("%.2f%%", item.percent * 100))
		titleTextElement:setText(item.title)

		if item.percent < 0.15 then
			percentTextElement:setTextColor(0.22323, 0.40724, 0.00368, 1)
			percentTextElement.textAlignment = RenderText.ALIGN_LEFT
		else
			percentTextElement:setTextColor(item.textColour[1], item.textColour[2], item.textColour[3], 1)
		end

		titleTextElement:setTextColor(0.22323, 0.40724, 0.00368, 1)
		titleTextElement.textAlignment = RenderText.ALIGN_LEFT

		table.insert(self.texts, {
			["percent"] = percentTextElement,
			["title"] = titleTextElement
		})
		item.textRef = #self.texts

	end

end


function PieChartElement:draw(clipX1, clipY1, clipX2, clipY2)

	local radius, thickness = self.absSize[1] * 0.5, self.absSize[1] * 0.89
	local aspectRadius = radius * g_screenAspectRatio
	local colourCodePositionX, colourCodePositionY = self.absPosition[1] + self.absSize[1] * 1.5, self.absPosition[2] + self.absSize[2] * 0.5
	local colourCodeWidth, colourCodeHeight = self.absSize[1] * 0.2, self.absSize[1] * 0.1

	local startX = self.absPosition[1] + radius
	local startY = self.absPosition[2]

	local totalNumSegments = 0

	for j, item in ipairs(self.data) do

		-- Pie Chart

		local r, g, b = item.colour[1], item.colour[2], item.colour[3]
		local numSegments = math.round(item.percent * PieChartElement.NUM_SEGMENTS)

		if j == #self.data or numSegments + totalNumSegments > PieChartElement.NUM_SEGMENTS then numSegments = PieChartElement.NUM_SEGMENTS - totalNumSegments end

		local percentTextElement, titleTextElement = self.texts[item.textRef].percent, self.texts[item.textRef].title

		for i = 1, numSegments do
		
			totalNumSegments = totalNumSegments + 1

			local endX = self.absPosition[1] + radius * math.cos(PieChartElement.RADIANS_PER_SEGMENT * totalNumSegments)
			local endY = self.absPosition[2] + aspectRadius * math.sin(PieChartElement.RADIANS_PER_SEGMENT * totalNumSegments)
			drawLine2D(startX, startY, endX, endY, thickness, r, g, b, 1)

			if i == math.ceil(numSegments / 2) then

				if item.percent < 0.15 then

					local lineEndX = startX + self.lineLength * math.cos(PieChartElement.RADIANS_PER_SEGMENT * totalNumSegments)
					local lineEndY = startY + self.lineLength * math.sin(PieChartElement.RADIANS_PER_SEGMENT * totalNumSegments)

					drawLine2D(startX, startY, lineEndX, lineEndY, self.lineWidth, 0.6, 0.6, 0.6, 1)
					percentTextElement:setAbsolutePosition(lineEndX, lineEndY)
				
				else

					percentTextElement:setAbsolutePosition(self.absPosition[1] - (self.absPosition[1] - endX) * 0.75, (self.absPosition[2] - g_pixelSizeY * 10) - (self.absPosition[2] - endY) * 0.75)

				end

			end 

			startY = endY
			startX = endX

		end


		-- Colour Codes

		drawFilledRect(colourCodePositionX, colourCodePositionY, colourCodeWidth, colourCodeHeight, r, g, b, 1, clipX1, clipY1, clipX2, clipY2)
		drawOutlineRect(colourCodePositionX, colourCodePositionY, colourCodeWidth, colourCodeHeight, colourCodeWidth * 0.05, colourCodeWidth * 0.05, 0, 0, 0, 1)
		titleTextElement:setAbsolutePosition(colourCodePositionX + colourCodeWidth * 1.25, colourCodePositionY - colourCodeHeight * 1.1)
		colourCodePositionY = colourCodePositionY - colourCodeHeight * 1.5

	end

	PieChartElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)

end