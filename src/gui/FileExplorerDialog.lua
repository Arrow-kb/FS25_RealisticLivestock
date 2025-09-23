FileExplorerDialog = {}


local modDirectory = g_currentModDirectory
local FileExplorerDialog_mt = Class(FileExplorerDialog, MessageDialog)


function FileExplorerDialog.register()

	local dialog = FileExplorerDialog.new()
	g_gui:loadGui(modDirectory .. "gui/FileExplorerDialog.xml", "FileExplorerDialog", dialog)
	FileExplorerDialog.INSTANCE = dialog

end


function FileExplorerDialog.show(files, baseDirectory, callback, target)

    if FileExplorerDialog.INSTANCE ~= nil then

        FileExplorerDialog.INSTANCE.files = files or {}
        FileExplorerDialog.INSTANCE.baseDirectory = baseDirectory or ""
        FileExplorerDialog.INSTANCE.callback = callback
        FileExplorerDialog.INSTANCE.target = target
        g_gui:showDialog("FileExplorerDialog")

    end

end


function FileExplorerDialog.new(target, customMt)

    local self = MessageDialog.new(target, customMt or FileExplorerDialog_mt)

    self.files = {}
    self.baseDirectory = ""
    self.currentFolder = {}
    self.currentFolderPath = {}
    self.resizeData = {
        ["active"] = false,
        ["maximise"] = false,
        ["delta"] = { 0, 0 }
    }

    return self

end


function FileExplorerDialog.createFromExistingGui(gui, _)

    FileExplorerDialog.register()
    FileExplorerDialog.show(gui.files)

end


function FileExplorerDialog:onGuiSetupFinished()

    FileExplorerDialog:superClass().onGuiSetupFinished(self)

    self.windowSize = {
        self.dialogElement.size[1],
        self.dialogElement.size[2]
    }

    local sum = self.windowSize[1] + self.windowSize[2]

    self.resizeData.delta = { (self.windowSize[2] / sum) * 0.01, (self.windowSize[1] / sum) * 0.01 }
    self.cellSize = self.windowSize[1] * 0.95
    self.fileListOffset = g_currentMission.hud.gameInfoDisplay:scalePixelToScreenHeight("-30")

end


function FileExplorerDialog:onOpen()

    FileExplorerDialog:superClass().onOpen(self)

    self.currentFolder = self.files[1]
    
    self.currentFolderPath = {
        1
    }
    
    self.pathText:setText(self.currentFolder.path)
    self.fileList:reloadData()

end


function FileExplorerDialog:onClose()

    FileExplorerDialog:superClass().onClose(self)

end


function FileExplorerDialog:onClickCancel()

    self:close()

end


function FileExplorerDialog:onClickOk()

    self:close()

    local file = self.currentFolder.files[self.fileList.selectedIndex - #self.currentFolder.folders]

    if file == nil then return end

    local name = file.name
    local valid = file.valid

    if name ~= nil and self.callback ~= nil and valid then

        if self.target ~= nil then
            self.callback(self.target, self.currentFolder.path .. "/" .. name)
        else
            self.callback(self.currentFolder.path .. "/" .. name)
        end

    end

end


function FileExplorerDialog:onClickResize()

    self.resizeData.active = true
    self.resizeData.maximise = not self.resizeData.maximise

end


function FileExplorerDialog:update(dT)

    FileExplorerDialog:superClass().update(self, dT)

    if self.resizeData.active then

        local data = self.resizeData

        self.dialogElement:setSize(self.dialogElement.size[1] + data.delta[1] * (data.maximise and 1 or -1), self.dialogElement.size[2] + data.delta[2] * (data.maximise and 1 or -1))

        local size = self.dialogElement.size

        if not data.maximise then
        
            if size[1] <= self.windowSize[1] and size[2] <= self.windowSize[2] then data.active = false end

        else
                    
            if size[1] >= 0.9 and size[2] >= 0.9 then data.active = false end

        end

        self.fileList:setSize(size[1] * 0.95, self.fileListSlider.size[2] - self.topPanel.size[2] + self.fileListOffset)
        self.pathText:setSize(size[1] * 0.7275)

        self.cellSize = size[1] * 0.95

        for _, cell in pairs(self.fileList.elements) do cell:setSize(self.cellSize) end

        self.fileList:updateView(true)

    end

end


function FileExplorerDialog:onClickPathUp()

    self.upButton:onFocusLeave()

    if #self.currentFolderPath <= 1 then return end

    self.currentFolder = self.files[1]

    for i = 2, #self.currentFolderPath - 1 do

        self.currentFolder = self.currentFolder.folders[self.currentFolderPath[i]]

    end

    table.remove(self.currentFolderPath, #self.currentFolderPath)

    self.pathText:setText(self.currentFolder.path)
    self.fileList:reloadData()

end


function FileExplorerDialog:getNumberOfSections()

	if self.currentFolder == nil or (#self.currentFolder.folders == 0 and #self.currentFolder.files == 0) then return 0 end

	return 1

end


function FileExplorerDialog:getNumberOfItemsInSection(list, section)

	return self.currentFolder == nil and 0 or (#self.currentFolder.folders + #self.currentFolder.files)

end


function FileExplorerDialog:getTitleForSectionHeader(list, section)

    return ""

end


function FileExplorerDialog:populateCellForItemInSection(list, section, index, cell)

    if index <= #self.currentFolder.folders then

        local folder = self.currentFolder.folders[index]

	    cell:getAttribute("name"):setText(folder.name)
        cell:getAttribute("icon"):setImageSlice(nil, "fileTypeIcons.folder")

        cell:setDisabled(g_server == nil or g_server.netIsRunning)

        if g_server == nil or g_server.netIsRunning then

            cell.onClickCallback = function() end

        else

            cell.onClickCallback = function()

                self.currentFolder = folder
                table.insert(self.currentFolderPath, index)

                self.pathText:setText(folder.path)

                self.fileList:reloadData()

            end

        end

    else

        local name = self.currentFolder.files[index - #self.currentFolder.folders].name
        local extension = string.sub(name, #name - 2)

        local valid = ""

        if not self.currentFolder.files[index - #self.currentFolder.folders].valid then

            valid = " - " .. g_i18n:getText("cl_invalidFile")

            cell:setDisabled(true)

        else

            cell:setDisabled(false)

        end

        cell:getAttribute("name"):setText(name .. valid)
        cell:getAttribute("icon"):setImageSlice(nil, "fileTypeIcons." .. extension)

        cell.onClickCallback = function() end

    end

    cell:setSize(self.cellSize)

end