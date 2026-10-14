local ADDON, ns = ...
local L = ns.L

local RECIPES_PER_FRAME = 150

---------------------------------------------------------------------------
-- 1. Métiers du personnage (fonctionne sans ouvrir aucune fenêtre)
---------------------------------------------------------------------------

function ns.ScanBaseProfessions()
	if not ns.char then return end
	local known = {}
	local indices = { GetProfessions() }
	for i = 1, 5 do
		local index = indices[i]
		if index then
			local name, icon, skill, maxSkill, _, _, skillLine = GetProfessionInfo(index)
			if skillLine and ns.PROFESSIONS[skillLine] and not ns.IGNORED_SKILL_LINES[skillLine] then
				local prof = ns.char.professions[skillLine] or { children = {} }
				prof.name, prof.icon = name, icon
				-- Niveau du palier le plus récent appris, mis à jour sans ouvrir le métier
				prof.skill, prof.max = skill, maxSkill
				ns.char.professions[skillLine] = prof
				known[skillLine] = true
			end
		end
	end
	-- Métiers désappris
	for skillLine in pairs(ns.char.professions) do
		if not known[skillLine] then
			ns.char.professions[skillLine] = nil
		end
	end
end

---------------------------------------------------------------------------
-- 2. Niveaux par extension (nécessite la fenêtre du métier ouverte)
---------------------------------------------------------------------------

local function IsOwnProfessionOpen()
	if not C_TradeSkillUI.IsTradeSkillReady() then return false end
	if C_TradeSkillUI.IsTradeSkillLinked() or C_TradeSkillUI.IsTradeSkillGuild() or C_TradeSkillUI.IsNPCCrafting() then
		return false
	end
	if C_TradeSkillUI.IsRuneforging and C_TradeSkillUI.IsRuneforging() then return false end
	local base = C_TradeSkillUI.GetBaseProfessionInfo()
	if not base or not base.professionID or not ns.PROFESSIONS[base.professionID] then
		return false
	end
	return true, base
end

-- Renvoie la table childID -> index d'extension pour le métier ouvert.
local function ScanChildren(parentID)
	local prof = ns.char.professions[parentID]
	if not prof then return {} end
	local infos = C_TradeSkillUI.GetChildProfessionInfos() or {}
	local n = #infos
	local childToExp = {}
	for i, info in ipairs(infos) do
		-- Liste triée du plus récent au plus ancien : le dernier est « Classique ».
		local expIndex = n - i + 1
		prof.children[expIndex] = {
			id = info.professionID,
			name = info.expansionName,
			profName = info.professionName,
			skill = info.skillLevel or 0,
			max = info.maxSkillLevel or 0,
			modifier = info.skillModifier or 0,
		}
		childToExp[info.professionID] = expIndex
	end
	prof.scanned = n > 0
	return childToExp
end

local function ExtractReagents(schematic)
	local reagents = {}
	local basic = Enum.CraftingReagentType and Enum.CraftingReagentType.Basic or 1
	for _, slot in ipairs(schematic.reagentSlotSchematics or {}) do
		if slot.reagentType == basic and slot.required ~= false and (slot.quantityRequired or 0) > 0 then
			local entry = { slot.quantityRequired }
			for _, reagent in ipairs(slot.reagents or {}) do
				if reagent.itemID then
					entry[#entry + 1] = reagent.itemID
				end
			end
			if #entry > 1 then
				reagents[#reagents + 1] = entry
			end
		end
	end
	return reagents
end

-- Met une recette en cache (données de jeu, communes à tous les personnages).
function ns.CacheRecipe(recipeID, parentID, expIndex)
	local ok, schematic = pcall(C_TradeSkillUI.GetRecipeSchematic, recipeID, false)
	if not ok or not schematic then return nil end
	local entry = ns.db.recipes[recipeID] or {}
	entry.p = parentID or entry.p
	entry.e = expIndex or entry.e
	entry.o = schematic.outputItemID
	entry.q = math.max(schematic.quantityMin or 1, 1)
	entry.r = ExtractReagents(schematic)
	ns.db.recipes[recipeID] = entry

	if parentID then
		local map = ns.db.byItem[parentID] or {}
		ns.db.byItem[parentID] = map
		if entry.o then
			map[entry.o] = map[entry.o] or recipeID
		end
		local info = C_TradeSkillUI.GetRecipeInfo(recipeID)
		if info and info.qualityItemIDs then
			for _, itemID in ipairs(info.qualityItemIDs) do
				map[itemID] = map[itemID] or recipeID
			end
		end
	end
	return entry
end

local scanJob -- coroutine du scan des recettes en cours

local function RecipeScanBody(parentID, childToExp, onDone)
	local ids = C_TradeSkillUI.GetAllRecipeIDs and C_TradeSkillUI.GetAllRecipeIDs() or C_TradeSkillUI.GetFilteredRecipeIDs()
	for i, recipeID in ipairs(ids or {}) do
		local info = C_TradeSkillUI.GetRecipeInfo(recipeID)
		if info then
			ns.char.learned[recipeID] = info.learned or nil
			local cached = ns.db.recipes[recipeID]
			if not cached or not cached.e or cached.p ~= parentID then
				local expIndex
				local pinfo = C_TradeSkillUI.GetProfessionInfoByRecipeID(recipeID)
				if pinfo and pinfo.professionID then
					expIndex = childToExp[pinfo.professionID]
				end
				if not expIndex then
					for childID, idx in pairs(childToExp) do
						if C_TradeSkillUI.IsRecipeInSkillLine(recipeID, childID) then
							expIndex = idx
							break
						end
					end
				end
				ns.CacheRecipe(recipeID, parentID, expIndex)
			end
		end
		if i % RECIPES_PER_FRAME == 0 then
			coroutine.yield()
		end
	end
	if onDone then onDone() end
end

local function RunJob(job)
	if scanJob ~= job then return end -- remplacé par un scan plus récent
	local ok, err = coroutine.resume(job)
	if not ok then
		scanJob = nil
		geterrorhandler()(err)
		return
	end
	if coroutine.status(job) == "dead" then
		if scanJob == job then scanJob = nil end
		ns.RequestRefresh()
	else
		C_Timer.After(0, function() RunJob(job) end)
	end
end

function ns.ScanRecipes(parentID, childToExp, onDone)
	local job = coroutine.create(function() RecipeScanBody(parentID, childToExp, onDone) end)
	scanJob = job
	RunJob(job)
end

function ns.IsScanning()
	return scanJob ~= nil
end

local pendingChange = false
function ns.OnTradeSkillChanged()
	if pendingChange or not ns.char then return end
	pendingChange = true
	C_Timer.After(0.3, function()
		pendingChange = false
		local ok, base = IsOwnProfessionOpen()
		if not ok then return end
		local childToExp = ScanChildren(base.professionID)
		ns.lastOpenParent = base.professionID
		if not scanJob and not ns.scanAllRunning then
			ns.ScanRecipes(base.professionID, childToExp)
		end
		ns.RequestRefresh()
	end)
end

---------------------------------------------------------------------------
-- 3. Scan automatique de tous les métiers (/mf scan)
---------------------------------------------------------------------------

function ns.ScanAll()
	if InCombatLockdown() then
		ns.Print(L.SCAN_COMBAT)
		return
	end
	if ns.scanAllRunning then return end
	local queue = {}
	for skillLine in pairs(ns.char.professions) do
		queue[#queue + 1] = skillLine
	end
	if #queue == 0 then
		ns.Print(L.NO_PROFESSION)
		return
	end
	ns.scanAllRunning = true
	ns.Print(L.SCAN_START)

	local function Finish()
		ns.scanAllRunning = false
		C_TradeSkillUI.CloseTradeSkill()
		local count = 0
		for _ in pairs(ns.db.recipes) do count = count + 1 end
		ns.Print(L.SCAN_DONE, #queue, count)
		ns.RequestRefresh()
	end

	local position = 0
	local function Next()
		position = position + 1
		local parentID = queue[position]
		if not parentID or InCombatLockdown() then
			Finish()
			return
		end
		C_TradeSkillUI.OpenTradeSkill(parentID)
		local waited = 0
		local ticker
		ticker = C_Timer.NewTicker(0.25, function()
			waited = waited + 0.25
			local ok, base = IsOwnProfessionOpen()
			if ok and base.professionID == parentID then
				ticker:Cancel()
				local childToExp = ScanChildren(parentID)
				ns.ScanRecipes(parentID, childToExp, function()
					C_Timer.After(0.1, Next)
				end)
			elseif waited >= 6 then
				ticker:Cancel()
				local prof = ns.char.professions[parentID]
				ns.Print(L.SCAN_TIMEOUT, prof and prof.name or tostring(parentID))
				Next()
			end
		end)
	end
	Next()
end

---------------------------------------------------------------------------
-- Vérification des guides intégrés contre les données du jeu
---------------------------------------------------------------------------

function ns.VerifyGuides()
	ns.Print(L.VERIFY_HEADER)
	for parentID, prof in pairs(ns.char.professions) do
		local def = ns.PROFESSIONS[parentID]
		local guides = def and ns.Guides[def.key]
		if guides then
			for expIndex, expKey in ipairs(ns.EXPANSIONS) do
				local guide = guides[expKey]
				if guide then
					local good = 0
					for i, step in ipairs(guide.steps) do
						if ns.ResolveStep(parentID, step) then
							good = good + 1
						else
							ns.Print(L.VERIFY_BAD, prof.name, ns.ExpansionLabel(expIndex), i, step.name or "?")
						end
					end
					ns.Print(L.VERIFY_OK, prof.name, ns.ExpansionLabel(expIndex), good)
				end
			end
		end
	end
end
