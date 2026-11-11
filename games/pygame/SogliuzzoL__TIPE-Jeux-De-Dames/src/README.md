# IA — jeu de dames

Projet **TIPE** (CPGE, 2024–2025) : moteur de dames internationales (plateau 10×10, 20 pions par camp) avec interface Pygame, et plusieurs adversaires automatiques, dont un agent entraîné par évolution.

## Contenu

| Fichier | Rôle |
|---|---|
| `src/plateau.py` | Règles : déplacements, prises obligatoires, promotion en dame, partie nulle après 25 coups sans prise |
| `src/main.py` | Boucle Pygame : humain contre bot, bot contre bot, simulations en série |
| `src/bots/ia.py` | Agent PyTorch : deux réseaux (choix de la pièce à déplacer, puis de la case d'arrivée) entraînés par évolution — population de modèles, mutation et croisement, sélection par parties contre un adversaire aléatoire |
| `src/bots/minimax.py` | Ébauche de minimax |
| `src/config.json` | Réglages : type de bot (`0` aléatoire, `1` minimax, `2` réseau), entraînement, camp du joueur |
| `src/datas/`, `src/score_7x7.csv` | Scores de balayages d'hyperparamètres (largeur × longueur de la couche cachée) |
| `src/graph*.py` | Tracés des scores et de leur évolution |
| `src/model_start_*`, `src/model_end_*` | Poids entraînés (format `torch.save`) |

## Lancer

```bash
cd src
python main.py
```

Le comportement est piloté par `config.json` : `bot_used` choisit l'adversaire, `human_vs_bot` passe en simulation, `ia_training` lance l'entraînement.

Dépendances : `pygame`, `torch`, `numpy`, `matplotlib`, `treelib`.

## Résultats

Les fichiers `datas/score_*.csv` et `score_7x7.csv` contiennent, pour chaque couple de tailles de couche cachée testé, les scores obtenus sur des séries de parties ; `graph.py` et `graph_evolution_score.py` les transforment en courbes.

## Limites

- Le bot « minimax » est une ébauche : `run_minimax` renvoie le premier coup légal, il ne joue pas réellement.
- `reconnaissance_image.py` est un script exploratoire qui attend des images (`jeudedames.jpg`) non fournies : il ne s'exécute pas tel quel.
- Aucun `requirements.txt` : les versions de dépendances ne sont pas épinglées.
- Les poids fournis sont ceux du dernier entraînement conservé, pas une référence reproductible.
