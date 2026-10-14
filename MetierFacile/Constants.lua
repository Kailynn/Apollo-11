local ADDON, ns = ...

-- Métiers, indexés par l'ID de la ligne de compétence « parente »
-- (celle renvoyée par GetProfessionInfo).
ns.PROFESSIONS = {
	[171] = { key = "alchemy" },
	[164] = { key = "blacksmithing" },
	[333] = { key = "enchanting" },
	[202] = { key = "engineering" },
	[773] = { key = "inscription" },
	[755] = { key = "jewelcrafting" },
	[165] = { key = "leatherworking" },
	[197] = { key = "tailoring" },
	[185] = { key = "cooking" },
	[182] = { key = "herbalism", gathering = true },
	[186] = { key = "mining", gathering = true },
	[393] = { key = "skinning", gathering = true },
	[356] = { key = "fishing", gathering = true },
}

-- Archéologie n'a pas de paliers par extension : ignorée.
ns.IGNORED_SKILL_LINES = { [794] = true }

-- Ordre chronologique des paliers. C_TradeSkillUI.GetChildProfessionInfos()
-- renvoie les paliers du plus récent au plus ancien : le dernier élément
-- est toujours « Classique », ce qui nous permet d'en déduire l'index.
ns.EXPANSIONS = {
	"classic", "outland", "northrend", "cataclysm", "pandaria", "draenor",
	"legion", "bfa", "shadowlands", "dragonflight", "tww", "midnight",
}

function ns.ExpansionKey(index)
	return ns.EXPANSIONS[index] or ("exp" .. index)
end

function ns.ExpansionLabel(index)
	return ns.EXPANSION_LABELS[index] or ("#" .. index)
end

-- Composants vendus par les PNJ fournisseurs de métiers (prix fixe, stock
-- illimité). Affichés avec la mention « vendeur » dans la liste d'achats.
ns.VENDOR_ITEMS = {
	-- Fils
	[2320] = true, [2321] = true, [4291] = true, [8343] = true, [14341] = true,
	-- Teintures, décolorant, sel
	[2324] = true, [2325] = true, [2604] = true, [2605] = true, [4340] = true,
	[4341] = true, [4342] = true, [6260] = true, [6261] = true, [10290] = true,
	[4289] = true,
	-- Fioles
	[3371] = true, [3372] = true, [8925] = true, [18256] = true,
	-- Flux, tiges, outils d'ingénieur
	[2880] = true, [3466] = true, [18567] = true, [2678] = true, [2692] = true,
	[3713] = true, [159] = true, [2596] = true, [1179] = true,
	-- Parchemins / encres de base de calligraphie
	[39354] = true, [39501] = true, [39502] = true, [10648] = true,
}
