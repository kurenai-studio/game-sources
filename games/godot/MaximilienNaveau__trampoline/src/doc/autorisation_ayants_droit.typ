// Autorisation des ayants droit de Michel Cheenne (voir NOTICE).
// PDF à imprimer : typst compile doc/autorisation_ayants_droit.typ
//   (ou : nix run nixpkgs#typst -- compile doc/autorisation_ayants_droit.typ)

#set document(title: "Autorisation de diffusion — Trampoline")
#set page(paper: "a4", margin: (x: 2.5cm, y: 2.5cm))
#set text(lang: "fr", size: 12pt)
#set par(justify: true, leading: 0.8em)
#show table: set par(justify: false)

#align(center)[
  #text(size: 18pt, weight: "bold")[Autorisation de diffusion]
  #v(0.2em)
  #text(size: 13pt)[« Trampoline – un jeu pour faire rebondir les mots »]
]

#v(2em)

Nous, soussignés, ayants droit de Michel Cheenne, co-auteur avec
Maximilien Naveau du jeu « Trampoline – un jeu pour faire rebondir les
mots », acceptons que l'œuvre de Michel Cheenne intégrée au jeu (ses
règles et ses grilles de mots croisés) soit diffusée avec le jeu sous la
licence GNU General Public License version 3 (GPL-3.0-only), y compris
dans des versions commerciales, à condition que Michel Cheenne soit
toujours crédité comme co-auteur.

Nous autorisons en outre Maximilien Naveau à diffuser de futures versions
du jeu sous une autre licence de son choix, à la même condition.

#v(2.5em)

Fait à #box(width: 6cm, repeat[.]), le #box(width: 4cm, repeat[.])

#v(2em)

Noms et signatures :

#v(0.8em)

#table(
  columns: (1.6fr, 1.2fr, 1.2fr),
  rows: (auto, 2.6cm, 2.6cm, 2.6cm, 2.6cm),
  inset: 8pt,
  align: (left + top),
  table.header(
    [*Nom et prénom*], [*Lien avec Michel Cheenne*], [*Signature*],
  ),
  [], [], [],
  [], [], [],
  [], [], [],
  [], [], [],
)
