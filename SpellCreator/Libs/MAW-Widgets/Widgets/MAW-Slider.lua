--[=[

    MindScape's AceGUI-3.0 Widgets
    * Slider with more User Friendly EditBox
    
    This Slider copies the default AceGUI-3.0 Slider Implementation but
    modifies the editbox to react to OnEditFocusLost instead of just
    OnEnterPressed. This comes as direct feedback from users mentioning
    that the standard editbox "didn't work", because they just typed something
    in and then hit "Okay" on the BlizzardInterfaceOptionsPanel, and their setting
    would not save. GG AceGUI, so user friendly.

--]=]

-- Create a new AceGUI widget type called ""
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
local Type = "MAW-Slider"
local Version = 1

-- Exit if a current or newer version is loaded.
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end


-- Constructor function for the custom slider
local function Constructor()
    local slider = AceGUI:Create("Slider") -- Create an instance of the AceGUI Slider widget
    
    -- Overwriting the editbox OnEditFocusLost to use the OnEnterPressed so mimic functionality and being more user friendly.
    local enterPressedScript = slider.editbox:GetScript("OnEnterPressed")
    slider.editbox:SetScript("OnEditFocusLost", enterPressedScript)
	slider.editbox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end) -- Override OnEnterPressed to fix a bug


    -- Register the custom widget type with AceGUI
    AceGUI:RegisterAsWidget(slider)
    return slider
end

-- Register the custom widget type with AceGUI
AceGUI:RegisterWidgetType(Type, Constructor, Version)