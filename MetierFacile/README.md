# MetierFacile — addon World of Warcraft (Retail / Midnight 12.x)

Addon d'aide à la montée des métiers :

1. **Détecte vos métiers** et leur niveau **pour chaque extension** (Classique, Outreterre, … Khaz Algar, Midnight).
2. **Dit quoi fabriquer** pour chaque extension, étape par étape, jusqu'au niveau max.
3. **Calcule la liste exacte des composants à acheter**, en déduisant ce que vous possédez déjà
   (sacs, banque, banque de composants et banque de bataillon).

## Installation

Copiez le dossier `MetierFacile` dans `World of Warcraft/_retail_/Interface/AddOns/`, puis relancez le jeu.

## Utilisation

| Commande | Effet |
|---|---|
| `/mf` | Ouvre / ferme la fenêtre |
| `/mf scan` | Ouvre chaque métier un instant pour relever les niveaux par extension et les recettes |
| `/mf liste` | Affiche la liste d'achats de la sélection dans le chat |
| `/mf verifier` | Contrôle les guides intégrés contre les données du jeu |
| `/mf reset` | Efface les données de l'addon |

Un bouton **MetierFacile** apparaît aussi dans la fenêtre des métiers de Blizzard et dans le menu des addons de la minicarte.

**Première utilisation** : cliquez sur « Scanner les métiers » (ou ouvrez une fois chaque métier).
Le jeu ne donne les niveaux par extension et le détail des recettes que lorsque la fenêtre du métier est ouverte ;
MetierFacile les mémorise ensuite.

## Comment les quantités sont calculées

- Les **composants de chaque recette** (et leurs quantités) sont lus dans les données du jeu
  (`C_TradeSkillUI.GetRecipeSchematic`) : ils sont toujours exacts et à jour, dans la langue de votre client.
- Le **nombre de fabrications** vient du guide intégré. Si vous êtes au milieu d'une étape, le reste est calculé au prorata.
- La liste d'achats **simule tout le parcours** : les objets fabriqués à une étape (ex. rouleaux d'étoffe) servent aux
  étapes suivantes, votre stock est déduit, et — option « Fabriquer les intermédiaires » — un composant que votre métier
  sait fabriquer est remplacé par ses matières premières.
- Les composants vendus par les PNJ sont marqués « vendeur ».
- Si **Auctionator** ou **TradeSkillMaster** est installé, le coût estimé à l'hôtel des ventes est affiché.

## Guides intégrés et plan automatique

- **Guides intégrés** (`Data/Guides_Classic.lua`) : Classique 1-300 pour Alchimie, Couture, Ingénierie, Forge,
  Travail du cuir et Cuisine.
- **Plan automatique** pour toutes les autres combinaisons métier/extension (y compris Midnight) : quand la fenêtre du
  métier est ouverte sur une extension, MetierFacile classe vos recettes connues selon leur couleur actuelle (orange,
  jaune, vert) et leur coût par point de compétence, liste les « premières fabrications » qui donnent un bonus, et
  calcule les composants nécessaires pour atteindre le max. C'est une estimation recalculée à chaque fabrication.
- **Métiers de récolte** (Minage, Herboristerie, Dépeçage, Pêche) : rien à acheter, l'addon indique où récolter.

### Ajouter un guide

Ajoutez une table dans `Data/` (et le fichier dans `MetierFacile.toc`) :

```lua
ns.Guides.alchemy.outland = { max = 75, steps = {
	{ from = 1, to = 15, crafts = 16, item = <ID de l'objet>, name = "Nom anglais (lisibilité)" },
	-- item = ID de l'objet fabriqué ; recipe = ID de recette pour les enchantements
}}
```

Les clés d'extension sont listées dans `Constants.lua` (`ns.EXPANSIONS`). Vérifiez ensuite en jeu avec `/mf verifier` :
toute étape dont l'objet ne correspond à aucune recette de votre métier est signalée et exclue de la liste d'achats.

## Tests hors jeu

```
cd MetierFacile
lua5.1 tests/run_tests.lua      # ou : python3 tests/run_tests.py (nécessite `pip install lupa`)
```

Les tests simulent l'API WoW (`tests/wow_mock.lua`) : détection des métiers, paliers par extension, résolution des
recettes, calcul de la liste d'achats, plan automatique et scan.
