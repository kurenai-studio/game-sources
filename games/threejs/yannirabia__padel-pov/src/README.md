# Play Padel 🎾

Un jeu de padel en 3D à la première personne, jouable directement dans le navigateur (Three.js).
Vue « casque VR » sans casque : choisissez votre champion (Djokovic, Nadal, Federer, Alcaraz ou Sinner) et affrontez l'ordinateur en 1 contre 1 ou en 2 contre 2 avec un coéquipier — ou vos amis **en ligne** (jusqu'à 4 joueurs), dans un stade au choix : tribunes rouges inspirées d'Anfield, ou tribunes bleu ciel et blanches sous le toit ondulé du Vélodrome de Marseille. Premier à 7 points.

## Lancer le jeu

- **En ligne :** 👉 [padel-pov.vercel.app](https://padel-pov.vercel.app) (ou [yannirabia.github.io/padel-pov](https://yannirabia.github.io/padel-pov/))
- **Le plus simple :** ouvrez `index.html` dans Chrome, Firefox ou Safari (connexion Internet requise pour charger Three.js).
- **Si la page reste noire :** lancez un serveur local dans le dossier, puis ouvrez http://localhost:8000
  ```bash
  python3 -m http.server 8000
  ```

## Jouer en ligne avec vos amis (1 contre 1 ou 2 contre 2)

1. Choisissez **EN LIGNE** sur l'écran d'accueil, puis votre joueur.
2. L'hôte choisit **1 contre 1** ou **2 contre 2**, puis clique sur **Créer une partie** : un code à 4 caractères s'affiche.
3. Il envoie ce code à ses amis, qui choisissent **EN LIGNE**, saisissent le code et cliquent sur **Rejoindre**.
4. En 1 contre 1, le match démarre dès que l'adversaire arrive. En 2 contre 2, l'hôte clique sur **Lancer le match** : les places libres sont jouées par l'ordinateur (et si un joueur quitte en cours de match, l'ordinateur le remplace).

Les deux navigateurs se connectent directement (WebRTC via [PeerJS](https://peerjs.com)) : aucun serveur à installer, le jeu reste une simple page web. Le navigateur de celui qui crée la partie calcule la balle, le score et les joueurs de l'ordinateur. Chaque champion ne peut être choisi qu'une fois par partie.
Sur certains réseaux très filtrés (Wi‑Fi d'entreprise ou d'école), la connexion directe peut échouer : essayez alors un autre réseau (4G par exemple).

## Comment bien frapper

- **Le timing compte** : frappez quand la balle est à environ 1 m de vous, à hauteur de hanche. Le jeu affiche **PARFAIT**, **BIEN**, **TROP TÔT**, **TROP TARD** ou **DÉCENTRÉ**.
- Une frappe parfaite part vite et précisément ; une frappe ratée part moins vite, à côté de la cible, et peut finir **dans le filet ou sur la vitre** (faute).
- **Maintenez le clic** pour charger la puissance (jauge sous le viseur) : balle plus rapide et plus profonde, mais plus risquée.
- **Smash** : une balle haute près du filet part en smash, très difficile à reprendre.
- **Service** : il doit rebondir avant la ligne de service adverse. Une faute = second service, deux fautes = point perdu. Servir fort est plus risqué.
- **Pour marquer** : l'adversaire rate plus souvent quand vous frappez vite et loin de lui. Il joue aussi tactiquement : il vise l'espace libre, lobe si vous êtes au filet, amortit si vous êtes au fond, smashe les balles hautes et monte parfois au filet pour volleyer. En niveau Expert, l'anneau d'aide au rebond disparaît.

## Sur téléphone

Ouvrez le lien sur votre téléphone et tournez-le **en mode paysage** (le jeu passe en plein écran quand c'est possible).

| Action | Geste |
| --- | --- |
| Se déplacer | Joystick sous le **pouce gauche** (il apparaît là où vous posez le doigt) |
| Regarder / viser | **Glisser** le doigt ailleurs sur l'écran |
| Frapper / servir | Bouton **FRAPPER** — maintenez pour plus de puissance |
| Lob / amortie | Boutons **LOB** et **AMORTIE** |
| Pause | Bouton ❚❚ en haut à gauche |

## Commandes (ordinateur)

| Action | Touche |
| --- | --- |
| Se déplacer | `Z` `Q` `S` `D` (ou `W` `A` `S` `D`) ou flèches |
| Regarder / viser | Souris |
| Frapper / servir | Clic gauche ou `Espace` (maintenir = plus de puissance) |
| Lob | Regarder vers le haut en frappant |
| Balle courte | Regarder vers le bas en frappant |
| Pause | `Échap` |

## Fonctionnalités

- 3 modes : **1 contre 1**, **2 contre 2** (votre coéquipier couvre l'autre moitié du terrain) et **en ligne** (1 contre 1 ou 2 contre 2, jusqu'à 4 joueurs)
- Terrain de 11 × 22 m, un peu plus grand qu'un terrain officiel (10 × 20 m), pour des échanges plus aérés
- 5 champions au choix — Djokovic, Nadal, Federer, Alcaraz, Sinner — en tenue de tennis aux couleurs de leur pays (nom dans le dos, drapeau sur la poitrine), animés (course, frappe)
- 3 niveaux : **Amateur**, **Pro**, **Expert** — l'adversaire court plus vite, se trompe moins et frappe plus fort et plus près des lignes à chaque niveau
- 2 stades au choix (Anfield ou Vélodrome), avec quatre tribunes pleines de supporters qui sautent à chaque point — en ligne, tout le monde joue dans le stade choisi par l'hôte
- Terrain bleu, lignes blanches, filet, parois vitrées et grillages
- 5 couleurs de raquette : rouge, bleu, vert, jaune, violet
- Raquette personnalisable : couleur, et au choix un **drapeau** (20 pays), un **nom** et/ou un **numéro** — 1, 2 ou 3 éléments, la taille s'adapte automatiquement ; aperçu en direct dans le menu, choix mémorisé, visible par vos adversaires en ligne
- Assistance légère : portée de frappe généreuse, balle qui passe toujours le filet, anneau indiquant le point de rebond, raquette qui s'illumine quand la balle est à portée
- Balle lumineuse avec traînée et ombre au sol
- Rebonds sur le sol et les vitres, règles de padel simplifiées
- Sons générés (frappe, rebond, vitre, filet, points)
- Écran d'accueil, pause, écran de fin avec « Rejouer »

## Réglages

Dans `index.html` : sensibilité souris (`0.0022`), vitesse du joueur (`5.5`), niveaux de difficulté (objet `LEVELS` : vitesse des adversaires, taux d'erreur, puissance, portée de frappe).

## Licence

[MIT](LICENSE)
