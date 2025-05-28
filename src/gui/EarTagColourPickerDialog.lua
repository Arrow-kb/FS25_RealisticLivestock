EarTagColourPickerDialog = {}

local earTagColourPickerDialog_mt = Class(EarTagColourPickerDialog, MessageDialog)
local modDirectory = g_currentModDirectory

EarTagColourPickerDialog.INPUT_THRESHOLD = 0.01
EarTagColourPickerDialog.INPUT_SCALE = 10000
EarTagColourPickerDialog.DOUBLE_CLICK_INTERVAL = 400


function EarTagColourPickerDialog.register()

    local dialog = EarTagColourPickerDialog.new()
    g_gui:loadGui(modDirectory .. "gui/EarTagColourPickerDialog.xml", "EarTagColourPickerDialog", dialog)
    EarTagColourPickerDialog.INSTANCE = dialog

end


function EarTagColourPickerDialog.show()

    if EarTagColourPickerDialog.INSTANCE ~= nil then
        local dialog = EarTagColourPickerDialog.INSTANCE
        g_gui:showDialog("EarTagColourPickerDialog")
    end

end


function EarTagColourPickerDialog.new(target, customMt)

    local self = MessageDialog.new(target, customMt or earTagColourPickerDialog_mt)

    self.animalTypes = g_currentMission.animalSystem:getTypes()

    return self

end


function EarTagColourPickerDialog.createFromExistingGui(gui, _)

    EarTagColourPickerDialog.register()
    EarTagColourPickerDialog.show()

end


function EarTagColourPickerDialog:onGuiSetupFinished()

    EarTagColourPickerDialog:superClass().onGuiSetupFinished(self)

    local typeTexts = {}

    for _, type in pairs(self.animalTypes) do

        table.insert(typeTexts, type.name)

    end

    self.animalTypePicker:setTexts(typeTexts)

    local rgbTexts = {}
    local hsvTexts = {}

	for i = 0, 360 do

        table.insert(hsvTexts, tostring(i))

        if i <= 255 then table.insert(rgbTexts, tostring(i)) end

    end
    
	self.hueSliderBase:setTexts(hsvTexts)
	self.hueSliderText:setTexts(hsvTexts)
    self.baseRgbRed:setTexts(rgbTexts)
	self.baseRgbGreen:setTexts(rgbTexts)
	self.baseRgbBlue:setTexts(rgbTexts)
    self.textRgbRed:setTexts(rgbTexts)
	self.textRgbGreen:setTexts(rgbTexts)
	self.textRgbBlue:setTexts(rgbTexts)

end


function EarTagColourPickerDialog:onOpen()

    EarTagColourPickerDialog:superClass().onOpen(self)
	
    self.customPickerUpDownEventId = g_inputBinding:registerActionEvent(InputAction.AXIS_PICK_COLOR_UPDOWN, self, self.onVerticalCursorInput, false, false, true, true)
	self.customPickerLeftRightEventId = g_inputBinding:registerActionEvent(InputAction.AXIS_PICK_COLOR_LEFTRIGHT, self, self.onHorizontalCursorInput, false, false, true, true)
    
    self.accumHorizontalInput, self.accumVerticalInput = 0, 0

	self.colorRender:createScene()

    self.animalTypePicker:setState(1)

    self.context = "earTagLeft"
    self:setColourFromType(1)

end


function EarTagColourPickerDialog:onClose()

    EarTagColourPickerDialog:superClass().onClose(self)

	g_inputBinding:removeActionEventsByTarget(self)
    
	self.colorRender:destroyScene()
    self.renderNode = nil

end


function EarTagColourPickerDialog:onAnimalTypeChanged()

    local index = self.animalTypePicker:getState()

    self:setColourFromType(index)

end


function EarTagColourPickerDialog:setColourFromType(index)

    local baseColour = self.animalTypes[index].colours[self.context]
    local textColour = self.animalTypes[index].colours[self.context .. "_text"]

    self.baseRgbRed:setState(math.floor(baseColour[1] * 255) + 1)
    self.baseRgbGreen:setState(math.floor(baseColour[2] * 255) + 1)
    self.baseRgbBlue:setState(math.floor(baseColour[3] * 255) + 1)

    self.textRgbRed:setState(math.floor(textColour[1] * 255) + 1)
    self.textRgbGreen:setState(math.floor(textColour[2] * 255) + 1)
    self.textRgbBlue:setState(math.floor(textColour[3] * 255) + 1)

    self:onBaseRGBChanged()
    self:onTextRGBChanged()

end


function EarTagColourPickerDialog:onBaseRGBChanged()

    local baseR = (self.baseRgbRed:getState() - 1) / 255
    local baseG = (self.baseRgbGreen:getState() - 1) / 255
    local baseB = (self.baseRgbBlue:getState() - 1) / 255

	local hsvR, hsvG, hsvB = GuiUtils.rgbToHSV(baseR, baseG, baseB)
	local r, g, b = GuiUtils.hsvToRGB(hsvR)

	self.customPickerBase:setImageColor(nil, math.pow(r, 2.2), math.pow(g, 2.2), math.pow(b, 2.2), 1)
	self.hueSliderBase:setState(math.floor(hsvR * 360) + 1)

	self.baseCursor:setAbsolutePosition(self.customPickerBase.absPosition[1] + self.customPickerBase.absSize[1] * hsvG - self.baseCursor.absSize[1] * 0.5, self.customPickerBase.absPosition[2] + self.customPickerBase.absSize[2] * hsvB - self.baseCursor.absSize[2] * 0.5)

    self:setCustomColorHSVBase(math.floor(hsvR * 360), hsvG, hsvB)

    self.pendingRenderUpdate = true

end


function EarTagColourPickerDialog:onTextRGBChanged()

    local textR = (self.textRgbRed:getState() - 1) / 255
    local textG = (self.textRgbGreen:getState() - 1) / 255
    local textB = (self.textRgbBlue:getState() - 1) / 255

	local hsvR, hsvG, hsvB = GuiUtils.rgbToHSV(textR, textG, textB)
	local r, g, b = GuiUtils.hsvToRGB(hsvR)

	self.customPickerText:setImageColor(nil, math.pow(r, 2.2), math.pow(g, 2.2), math.pow(b, 2.2), 1)
	self.hueSliderText:setState(math.floor(hsvR * 360) + 1)

	self.textCursor:setAbsolutePosition(self.customPickerText.absPosition[1] + self.customPickerText.absSize[1] * hsvG - self.textCursor.absSize[1] * 0.5, self.customPickerText.absPosition[2] + self.customPickerText.absSize[2] * hsvB - self.textCursor.absSize[2] * 0.5)

    self:setCustomColorHSVText(math.floor(hsvR * 360), hsvG, hsvB)

    self.pendingRenderUpdate = true

end


function EarTagColourPickerDialog:onBaseHueChanged(index)

	local hsvR, hsvG, hsvB = GuiUtils.hsvToRGB((index - 1) / 360)

	local r = math.pow(hsvR, 2.2)
	local g = math.pow(hsvG, 2.2)
	local b = math.pow(hsvB, 2.2)

	self.customPickerBase:setImageColor(nil, r, g, b, 1)
	
    self.baseRgbRed:setState(math.floor(r * 255) + 1)
    self.baseRgbGreen:setState(math.floor(g * 255) + 1)
    self.baseRgbBlue:setState(math.floor(b * 255) + 1)

    self:setCustomColorHSVBase(index - 1)

    self.pendingRenderUpdate = true

end


function EarTagColourPickerDialog:onTextHueChanged(index)

	local hsvR, hsvG, hsvB = GuiUtils.hsvToRGB((index - 1) / 360)

	local r = math.pow(hsvR, 2.2)
	local g = math.pow(hsvG, 2.2)
	local b = math.pow(hsvB, 2.2)

	self.customPickerText:setImageColor(nil, r, g, b, 1)
	
    self.textRgbRed:setState(math.floor(r * 255) + 1)
    self.textRgbGreen:setState(math.floor(g * 255) + 1)
    self.textRgbBlue:setState(math.floor(b * 255) + 1)

    self:setCustomColorHSVText(index - 1)

    self.pendingRenderUpdate = true

end


function EarTagColourPickerDialog:setCustomColorHSVBase(index, hsvG, hsvB)

    if hsvG ~= nil and hsvB ~= nil then
		self.baseCursor:setAbsolutePosition(self.customPickerBase.absPosition[1] + self.customPickerBase.absSize[1] * hsvG - self.baseCursor.absSize[1] * 0.5, self.customPickerBase.absPosition[2] + self.customPickerBase.absSize[2] * hsvB - self.baseCursor.absSize[2] * 0.5)
	end

	if not hsvG then
		local sG = (self.baseCursor.absPosition[1] + self.baseCursor.absSize[1] * 0.5 - self.customPickerBase.absPosition[1]) / self.customPickerBase.absSize[1]
		hsvG = math.clamp(sG, 0, 1)
	end

	if not hsvB then
		local sB = (self.baseCursor.absPosition[2] + self.baseCursor.absSize[2] * 0.5 - self.customPickerBase.absPosition[2]) / self.customPickerBase.absSize[2]
		hsvB = math.clamp(sB, 0, 1)
	end

    local r, g, b = GuiUtils.hsvToRGB(index / 360, hsvG, hsvB)

    self.baseRgbRed:setState(math.floor(r * 255) + 1)
    self.baseRgbGreen:setState(math.floor(g * 255) + 1)
    self.baseRgbBlue:setState(math.floor(b * 255) + 1)

    self.pendingRenderUpdate = true

end


function EarTagColourPickerDialog:setCustomColorHSVText(index, hsvG, hsvB)

    if hsvG ~= nil and hsvB ~= nil then
		self.textCursor:setAbsolutePosition(self.customPickerText.absPosition[1] + self.customPickerText.absSize[1] * hsvG - self.textCursor.absSize[1] * 0.5, self.customPickerText.absPosition[2] + self.customPickerText.absSize[2] * hsvB - self.textCursor.absSize[2] * 0.5)
	end

	if not hsvG then
		local sG = (self.textCursor.absPosition[1] + self.textCursor.absSize[1] * 0.5 - self.customPickerText.absPosition[1]) / self.customPickerText.absSize[1]
		hsvG = math.clamp(sG, 0, 1)
	end

	if not hsvB then
		local sB = (self.textCursor.absPosition[2] + self.textCursor.absSize[2] * 0.5 - self.customPickerText.absPosition[2]) / self.customPickerText.absSize[2]
		hsvB = math.clamp(sB, 0, 1)
	end

    local r, g, b = GuiUtils.hsvToRGB(index / 360, hsvG, hsvB)

    self.textRgbRed:setState(math.floor(r * 255) + 1)
    self.textRgbGreen:setState(math.floor(g * 255) + 1)
    self.textRgbBlue:setState(math.floor(b * 255) + 1)

    self.pendingRenderUpdate = true

end


function EarTagColourPickerDialog:onClickOk()

    local typeIndex = self.animalTypePicker:getState()

    local baseR = (self.baseRgbRed:getState() - 1) / 255
    local baseG = (self.baseRgbGreen:getState() - 1) / 255
    local baseB = (self.baseRgbBlue:getState() - 1) / 255

    local textR = (self.textRgbRed:getState() - 1) / 255
    local textG = (self.textRgbGreen:getState() - 1) / 255
    local textB = (self.textRgbBlue:getState() - 1) / 255

    local type = g_currentMission.animalSystem.types[typeIndex]
    type.colours[self.context] = { baseR, baseG, baseB }
    type.colours[self.context .. "_text"] = { textR, textG, textB }

    for _, placeable in pairs(g_currentMission.husbandrySystem.placeables) do

        if placeable:getAnimalTypeIndex() ~= typeIndex then continue end

        local animals = placeable:getClusters()

        for _, animal in pairs(animals) do

            if animal.idFull ~= nil and animal.idFull ~= "1-1" then

                local sep = string.find(animal.idFull, "-")
                local husbandry = tonumber(string.sub(animal.idFull, 1, sep - 1))
                local animalId = tonumber(string.sub(animal.idFull, sep + 1))

                if husbandry ~= 0 and animalId ~= 0 then

                    local rootNode = getAnimalRootNode(husbandry, animalId)

                    if rootNode ~= 0 then

                        local visualData = g_currentMission.animalSystem:getVisualByAge(animal.subTypeIndex, animal.age)

                        if visualData[self.context] ~= nil then

                            local node = I3DUtil.indexToObject(rootNode, visualData[self.context])

                            if node ~= nil and node ~= 0 then

                                setShaderParameter(node, "colorScale", baseR, baseG, baseB, nil, false)

                                for i = 0, getNumOfChildren(node) - 1 do

                                    local child = getChildAt(node, i)
                                    setShaderParameter(child, "colorScale", textR, textG, textB, nil, false)

                                end

                            end

                        end

                    end

                end

            end

        end

    end

end


function EarTagColourPickerDialog:onClickEarTagLeft()

    self.context = "earTagLeft"
    self.animalTypePicker:setState(1)
    self:setColourFromType(1)

end


function EarTagColourPickerDialog:onClickEarTagRight()

    self.context = "earTagRight"
    self.animalTypePicker:setState(1)
    self:setColourFromType(1)

end


function EarTagColourPickerDialog:update(dT)

    EarTagColourPickerDialog:superClass().update(self, dT)

    if self.pendingRenderUpdate and self.colorRender.scene ~= nil then

        local baseR = (self.baseRgbRed:getState() - 1) / 255
        local baseG = (self.baseRgbGreen:getState() - 1) / 255
        local baseB = (self.baseRgbBlue:getState() - 1) / 255

        local textR = (self.textRgbRed:getState() - 1) / 255
        local textG = (self.textRgbGreen:getState() - 1) / 255
        local textB = (self.textRgbBlue:getState() - 1) / 255

        if self.renderNode == nil then self.renderNode = getChildAt(getChildAt(self.colorRender.scene, 0), 0) end

        setShaderParameter(self.renderNode, "colorScale", baseR, baseG, baseB)

        for i = 0, getNumOfChildren(self.renderNode) - 1 do

            local child = getChildAt(self.renderNode, i)
            setShaderParameter(child, "colorScale", textR, textG, textB)

        end

        self.colorRender:setRenderDirty()
        self.pendingRenderUpdate = false

    end

end


function EarTagColourPickerDialog:mouseEvent(pixelX, pixelY, isDown, isUp)

	local pixelsX = 20 * g_pixelSizeX
	local pixelsY = 20 * g_pixelSizeY

	if GuiUtils.checkOverlayOverlap(pixelX, pixelY, self.customPickerBase.absPosition[1] - pixelsX, self.customPickerBase.absPosition[2] - pixelsY, self.customPickerBase.absSize[1] + pixelsX * 2, self.customPickerBase.absSize[2] + pixelsY * 2) and self.customPickerBase:getIsVisible() then

		if isDown then
			self.inputDown = true
		end

		if self.inputDown then

			local positionX = math.clamp(pixelX, self.customPickerBase.absPosition[1], self.customPickerBase.absPosition[1] + self.customPickerBase.absSize[1])
			local positionY = math.clamp(pixelY, self.customPickerBase.absPosition[2], self.customPickerBase.absPosition[2] + self.customPickerBase.absSize[2])

			self.baseCursor:setAbsolutePosition(positionX - self.baseCursor.absSize[1] * 0.5, positionY - self.baseCursor.absSize[2] * 0.5)
			self:setCustomColorHSVBase(self.hueSliderBase:getState() - 1)

		end
	end

	if GuiUtils.checkOverlayOverlap(pixelX, pixelY, self.customPickerText.absPosition[1] - pixelsX, self.customPickerText.absPosition[2] - pixelsY, self.customPickerText.absSize[1] + pixelsX * 2, self.customPickerText.absSize[2] + pixelsY * 2) and self.customPickerText:getIsVisible() then

		if isDown then
			self.inputDown = true
		end

		if self.inputDown then

			local positionX = math.clamp(pixelX, self.customPickerText.absPosition[1], self.customPickerText.absPosition[1] + self.customPickerText.absSize[1])
			local positionY = math.clamp(pixelY, self.customPickerText.absPosition[2], self.customPickerText.absPosition[2] + self.customPickerText.absSize[2])

			self.textCursor:setAbsolutePosition(positionX - self.textCursor.absSize[1] * 0.5, positionY - self.textCursor.absSize[2] * 0.5)
			self:setCustomColorHSVText(self.hueSliderText:getState() - 1)

		end
	end

	if isUp then
		self.inputDown = false
	end

end


function EarTagColourPickerDialog:onHorizontalCursorInput(_, amount)
	self.accumHorizontalInput = self.accumHorizontalInput + amount
end


function EarTagColourPickerDialog:onVerticalCursorInput(_, amount)
	self.accumVerticalInput = self.accumVerticalInput + amount
end