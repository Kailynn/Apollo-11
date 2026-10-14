local ADDON, ns = ...
local L = ns.L

ns.Guides = ns.Guides or {}      -- [profKey][expKey] = { steps = {...} }
ns.Gathering = ns.Gathering or {} -- [profKey][expKey] = { "zone", ... }

local DEFAULT_DB = {
	version = 1,
	recipes = {},  -- [recipeID] = { p = parentSkillLine, e = expIndex, o = outputItemID, q = quantity, r = { {qty, itemID, ...}, ... } }
	byItem = {},   -- [parentSkillLine][itemID] = recipeID
	settings = { expand = true },
}

local DEFAULT_CHAR = {
	professions = {}, -- [parentSkillLine] = { name, icon, skill, max, children = { [expIndex] = { id, name, skill, max } } }
	learned = {},     -- [recipeID] = true
}

local function ApplyDefaults(target, defaults)
	for k, v in pairs(defaults) do
		if target[k] == nil then
			target[k] = type(v) == "table" and ApplyDefaults({}, v) or v
		end
	end
	return target
end

function ns.Print(msg, ...)
	if select("#", ...) > 0 then
		msg = msg:format(...)
	end
	print("|cff33ccff" .. L.TITLE .. "|r " .. msg)
end

-- Rafraîchissement groupé de l'interface (évite de reconstruire 10 fois par seconde).
local refreshPending = false
function ns.RequestRefresh()
	if refreshPending then return end
	refreshPending = true
	C_Timer.After(0.2, function()
		refreshPending = false
		if ns.UI and ns.UI.Refresh then
			ns.UI:Refresh()
		end
	end)
end

local frame = CreateFrame("Frame")
ns.eventFrame = frame

local events = {}

function events.ADDON_LOADED(name)
	if name ~= ADDON then return end
	MetierFacileDB = ApplyDefaults(MetierFacileDB or {}, DEFAULT_DB)
	MetierFacileCharDB = ApplyDefaults(MetierFacileCharDB or {}, DEFAULT_CHAR)
	ns.db = MetierFacileDB
	ns.char = MetierFacileCharDB
	frame:UnregisterEvent("ADDON_LOADED")
end

function events.PLAYER_LOGIN()
	ns.ScanBaseProfessions()
	ns.Print(L.LOADED)
end

function events.SKILL_LINES_CHANGED()
	ns.ScanBaseProfessions()
	ns.RequestRefresh()
end

function events.TRADE_SKILL_SHOW()
	ns.OnTradeSkillChanged()
end

function events.TRADE_SKILL_LIST_UPDATE()
	ns.OnTradeSkillChanged()
end

function events.TRADE_SKILL_DATA_SOURCE_CHANGED()
	ns.OnTradeSkillChanged()
end

function events.BAG_UPDATE_DELAYED()
	ns.RequestRefresh()
end

function events.BANKFRAME_OPENED()
	ns.RequestRefresh()
end

function events.GET_ITEM_INFO_RECEIVED()
	ns.RequestRefresh()
end

frame:SetScript("OnEvent", function(_, event, ...)
	local handler = events[event]
	if handler then
		handler(...)
	end
end)
for event in pairs(events) do
	frame:RegisterEvent(event)
end

-- Commandes
SLASH_METIERFACILE1 = "/mf"
SLASH_METIERFACILE2 = "/metierfacile"
SlashCmdList.METIERFACILE = function(msg)
	local cmd = strtrim((msg or ""):lower())
	if cmd == "" then
		ns.UI:Toggle()
	elseif cmd == "scan" then
		ns.ScanAll()
	elseif cmd == "liste" or cmd == "list" then
		ns.UI:PrintSelectionToChat()
	elseif cmd == "verifier" or cmd == "vérifier" or cmd == "verify" then
		ns.VerifyGuides()
	elseif cmd == "reset" then
		wipe(MetierFacileDB)
		wipe(MetierFacileCharDB)
		ApplyDefaults(MetierFacileDB, DEFAULT_DB)
		ApplyDefaults(MetierFacileCharDB, DEFAULT_CHAR)
		ns.ScanBaseProfessions()
		ns.Print(L.RESET_DONE)
		ns.RequestRefresh()
	else
		ns.Print(L.HELP)
	end
end

function MetierFacile_OnAddonCompartmentClick()
	ns.UI:Toggle()
end
