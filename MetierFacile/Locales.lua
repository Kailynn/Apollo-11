local ADDON, ns = ...

-- Chaînes d'interface. Le français est la langue de référence ; l'anglais sert
-- de repli pour les autres clients.
local L = setmetatable({}, { __index = function(_, k) return k end })
ns.L = L

local locale = GetLocale()

if locale == "frFR" then
	L.TITLE = "MetierFacile"
	L.LOADED = "chargé. Tapez /mf pour ouvrir la fenêtre."
	L.NO_PROFESSION = "Aucun métier détecté sur ce personnage."
	L.SCAN = "Scanner les métiers"
	L.SCAN_START = "Scan des métiers en cours… (ne fermez pas la fenêtre des métiers)"
	L.SCAN_DONE = "Scan terminé : %d métier(s), %d recettes en cache."
	L.SCAN_COMBAT = "Impossible de scanner en combat."
	L.SCAN_TIMEOUT = "Le métier %s n'a pas répondu, ignoré."
	L.NOT_SCANNED = "Niveaux par extension inconnus : ouvrez la fenêtre de ce métier (ou cliquez sur « Scanner les métiers »)."
	L.ALL_EXPANSIONS = "Toutes les extensions"
	L.EXP_MAXED = "Niveau max atteint !"
	L.STEPS = "Ce qu'il faut monter"
	L.SHOPPING = "Composants à acheter"
	L.TO_CRAFT_FIRST = "Composants intermédiaires à fabriquer d'abord"
	L.NOTHING_TO_BUY = "Rien à acheter : vous avez déjà tout en stock."
	L.OWNED = "possédé"
	L.VENDOR = "vendeur"
	L.CRAFT_X = "Fabriquer %d × %s"
	L.SKILL_RANGE = "%d → %d"
	L.UNRESOLVED = "recette non trouvée dans votre métier (ouvrez le métier puis /mf scan)"
	L.NOT_LEARNED = "recette à apprendre (maître de métier)"
	L.UNRESOLVED_WARNING = "Attention : %d étape(s) non résolue(s) ne sont pas comptées dans cette liste."
	L.NOTE = "Note"
	L.GUIDE_SOURCE = "Guide intégré"
	L.AUTO_SOURCE = "Plan automatique (données du jeu)"
	L.AUTO_NEED_OPEN = "Pas de guide intégré pour cette extension. Ouvrez la fenêtre du métier sur cette extension : MetierFacile calculera le meilleur plan à partir des recettes que vous connaissez."
	L.AUTO_NONE = "Aucune recette connue ne fait encore progresser ce palier. Apprenez de nouvelles recettes auprès du maître de métier."
	L.AUTO_ESTIMATE = "Estimation : les recettes changent de couleur en montant, le plan est recalculé à chaque fabrication."
	L.FIRST_CRAFTS = "Premières fabrications (bonus de compétence garanti)"
	L.BEST_RECIPES = "Meilleures recettes pour progresser maintenant"
	L.PER_POINT = "%.1f composants / point"
	L.EST_CRAFTS = "≈ %d fabrications"
	L.GATHERING = "Métier de récolte : rien à acheter. Où récolter :"
	L.TOTAL_COST = "Coût estimé (hôtel des ventes) : %s"
	L.CHAT_HEADER = "Liste d'achats MetierFacile — %s (%s) :"
	L.PRINT_CHAT = "Afficher dans le chat"
	L.EXPAND = "Fabriquer les intermédiaires"
	L.EXPAND_TIP = "Si coché, les composants fabricables par ce métier (rouleaux d'étoffe, peaux traitées…) sont remplacés par leurs matières premières."
	L.VERIFY_HEADER = "Vérification des guides intégrés :"
	L.VERIFY_OK = "%s / %s : %d étapes valides."
	L.VERIFY_BAD = "%s / %s : étape %d (%s) non résolue."
	L.HELP = "Commandes : /mf (fenêtre), /mf scan, /mf liste, /mf verifier, /mf reset"
	L.RESET_DONE = "Données de MetierFacile réinitialisées."
	L.LEVEL = "Niveau"
	L.SELECT = "Sélectionnez un métier et une extension à gauche."
else
	L.TITLE = "MetierFacile"
	L.LOADED = "loaded. Type /mf to open the window."
	L.NO_PROFESSION = "No profession found on this character."
	L.SCAN = "Scan professions"
	L.SCAN_START = "Scanning professions… (do not close the profession window)"
	L.SCAN_DONE = "Scan complete: %d profession(s), %d recipes cached."
	L.SCAN_COMBAT = "Cannot scan while in combat."
	L.SCAN_TIMEOUT = "Profession %s did not respond, skipped."
	L.NOT_SCANNED = "Expansion skill levels unknown: open this profession's window (or click \"Scan professions\")."
	L.ALL_EXPANSIONS = "All expansions"
	L.EXP_MAXED = "Max level reached!"
	L.STEPS = "What to craft"
	L.SHOPPING = "Reagents to buy"
	L.TO_CRAFT_FIRST = "Intermediate reagents to craft first"
	L.NOTHING_TO_BUY = "Nothing to buy: you already have everything."
	L.OWNED = "owned"
	L.VENDOR = "vendor"
	L.CRAFT_X = "Craft %d × %s"
	L.SKILL_RANGE = "%d → %d"
	L.UNRESOLVED = "recipe not found in your profession (open the profession then /mf scan)"
	L.NOT_LEARNED = "recipe to learn (profession trainer)"
	L.UNRESOLVED_WARNING = "Warning: %d unresolved step(s) are not included in this list."
	L.NOTE = "Note"
	L.GUIDE_SOURCE = "Built-in guide"
	L.AUTO_SOURCE = "Automatic plan (game data)"
	L.AUTO_NEED_OPEN = "No built-in guide for this expansion. Open the profession window on this expansion: MetierFacile will build the best plan from the recipes you know."
	L.AUTO_NONE = "No known recipe gives skill-ups for this tier yet. Learn new recipes from the trainer."
	L.AUTO_ESTIMATE = "Estimate: recipes change color as you level, the plan is recomputed after every craft."
	L.FIRST_CRAFTS = "First crafts (guaranteed skill bonus)"
	L.BEST_RECIPES = "Best recipes to level right now"
	L.PER_POINT = "%.1f reagents / point"
	L.EST_CRAFTS = "≈ %d crafts"
	L.GATHERING = "Gathering profession: nothing to buy. Where to gather:"
	L.TOTAL_COST = "Estimated cost (auction house): %s"
	L.CHAT_HEADER = "MetierFacile shopping list — %s (%s):"
	L.PRINT_CHAT = "Print to chat"
	L.EXPAND = "Craft intermediates"
	L.EXPAND_TIP = "When checked, reagents this profession can craft (cloth bolts, cured hides…) are replaced by their raw materials."
	L.VERIFY_HEADER = "Checking built-in guides:"
	L.VERIFY_OK = "%s / %s: %d valid steps."
	L.VERIFY_BAD = "%s / %s: step %d (%s) unresolved."
	L.HELP = "Commands: /mf (window), /mf scan, /mf list, /mf verify, /mf reset"
	L.RESET_DONE = "MetierFacile data reset."
	L.LEVEL = "Level"
	L.SELECT = "Select a profession and an expansion on the left."
end

-- Noms d'extension utilisés quand le jeu ne les a pas encore fournis
-- (le nom réel renvoyé par le jeu est toujours préféré).
ns.EXPANSION_LABELS = (locale == "frFR") and {
	"Classique", "Outreterre", "Norfendre", "Cataclysm", "Pandarie", "Draenor",
	"Légion", "Kul Tiras / Zandalar", "Ombreterre", "Îles aux Dragons", "Khaz Algar", "Midnight",
} or {
	"Classic", "Outland", "Northrend", "Cataclysm", "Pandaria", "Draenor",
	"Legion", "Kul Tiras / Zandalar", "Shadowlands", "Dragon Isles", "Khaz Algar", "Midnight",
}
