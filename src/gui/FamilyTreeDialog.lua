FamilyTreeDialog = {}


local FamilyTreeDialog_mt = Class(FamilyTreeDialog, MessageDialog)
local modDirectory = g_currentModDirectory


function FamilyTreeDialog.register()

    local dialog = FamilyTreeDialog.new()
    g_gui:loadGui(modDirectory .. "gui/FamilyTreeDialog.xml", "FamilyTreeDialog", dialog)
    FamilyTreeDialog.INSTANCE = dialog

end


function FamilyTreeDialog.new(target, customMt)

    local self = MessageDialog.new(target, customMt or FamilyTreeDialog_mt)

    return self

end


function FamilyTreeDialog.createFromExistingGui(gui)

    FamilyTreeDialog.register()
    FamilyTreeDialog.show()

end


function FamilyTreeDialog.show(animal)

    if FamilyTreeDialog.INSTANCE == nil then FamilyTreeDialog.register() end

    local dialog = FamilyTreeDialog.INSTANCE
    dialog:setFamilyTreeFromAnimal(animal)

    g_gui:showDialog("FamilyTreeDialog")

end


function FamilyTreeDialog:onClickOk()

    self:close()

end


function FamilyTreeDialog:onOpen()

    FamilyTreeDialog:superClass().onOpen(self)

end


function FamilyTreeDialog:setFamilyTreeFromAnimal(animal)

   self.tree = g_familyTreeManager:getFamilyTreeFromAnimal(animal)
   self.focusedGeneration = animal:getMotherFamilyTreeGeneration()
   self.layout:resetLayout()

end


function FamilyTreeDialog:getNumOfGenerations()

    return self.tree:getNumOfGenerations()

end


function FamilyTreeDialog:getNumOfItemsInGeneration(generation)

    return self.tree:getNumOfAnimalsInGeneration(generation)

end


function FamilyTreeDialog:getDataForCellInGeneration(generation, index)

    local animal = self.tree:getMemberByGeneration(generation, index)
    local data = {
        ["image"] = animal:getImage(),
        ["id"] = animal:getId(),
        ["index"] = index,
        ["age"] = animal:getAge(),
        ["mother"] = animal:getMother(),
        ["father"] = animal:getFather(),
        ["children"] = animal:getChildren()
    }

    return data

end