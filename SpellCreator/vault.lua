---@class ns
local ns = select(2, ...)

ns.Vault = {
    phase = {
        isLoaded = false,
        isSavingOrLoadingAddonData = false,
        spells = {},
    },
}
