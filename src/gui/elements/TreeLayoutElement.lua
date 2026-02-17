TreeLayoutElement = {}

local TreeLayoutElement_mt = Class(TreeLayoutElement, GuiElement)

Gui.registerGuiElement("TreeLayout", TreeLayoutElement)
Gui.registerGuiElementProcFunction("TreeLayout", Gui.assignPlaySampleCallback)


function TreeLayoutElement.new(target, customMt)

	local self = GuiElement.new(target, customMt or TreeLayoutElement_mt)

	self.cells = {}
	self.isMouseDown = false
	self.lastMousePosX, self.lastMousePosY = 0, 0
	self.horizontalDelta, self.verticalDelta = 0, 0
	self.lastHorizontalDelta, self.lastVerticalDelta = 0, 0
	self.mouseDownTime = 0
	self.contentOffsetX, self.contentOffsetY = 0.5, 0.5
	self.lines = {}
	
	return self

end


function TreeLayoutElement:loadFromXML(xmlFile, key)

	TreeLayoutElement:superClass().loadFromXML(self, xmlFile, key)

	self.sliderHorizontalId = getXMLString(xmlFile, key .. "#sliderHorizontal")
	self.sliderVerticalId = getXMLString(xmlFile, key .. "#sliderVertical")

end


function TreeLayoutElement:onGuiSetupFinished()

	TreeLayoutElement:superClass().onGuiSetupFinished(self)

	if self.target[self.sliderHorizontalId] ~= nil then self.sliderHorizontal = self.target[self.sliderHorizontalId] end
	if self.target[self.sliderVerticalId] ~= nil then self.sliderVertical = self.target[self.sliderVerticalId] end

end


function TreeLayoutElement:resetLayout()

	self.cells = {}

	local numGenerations = self.target:getNumOfGenerations()

	for i = 1, numGenerations do

		local numCells = self.target:getNumOfItemsInGeneration(i)
		local generation = {}

		for j = 1, numCells do

			local data = self.target:getDataForCellInGeneration(i, j)

			table.insert(generation, data)

		end

		table.insert(self.cells, generation)

	end

	self:buildCells()

end


function TreeLayoutElement:buildCells()

	self.lines = {}

	for i = #self.elements, 2, -1 do
		self.elements[i]:delete()
		self.elements[i] = nil
	end

	local template = self.elements[1]
	local width, height = 1, #self.cells * 0.2 - 0.1
	local y = #self.cells * 0.2 - 0.1

	local function sortGeneration(a, b)

		if a.age == b.age then return a.index < b.index end

		return a.age > b.age

	end

	print("---")

	-- x coord needs to leave space (3 cells per generation) for each generation from the current gen to the last gen that leads back to the current gen
	-- for simplicity assume that all animals have 3 children
	-- use recursive function to loop through next generations

	-- the below centers the cells at +- 0.15 around the parent cell regardless of num children. width between cells should be as above. but x coord needs to take into account num children
	-- use a page system (left arrow / right arrow around children cells) to show next/previous 3 children
	-- use the same system for different fathers of mother's children

	-- different pages of children will surely result in different amounts of generations from current generation. so the x coord should take the width of the branch of the child with the widest possible branch.
	-- otherwise the entire tree will have to be revalidated every time the page is clicked. which is messy and costs performance.
	-- perhaps the number of generations shown at once should be limited to 10.

	for i, generation in pairs(self.cells) do

		table.sort(generation, sortGeneration)

		for j, cell in ipairs(generation) do

			local x = 0.5
			cell.visible, cell.displayedChildren = true, 0

			if cell.mother ~= nil and i ~= 1 then

				local motherId = cell.mother.id

				for _, pCell in ipairs(self.cells[i - 1]) do

					if pCell.id == motherId then

						if pCell.displayedChildren < 3 and pCell.visible then
							x = pCell.x + 0.15 * (pCell.displayedChildren - 1)

							if pCell.displayedChildren == 0 then self:addLine(pCell.x + 0.025, pCell.y, pCell.x + 0.025, pCell.y - 0.075) end

							pCell.displayedChildren = pCell.displayedChildren + 1
							self:addLine(pCell.x + 0.025, y + 0.125, x + 0.025, y + 0.125)
							self:addLine(x + 0.025, y + 0.125, x + 0.025, y + 0.075)
						else
							cell.visible = false
						end

						break

					end

				end

			end

			if not cell.visible then continue end

			print(string.format("%s = %.4f %.4f", cell.id, x, y))

			local item = template:clone(self)
			item:setVisible(true)
			item:setImageFilename(cell.image)
			item:setAbsolutePosition(x, y)
			cell.x, cell.y = x, y
			cell.element = item

		end

		y = y - 0.2

	end

	self.contentSize = { width, y }

	self.sliderHorizontal:setMinValue(1)
	self.sliderHorizontal:setMaxValue(width / self.absSize[1] * 20)
	self.sliderHorizontal:setSliderSize(self.absSize[1], width)
	self.sliderHorizontal.needsSlider = width >= 1

	self.sliderVertical:setMinValue(1)
	self.sliderVertical:setMaxValue(y / self.absSize[2] * 20)
	self.sliderVertical:setSliderSize(self.absSize[2], y)
	self.sliderVertical.needsSlider = y >= 1

end


function TreeLayoutElement:addLine(sx, sy, ex, ey)

	table.insert(self.lines, { sx, sy, ex, ey })

end


function TreeLayoutElement:onSliderValueChanged(slider, newValue)

	if slider.direction == SliderElement.DIRECTION_X then
		local value = (self.contentSize[1] - self.absSize[1]) / (slider.maxValue - slider.minValue) * (newValue - slider.minValue)
		self:scrollTo(value, self.absPosition[2], false)
	else
		local value = (self.contentSize[2] - self.absSize[2]) / (slider.maxValue - slider.minValue) * (newValue - slider.minValue)
		self:scrollTo(self.absPosition[1], value, false)
	end

end


function TreeLayoutElement:scrollTo(x, y, updateSlider)

	self:setAbsolutePosition(x, y)

	self.isMovingToTarget = false

	if updateSlider and self.sliderHorizontal ~= nil then
		local value = y / ((self.contentSize[1] - self.absSize[1]) / self.sliderHorizontal.maxValue)
		self.sliderHorizontal:setValue(value, true)
	end

	if updateSlider and self.sliderVertical ~= nil then
		local value = y / ((self.contentSize[2] - self.absSize[2]) / self.sliderVertical.maxValue)
		self.sliderVertical:setValue(value, true)
	end

end


function TreeLayoutElement:draw(clipX1, clipY1, clipX2, clipY2)

	for _, line in pairs(self.lines) do drawLine2D(line[1], line[2], line[3], line[4], 0.005, 0.05, 0.05, 0.05, 1) end

	TreeLayoutElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)

end


--function TreeLayoutElement:update(dt)

	--TreeLayoutElement:superClass().update(self, dt)

	--if self.isMovingToTarget then
		--local offset = nil

		--if self:getIsVisible() then
			--offset = self.firstVisibleY + (self.targetFirstVisibleY - self.firstVisibleY) * 0.01 * dt

			--if math.abs(self.targetFirstVisibleY - offset) < 0.0005 then
			--	self.isMovingToTarget = false
		--	end
		--else
		--	offset = self.targetFirstVisibleY
		--	self.isMovingToTarget = false
		--end

		--self:scrollTo(offset, false, true)
	--end

--end