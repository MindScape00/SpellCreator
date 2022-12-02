---@class ns
local ns = select(2, ...)

ns.Vault = {
    ---@class PhaseVault
    ---@field spells table<CommID, VaultSpell>
    phase = {
        isLoaded = false,
        isSavingOrLoadingAddonData = false,
        spells = {},
    },
}
