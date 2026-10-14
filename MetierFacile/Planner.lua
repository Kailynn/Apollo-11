local ADDON, ns = ...
local L = ns.L

local MAX_EXPAND_DEPTH = 3
local GAIN_BY_DIFFICULTY = { [0] = 1, [1] = 0.65, [2] = 0.3, [3] = 0 } -- orange, jaune, vert, gris

---------------------------------------------------------------------------
-- Données utilitaires
---------------------------------------------------------------------------

function ns.OwnedCount(itemID)
	-- Sacs + banque + banque de composants + banque de bataillon
	return C_Item.GetItemCount(itemID, true, false, true, true) or 0
end

-- Prix à l'hôtel des ventes si Auctionator ou TSM est installé (en pièces de cuivre).
function ns.GetPrice(itemID)
	if Auctionator and Auctionator.API and Auctionator.API.v1 then
		local ok, price = pcall(Auctionator.API.v1.GetAuctionPriceByItemID, ADDON, itemID)
		if ok and price then return price end
	end
	if TSM_API and TSM_API.GetCustomPriceValue then
		local ok, price = pcall(TSM_API.GetCustomPriceValue, "dbminbuyout", "i:" .. itemID)
		if ok and price then return price end
	end
	return nil
end

function ns.GetRecipeData(recipeID)
	return ns.db.recipes[recipeID] or ns.CacheRecipe(recipeID)
end

function ns.ResolveStep(parentID, step)
	if step.recipe then
		return ns.GetRecipeData(step.recipe) and step.recipe or nil
	end
	local map = ns.db.byItem[parentID]
	return map and step.item and map[step.item] or nil
end

function ns.GetGuide(parentID, expIndex)
	local def = ns.PROFESSIONS[parentID]
	local guides = def and ns.Guides[def.key]
	return guides and guides[ns.ExpansionKey(expIndex)]
end

local function GetChild(parentID, expIndex)
	local prof = ns.char.professions[parentID]
	return prof and prof.children[expIndex]
end

-- Nombre d'expansions connues pour ce métier (scan ou, à défaut, toutes).
function ns.GetExpansionCount(parentID)
	local prof = ns.char.professions[parentID]
	local n = 0
	if prof then
		for index in pairs(prof.children) do
			n = math.max(n, index)
		end
	end
	return n > 0 and n or #ns.EXPANSIONS
end

---------------------------------------------------------------------------
-- Liste d'achats : simule la consommation du stock étape par étape.
-- Les produits des étapes précédentes (ex. rouleaux d'étoffe) alimentent
-- les étapes suivantes ; un composant manquant que le métier sait fabriquer
-- est remplacé par ses propres composants (option « intermédiaires »).
---------------------------------------------------------------------------

function ns.ComputeShopping(parentID, entries)
	local pool, ownedUsed, buy, craft = {}, {}, {}, {}
	local order = {}
	local expand = ns.db.settings.expand
	local map = ns.db.byItem[parentID] or {}

	local function Available(itemID)
		if pool[itemID] == nil then
			pool[itemID] = ns.OwnedCount(itemID)
		end
		return pool[itemID]
	end

	local Consume
	Consume = function(variants, qty, depth)
		-- Le stock de toutes les qualités d'un composant compte.
		for _, itemID in ipairs(variants) do
			if qty <= 0 then break end
			local take = math.min(Available(itemID), qty)
			if take > 0 then
				pool[itemID] = pool[itemID] - take
				qty = qty - take
				ownedUsed[itemID] = (ownedUsed[itemID] or 0) + take
			end
		end
		if qty <= 0 then return end

		local itemID = variants[1]
		local subRecipe = expand and depth < MAX_EXPAND_DEPTH and map[itemID]
		local sub = subRecipe and ns.char.learned[subRecipe] and ns.GetRecipeData(subRecipe)
		if sub and #sub.r > 0 then
			local count = math.ceil(qty / sub.q)
			if not craft[subRecipe] then
				craft[subRecipe] = 0
				order[#order + 1] = subRecipe
			end
			craft[subRecipe] = craft[subRecipe] + count
			for _, reagent in ipairs(sub.r) do
				Consume({ select(2, unpack(reagent)) }, reagent[1] * count, depth + 1)
			end
			pool[itemID] = Available(itemID) + count * sub.q - qty
		else
			buy[itemID] = (buy[itemID] or 0) + qty
		end
	end

	for _, entry in ipairs(entries) do
		local data = entry.recipeID and ns.GetRecipeData(entry.recipeID)
		if data and entry.crafts > 0 then
			for _, reagent in ipairs(data.r) do
				Consume({ select(2, unpack(reagent)) }, reagent[1] * entry.crafts, 0)
			end
			if data.o then
				pool[data.o] = Available(data.o) + entry.crafts * data.q
			end
		end
	end

	local list, totalCost, missingPrice = {}, 0, false
	for itemID, qty in pairs(buy) do
		local price = ns.GetPrice(itemID)
		if price then
			totalCost = totalCost + price * qty
		else
			missingPrice = true
		end
		list[#list + 1] = {
			itemID = itemID,
			qty = qty,
			owned = ownedUsed[itemID] or 0,
			vendor = ns.VENDOR_ITEMS[itemID],
			price = price,
		}
	end
	table.sort(list, function(a, b)
		if (a.vendor and 1 or 0) ~= (b.vendor and 1 or 0) then
			return not a.vendor
		end
		return a.itemID < b.itemID
	end)

	local intermediates = {}
	for _, recipeID in ipairs(order) do
		intermediates[#intermediates + 1] = { recipeID = recipeID, crafts = craft[recipeID] }
	end

	return {
		buy = list,
		intermediates = intermediates,
		totalCost = totalCost > 0 and totalCost or nil,
		missingPrice = missingPrice,
	}
end

---------------------------------------------------------------------------
-- Plan basé sur un guide intégré
---------------------------------------------------------------------------

function ns.RemainingCrafts(step, skill)
	if skill >= step.to then return 0 end
	if skill <= step.from then return step.crafts end
	return math.ceil(step.crafts * (step.to - skill) / (step.to - step.from))
end

local function BuildGuidePlan(parentID, expIndex, guide)
	local child = GetChild(parentID, expIndex)
	local skill = child and child.skill or 0
	local plan = {
		source = "guide",
		parentID = parentID,
		expIndex = expIndex,
		skill = skill,
		max = child and child.max > 0 and child.max or guide.max,
		scanned = child ~= nil,
		steps = {},
		entries = {},
	}
	for _, step in ipairs(guide.steps) do
		local crafts = ns.RemainingCrafts(step, skill)
		if crafts > 0 then
			local recipeID = ns.ResolveStep(parentID, step)
			local row = {
				step = step,
				recipeID = recipeID,
				crafts = crafts,
				learned = recipeID and ns.char.learned[recipeID] or false,
			}
			plan.steps[#plan.steps + 1] = row
			if recipeID then
				plan.entries[#plan.entries + 1] = { recipeID = recipeID, crafts = crafts }
			else
				plan.unresolved = (plan.unresolved or 0) + 1
			end
		end
	end
	plan.done = #plan.steps == 0
	return plan
end

---------------------------------------------------------------------------
-- Plan automatique (aucun guide) : basé sur les recettes connues et leur
-- couleur actuelle, lues en direct dans la fenêtre du métier.
---------------------------------------------------------------------------

local function ReagentWeight(data)
	local cost, items, priced = 0, 0, true
	for _, reagent in ipairs(data.r) do
		local qty = reagent[1]
		items = items + qty
		local price = ns.GetPrice(reagent[2])
		if price then
			cost = cost + price * qty
		else
			priced = false
		end
	end
	return priced and cost or items, items
end

local function IsProfessionOpen(parentID)
	if not C_TradeSkillUI.IsTradeSkillReady() or C_TradeSkillUI.IsTradeSkillLinked() then return false end
	local base = C_TradeSkillUI.GetBaseProfessionInfo()
	return base and base.professionID == parentID
end

local function BuildAutoPlan(parentID, expIndex)
	local child = GetChild(parentID, expIndex)
	local plan = {
		source = "auto",
		parentID = parentID,
		expIndex = expIndex,
		skill = child and child.skill or 0,
		max = child and child.max or 0,
		scanned = child ~= nil,
		live = IsProfessionOpen(parentID),
		firstCrafts = {},
		best = {},
		entries = {},
	}
	if child and child.max > 0 and child.skill >= child.max then
		plan.done = true
		return plan
	end
	if not plan.live then
		return plan
	end

	local remaining = math.max(plan.max - plan.skill, 0)
	for recipeID, data in pairs(ns.db.recipes) do
		if data.p == parentID and data.e == expIndex and ns.char.learned[recipeID] and #data.r > 0 then
			local info = C_TradeSkillUI.GetRecipeInfo(recipeID)
			if info and info.learned and not info.disabled then
				local weight, items = ReagentWeight(data)
				if info.firstCraft then
					plan.firstCrafts[#plan.firstCrafts + 1] = { recipeID = recipeID, crafts = 1, items = items }
				end
				local gain = info.canSkillUp and (GAIN_BY_DIFFICULTY[info.relativeDifficulty or 3] or 0) or 0
				if gain > 0 and info.relativeDifficulty == 0 then
					gain = math.max(info.numSkillUps or 1, 1)
				end
				if gain > 0 then
					plan.best[#plan.best + 1] = {
						recipeID = recipeID,
						gain = gain,
						ratio = weight / gain,
						perPoint = items / gain,
						difficulty = info.relativeDifficulty,
					}
				end
			end
		end
	end
	table.sort(plan.best, function(a, b) return a.ratio < b.ratio end)
	for i = #plan.best, 6, -1 do
		plan.best[i] = nil
	end

	for _, first in ipairs(plan.firstCrafts) do
		plan.entries[#plan.entries + 1] = first
	end
	local top = plan.best[1]
	if top and remaining > 0 then
		top.crafts = math.ceil(remaining / top.gain)
		plan.entries[#plan.entries + 1] = { recipeID = top.recipeID, crafts = top.crafts }
	end
	plan.empty = #plan.best == 0 and #plan.firstCrafts == 0
	return plan
end

---------------------------------------------------------------------------
-- Point d'entrée
---------------------------------------------------------------------------

-- expIndex = "all" agrège toutes les extensions disposant d'un guide.
function ns.BuildPlan(parentID, expIndex)
	local def = ns.PROFESSIONS[parentID]
	if not def then return nil end

	if def.gathering then
		local tips = ns.Gathering[def.key]
		return {
			source = "gathering",
			parentID = parentID,
			expIndex = expIndex,
			tips = tips and expIndex ~= "all" and tips[ns.ExpansionKey(expIndex)] or nil,
			child = expIndex ~= "all" and GetChild(parentID, expIndex) or nil,
		}
	end

	local plan
	if expIndex == "all" then
		plan = { source = "all", parentID = parentID, expIndex = "all", parts = {}, entries = {} }
		for index = 1, ns.GetExpansionCount(parentID) do
			local guide = ns.GetGuide(parentID, index)
			if guide then
				local part = BuildGuidePlan(parentID, index, guide)
				if not part.done then
					plan.parts[#plan.parts + 1] = part
					for _, entry in ipairs(part.entries) do
						plan.entries[#plan.entries + 1] = entry
					end
					if part.unresolved then
						plan.unresolved = (plan.unresolved or 0) + part.unresolved
					end
				end
			end
		end
	else
		local guide = ns.GetGuide(parentID, expIndex)
		plan = guide and BuildGuidePlan(parentID, expIndex, guide) or BuildAutoPlan(parentID, expIndex)
	end
	plan.shopping = ns.ComputeShopping(parentID, plan.entries)
	plan.shopping.unresolved = plan.unresolved
	return plan
end
