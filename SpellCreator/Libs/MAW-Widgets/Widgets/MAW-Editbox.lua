--[=[

    MindScape's AceGUI-3.0 Widgets
    * Editbox with more User Friendly OnFocusLost
    
    This Editbox copies the default AceGUI-3.0 Editbox Implementation but
    modifies the editbox to react to OnEditFocusLost instead of just
    OnEnterPressed. This comes as direct feedback from users mentioning
    that the standard editbox "didn't work", because they just typed something
    in and then hit "Okay" on the BlizzardInterfaceOptionsPanel, and their setting
    would not save. GG AceGUI, so user friendly.

--]=]

-- Create a new AceGUI widget type
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
local Type = "MAW-Editbox"
local Version = 1

-- Exit if a current or newer version is loaded.
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end


-- Constructor function
local function Constructor()
    local object = AceGUI:Create("EditBox") -- Create an instance of the AceGUI widget
    
    -- Overwriting the editbox OnEditFocusLost to use the OnEnterPressed so mimic functionality and being more user friendly.
    local enterPressedScript = object.editbox:GetScript("OnEnterPressed")
    object.editbox:SetScript("OnEditFocusLost", enterPressedScript)
	object.editbox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end) -- Override OnEnterPressed to fix a bug


    -- Register the custom widget type with AceGUI
    AceGUI:RegisterAsWidget(object)
    return object
end

-- Register the custom widget type with AceGUI
AceGUI:RegisterWidgetType(Type, Constructor, Version)