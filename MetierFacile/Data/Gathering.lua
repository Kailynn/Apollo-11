local ADDON, ns = ...

-- Conseils de récolte par extension (métiers sans composants à acheter).
local G = ns.Gathering

G.mining = {
	classic = {
		"1-65 : Cuivre — Forêt d'Elwynn, Dun Morogh, Durotar, Mulgore",
		"65-125 : Étain — Les Carmines, Contreforts de Hautebrande, Les Tarides",
		"125-175 : Fer — Hautes-terres d'Arathi, Désolace",
		"175-250 : Mithril — Terres ingrates, Tanaris, Les Hinterlands",
		"250-300 : Thorium — Cratère d'Un'Goro, Steppes ardentes, Berceau-de-l'Hiver",
	},
	outland = { "Gangrefer — Péninsule des Flammes infernales", "Adamantite — Nagrand, Forêt de Terokkar" },
	northrend = { "Cobalt — Toundra Boréenne, Fjord Hurlant", "Saronite — Bassin de Sholazar, La Couronne de glace" },
	cataclysm = { "Obsidium — Mont Hyjal, Vashj'ir, Le Tréfonds", "Élémentium — Hautes-terres du Crépuscule, Uldum" },
	pandaria = { "Fer fantôme — Forêt de Jade, Vallée des Quatre vents", "Kyparite / Trillium — Sommet de Kun-Lai, Steppes de Tanglong" },
	draenor = { "Mine du fief (niveau 2+) et Gorgrond" },
	legion = { "Pierre de lune — Haut-Roc, Azsuna", "Gangrardoise — Suramar, Rivage Brisé" },
	bfa = { "Monélite / Argent-tempête — Drustvar, Zuldazar, Nazmir", "Platine — Nazjatar" },
	shadowlands = { "Laestrite — Bastion, Maldraxxus", "Éléthium — Revendreth, Sylvarden" },
	dragonflight = { "Sérévite — Rivages de l'Éveil, Plaines d'Ohn'ahra", "Draconium — Travée d'Azur, Thaldraszus" },
	tww = { "Bismuth — Île de Dorn", "Griffefer / Aqirite — Les Tréfonds Retentissants, Sainte-Chute, Azj-Kahet" },
	midnight = { "Zones de Midnight : Bois des Chants éternels, Zul'Aman, Harandar, Tempête du Vide" },
}

G.herbalism = {
	classic = {
		"1-70 : Pacifique / Feuillargent — zones de départ",
		"70-115 : Mage royal / Églantine — Marche de l'Ouest, Les Tarides",
		"115-170 : Doulourante / Aciérite sauvage — Contreforts de Hautebrande, Bois de la Pénombre",
		"170-230 : Sang-royal / Fleur de feu — Marécage d'Âprefange, Gorge des Vents brûlants",
		"230-300 : Soleillette / Rêvefeuille — Féralas, Gangrebois, Berceau-de-l'Hiver",
	},
	outland = { "Gangrelette / Rêveline — Péninsule des Flammes infernales, Marécage de Zangar" },
	northrend = { "Dorépine / Folle-épine — Toundra Boréenne, Bassin de Sholazar" },
	cataclysm = { "Lierre-cendre / Cœur-de-chat — Mont Hyjal, Uldum" },
	pandaria = { "Thé vert — Forêt de Jade", "Fleur de neige / Silkweed — Kun-Lai, Vallée des Quatre vents" },
	draenor = { "Jardin du fief et Gorgrond" },
	legion = { "Aethril / Rêvefeuille — Azsuna, Val'sharah" },
	bfa = { "Ancoria / Sirène — Tiragarde, Zuldazar" },
	shadowlands = { "Lumibaie / Velour de veuve — Ardenweald, Maldraxxus" },
	dragonflight = { "Hochenblume — Plaines d'Ohn'ahra, Rivages de l'Éveil" },
	tww = { "Mycobloom / Luredrop — Île de Dorn, Sainte-Chute" },
	midnight = { "Zones de Midnight : Bois des Chants éternels, Zul'Aman, Harandar" },
}

G.skinning = {
	classic = {
		"1-75 : bêtes des zones de départ (loups, sangliers)",
		"75-150 : Les Tarides, Contreforts de Hautebrande",
		"150-225 : Strangleronce, Marais des Chagrins",
		"225-300 : Cratère d'Un'Goro, Berceau-de-l'Hiver",
	},
	outland = { "Nagrand (talbuks, clefts)" },
	northrend = { "Toundra Boréenne, Bassin de Sholazar (rhinos)" },
	cataclysm = { "Uldum, Hautes-terres du Crépuscule" },
	pandaria = { "Steppes de Tanglong, Sommet de Kun-Lai" },
	draenor = { "Nagrand, Gorgrond" },
	legion = { "Haut-Roc, Val'sharah" },
	bfa = { "Drustvar, Nazmir" },
	shadowlands = { "Maldraxxus, Ardenweald" },
	dragonflight = { "Plaines d'Ohn'ahra" },
	tww = { "Île de Dorn, Sainte-Chute" },
	midnight = { "Zones de Midnight : Harandar, Zul'Aman" },
}

G.fishing = {}
for _, key in ipairs(ns.EXPANSIONS) do
	G.fishing[key] = { "Pêchez dans n'importe quelle eau des zones de cette extension : chaque prise fait progresser ce palier." }
end
