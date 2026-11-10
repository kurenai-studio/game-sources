# The crossword-reconstruction puzzle data for doc/RULES.md's third
# single-player mode: each puzzle is 13 (clue, 9-letter answer) pairs,
# one per board row. Extracted from Michel Cheenne's `GRILLE *.xls`
# sheets (kept privately, not in this repository) — every
# `GRILLE nn&mmr.xls` sheet prints both puzzle nn's own (unanswered)
# clues AND puzzle mm's answer key (its clues WITH their solutions), so
# e.g. `02&01r.xls`'s answer-key half is puzzle 1's complete, solved
# data. Puzzles 1-10 (from `02&01r.xls` through `11&10r.xls`) are all
# usable this way; puzzle 11 has clues but no file ever supplies its
# answers, so it can't be included here.
class_name CrosswordPuzzles
extends RefCounted

const PUZZLES := [
	[
		["Oiseau pastis.", "PERROQUET"],
		["S'occupe des légumes", "JARDINIER"],
		["Véhicule spécialisé.", "AMBULANCE"],
		["Boirez goulûment.", "SIFFLEREZ"],
		["POETE.", "KARLFELDT"],
		["Femme d'envahisseur venu de l'est.", "WISIGOTHE"],
		["Périlleux.", "DANGEREUX"],
		["Concert.", "SYMPHONIE"],
		["Vaudrais cher.", "COUTERAIS"],
		["Dames-jeannes.", "BOMBONNES"],
		["Subsistent.", "SURVIVENT"],
		["Admises", "ACCEPTEES"],
		["Font Briller.", "ASTIQUENT"],
	],  # Puzzle 1
	[
		["Équilibre.", "STABILITE"],
		["Réclamez.", "QUEMANDEZ"],
		["Méfiante.", "INCREDULE"],
		["Petits véhicules sur rails.", "WAGONNETS"],
		["A pied, use les souliers.", "KILOMETRE"],
		["Intéressons fortement.", "CAPTIVONS"],
		["Briller beaucoup.", "FLAMBOYER"],
		["Retire la prise.", "DEBRANCHE"],
		["Prouver.", "JUSTIFIER"],
		["Unau.", "PARESSEUX"],
		["Relatifs aux champignons.", "FONGIQUES"],
		["Directeur d'un lycée.", "PROVISEUR"],
		["Expient.  (Se …)", "RACHETENT"],
	],  # Puzzle 2
	[
		["Caissons.", "COFFRAGES"],
		["Aggloméré .", "BRIQUETTE"],
		["Tension du ressort d'une horloge.", "REMONTAGE"],
		["Véhicule lourd.", "HALFTRACK"],
		["Fait voir plus loin.", "PRESBYTIE"],
		["Apprendrez.", "ETUDIEREZ"],
		["Juste à côté.", "JUXTAPOSE"],
		["Habitantes d'un pays voisin.", "WALLONNES"],
		["ILES.", "MARQUISES"],
		["Intolérantes.", "CHAUVINES"],
		["Léger.", "IMPRUDENT"],
		["Fil Tressé.", "CORDONNET"],
		["Fume.", "FERTILISE"],
	],  # Puzzle 3
	[
		["Relatif à l'estomac.", "GASTRIQUE"],
		["Fromages (cool).", "FROMETONS"],
		["Adresseriez.", "ENVERRIEZ"],
		["Zéro de conduite.", "CHAUFFARD"],
		["Desserts.", "VACHERINS"],
		["Périodique.", "BIMENSUEL"],
		["Unités de mesure.", "KILOWATTS"],
		["Restitue.", "REMBOURSE"],
		["Bâclent.", "EXPEDIENT"],
		["Dynamique.", "PETULANTE"],
		["…de la flotte peut-être.", "EQUIPAGES"],
		["Champignons.", "CLITOCYBE"],
		["Fumons, buttons, fauchons…", "JARDINONS"],
	],  # Puzzle 4
	[
		["Demi-portion.", "FRELUQUET"],
		["Manque d'audace.", "FRILOSITE"],
		["Rétrocédiez.", "REVENDIEZ"],
		["Toxique.", "VENENEUSE"],
		["Période.", "PRINTEMPS"],
		["Manettes.", "JOYSTICKS"],
		["Emouvants.", "TOUCHANTS"],
		["Ajustaient.", "CADRAIENT"],
		["Jeu d'eau.", "WATERPOLO"],
		["Bons pour la retraite.", "FLAMBEAUX"],
		["Enrôlé.", "EMBRIGADE"],
		["Attaquions.", "CHARGIONS"],
		["Coquillages.", "BERNIQUES"],
	],  # Puzzle 5
	[
		["Embrasse tout.", "UNIVERSEL"],
		["Examen minutieux.", "EPLUCHAGE"],
		["TEMPLE du TENNIS.", "WIMBLEDON"],
		["Chansons.", "COMPTINES"],
		["Contradicteurs.", "FRONDEURS"],
		["Conclusions vues en troisième ligne.", "TIEBREAKS"],
		["Hormone.", "THYROXINE"],
		["Tout le monde peut l'être.", "QUICONQUE"],
		["CHEF-LIEU de CANTON - 48.", "MARVEJOLS"],
		["Glisseras.", "PATINERAS"],
		["Réduit la température.", "FEBRIFUGE"],
		["Touchées.", "ATTEINTES"],
		["Répertoriez l'are.", "CADASTREZ"],
	],  # Puzzle 6
	[
		["Rassemblés", "MOBILISES"],
		["Demanderesse", "PLAIDANTE"],
		["Assombrie", "OBSCURCIE"],
		["Solides agglomérats de poudres", "FRITTAGES"],
		["Funèbre", "FUNERAIRE"],
		["Précisément", "JUSTEMENT"],
		["Dénaturons", "DEFORMONS"],
		["Enfermerez vos moutons", "PARQUEREZ"],
		["Biquette", "CHEVRETTE"],
		["Fondée par saint Bernard", "CLAIRVAUX"],
		["Additionnée d'un acide", "PHENIQUEE"],
		["Dégageons", "DEBLAYONS"],
		["Nom ancien, d'une ville du comté de Dublin", "KINGSTOWN"],
	],  # Puzzle 7
	[
		['Travailler en "RAFALES"', "BOMBARDER"],
		["Enracinée", "CHRONIQUE"],
		["INGENIEUR, le premier à énoncer le principe du radar", "GERNSBACK"],
		["Non séparées", "INDIVISES"],
		["Pertinent", "JUDICIEUX"],
		["Distante", "LOINTAINE"],
		["Vole chez des voisins", "LUFTWAFFE"],
		["Bousculent", "MALMENENT"],
		["Etouffez", "OPPRESSEZ"],
		["Ecot", "QUOTEPART"],
		["REGION de GRECE", "THESSALIE"],
		["Retournèrent encore", "TERCERENT"],
		["Usagers de lignes…", "VOYAGEURS"],
	],  # Puzzle 8
	[
		["Restes après comptes", "RELIQUATS"],
		["Trop d'indulgence", "FAIBLESSE"],
		["Organe de distribution d'un carburant", "INJECTEUR"],
		["Rus dans les rues", "CANIVEAUX"],
		["Période non définie", "LONGTEMPS"],
		["Levrettes d'Italie", "LEVRONNES"],
		["Dédier", "DEDICACER"],
		["Petit chien de compagnie", "YORKSHIRE"],
		["Affiche la puissance", "WATTMETRE"],
		["Un des effets de l'aspirine", "FEBRIFUGE"],
		["Cernions", "TRAQUIONS"],
		["Parez", "POMPONNEZ"],
		["Plis", "HABITUDES"],
	],  # Puzzle 9
	[
		["Habitante", "CITOYENNE"],
		["Maître d'hôtel", "MAJORDOME"],
		["Sujet d'émir", "KOWEITIEN"],
		["Sans retenue", "EFFRENEES"],
		["Piquez", "CHAPARDEZ"],
		["Peut qualifier la Physique ou la Mécanique", "QUANTIQUE"],
		["Félins", "PANTHERES"],
		["Atlas est du nombre", "VERTEBRES"],
		["Oiseaux colorés d'Europe", "PICSVERTS"],
		["Garçon de courses", "GROUILLOT"],
		["Groupes d'admirateurs", "FANSCLUBS"],
		["Gratte-ciel", "BUILDINGS"],
		["Les précédents en dévorent énormément", "MATERIAUX"],
	],  # Puzzle 10
]
