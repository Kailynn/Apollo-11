-- Simulation minimale de l'API WoW pour tester MetierFacile hors du jeu.
-- Utilisée par tests/run_tests.lua (Lua 5.1, comme le client WoW).

local M = { timers = {}, printed = {}, bags = {}, open = nil }
_G.MOCK = M

function wipe(t) for k in pairs(t) do t[k] = nil end return t end
function strtrim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
function tinsert(t, v) table.insert(t, v) end
function print(...) local parts = {} for i = 1, select("#", ...) do parts[#parts + 1] = tostring(select(i, ...)) end M.printed[#M.printed + 1] = table.concat(parts, " ") end
function GetLocale() return M.locale or "frFR" end
function InCombatLockdown() return false end
function geterrorhandler() return function(err) error(err, 0) end end
function GetMoneyString(c) return c .. "c" end
UISpecialFrames = {}
SlashCmdList = {}
Enum = { CraftingReagentType = { Modifying = 0, Basic = 1, Finishing = 2 } }
ITEM_QUALITY_COLORS = { [1] = { hex = "|cffffffff" } }

-- Timers : exécutés manuellement par M.Flush()
C_Timer = {}
function C_Timer.After(_, fn) M.timers[#M.timers + 1] = fn end
function C_Timer.NewTicker(_, fn)
	local ticker = { cancelled = false }
	function ticker:Cancel() self.cancelled = true end
	local function tick()
		if ticker.cancelled then return end
		fn()
		if not ticker.cancelled then M.timers[#M.timers + 1] = tick end
	end
	M.timers[#M.timers + 1] = tick
	return ticker
end
function M.Flush(limit)
	limit = limit or 100000
	local n = 0
	while #M.timers > 0 and n < limit do
		local fn = table.remove(M.timers, 1)
		fn()
		n = n + 1
	end
	return n
end

-- Cadres : objets factices qui acceptent toutes les méthodes.
local FrameMT = {}
FrameMT.__index = function(self, key)
	if key == "TitleText" or key == "text" then
		local fs = setmetatable({}, FrameMT)
		rawset(self, key, fs)
		return fs
	end
	return function(obj, ...)
		if key == "SetScript" then rawset(obj, "_scripts", rawget(obj, "_scripts") or {}); obj._scripts[select(1, ...)] = select(2, ...) end
		if key == "RegisterEvent" then M.events = M.events or {}; M.events[select(1, ...)] = obj end
		if key == "SetText" then rawset(obj, "_text", select(1, ...)) end
		if key == "Show" then rawset(obj, "_shown", true) end
		if key == "Hide" then rawset(obj, "_shown", false) end
		if key == "SetShown" then rawset(obj, "_shown", select(1, ...) and true or false) end
		if key == "IsShown" then return rawget(obj, "_shown") end
		if key == "GetChecked" then return rawget(obj, "_checked") end
		if key == "SetChecked" then rawset(obj, "_checked", select(1, ...)) end
		if key == "GetStringHeight" then return 100 end
		if key == "CreateFontString" or key == "CreateTexture" then return setmetatable({}, FrameMT) end
		return nil
	end
end
function CreateFrame() return setmetatable({}, FrameMT) end
UIParent = CreateFrame()
GameTooltip = CreateFrame()
GameTooltip_Hide = function() end
EventUtil = { ContinueOnAddOnLoaded = function() end }

function M.Fire(event, ...)
	local frame = M.events and M.events[event]
	if frame and frame._scripts and frame._scripts.OnEvent then
		frame._scripts.OnEvent(frame, event, ...)
	end
end

-- Objets
M.items = {}
C_Item = {}
function C_Item.GetItemCount(id) return M.bags[id] or 0 end
function C_Item.GetItemNameByID(id) return M.items[id] or ("Item" .. id) end
function C_Item.GetItemIconByID() return 134400 end
function C_Item.GetItemQualityByID() return 1 end
function C_Item.GetItemInfo(id) return M.items[id], "[" .. (M.items[id] or id) .. "]" end
function C_Item.RequestLoadItemDataByID() end

-- Métiers du personnage : { {skillLine=171, name="Alchimie", skill=.., max=..} }
M.professions = {}
function GetProfessions()
	local r = {}
	for i = 1, #M.professions do r[i] = i end
	return r[1], r[2], nil, r[3], r[4]
end
function GetProfessionInfo(index)
	local p = M.professions[index]
	return p.name, 1, p.skill, p.max, 0, 0, p.skillLine
end

-- Recettes : M.recipes[recipeID] = { parent=171, child=2485, out=118, q=1, reagents={{qty, id...}}, learned=true, difficulty=0, numSkillUps=1, firstCraft=false }
-- Paliers : M.children[parent] = { {professionID=..., expansionName=..., skillLevel=..., maxSkillLevel=...}, ... } (récent -> ancien)
M.recipes, M.children = {}, {}
C_TradeSkillUI = {}
function C_TradeSkillUI.IsTradeSkillReady() return M.open ~= nil end
function C_TradeSkillUI.IsTradeSkillLinked() return false end
function C_TradeSkillUI.IsTradeSkillGuild() return false end
function C_TradeSkillUI.IsNPCCrafting() return false end
function C_TradeSkillUI.GetBaseProfessionInfo() return { professionID = M.open } end
function C_TradeSkillUI.GetChildProfessionInfo() return { professionID = 0 } end
function C_TradeSkillUI.GetChildProfessionInfos() return M.children[M.open] or {} end
function C_TradeSkillUI.OpenTradeSkill(id) M.open = id; M.Fire("TRADE_SKILL_SHOW") return true end
function C_TradeSkillUI.CloseTradeSkill() M.open = nil end
function C_TradeSkillUI.GetAllRecipeIDs()
	local ids = {}
	for id, r in pairs(M.recipes) do if r.parent == M.open then ids[#ids + 1] = id end end
	table.sort(ids)
	return ids
end
function C_TradeSkillUI.GetRecipeInfo(id)
	local r = M.recipes[id]
	if not r then return nil end
	return {
		recipeID = id, learned = r.learned ~= false, disabled = false,
		relativeDifficulty = r.difficulty or 0, numSkillUps = r.numSkillUps or 1,
		canSkillUp = (r.difficulty or 0) < 3, firstCraft = r.firstCraft or false,
		qualityItemIDs = r.qualities,
	}
end
function C_TradeSkillUI.GetProfessionInfoByRecipeID(id)
	local r = M.recipes[id]
	return { professionID = r and r.child or 0 }
end
function C_TradeSkillUI.IsRecipeInSkillLine(id, child) return M.recipes[id] and M.recipes[id].child == child end
function C_TradeSkillUI.GetRecipeSchematic(id)
	local r = M.recipes[id]
	if not r then error("bad recipe") end
	local slots = {}
	for _, reagent in ipairs(r.reagents) do
		local list = {}
		for i = 2, #reagent do list[#list + 1] = { itemID = reagent[i] } end
		slots[#slots + 1] = { reagentType = 1, required = true, quantityRequired = reagent[1], reagents = list }
	end
	-- un emplacement optionnel qui doit être ignoré
	slots[#slots + 1] = { reagentType = 0, required = false, quantityRequired = 1, reagents = { { itemID = 99999 } } }
	return { recipeID = id, name = r.name or ("Recipe" .. id), outputItemID = r.out, quantityMin = r.q or 1, reagentSlotSchematics = slots }
end

return M
