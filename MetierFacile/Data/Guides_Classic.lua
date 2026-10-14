local ADDON, ns = ...

--[[
Guides intégrés.

Format d'une étape :
  { from = 1, to = 60, crafts = 60, item = 118, name = "Minor Healing Potion", note = "..." }

  from / to  : plage de compétence couverte par l'étape
  crafts     : nombre de fabrications prévues pour toute la plage (moyenne
               observée, les recettes jaunes/vertes ne donnent pas toujours
               un point). Si le personnage est déjà au milieu de la plage,
               le nombre restant est calculé au prorata.
  item       : ID de l'objet fabriqué. La recette correspondante est retrouvée
               dans les données du jeu lors du scan du métier : les quantités
               de composants affichées viennent donc toujours du jeu, jamais
               de ce fichier.
  recipe     : (optionnel) ID de la recette, pour les recettes sans objet
               (enchantements). Prioritaire sur « item ».
  name       : nom anglais, uniquement pour la lisibilité de ce fichier.

Ajouter une extension : ns.Guides.<metier>.<cle> avec une clé de
ns.EXPANSIONS (outland, northrend, …). Les extensions sans guide utilisent le
plan automatique calculé à partir des recettes connues.
Commande de contrôle en jeu : /mf verifier
]]

local G = ns.Guides

G.alchemy = G.alchemy or {}
G.alchemy.classic = { max = 300, steps = {
	{ from = 1,   to = 60,  crafts = 65, item = 118,   name = "Minor Healing Potion" },
	{ from = 60,  to = 110, crafts = 55, item = 858,   name = "Lesser Healing Potion", note = "Utilise les Potions de soins mineures fabriquées avant." },
	{ from = 110, to = 140, crafts = 33, item = 929,   name = "Healing Potion" },
	{ from = 140, to = 155, crafts = 16, item = 3385,  name = "Lesser Mana Potion" },
	{ from = 155, to = 185, crafts = 33, item = 1710,  name = "Greater Healing Potion" },
	{ from = 185, to = 210, crafts = 28, item = 8949,  name = "Elixir of Agility" },
	{ from = 210, to = 215, crafts = 5,  item = 8951,  name = "Elixir of Greater Defense" },
	{ from = 215, to = 230, crafts = 16, item = 3928,  name = "Superior Healing Potion" },
	{ from = 230, to = 250, crafts = 22, item = 9154,  name = "Elixir of Detect Undead" },
	{ from = 250, to = 265, crafts = 16, item = 9187,  name = "Elixir of Greater Agility" },
	{ from = 265, to = 285, crafts = 22, item = 13443, name = "Superior Mana Potion" },
	{ from = 285, to = 300, crafts = 17, item = 13446, name = "Major Healing Potion" },
} }

G.tailoring = G.tailoring or {}
G.tailoring.classic = { max = 300, steps = {
	{ from = 1,   to = 45,  crafts = 50, item = 2996,  name = "Bolt of Linen Cloth" },
	{ from = 45,  to = 70,  crafts = 27, item = 4238,  name = "Linen Bag" },
	{ from = 70,  to = 75,  crafts = 5,  item = 2580,  name = "Reinforced Linen Cape" },
	{ from = 75,  to = 105, crafts = 34, item = 2997,  name = "Bolt of Woolen Cloth" },
	{ from = 105, to = 110, crafts = 5,  item = 2587,  name = "Gray Woolen Shirt" },
	{ from = 110, to = 125, crafts = 16, item = 4314,  name = "Double-stitched Woolen Shoulders" },
	{ from = 125, to = 145, crafts = 24, item = 4305,  name = "Bolt of Silk Cloth" },
	{ from = 145, to = 160, crafts = 16, item = 7048,  name = "Azure Silk Hood" },
	{ from = 160, to = 170, crafts = 11, item = 7050,  name = "Silk Headband" },
	{ from = 170, to = 175, crafts = 5,  item = 4334,  name = "Formal White Shirt" },
	{ from = 175, to = 185, crafts = 12, item = 4339,  name = "Bolt of Mageweave" },
	{ from = 185, to = 200, crafts = 16, item = 7058,  name = "Crimson Silk Vest" },
	{ from = 200, to = 215, crafts = 16, item = 7062,  name = "Crimson Silk Pantaloons" },
	{ from = 215, to = 220, crafts = 5,  item = 9999,  name = "Black Mageweave Leggings" },
	{ from = 220, to = 230, crafts = 11, item = 10003, name = "Black Mageweave Gloves" },
	{ from = 230, to = 250, crafts = 22, item = 10024, name = "Black Mageweave Headband" },
	{ from = 250, to = 260, crafts = 12, item = 14048, name = "Bolt of Runecloth" },
	{ from = 260, to = 280, crafts = 22, item = 13856, name = "Runecloth Belt" },
	{ from = 280, to = 300, crafts = 22, item = 13863, name = "Runecloth Gloves" },
} }

G.engineering = G.engineering or {}
G.engineering.classic = { max = 300, steps = {
	{ from = 1,   to = 30,  crafts = 33, item = 4357,  name = "Rough Blasting Powder" },
	{ from = 30,  to = 50,  crafts = 22, item = 4359,  name = "Handful of Copper Bolts" },
	{ from = 50,  to = 51,  crafts = 1,  item = 6219,  name = "Arclight Spanner", note = "Outil indispensable, à garder dans les sacs." },
	{ from = 51,  to = 65,  crafts = 15, item = 4361,  name = "Copper Tube" },
	{ from = 65,  to = 75,  crafts = 11, item = 4362,  name = "Rough Boomstick" },
	{ from = 75,  to = 95,  crafts = 22, item = 4364,  name = "Coarse Blasting Powder" },
	{ from = 95,  to = 105, crafts = 11, item = 4404,  name = "Silver Contact" },
	{ from = 105, to = 120, crafts = 16, item = 4371,  name = "Bronze Tube" },
	{ from = 120, to = 125, crafts = 5,  item = 4374,  name = "Small Bronze Bomb" },
	{ from = 125, to = 145, crafts = 22, item = 4377,  name = "Heavy Blasting Powder" },
	{ from = 145, to = 150, crafts = 5,  item = 4380,  name = "Big Bronze Bomb" },
	{ from = 150, to = 175, crafts = 28, item = 4375,  name = "Whirring Bronze Gizmo" },
	{ from = 175, to = 176, crafts = 1,  item = 10498, name = "Gyromatic Micro-Adjustor", note = "Outil indispensable, à garder dans les sacs." },
	{ from = 176, to = 195, crafts = 21, item = 10505, name = "Solid Blasting Powder" },
	{ from = 195, to = 200, crafts = 5,  item = 4394,  name = "Big Iron Bomb" },
	{ from = 200, to = 210, crafts = 11, item = 10558, name = "Gold Power Core" },
	{ from = 210, to = 225, crafts = 16, item = 10559, name = "Mithril Tube" },
	{ from = 225, to = 235, crafts = 11, item = 10560, name = "Unstable Trigger" },
	{ from = 235, to = 245, crafts = 11, item = 10561, name = "Mithril Casing" },
	{ from = 245, to = 250, crafts = 5,  item = 10562, name = "Hi-Explosive Bomb" },
	{ from = 250, to = 260, crafts = 11, item = 15992, name = "Dense Blasting Powder" },
	{ from = 260, to = 285, crafts = 28, item = 15994, name = "Thorium Widget" },
	{ from = 285, to = 300, crafts = 17, item = 16000, name = "Thorium Tube" },
} }

G.blacksmithing = G.blacksmithing or {}
G.blacksmithing.classic = { max = 300, steps = {
	{ from = 1,   to = 25,  crafts = 27, item = 2862,  name = "Rough Sharpening Stone" },
	{ from = 25,  to = 45,  crafts = 22, item = 3470,  name = "Rough Grinding Stone" },
	{ from = 45,  to = 75,  crafts = 32, item = 2851,  name = "Copper Chain Belt" },
	{ from = 75,  to = 90,  crafts = 16, item = 3478,  name = "Coarse Grinding Stone" },
	{ from = 90,  to = 100, crafts = 10, item = 2857,  name = "Runed Copper Belt" },
	{ from = 100, to = 105, crafts = 5,  item = 6338,  name = "Silver Rod" },
	{ from = 105, to = 125, crafts = 22, item = 2865,  name = "Rough Bronze Leggings" },
	{ from = 125, to = 150, crafts = 27, item = 3486,  name = "Heavy Grinding Stone" },
	{ from = 150, to = 165, crafts = 16, item = 3842,  name = "Green Iron Leggings" },
	{ from = 165, to = 200, crafts = 40, item = 3835,  name = "Green Iron Bracers" },
	{ from = 200, to = 210, crafts = 11, item = 7966,  name = "Solid Grinding Stone" },
	{ from = 210, to = 235, crafts = 28, item = 7922,  name = "Steel Plate Helm" },
	{ from = 235, to = 250, crafts = 16, item = 7931,  name = "Mithril Coif" },
	{ from = 250, to = 260, crafts = 11, item = 12404, name = "Dense Sharpening Stone" },
	{ from = 260, to = 270, crafts = 11, item = 12408, name = "Thorium Bracers" },
	{ from = 270, to = 300, crafts = 35, item = 12425, name = "Imperial Plate Bracers" },
} }

G.leatherworking = G.leatherworking or {}
G.leatherworking.classic = { max = 300, steps = {
	{ from = 1,   to = 35,  crafts = 40, item = 2304,  name = "Light Armor Kit" },
	{ from = 35,  to = 55,  crafts = 22, item = 4231,  name = "Cured Light Hide" },
	{ from = 55,  to = 85,  crafts = 32, item = 4239,  name = "Embossed Leather Gloves" },
	{ from = 85,  to = 100, crafts = 16, item = 4246,  name = "Fine Leather Belt" },
	{ from = 100, to = 120, crafts = 22, item = 4233,  name = "Cured Medium Hide" },
	{ from = 120, to = 125, crafts = 5,  item = 4246,  name = "Fine Leather Belt" },
	{ from = 125, to = 150, crafts = 27, item = 4249,  name = "Dark Leather Belt" },
	{ from = 150, to = 160, crafts = 11, item = 4236,  name = "Cured Heavy Hide" },
	{ from = 160, to = 170, crafts = 11, item = 4265,  name = "Heavy Armor Kit" },
	{ from = 170, to = 200, crafts = 33, item = 5964,  name = "Barbaric Shoulders" },
	{ from = 200, to = 220, crafts = 22, item = 8173,  name = "Thick Armor Kit" },
	{ from = 220, to = 250, crafts = 33, item = 8176,  name = "Nightscape Headband" },
	{ from = 250, to = 260, crafts = 11, item = 8193,  name = "Nightscape Pants" },
	{ from = 260, to = 290, crafts = 33, item = 15564, name = "Rugged Armor Kit" },
	{ from = 290, to = 300, crafts = 11, item = 15086, name = "Wicked Leather Headband" },
} }

G.cooking = G.cooking or {}
G.cooking.classic = { max = 300, steps = {
	{ from = 1,   to = 50,  crafts = 55, item = 2680,  name = "Spiced Wolf Meat" },
	{ from = 50,  to = 90,  crafts = 45, item = 5525,  name = "Boiled Clams" },
	{ from = 90,  to = 130, crafts = 45, item = 2683,  name = "Crab Cake" },
	{ from = 130, to = 175, crafts = 50, item = 3665,  name = "Curiously Tasty Omelet" },
	{ from = 175, to = 225, crafts = 55, item = 12210, name = "Roast Raptor" },
	{ from = 225, to = 275, crafts = 55, item = 18045, name = "Tender Wolf Steak" },
	{ from = 275, to = 300, crafts = 30, item = 13928, name = "Grilled Squid" },
} }
