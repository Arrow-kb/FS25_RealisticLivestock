DoubleOptionSliderElement = {}

local doubleOptionSliderElement_mt = Class(DoubleOptionSliderElement, MultiTextOptionElement)

Gui.registerGuiElement("DoubleOptionSlider", DoubleOptionSliderElement)
Gui.registerGuiElementProcFunction("DoubleOptionSlider", Gui.assignPlaySampleCallback)


function DoubleOptionSliderElement.new(target, customMt)

	local self = MultiTextOptionElement.new(target, customMt or doubleOptionSliderElement_mt)
	
	self.leftSliderElement = nil
	self.rightSliderElement = nil
	self.sliderOffset = nil
	self.defaultProfileSlider = nil
	self.defaultProfileSliderRound = nil
	self.useFillingBar = false
	self.fillingBarElement = nil
	self.defaultProfileFillingBar = nil
	self.defaultProfileFillingBarThreePart = nil
	self.updateTextPosition = true
	self.leftState = 1
	self.rightState = 2
    self.fillingBarOffset = GuiUtils.getNormalizedScreenValues("2px 0px")

	return self

end


function DoubleOptionSliderElement:loadFromXML(handle, key)

	DoubleOptionSliderElement:superClass().loadFromXML(self, handle, key)

	self.sliderOffset = GuiUtils.getNormalizedXValue(getXMLInt(handle, key .. "#sliderOffset"), self.sliderOffset)
	self.useFillingBar = getXMLBool(handle, key .. "#useFillingBar") or self.useFillingBar
	self.updateTextPosition = getXMLBool(handle, key .. "#updateTextPosition") or self.updateTextPosition

end


function DoubleOptionSliderElement:loadProfile(profile, applyProfile)

	DoubleOptionSliderElement:superClass().loadProfile(self, profile, applyProfile)

	self.sliderOffset = GuiUtils.getNormalizedXValue(profile:getValue("sliderOffset"), self.sliderOffset)
	self.useFillingBar = profile:getBool("useFillingBar", self.useFillingBar)
	self.updateTextPosition = profile:getBool("updateTextPosition", self.updateTextPosition)
	self.defaultProfileSlider = profile:getValue("defaultProfileSlider", self.defaultProfileSlider)
	self.defaultProfileSliderRound = profile:getValue("defaultProfileSliderRound", self.defaultProfileSliderRound)
	self.defaultProfileFillingBar = profile:getValue("defaultProfileFillingBar", self.defaultProfileFillingBar)
	self.defaultProfileFillingBarThreePart = profile:getValue("defaultProfileFillingBarThreePart", self.defaultProfileFillingBarThreePart)

end


function DoubleOptionSliderElement:copyAttributes(target)

	self.sliderOffset = target.sliderOffset
	self.useFillingBar = target.useFillingBar
	self.updateTextPosition = target.updateTextPosition
	self.defaultProfileSlider = target.defaultProfileSlider
	self.defaultProfileSliderRound = target.defaultProfileSliderRound
	self.defaultProfileFillingBar = target.defaultProfileFillingBar
	self.defaultProfileFillingBarThreePart = target.defaultProfileFillingBarThreePart

	self.leftSliderElement = target.leftSliderElement
	self.rightSliderElement = target.rightSliderElement
	self.leftState = target.leftState
	self.rightState = target.rightState
	self.leftSliderMousePosX = target.leftSliderMousePosX
	self.rightSliderMousePosX = target.rightSliderMousePosX
	self.texts = target.texts
	self.isLeftSliderPressed = target.isLeftSliderPressed
	self.isRightSliderPressed = target.isRightSliderPressed

	DoubleOptionSliderElement:superClass().copyAttributes(self, target)

end


function DoubleOptionSliderElement:setElementsByName()

	DoubleOptionSliderElement:superClass().setElementsByName(self)

	for _, element in pairs(self.elements) do

		if element.name == "leftSlider" then
			self.leftSliderElement = element
			element.target = self
		end

		if element.name == "rightSlider" then
			self.rightSliderElement = element
			element.target = self
		end

		if element.name == "fillingBar" then
			self.fillingBarElement = element
			element.target = self
		end

	end

	if self.fillingBarElement == nil then
		self.useFillingBar = false
	end

	if self.leftSliderElement == nil then
		Logging.warning("DoubleOptionSliderElement: could not find a left slider element for element with profile " .. self.profile)
	elseif self.rightSliderElement == nil then
		Logging.warning("DoubleOptionSliderElement: could not find a right slider element for element with profile " .. self.profile)
	end

end


function DoubleOptionSliderElement:addDefaultElements()

	DoubleOptionSliderElement:superClass().addDefaultElements(self)

	if self.autoAddDefaultElements then

		if self:getDescendantByName("fillingBar") == nil then

			if self.defaultProfileFillingBar == nil then

				if self.defaultProfileFillingBarThreePart ~= nil then
					local element = ThreePartBitmapElement.new(self)
					element.name = "fillingBar"
					self:addElement(element)
					element:applyProfile(self.defaultProfileFillingBarThreePart)
				end

			else

				local element = BitmapElement.new(self)
				element.name = "fillingBar"
				self:addElement(element)
				element:applyProfile(self.defaultProfileFillingBar)

			end

		end

		if self:getDescendantByName("leftSlider") == nil then

			if self.defaultProfileSliderRound ~= nil then

				local element = RoundCornerElement.new(self)
				element.name = "leftSlider"
				self:addElement(element)
				element:applyProfile(self.defaultProfileSliderRound)

				return

			end

			if self.defaultProfileSlider ~= nil then

				local element = BitmapElement.new(self)
				element.name = "leftSlider"
				self:addElement(element)
				element:applyProfile(self.defaultProfileSlider)

			end

		end

		if self:getDescendantByName("rightSlider") == nil then

			if self.defaultProfileSliderRound ~= nil then

				local element = RoundCornerElement.new(self)
				element.name = "rightSlider"
				self:addElement(element)
				element:applyProfile(self.defaultProfileSliderRound)

				return

			end

			if self.defaultProfileSlider ~= nil then

				local element = BitmapElement.new(self)
				element.name = "rightSlider"
				self:addElement(element)
				element:applyProfile(self.defaultProfileSlider)

			end

		end

	end

end


function DoubleOptionSliderElement:onOpen()

	DoubleOptionSliderElement:superClass().onOpen(self)
	self:updateSlider()

end


function DoubleOptionSliderElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)

	if self:getIsActive() then

		eventUsed = self.wasContinuousTrigger and isUp and true or (MultiTextOptionElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) and true or eventUsed)

		if isDown then

			local leftButton = self.leftButtonElement
            self.isLeftButtonPressed = not self.hideLeftRightButtons and GuiUtils.checkOverlayOverlap(posX, posY, leftButton.absPosition[1], leftButton.absPosition[2], leftButton.absSize[1], leftButton.absSize[2], leftButton.hotspot)

            local rightButton = self.rightButtonElement
            self.isRightButtonPressed = not self.hideLeftRightButtons and GuiUtils.checkOverlayOverlap(posX, posY, rightButton.absPosition[1], rightButton.absPosition[2], rightButton.absSize[1], rightButton.absSize[2], rightButton.hotspot)

            local leftSlider = self.leftSliderElement
            self.isLeftSliderPressed = leftSlider ~= nil and GuiUtils.checkOverlayOverlap(posX, posY, leftSlider.absPosition[1], leftSlider.absPosition[2], leftSlider.absSize[1], leftSlider.absSize[2], leftSlider.hotspot)

            local rightSlider = self.rightSliderElement
            self.isRightSliderPressed = rightSlider ~= nil and GuiUtils.checkOverlayOverlap(posX, posY, rightSlider.absPosition[1], rightSlider.absPosition[2], rightSlider.absSize[1], rightSlider.absSize[2], rightSlider.hotspot)

            if self.leftSliderMousePosX == nil and self.isLeftSliderPressed then self.leftSliderMousePosX = posX end
            if self.rightSliderMousePosX == nil and self.isRightSliderPressed then self.rightSliderMousePosX = posX end

            self.delayTime = g_time

		elseif isUp then

			self.delayTime = math.huge
			self.scrollDelayDuration = MultiTextOptionElement.FIRST_INPUT_DELAY
			self.wasContinuousTrigger = false
			self.continuousTriggerTime = 0
			self.isLeftButtonPressed = false
			self.leftDelayTime = 0
			self.isRightButtonPressed = false
			self.rightDelayTime = 0
			self.isLeftSliderPressed = false
			self.isRightSliderPressed = false
			self.leftSliderMousePosX = nil
			self.rightSliderMousePosX = nil
			self.hasWrapped = false

		end

		if eventUsed or not GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2], nil) then

			if self.inputEntered and not self.focusActive then

				FocusManager:unsetHighlight(self)
				self.inputEntered = false

			end

		else

			if not (self.inputEntered or self:getIsFocused()) then

				FocusManager:setHighlight(self)
				self.inputEntered = true

			end

			if #self.texts > 1 then

				if not self:getIsFocused() and (self.isLeftSliderPressed or self.isRightSliderPressed) then FocusManager:setFocus(self) end

				if self.isLeftSliderPressed then

					local slider = self.leftSliderElement
					local sliderWidth = slider.absSize[1]
					local stepSize = (self.absSize[1] - 2 * self.sliderOffset - sliderWidth) / (#self.texts - 1)

					local mouseMoveDistance = posX - self.leftSliderMousePosX
					local sliderLocalPosX = slider.absPosition[1] - self.absPosition[1] - self.sliderOffset

					local sliderPosX = MathUtil.snapValue(sliderLocalPosX + mouseMoveDistance, stepSize)
					sliderPosX = math.clamp(sliderPosX, 0, self.absSize[1] - sliderWidth - 2 * self.sliderOffset)
					local state = MathUtil.round(sliderPosX / stepSize) + 1

					--if state ~= self.leftState and (self.leftState ~= self.rightState or (self.leftState == self.rightState and state < self.leftState)) then
					if state ~= self.leftState then
						--print(string.format("left: %s, %s, %s", tostring(state ~= self.leftState), tostring(self.leftState == self.rightState), tostring(state < self.leftState)))

						self.leftSliderMousePosX = self.leftSliderMousePosX + stepSize * (state - self.leftState)
						self.leftState = state
						self:setState(state, true)

						slider:setAbsolutePosition(self.absPosition[1] + sliderPosX + self.sliderOffset, slider.absPosition[2])

						if self.updateTextPosition then self.textElement:setAbsolutePosition(slider.absPosition[1] - (self.textElement.absSize[1] - slider.absSize[1]) * 0.5, self.textElement.absPosition[2]) end

						if self.useFillingBar then 
		
							local lowestSlider = self:getLowestSlider()

							self.fillingBarElement.offset[1] = lowestSlider.absPosition[1] - self.fillingBarElement.absPosition[1] + self.fillingBarOffset[1]
							self.fillingBarElement:setSize(math.abs((self.leftState - 1) - (self.rightState - 1)) / (#self.texts - 1) * (self.absSize[1] - self.sliderOffset * 2) + self.sliderOffset, nil)
					
						end

					end

				elseif self.isRightSliderPressed then

					local slider = self.rightSliderElement
					local sliderWidth = slider.absSize[1]
					local stepSize = (self.absSize[1] - 2 * self.sliderOffset - sliderWidth) / (#self.texts - 1)

					local mouseMoveDistance = posX - self.rightSliderMousePosX
					local sliderLocalPosX = slider.absPosition[1] - self.absPosition[1] - self.sliderOffset

					local sliderPosX = MathUtil.snapValue(sliderLocalPosX + mouseMoveDistance, stepSize)
					sliderPosX = math.clamp(sliderPosX, 0, self.absSize[1] - sliderWidth - 2 * self.sliderOffset)
					local state = MathUtil.round(sliderPosX / stepSize) + 1

					--if state ~= self.rightState and (self.leftState ~= self.rightState or (self.leftState == self.rightState and state > self.rightState)) then
					if state ~= self.rightState then
						--print(string.format("right: %s, %s, %s", tostring(state ~= self.rightState), tostring(self.leftState == self.rightState), tostring(state > self.rightState)))

						self.rightSliderMousePosX = self.rightSliderMousePosX + stepSize * (state - self.rightState)
						self.rightState = state
						self:setState(state, true)
					
						slider:setAbsolutePosition(self.absPosition[1] + sliderPosX + self.sliderOffset, slider.absPosition[2])

						if self.updateTextPosition then self.textElement:setAbsolutePosition(slider.absPosition[1] - (self.textElement.absSize[1] - slider.absSize[1]) * 0.5, self.textElement.absPosition[2]) end

						if self.useFillingBar then
		
							local lowestSlider = self:getLowestSlider()

							self.fillingBarElement.offset[1] = lowestSlider.absPosition[1] - self.fillingBarElement.absPosition[1] + self.fillingBarOffset[1]
							self.fillingBarElement:setSize(math.abs((self.leftState - 1) - (self.rightState - 1)) / (#self.texts - 1) * (self.absSize[1] - self.sliderOffset * 2) + self.sliderOffset, nil)

						end

					end

				end

			end

		end

	end

	return eventUsed

end


function DoubleOptionSliderElement:updateSlider()

    if self.leftSliderElement ~= nil then

        if self.sliderOffset == nil then
            self.sliderOffset = self.leftButtonElement.absSize[1]
        end

        local text = self.textElement
        local slider = self.leftSliderElement

        local minVal = self.absPosition[1] + self.sliderOffset
        local maxVal = self.absPosition[1] + self.absSize[1] - slider.absSize[1] - self.sliderOffset
        local pos = maxVal
        if #self.texts > 1 then
            pos = minVal + (self.leftState - 1) / (#self.texts - 1) * (maxVal - minVal)
        end

        slider:setAbsolutePosition(pos, slider.absPosition[2])

        if self.updateTextPosition then
            text:setAbsolutePosition(pos - (text.absSize[1] - slider.absSize[1]) * 0.5, text.absPosition[2])
        end

    end

    if self.rightSliderElement ~= nil then

        if self.sliderOffset == nil then
            self.sliderOffset = self.leftButtonElement.absSize[1]
        end

        local text = self.textElement
        local slider = self.rightSliderElement

        local minVal = self.absPosition[1] + self.sliderOffset
        local maxVal = self.absPosition[1] + self.absSize[1] - slider.absSize[1] - self.sliderOffset
        local pos = maxVal
        if #self.texts > 1 then
            pos = minVal + (self.rightState - 1) / (#self.texts - 1) * (maxVal - minVal)
        end

        slider:setAbsolutePosition(pos, slider.absPosition[2])

    end

	if self.useFillingBar and self.leftSliderElement ~= nil and self.rightSliderElement ~= nil then

		local fillingBarSize = self.absSize[1] - self.sliderOffset

        if #self.texts > 1 then
            fillingBarSize = math.abs((self.leftState - 1) - (self.rightState - 1)) / (#self.texts - 1) * (self.absSize[1] - self.sliderOffset * 2) + self.sliderOffset
        end
		

		local lowestSlider = self:getLowestSlider()

		self.fillingBarElement.offset[1] = lowestSlider.absPosition[1] - self.fillingBarElement.absPosition[1] + self.fillingBarOffset[1]
        self.fillingBarElement:setSize(fillingBarSize, nil)

	end

end


function DoubleOptionSliderElement:updateFillingBar()

	if self.useFillingBar and self.leftSliderElement ~= nil and self.rightSliderElement ~= nil then

		local fillingBarSize = self.absSize[1] - self.sliderOffset

        if #self.texts > 1 then
            fillingBarSize = math.abs((self.leftState - 1) - (self.rightState - 1)) / (#self.texts - 1) * (self.absSize[1] - self.sliderOffset * 2) + self.sliderOffset
        end
		

		local lowestSlider = self:getLowestSlider()

		self.fillingBarElement.offset[1] = lowestSlider.absPosition[1] - self.fillingBarElement.absPosition[1] + self.fillingBarOffset[1]
        self.fillingBarElement:setSize(fillingBarSize, nil)

	end

end


function DoubleOptionSliderElement:updateAbsolutePosition()

    DoubleOptionSliderElement:superClass().updateAbsolutePosition(self)
	self:updateSlider()

end


function DoubleOptionSliderElement:updateContentElement()

    DoubleOptionSliderElement:superClass().updateContentElement(self)

	if self.texts ~= nil and #self.texts > 0 then

		local lowestState = self:getLowestState()
		local highestState = self:getHighestState()

		if lowestState == highestState then
			self.textElement:setText(self.texts[lowestState])
		else
			self.textElement:setText(self.texts[lowestState] .. " - " .. self.texts[highestState])
		end

	end

end


function DoubleOptionSliderElement:setTexts(texts)

	self.leftState = 1
	self.rightState = #texts

	DoubleOptionSliderElement:superClass().setTexts(self, texts)

	self:updateSlider()

end


function DoubleOptionSliderElement:getHighestSlider()

	return self.leftState > self.rightState and self.leftSliderElement or self.rightSliderElement

end


function DoubleOptionSliderElement:getLowestSlider()

	return self.leftState <= self.rightState and self.leftSliderElement or self.rightSliderElement

end


function DoubleOptionSliderElement:getHighestState()

	return self.leftState > self.rightState and self.leftState or self.rightState

end


function DoubleOptionSliderElement:getLowestState()

	return self.leftState <= self.rightState and self.leftState or self.rightState

end