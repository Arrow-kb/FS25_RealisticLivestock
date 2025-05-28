TripleOptionElement = {}

TripleOptionElement.STATE_LEFT = 1
TripleOptionElement.STATE_MIDDLE = 2
TripleOptionElement.STATE_RIGHT = 3
TripleOptionElement.STRING_ON = "ui_on"
TripleOptionElement.STRING_ANY = "Any"
TripleOptionElement.STRING_OFF = "ui_off"
TripleOptionElement.STRING_YES = "ui_yes"
TripleOptionElement.STRING_NO = "ui_no"
TripleOptionElement.NUM_SLIDER_STATES = 12

local tripleOptionElement_mt = Class(TripleOptionElement, MultiTextOptionElement)

Gui.registerGuiElement("TripleOption", TripleOptionElement)
Gui.registerGuiElementProcFunction("TripleOption", Gui.assignPlaySampleCallback)


function TripleOptionElement.new(target, custom_mt)

    local self = MultiTextOptionElement.new(target, custom_mt or tripleOptionElement_mt)

    self.sliderElement = nil
    self.isSliderMoving = false
    self.sliderState = 0
    self.sliderMovingDirection = 0
    self.middleButtonElement = nil
    self.defaultProfileButtonMiddle = nil

    self.useYesNoTexts = false

    return self

end


function TripleOptionElement:loadFromXML(xmlFile, key)

    TripleOptionElement:superClass().loadFromXML(self, xmlFile, key)

    self.useYesNoTexts = Utils.getNoNil(getXMLBool(xmlFile, key.."#useYesNoTexts"), self.useYesNoTexts)

end


function TripleOptionElement:loadProfile(profile, applyProfile)

    TripleOptionElement:superClass().loadProfile(self, profile, applyProfile)

    self.useYesNoTexts = profile:getBool("useYesNoTexts", self.useYesNoTexts)

    self.sliderOffset = GuiUtils.getNormalizedScreenValues(profile:getValue("sliderOffset"), self.sliderOffset)
    self.defaultProfileSlider = profile:getValue("defaultProfileSlider", self.defaultProfileSlider)
    self.defaultProfileSliderRound = profile:getValue("defaultProfileSliderRound", self.defaultProfileSliderRound)
    self.defaultProfileSliderThreePart = profile:getValue("defaultProfileSliderThreePart", self.defaultProfileSliderThreePart)
    self.defaultProfileButtonMiddle = profile:getValue("defaultProfileButtonMiddle", self.defaultProfileButtonMiddle)

end


function TripleOptionElement:copyAttributes(src)

    TripleOptionElement:superClass().copyAttributes(self, src)

    self.useYesNoTexts = src.useYesNoTexts
    self.defaultProfileSlider = src.defaultProfileSlider
    self.defaultProfileSliderRound = src.defaultProfileSliderRound
    self.defaultProfileSliderThreePart = src.defaultProfileSliderThreePart
    self.defaultProfileButtonMiddle = src.defaultProfileButtonMiddle

end


function TripleOptionElement:setElementsByName()

    TripleOptionElement:superClass().setElementsByName(self)

    for _, element in pairs(self.elements) do

        if element.name == "slider" then
            self.sliderElement = element
            element.target = self
            element:updateAbsolutePosition()
        end

        if element.name == "middle" then

			if self.middleButtonElement ~= nil and self.middleButtonElement ~= element then self.middleButtonElement:delete() end

			self.middleButtonElement = element
			element.target = self
			element:setHandleFocus(false)
			element:setCallback("onClickCallback", "onMiddleButtonClicked")
			element:setDisabled(self.disabled)
			element:setVisible(not self.hideLeftRightButtons)
        
        end

    end

    if self.sliderElement == nil then
        Logging.warning("TripleOptionElement: could not find a slider element for element with profile " .. self.profile)
    end

    self.leftButtonElement:setSelected(true)
    self.leftButtonElement.getIsSelected = function() return self.state == TripleOptionElement.STATE_LEFT end
    self.leftButtonElement.getIsScrollingAllowed = function() return self:getIsFocused() or self:getIsHighlighted() end

    self.middleButtonElement.getIsSelected = function() return self.state == TripleOptionElement.STATE_MIDDLE end
    self.middleButtonElement.getIsScrollingAllowed = function() return self:getIsFocused() or self:getIsHighlighted() end

    self.rightButtonElement.getIsSelected = function() return self.state == TripleOptionElement.STATE_RIGHT end
    self.rightButtonElement.getIsScrollingAllowed = function() return self:getIsFocused() or self:getIsHighlighted() end

    self.sliderDelta = (self.absSize[1] - self.sliderElement.absSize[1]) / TripleOptionElement.NUM_SLIDER_STATES

end


function TripleOptionElement:addDefaultElements()

    TripleOptionElement:superClass().addDefaultElements(self)

    if self.autoAddDefaultElements then

        if self:getDescendantByName("slider") == nil then
            if self.defaultProfileSliderRound ~= nil then
                local baseElement = RoundCornerElement.new(self)
                baseElement.name = "slider"
                self:addElement(baseElement)
                baseElement:applyProfile(self.defaultProfileSliderRound)
            elseif self.defaultProfileSliderThreePart ~= nil then
                local baseElement = ThreePartBitmapElement.new(self)
                baseElement.name = "slider"
                self:addElement(baseElement)
                baseElement:applyProfile(self.defaultProfileSliderThreePart)
            elseif self.defaultProfileSlider ~= nil then
                local baseElement = BitmapElement.new(self)
                baseElement.name = "slider"
                self:addElement(baseElement)
                baseElement:applyProfile(self.defaultProfileSlider)
            end
        end

        
		if self:getDescendantByName("middle") == nil then
			local element = ButtonElement.new(self)
			element.name = "middle"
			self:addElement(element)
			element:applyProfile(self.defaultProfileButtonMiddle)
		end

    end

end


function TripleOptionElement:onGuiSetupFinished()

    TripleOptionElement:superClass().onGuiSetupFinished(self)

    if self.useYesNoTexts then
        self:setTexts({g_i18n:getText(TripleOptionElement.STRING_NO), g_i18n:getText(TripleOptionElement.STRING_ANY), g_i18n:getText(TripleOptionElement.STRING_YES)})
    else
        self:setTexts({g_i18n:getText(TripleOptionElement.STRING_OFF), g_i18n:getText(TripleOptionElement.STRING_ANY), g_i18n:getText(TripleOptionElement.STRING_ON)})
    end

    self.textElement:setVisible(false)

end


function TripleOptionElement:getIsChecked()

    return self.state == TripleOptionElement.STATE_RIGHT

end


function TripleOptionElement:setIsChecked(isChecked, skipAnimation, forceEvent)
    if isChecked then
        self:setState(TripleOptionElement.STATE_RIGHT, forceEvent)
    else
        self:setState(TripleOptionElement.STATE_LEFT, forceEvent)
    end

    self.skipAnimation = skipAnimation
end


function TripleOptionElement:getIsActiveNonRec()

    return self:getIsVisibleNonRec()

end


function TripleOptionElement:setTexts(texts)

    if #texts ~= 3 then
        Logging.warning("TripleOptionElement: called setTexts() with invalid number of texts, triple option requires exactly 3 texts")
        printCallstack()
    end

    TripleOptionElement:superClass().setTexts(self, texts)

    self.leftButtonElement:setText(texts[1])
    self.middleButtonElement:setText(texts[2])
    self.rightButtonElement:setText(texts[3])

end


function TripleOptionElement:update(dt)

    TripleOptionElement:superClass().update(self, dt)

    if self.sliderMovingDirection ~= 0 then

        if self.skipAnimation then
            self.sliderState = self.sliderMovingDirection > 0 and TripleOptionElement.NUM_SLIDER_STATES or 0
        else
            self.sliderState = self.sliderState + self.sliderMovingDirection
        end

        if self.sliderState <= 0 or self.sliderState >= TripleOptionElement.NUM_SLIDER_STATES or self.sliderState == (self.state - 1) * (TripleOptionElement.NUM_SLIDER_STATES / 2) then
            self.sliderMovingDirection = 0
        end

        self.sliderElement:setPosition(self.sliderDelta * self.sliderState)

    end

    self.skipAnimation = false

end


function TripleOptionElement:inputLeft()

    if self.sliderMovingDirection == 0 and (self:getIsFocused() or self.leftButtonElement:getIsPressed()) then
        self:onLeftButtonClicked()

        return true
    else
        return false
    end

end


function TripleOptionElement:inputRight()

    local middleButtonPressed = self.middleButtonElement:getIsPressed()
    local rightButtonPressed = self.rightButtonElement:getIsPressed()

    if self.sliderMovingDirection == 0 and (self:getIsFocused() or middleButtonPressed or rightButtonPressed) then

        if rightButtonPressed then
            self:onRightButtonClicked()
        elseif middleButtonPressed then
            self:onMiddleButtonClicked()
        end

        return true
    else
        return false
    end

end


function TripleOptionElement:setState(state, forceEvent, skipAnimation)

    if state ~= TripleOptionElement.STATE_LEFT and state ~= TripleOptionElement.STATE_MIDDLE and state ~= TripleOptionElement.STATE_RIGHT then
        Logging.warning("TripleOptionElement: invalid state input " .. state .. ", only 1, 2 and 3 allowed")
        return
    end

    if state == self.state then
        return
    end

    self.oldState = self.state

    state = math.clamp(state, TripleOptionElement.STATE_LEFT, TripleOptionElement.STATE_RIGHT)
    TripleOptionElement:superClass().setState(self, state, forceEvent)

    self:updateSelection()

    self.skipAnimation = skipAnimation

end


function TripleOptionElement:onRightButtonClicked()

    self:setSoundSuppressed(true)
    FocusManager:setFocus(self)
    self:setSoundSuppressed(false)

    if self:getCanChangeState() and self.state ~= TripleOptionElement.STATE_RIGHT then

        self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)

        self:setState(TripleOptionElement.STATE_RIGHT)

        self:updateContentElement()
        self:raiseClickCallback(false)
        self:notifyIndexChange(self.state, #self.texts)

    end

end


function TripleOptionElement:onMiddleButtonClicked()

    self:setSoundSuppressed(true)
    FocusManager:setFocus(self)
    self:setSoundSuppressed(false)

    if self:getCanChangeState() and self.state ~= TripleOptionElement.STATE_MIDDLE then

        self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)

        self:setState(TripleOptionElement.STATE_MIDDLE)

        self:updateContentElement()
        self:raiseClickCallback(false)
        self:notifyIndexChange(self.state, #self.texts)

    end

end


function TripleOptionElement:onLeftButtonClicked()

    self:setSoundSuppressed(true)
    FocusManager:setFocus(self)
    self:setSoundSuppressed(false)

    if self:getCanChangeState() and self.state ~= TripleOptionElement.STATE_LEFT then

        self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)

        self:setState(TripleOptionElement.STATE_LEFT)

        self:updateContentElement()
        self:raiseClickCallback(true)
        self:notifyIndexChange(self.state, #self.texts)

    end

end


function TripleOptionElement:updateSelection()

    self.leftButtonElement:setSelected(self.state == TripleOptionElement.STATE_LEFT)
    self.middleButtonElement:setSelected(self.state == TripleOptionElement.STATE_MIDDLE)
    self.rightButtonElement:setSelected(self.state == TripleOptionElement.STATE_RIGHT)

    self.sliderMovingDirection = self.oldState > self.state and -1 or 1

end