-- Tests hors jeu. Lancer depuis le dossier MetierFacile :
--   lua5.1 tests/run_tests.lua
-- (ou via python3 tests/run_tests.py si seul lupa est disponible)

local M = dofile("tests/wow_mock.lua")

local FILES = {
	"Locales.lua", "Constants.lua", "Core.lua", "Scanner.lua", "Planner.lua", "UI.lua",
	"Data/Guides_Classic.lua", "Data/Gathering.lua",
}

local ns = {}
for _, file in ipairs(FILES) do
	local chunk = assert(loadfile(file))
	chunk("MetierFacile", ns)
end

local failures, total = 0, 0
local function check(cond, label)
	total = total + 1
	if not cond then
		failures = failures + 1
		io.write("ÉCHEC : " .. label .. "\n")
	end
end
local function eq(a, b, label) check(a == b, label .. " (attendu " .. tostring(b) .. ", obtenu " .. tostring(a) .. ")") end

-- Vérifie que tous les fichiers listés dans le .toc existent et sont chargés ici
do
	local toc = io.open("MetierFacile.toc"):read("*a")
	local listed = 0
	for line in toc:gmatch("[^\r\n]+") do
		if line:match("%.lua$") then
			listed = listed + 1
			local path = line:gsub("\\", "/")
			local found = false
			for _, f in ipairs(FILES) do if f == path then found = true end end
			check(found, "fichier du .toc chargé par les tests : " .. path)
		end
	end
	eq(listed, #FILES, "nombre de fichiers dans le .toc")
end

-- Validation du format des guides
for profKey, guides in pairs(ns.Guides) do
	for expKey, guide in pairs(guides) do
		local last = 1
		for i, step in ipairs(guide.steps) do
			local label = profKey .. "." .. expKey .. " étape " .. i
			check(step.item or step.recipe, label .. " a un item ou une recette")
			check(step.from < step.to, label .. " from < to")
			eq(step.from, last, label .. " continue l'étape précédente")
			check(step.crafts >= (step.to - step.from) * 0.9, label .. " nombre de fabrications plausible")
			last = step.to
		end
		eq(last, guide.max, profKey .. "." .. expKey .. " atteint le max")
	end
end

---------------------------------------------------------------------------
-- Scénario : personnage couturier (classique 60/300) + mineur
---------------------------------------------------------------------------
M.professions = {
	{ skillLine = 197, name = "Couture", skill = 12, max = 100 },
	{ skillLine = 186, name = "Minage", skill = 5, max = 100 },
}
local children = {}
for i = 12, 1, -1 do
	children[#children + 1] = {
		professionID = 3000 + i,
		expansionName = "Exp" .. i,
		professionName = "Couture " .. i,
		skillLevel = (i == 1 and 60) or (i == 11 and 12) or 0,
		maxSkillLevel = (i == 1 and 300) or 100,
	}
end
M.children[197] = children

local LINEN, BOLT_LINEN, COARSE_THREAD, WOOL, BOLT_WOOL = 2589, 2996, 2320, 2592, 2997
M.recipes = {
	[101] = { parent = 197, child = 3001, out = BOLT_LINEN, reagents = { { 2, LINEN } } },
	[102] = { parent = 197, child = 3001, out = 4238, reagents = { { 3, BOLT_LINEN }, { 3, COARSE_THREAD } } },
	[103] = { parent = 197, child = 3001, out = 2580, reagents = { { 2, BOLT_LINEN }, { 3, COARSE_THREAD } }, learned = false },
	[104] = { parent = 197, child = 3001, out = BOLT_WOOL, reagents = { { 3, WOOL } } },
	-- Khaz Algar (index 11) : deux recettes, l'une orange, l'autre verte, une première fabrication
	[201] = { parent = 197, child = 3011, out = 5001, reagents = { { 4, 6001, 6002 } }, difficulty = 0, numSkillUps = 1 },
	[202] = { parent = 197, child = 3011, out = 5002, reagents = { { 2, 6001, 6002 } }, difficulty = 2 },
	[203] = { parent = 197, child = 3011, out = 5003, reagents = { { 10, 6003 } }, difficulty = 3, firstCraft = true },
}
M.bags = { [LINEN] = 10, [6002] = 5 }

M.Fire("ADDON_LOADED", "MetierFacile")
M.Fire("PLAYER_LOGIN")
eq(ns.char.professions[197].name, "Couture", "métier détecté sans fenêtre")
eq(ns.char.professions[197].skill, 12, "niveau global détecté")
eq(next(ns.char.professions[197].children), nil, "pas de paliers avant ouverture")

-- Sans scan : le guide est affiché depuis le début avec un avertissement
local plan = ns.BuildPlan(197, 1)
eq(plan.source, "guide", "guide classique utilisé")
eq(plan.scanned, false, "plan signalé non scanné")
eq(#plan.entries, 0, "aucune recette résolue avant scan")

-- Ouverture du métier : paliers + recettes
C_TradeSkillUI.OpenTradeSkill(197)
M.Flush()
local prof = ns.char.professions[197]
eq(prof.children[1].id, 3001, "palier classique = dernier de la liste")
eq(prof.children[1].skill, 60, "niveau classique")
eq(prof.children[11].skill, 12, "niveau Khaz Algar")
eq(prof.children[12].id, 3012, "palier le plus récent")
eq(ns.db.byItem[197][BOLT_LINEN], 101, "recette résolue par objet")
eq(ns.db.recipes[102].e, 1, "recette rattachée au palier classique")
eq(#ns.db.recipes[102].r, 2, "emplacement optionnel ignoré")
eq(ns.char.learned[103], nil, "recette non apprise")

-- Guide classique à 60/300
plan = ns.BuildPlan(197, 1)
eq(plan.skill, 60, "compétence du plan")
eq(plan.steps[1].step.item, 4238, "première étape restante = Linen Bag")
eq(plan.steps[1].crafts, 11, "fabrications restantes au prorata (27 × 10/25)")
eq(plan.steps[2].learned, false, "cape signalée à apprendre")
eq(plan.shopping.unresolved, 15, "étapes non résolues signalées dans la liste d'achats")

local function buyMap(p)
	local m = {}
	for _, it in ipairs(p.shopping.buy) do m[it.itemID] = it end
	return m
end

-- 11 sacs (33 rouleaux) + 5 capes (10 rouleaux) = 43 rouleaux -> 86 lin, 10 possédés
local buy = buyMap(plan)
eq(buy[LINEN] and buy[LINEN].qty, 76, "lin à acheter (intermédiaires fabriqués)")
eq(buy[LINEN] and buy[LINEN].owned, 10, "lin possédé déduit")
eq(buy[COARSE_THREAD] and buy[COARSE_THREAD].qty, 48, "fil grossier")
eq(buy[COARSE_THREAD] and buy[COARSE_THREAD].vendor, true, "fil signalé vendeur")
eq(buy[WOOL] and buy[WOOL].qty, 102, "laine pour 34 rouleaux")
eq(buy[BOLT_LINEN], nil, "pas d'achat de rouleaux quand on les fabrique")
eq(plan.shopping.intermediates[1].recipeID, 101, "rouleaux de lin à fabriquer")
eq(plan.shopping.intermediates[1].crafts, 43, "43 rouleaux de lin")

-- Option désactivée : on achète les rouleaux
ns.db.settings.expand = false
buy = buyMap(ns.BuildPlan(197, 1))
eq(buy[BOLT_LINEN] and buy[BOLT_LINEN].qty, 43, "rouleaux achetés si option désactivée")
eq(buy[LINEN], nil, "pas de lin si option désactivée")
ns.db.settings.expand = true

-- Les rouleaux en stock sont utilisés avant d'en fabriquer
M.bags[BOLT_LINEN] = 13
buy = buyMap(ns.BuildPlan(197, 1))
eq(buy[LINEN] and buy[LINEN].qty, 50, "30 rouleaux à fabriquer -> 60 lin - 10 possédés")
M.bags[BOLT_LINEN] = nil

-- Plan sur un palier antérieur : étape 1 du guide produit les rouleaux utilisés ensuite
prof.children[1].skill = 1
plan = ns.BuildPlan(197, 1)
eq(plan.steps[1].crafts, 50, "étape 1 complète")
buy = buyMap(plan)
-- 50 rouleaux produits ; besoin 27*3 + 5*2 = 91 rouleaux -> 41 à fabriquer en plus => (50+41)*2 = 182 lin - 10
eq(buy[LINEN] and buy[LINEN].qty, 172, "les rouleaux produits par le guide alimentent les étapes suivantes")
prof.children[1].skill = 60

-- Toutes les extensions
plan = ns.BuildPlan(197, "all")
eq(plan.source, "all", "agrégat")
eq(#plan.parts, 1, "un seul guide disponible (classique)")

-- Plan automatique Khaz Algar (fenêtre ouverte)
plan = ns.BuildPlan(197, 11)
eq(plan.source, "auto", "plan auto sans guide")
eq(plan.live, true, "fenêtre ouverte détectée")
eq(plan.best[1].recipeID, 201, "recette orange préférée")
eq(plan.best[1].crafts, 88, "fabrications estimées (100-12)/1")
eq(#plan.firstCrafts, 1, "une première fabrication")
buy = buyMap(plan)
-- 88 × 4 = 352 composants (qualités 6001/6002) - 5 possédés en qualité 2
eq(buy[6001] and buy[6001].qty, 347, "composants à qualité multiple, stock toutes qualités déduit")
eq(buy[6003] and buy[6003].qty, 10, "composants de la première fabrication")

-- Fenêtre fermée : le plan auto demande d'ouvrir le métier
C_TradeSkillUI.CloseTradeSkill()
plan = ns.BuildPlan(197, 11)
eq(plan.live, false, "plan auto hors fenêtre")
eq(#plan.shopping.buy, 0, "pas d'achats sans données en direct")

-- Récolte
plan = ns.BuildPlan(186, 1)
eq(plan.source, "gathering", "minage = récolte")
check(plan.tips and #plan.tips > 0, "conseils de minage classique")

-- Rendu texte (ne doit pas planter)
for _, exp in ipairs({ 1, 11, 12, "all" }) do
	local lines = ns.UI:BuildLines(ns.BuildPlan(197, exp), false)
	check(#lines > 1, "rendu " .. tostring(exp))
	ns.UI:BuildLines(ns.BuildPlan(197, exp), true)
end
ns.UI:Toggle()
ns.UI:Refresh()
ns.UI:PrintSelectionToChat()

-- Scan automatique de tous les métiers
SlashCmdList.METIERFACILE("scan")
M.Flush()
local done = false
for _, line in ipairs(M.printed) do
	if line:find("Scan terminé") then done = true end
end
check(done, "scan automatique terminé")
eq(M.open, nil, "fenêtre refermée après scan")

-- Métier désappris
table.remove(M.professions, 2)
M.Fire("SKILL_LINES_CHANGED")
eq(ns.char.professions[186], nil, "métier désappris retiré")

SlashCmdList.METIERFACILE("verifier")
SlashCmdList.METIERFACILE("aide")

if os.getenv("VERBOSE") then
	C_TradeSkillUI.OpenTradeSkill(197)
	M.Flush()
	for _, exp in ipairs({ 1, 11 }) do
		io.write(table.concat(ns.UI:BuildLines(ns.BuildPlan(197, exp), false), "\n"), "\n\n")
	end
end

io.write(("%d/%d tests réussis\n"):format(total - failures, total))
if failures > 0 then os.exit(1) end
