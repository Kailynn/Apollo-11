local ADDON, ns = ...
local L = ns.L

local UI = {}
ns.UI = UI

local LEFT_WIDTH = 240
local ROW_HEIGHT = 20
local COLOR_DONE, COLOR_PROGRESS, COLOR_EMPTY = "ff40ff40", "ffffd100", "ff808080"

---------------------------------------------------------------------------
-- Mise en forme
---------------------------------------------------------------------------

local function Colorize(color, text)
	return "|c" .. color .. text .. "|r"
end

local function ItemText(itemID, forChat)
	if forChat then
		local _, link = C_Item.GetItemInfo(itemID)
		return link or ("item:" .. itemID)
	end
	local name = C_Item.GetItemNameByID(itemID)
	if not name then
		C_Item.RequestLoadItemDataByID(itemID)
		name = "item:" .. itemID
	end
	local icon = C_Item.GetItemIconByID(itemID)
	local quality = C_Item.GetItemQualityByID(itemID)
	local color = quality and ITEM_QUALITY_COLORS[quality] and ITEM_QUALITY_COLORS[quality].hex or "|cffffffff"
	return (icon and ("|T" .. icon .. ":14|t ") or "") .. color .. name .. "|r"
end

local recipeNames = {}
local function RecipeText(recipeID, forChat)
	if forChat then
		local link = C_TradeSkillUI.GetRecipeLink and C_TradeSkillUI.GetRecipeLink(recipeID)
		if link then return link end
	end
	if not recipeNames[recipeID] then
		local ok, schematic = pcall(C_TradeSkillUI.GetRecipeSchematic, recipeID, false)
		recipeNames[recipeID] = ok and schematic and schematic.name or ("recette " .. recipeID)
	end
	return Colorize("ffffffff", recipeNames[recipeID])
end

local function StepText(row, forChat)
	if row.recipeID then
		return RecipeText(row.recipeID, forChat)
	end
	if row.step.item then
		return ItemText(row.step.item, forChat)
	end
	return row.step.name or "?"
end

local function Money(copper)
	return GetMoneyString and GetMoneyString(copper, true) or tostring(copper)
end

local function ExpansionName(parentID, expIndex)
	if expIndex == "all" then return L.ALL_EXPANSIONS end
	local prof = ns.char.professions[parentID]
	local child = prof and prof.children[expIndex]
	return child and child.name or ns.ExpansionLabel(expIndex)
end

---------------------------------------------------------------------------
-- Construction du texte d'un plan (fenêtre et chat)
---------------------------------------------------------------------------

local function AddShopping(lines, shopping, forChat)
	if #shopping.intermediates > 0 then
		lines[#lines + 1] = ""
		lines[#lines + 1] = Colorize("ff33ccff", L.TO_CRAFT_FIRST)
		for _, entry in ipairs(shopping.intermediates) do
			lines[#lines + 1] = "  " .. L.CRAFT_X:format(entry.crafts, RecipeText(entry.recipeID, forChat))
		end
	end
	lines[#lines + 1] = ""
	lines[#lines + 1] = Colorize("ff33ccff", L.SHOPPING)
	if #shopping.buy == 0 then
		lines[#lines + 1] = "  " .. Colorize(COLOR_DONE, L.NOTHING_TO_BUY)
	end
	for _, item in ipairs(shopping.buy) do
		local extra = {}
		if item.owned > 0 then extra[#extra + 1] = item.owned .. " " .. L.OWNED end
		if item.vendor then extra[#extra + 1] = L.VENDOR end
		if item.price and not forChat then extra[#extra + 1] = Money(item.price * item.qty) end
		local suffix = #extra > 0 and ("  " .. Colorize(COLOR_EMPTY, "(" .. table.concat(extra, ", ") .. ")")) or ""
		lines[#lines + 1] = ("  %d × %s%s"):format(item.qty, ItemText(item.itemID, forChat), suffix)
	end
	if shopping.unresolved then
		lines[#lines + 1] = "  " .. Colorize("ffff6060", L.UNRESOLVED_WARNING:format(shopping.unresolved))
	end
	if shopping.totalCost and not forChat then
		lines[#lines + 1] = ""
		lines[#lines + 1] = L.TOTAL_COST:format(Money(shopping.totalCost))
	end
end

local function AddGuideSteps(lines, plan, forChat)
	if not plan.scanned then
		lines[#lines + 1] = Colorize("ffff6060", L.NOT_SCANNED)
	end
	if plan.done then
		lines[#lines + 1] = Colorize(COLOR_DONE, L.EXP_MAXED)
		return
	end
	for _, row in ipairs(plan.steps) do
		local text = ("  %s  %s"):format(
			Colorize(COLOR_PROGRESS, L.SKILL_RANGE:format(math.max(row.step.from, plan.skill), row.step.to)),
			L.CRAFT_X:format(row.crafts, StepText(row, forChat)))
		lines[#lines + 1] = text
		if not row.recipeID then
			lines[#lines + 1] = "      " .. Colorize("ffff6060", L.UNRESOLVED)
		elseif not row.learned then
			lines[#lines + 1] = "      " .. Colorize("ffff9933", L.NOT_LEARNED)
		end
		if row.step.note and not forChat then
			lines[#lines + 1] = "      " .. Colorize(COLOR_EMPTY, row.step.note)
		end
	end
end

function UI:BuildLines(plan, forChat)
	local lines = {}
	local parentID = plan.parentID
	local prof = ns.char.professions[parentID]
	lines[#lines + 1] = Colorize("ffffd100", (prof and prof.name or "?") .. " — " .. ExpansionName(parentID, plan.expIndex))

	if plan.source == "gathering" then
		if plan.child then
			lines[#lines + 1] = ("%s : %d / %d"):format(L.LEVEL, plan.child.skill, plan.child.max)
		end
		lines[#lines + 1] = ""
		lines[#lines + 1] = L.GATHERING
		for _, tip in ipairs(plan.tips or {}) do
			lines[#lines + 1] = "  • " .. tip
		end
		return lines
	end

	if plan.source == "guide" then
		lines[#lines + 1] = ("%s : %d / %d   |cff808080(%s)|r"):format(L.LEVEL, plan.skill, plan.max, L.GUIDE_SOURCE)
		lines[#lines + 1] = ""
		lines[#lines + 1] = Colorize("ff33ccff", L.STEPS)
		AddGuideSteps(lines, plan, forChat)
	elseif plan.source == "all" then
		for _, part in ipairs(plan.parts) do
			lines[#lines + 1] = ""
			lines[#lines + 1] = Colorize("ff33ccff", ("%s (%d / %d)"):format(ExpansionName(parentID, part.expIndex), part.skill, part.max))
			AddGuideSteps(lines, part, forChat)
		end
		if #plan.parts == 0 then
			lines[#lines + 1] = Colorize(COLOR_DONE, L.EXP_MAXED)
		end
	elseif plan.source == "auto" then
		lines[#lines + 1] = ("%s : %d / %d   |cff808080(%s)|r"):format(L.LEVEL, plan.skill, plan.max, L.AUTO_SOURCE)
		lines[#lines + 1] = ""
		if not plan.scanned then
			lines[#lines + 1] = Colorize("ffff6060", L.NOT_SCANNED)
		end
		if plan.done then
			lines[#lines + 1] = Colorize(COLOR_DONE, L.EXP_MAXED)
			return lines
		elseif not plan.live then
			lines[#lines + 1] = L.AUTO_NEED_OPEN
			return lines
		elseif plan.empty then
			lines[#lines + 1] = L.AUTO_NONE
			return lines
		end
		if #plan.firstCrafts > 0 then
			lines[#lines + 1] = Colorize("ff33ccff", L.FIRST_CRAFTS)
			for _, entry in ipairs(plan.firstCrafts) do
				lines[#lines + 1] = "  " .. L.CRAFT_X:format(1, RecipeText(entry.recipeID, forChat))
			end
			lines[#lines + 1] = ""
		end
		if #plan.best > 0 then
			lines[#lines + 1] = Colorize("ff33ccff", L.BEST_RECIPES)
			for i, entry in ipairs(plan.best) do
				local text = "  " .. RecipeText(entry.recipeID, forChat) .. "  " .. Colorize(COLOR_EMPTY, L.PER_POINT:format(entry.perPoint))
				if i == 1 and entry.crafts then
					text = text .. "  " .. Colorize(COLOR_PROGRESS, L.EST_CRAFTS:format(entry.crafts))
				end
				lines[#lines + 1] = text
			end
			lines[#lines + 1] = Colorize(COLOR_EMPTY, L.AUTO_ESTIMATE)
		end
	end

	AddShopping(lines, plan.shopping, forChat)
	return lines
end

---------------------------------------------------------------------------
-- Fenêtre principale
---------------------------------------------------------------------------

function UI:Create()
	if self.frame then return end
	local f = CreateFrame("Frame", "MetierFacileFrame", UIParent, "BasicFrameTemplateWithInset")
	f:SetSize(820, 540)
	f:SetPoint("CENTER")
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:SetClampedToScreen(true)
	f:SetFrameStrata("HIGH")
	f:Hide()
	tinsert(UISpecialFrames, "MetierFacileFrame")
	f.TitleText:SetText(L.TITLE)
	f:SetScript("OnShow", function() UI:Refresh() end)
	self.frame = f

	-- Liste des métiers / extensions (gauche)
	local left = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
	left:SetPoint("TOPLEFT", 12, -32)
	left:SetPoint("BOTTOMLEFT", 12, 44)
	left:SetWidth(LEFT_WIDTH)
	local leftChild = CreateFrame("Frame", nil, left)
	leftChild:SetSize(LEFT_WIDTH, 1)
	left:SetScrollChild(leftChild)
	self.leftChild = leftChild
	self.rows = {}

	-- Détail (droite)
	local right = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
	right:SetPoint("TOPLEFT", left, "TOPRIGHT", 34, 0)
	right:SetPoint("BOTTOMRIGHT", -32, 44)
	local rightChild = CreateFrame("Frame", nil, right)
	rightChild:SetSize(500, 1)
	right:SetScrollChild(rightChild)
	local text = rightChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	text:SetPoint("TOPLEFT", 4, -4)
	text:SetJustifyH("LEFT")
	text:SetJustifyV("TOP")
	text:SetSpacing(3)
	self.right, self.rightChild, self.text = right, rightChild, text
	right:SetScript("OnSizeChanged", function(_, width)
		rightChild:SetWidth(width)
		text:SetWidth(width - 8)
	end)

	-- Boutons du bas
	local scan = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	scan:SetSize(170, 24)
	scan:SetPoint("BOTTOMLEFT", 14, 12)
	scan:SetText(L.SCAN)
	scan:SetScript("OnClick", function() ns.ScanAll() end)

	local chat = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	chat:SetSize(170, 24)
	chat:SetPoint("LEFT", scan, "RIGHT", 8, 0)
	chat:SetText(L.PRINT_CHAT)
	chat:SetScript("OnClick", function() UI:PrintSelectionToChat() end)

	local expand = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
	expand:SetSize(24, 24)
	expand:SetPoint("LEFT", chat, "RIGHT", 16, 0)
	expand.text = expand:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	expand.text:SetPoint("LEFT", expand, "RIGHT", 2, 0)
	expand.text:SetText(L.EXPAND)
	expand:SetScript("OnClick", function(btn)
		ns.db.settings.expand = btn:GetChecked() and true or false
		UI:Refresh()
	end)
	expand:SetScript("OnEnter", function(btn)
		GameTooltip:SetOwner(btn, "ANCHOR_TOP")
		GameTooltip:SetText(L.EXPAND_TIP, nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	expand:SetScript("OnLeave", GameTooltip_Hide)
	self.expand = expand
end

local function GetRow(index)
	local row = UI.rows[index]
	if row then return row end
	row = CreateFrame("Button", nil, UI.leftChild)
	row:SetSize(LEFT_WIDTH - 4, ROW_HEIGHT)
	row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
	row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	row.selected = row:CreateTexture(nil, "BACKGROUND")
	row.selected:SetAllPoints()
	row.selected:SetColorTexture(0.2, 0.6, 1, 0.25)
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(16, 16)
	row.icon:SetPoint("LEFT", 2, 0)
	row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.label:SetJustifyH("LEFT")
	row.value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.value:SetPoint("RIGHT", -4, 0)
	row:SetScript("OnClick", function(btn)
		if btn.parentID then
			UI.selParent, UI.selExp = btn.parentID, btn.expIndex
			UI:Refresh()
		end
	end)
	UI.rows[index] = row
	return row
end

-- Ordre d'affichage : métiers principaux d'abord, puis secondaires, par nom.
local function SortedProfessions()
	local list = {}
	for parentID, prof in pairs(ns.char.professions) do
		list[#list + 1] = { id = parentID, prof = prof }
	end
	table.sort(list, function(a, b)
		local ga, gb = ns.PROFESSIONS[a.id].gathering and 1 or 0, ns.PROFESSIONS[b.id].gathering and 1 or 0
		if ga ~= gb then return ga < gb end
		return (a.prof.name or "") < (b.prof.name or "")
	end)
	return list
end

-- Sélection par défaut : le palier le plus récent commencé mais pas terminé.
local function DefaultSelection(list)
	for _, entry in ipairs(list) do
		for index = ns.GetExpansionCount(entry.id), 1, -1 do
			local child = entry.prof.children[index]
			if child and child.skill > 0 and child.skill < child.max then
				return entry.id, index
			end
		end
	end
	local first = list[1]
	return first and first.id, first and ns.GetExpansionCount(first.id)
end

function UI:RefreshList(list)
	local index = 0
	local function AddRow(parentID, expIndex, icon, label, value, color, isHeader)
		index = index + 1
		local row = GetRow(index)
		row.parentID, row.expIndex = parentID, expIndex
		row.icon:SetShown(icon ~= nil)
		if icon then row.icon:SetTexture(icon) end
		row.label:ClearAllPoints()
		row.label:SetPoint("LEFT", icon and 22 or 14, 0)
		row.label:SetPoint("RIGHT", row.value, "LEFT", -4, 0)
		row.label:SetFontObject(isHeader and "GameFontNormal" or "GameFontHighlightSmall")
		row.label:SetText(label)
		row.value:SetText(value and Colorize(color, value) or "")
		row.selected:SetShown(parentID == self.selParent and expIndex == self.selExp)
		row:EnableMouse(expIndex ~= nil)
		row:Show()
	end

	for _, entry in ipairs(list) do
		local parentID, prof = entry.id, entry.prof
		AddRow(nil, nil, prof.icon, prof.name, prof.skill and (prof.skill .. " / " .. prof.max), COLOR_PROGRESS, true)
		local def = ns.PROFESSIONS[parentID]
		if not def.gathering and ns.Guides[def.key] then
			AddRow(parentID, "all", nil, L.ALL_EXPANSIONS)
		end
		for expIndex = ns.GetExpansionCount(parentID), 1, -1 do
			local child = prof.children[expIndex]
			local value, color
			if child then
				value = child.skill .. " / " .. child.max
				color = (child.max > 0 and child.skill >= child.max) and COLOR_DONE
					or (child.skill > 0 and COLOR_PROGRESS or COLOR_EMPTY)
			end
			AddRow(parentID, expIndex, nil, ExpansionName(parentID, expIndex), value, color)
		end
	end
	for i = index + 1, #self.rows do
		self.rows[i]:Hide()
	end
	self.leftChild:SetHeight(math.max(index * ROW_HEIGHT, 1))
end

function UI:Refresh()
	if not self.frame or not self.frame:IsShown() or not ns.char then return end
	self.expand:SetChecked(ns.db.settings.expand)
	local list = SortedProfessions()
	if not self.selParent or not ns.char.professions[self.selParent] then
		self.selParent, self.selExp = DefaultSelection(list)
	end
	self:RefreshList(list)

	if #list == 0 then
		self.text:SetText(L.NO_PROFESSION)
	elseif not self.selParent then
		self.text:SetText(L.SELECT)
	else
		local plan = ns.BuildPlan(self.selParent, self.selExp)
		self.text:SetText(table.concat(self:BuildLines(plan, false), "\n"))
	end
	self.rightChild:SetHeight(self.text:GetStringHeight() + 10)
end

function UI:Toggle()
	self:Create()
	self.frame:SetShown(not self.frame:IsShown())
end

function UI:PrintSelectionToChat()
	self:Create()
	if not self.selParent then
		self.selParent, self.selExp = DefaultSelection(SortedProfessions())
	end
	if not self.selParent then
		ns.Print(L.NO_PROFESSION)
		return
	end
	local plan = ns.BuildPlan(self.selParent, self.selExp)
	local prof = ns.char.professions[self.selParent]
	ns.Print(L.CHAT_HEADER, prof.name, ExpansionName(self.selParent, self.selExp))
	local noLiveData = plan.source == "auto" and (not plan.live or plan.done or plan.empty)
	if not plan.shopping or noLiveData then
		for _, line in ipairs(self:BuildLines(plan, true)) do
			print(line)
		end
		return
	end
	local lines = {}
	AddShopping(lines, plan.shopping, true)
	for _, line in ipairs(lines) do
		if line ~= "" then print(line) end
	end
end

-- Bouton d'accès rapide dans la fenêtre des métiers de Blizzard
EventUtil.ContinueOnAddOnLoaded("Blizzard_Professions", function()
	if not ProfessionsFrame then return end
	local button = CreateFrame("Button", nil, ProfessionsFrame, "UIPanelButtonTemplate")
	button:SetSize(110, 22)
	button:SetPoint("TOPRIGHT", ProfessionsFrame, "TOPRIGHT", -60, -1)
	button:SetFrameStrata("HIGH")
	button:SetText(L.TITLE)
	button:SetScript("OnClick", function()
		UI:Create()
		local parentID = ns.lastOpenParent
		local base = C_TradeSkillUI.GetBaseProfessionInfo()
		local child = C_TradeSkillUI.GetChildProfessionInfo()
		if base and ns.char.professions[base.professionID] then
			parentID = base.professionID
			UI.selParent = parentID
			for index, info in pairs(ns.char.professions[parentID].children) do
				if child and info.id == child.professionID then
					UI.selExp = index
				end
			end
		end
		UI.frame:Show()
		UI:Refresh()
	end)
end)
