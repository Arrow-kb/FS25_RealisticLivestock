ProfileDialog = {}

local ProfileDialog_mt = Class(ProfileDialog, MessageDialog)
local modSettingsDirectory = g_currentModSettingsDirectory
local modDirectory = g_currentModDirectory


function ProfileDialog.register()

    local dialog = ProfileDialog.new()
    g_gui:loadGui(modDirectory .. "gui/ProfileDialog.xml", "ProfileDialog", dialog)
    ProfileDialog.INSTANCE = dialog

end


function ProfileDialog.show(context, manager, callback, target)
    
    if ProfileDialog.INSTANCE == nil then ProfileDialog.register() end

    local dialog = ProfileDialog.INSTANCE

    dialog.context = context or "save"
    dialog.manager = manager
    dialog.callback = callback
    dialog.target = target

    g_gui:showDialog("ProfileDialog")

end


function ProfileDialog.new(target, customMt)

    local self = MessageDialog.new(target, customMt or ProfileDialog_mt)

    self.context = "save"
    self.profiles = {}

    self:loadProfiles()
    
    return self

end


function ProfileDialog.createFromExistingGui(gui, _)

    ProfileDialog.register()
    ProfileDialog.show()

end


function ProfileDialog:loadProfiles()

    local xmlFile = XMLFile.loadIfExists("aiManagerProfiles", modSettingsDirectory .. "aiManagerProfiles.xml")

    if xmlFile == nil then return end

    xmlFile:iterate("profiles.profile", function(_, key)

        local name = xmlFile:getString(key .. "#profileName")
        local manager = AIAnimalManager.new()
        manager.isProfile = true
        manager:loadFromXMLFile(xmlFile, key)

        self.profiles[name] = manager

    end)

    xmlFile:delete()

end


function ProfileDialog:saveProfiles()

    local xmlFile = XMLFile.create("aiManagerProfiles", modSettingsDirectory .. "aiManagerProfiles.xml", "profiles")

    if xmlFile == nil then return end

    local i = 0

    for name, profile in pairs(self.profiles) do

        local key = string.format("profiles.profile(%s)", i)

        xmlFile:setString(key .. "#profileName", name)
        profile:saveToXMLFile(xmlFile, key)
        i = i + 1

    end

    xmlFile:save(false, true)
    xmlFile:delete()

end


function ProfileDialog.getProfiles()

    return ProfileDialog.INSTANCE.profiles

end


function ProfileDialog.getAmountOfProfiles()

    local profiles = ProfileDialog.INSTANCE.profiles

    if profiles == nil then return 0 end

    local i = 0

    for _, profile in pairs(profiles) do i = i + 1 end

    return i

end


function ProfileDialog.getHasProfiles()

    local profiles = ProfileDialog.INSTANCE.profiles

    if profiles == nil then return false end

    for name, profile in pairs(profiles) do return true end

    return false

end


function ProfileDialog:onOpen()

    ProfileDialog:superClass().onOpen(self)

    if self.context == "save" then

        self.saveContainer:setVisible(true)
        self.loadContainer:setVisible(false)

        self.saveButton:setVisible(true)
        self.loadButton:setVisible(false)

        self.buttonsPC:invalidateLayout()

        FocusManager:setFocus(self.saveProfileInput)

    end

    if self.context == "load" then

        self.saveContainer:setVisible(false)
        self.loadContainer:setVisible(true)

        self.saveButton:setVisible(false)
        self.loadButton:setVisible(true)

        self.buttonsPC:invalidateLayout()

        local texts = {}

        for name, profile in pairs(self.profiles) do

            table.insert(texts, name)

        end

        self.loadProfileSelector:setTexts(texts)
        self.loadProfileSelector:setState(1)
        self.profileIndexToName = texts

        FocusManager:setFocus(self.loadProfileSelector)

    end

end


function ProfileDialog:onClickSave()

    local name = self.saveProfileInput:getText()
    local profile = self.manager:createProfile()

    self.profiles[name] = profile
    self:saveProfiles()

    self:close()

    self.callback(self.target)

end


function ProfileDialog:onClickLoad()

    local profile = self.profiles[self.profileIndexToName[self.loadProfileSelector:getState()]]

    if profile ~= nil then self.manager:copyProfile(profile) end

    self:close()

    self.callback(self.target)

end