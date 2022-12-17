---@class ns
local ns = select(2, ...)

local Comms = ns.Comms
local Serializer = ns.Serializer

local cache = {}

local function addSpellToCache(spellData, charOrPhase)
	if not spellData or not charOrPhase then return end
	if not cache[charOrPhase] then cache[charOrPhase] = {} end
	cache[charOrPhase][spellData.commID] = spellData
end

local function getSpellFromCache(commID, charOrPhase)
	if not commID or not charOrPhase then return nil end
	if not cache[charOrPhase] then return nil end
	return cache[charOrPhase][commID] or nil
end

local function saveSpellFromCache(commId, charOrPhase)
	local spellData = getSpellFromCache(commId, charOrPhase)
	if not spellData then return end -- spell was not in the cache, we can add a requestSpellFromPlayer here if we want? Shouldn't really be possible tho.
	Comms.tryToSaveReceivedSpell(spellData, charOrPhase, ns.MainFuncs.updateSpellLoadRows)
end

---@class Utils_ChatLinkCache
ns.Utils.ChatLinkCache = {
	cache = cache,
	addSpellToCache = addSpellToCache,
	getSpellFromCache = getSpellFromCache,
	saveSpellFromCache = saveSpellFromCache,
}
