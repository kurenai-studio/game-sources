// Gals are budding yeasts with clustered daughters, or molds (Fumi) that play
// as a spore planting colonies (see mold.js).
//
// `zone`: inhibition diameter (mm), scaled by ZONE_*; null = resistant.
// Candi: CLSI M44 approximations. Sasha/Olive: efficacy estimates.
//
// `antifungals`: disks in level order, with standard codes.
// `scientific`: species above dish; gal's name uses her `color`.
// Italics throughout unless *asterisks* mark specific parts.
// `colors`: daughter-cell colors.
// `facts`: random win/lose pop-up facts (game/facts.js); *names* italicize.
export const SPECIES = {
  sasha: {
    facts: [
      "Sasha's genus name, Saccharomyces, means \"sugar fungus.\"",
      "Sasha makes bread rise: the carbon dioxide she gives off puffs the dough up with bubbles.",
      "Sasha turns sugar into alcohol and carbon dioxide, which is how beer and wine are made.",
      "Sasha reproduces by budding: a small daughter swells out of her side and pinches off.",
      "Each time Sasha buds, she gets a ring-shaped bud scar, so you can count her daughters.",
      "In 1996, Sasha became the first eukaryote to have her whole genome sequenced.",
      "Unlike bacteria, Sasha keeps her DNA in a nucleus, just like your cells do.",
      "Fungi like Sasha are more closely related to animals than to plants.",
      "In the 1850s, Louis Pasteur showed that living yeast like Sasha causes fermentation.",
      "Scientists study Sasha to learn how cell division, aging and DNA repair work in us.",
      "Sasha's cell wall has a little chitin in it, the same tough stuff as insect shells.",
      "Sasha can live with one set of chromosomes (haploid) or two (diploid).",
      "Sasha makes alcohol from sugar even with oxygen around, called the Crabtree effect.",
      "Engineered cells of Sasha's species help make insulin for people with diabetes.",
    ],
    scientific: 'Saccharomyces cerevisiae',
    color: '#8a5a2b', // for her name above the dish
    kind: 'yeast',
    colors: { fill: '#f3dfbf', stroke: '#8a5a2b', highlight: '#fbf3e4', dark: '#5b3a1e' },
    antifungals: [
      { code: 'AMB', name: 'amphotericin B', zone: 17 },
      { code: 'NY', name: 'nystatin', zone: 20 },
      { code: 'VOR', name: 'voriconazole', zone: 25 },
      { code: 'CAS', name: 'caspofungin', zone: 20 },
      { code: 'FLC', name: 'fluconazole', zone: 15 },
    ],
  },
  candi: {
    facts: [
      "Candi lives harmlessly in the mouth, gut and skin of most people.",
      "Candi can switch shapes: round budding yeast cells or long threads called hyphae.",
      "Switching to hyphae helps Candi push into tissue, part of how she causes disease.",
      "Candi causes thrush, white patches inside the mouth.",
      "Candi is the most common cause of yeast infections.",
      "Candi's genus, *Candida*, comes from candidus, Latin for white, like her creamy colonies.",
      "In serum at body temperature, Candi sprouts germ tubes within hours, a classic lab test.",
      "On a special agar called CHROMagar Candida, Candi's colonies turn green.",
      "Candi builds slimy biofilms on catheters and other medical devices.",
      "Antibiotics can let Candi overgrow by killing the bacteria that usually keep her in check.",
      "Candi makes a toxin called candidalysin that punches holes in human cells.",
      "On cornmeal agar, Candi makes chlamydospores: big, round, thick-walled cells.",
      "Candi's cousin *Candida auris* was first described in 2009 and resists many antifungals.",
    ],
    scientific: 'Candida albicans',
    color: '#1d4ed8', // for her name above the dish
    kind: 'yeast',
    colors: { fill: '#d6e8ff', stroke: '#2563eb', highlight: '#ffffff', dark: '#1e3a8a' },
    antifungals: [
      { code: 'FLC', name: 'fluconazole', zone: 30 },
      { code: 'NY', name: 'nystatin', zone: 21 },
      { code: 'VOR', name: 'voriconazole', zone: 31 },
      { code: 'MCF', name: 'micafungin', zone: 27 },
      { code: 'CAS', name: 'caspofungin', zone: 22 },
    ],
  },
  olive: {
    facts: [
      "Olive's genus, *Malassezia*, is named for Louis-Charles Malassez, a French scientist.",
      "Olive's species name, *furfur*, is Latin for \"bran,\" after the flaky scales she causes.",
      "Yeasts in Olive's genus were once called *Pityrosporum*, a name meaning \"bran spore.\"",
      "Yeasts in Olive's genus live on most people's skin, especially oily spots like the scalp.",
      "Olive can't make her own fatty acids, so she eats the oils on your skin.",
      "One way to grow Olive in the lab is to add a thin layer of olive oil to her culture plate.",
      "Olive buds again and again from one end, so her cells can look like little bowling pins.",
      "Olive has a little collar at her budding site, called a collarette.",
      "*Malassezia* yeasts like Olive play a part in dandruff.",
      "Olive can cause pityriasis versicolor: patches of skin that turn lighter or darker.",
      "Scraped from her rash, Olive's hyphae and yeasts look like \"spaghetti and meatballs.\"",
      "Olive can infect preemies' blood via IV lines that feed them fats, which help her grow.",
      "Olive is a basidiomycete yeast, on the same big fungal branch as cap-and-stem mushrooms.",
    ],
    scientific: 'Malassezia furfur',
    color: '#556b14', // for her name above the dish
    kind: 'yeast',
    // She buds again and again from the same end of her cell (monopolar
    // budding), so her bud always grows from the top.
    budsFromOneEnd: true,
    colors: { fill: '#d9e6a6', stroke: '#6b7a2a', highlight: '#f7faea', dark: '#3a4410' },
    // Malassezia has no standard disk sizes, so these are estimates
    antifungals: [
      { code: 'KCA', name: 'ketoconazole', zone: 32 },
      { code: 'ITC', name: 'itraconazole', zone: 28 },
      { code: 'VOR', name: 'voriconazole', zone: 26 },
      { code: 'AMB', name: 'amphotericin B', zone: 17 },
    ],
  },
  yara: {
    facts: [
      "Yara's species name, *lipolytica*, means \"fat-breaking\": she can feed on fats.",
      "Yara's genus is named for David Yarrow, a yeast scientist.",
      "Yara stores fat in cell droplets, sometimes over a third of her dry weight.",
      "Yara can bud as single cells or grow attached chains called pseudohyphae.",
      "Yara can also grow true hyphae, long threads like a mold's.",
      "Yara turns up in cheese, sausages, soil and oil-polluted seawater.",
      "Yara can eat some oil hydrocarbons, so scientists study her for pollution cleanup.",
      "Companies use engineered Yara strains to make omega-3 fats for feed and supplements.",
      "Yara can make citric acid, which gives many fruit drinks their sour taste.",
      "Most Yara strains can't grow at 37°C, and she only rarely causes infections.",
      "Bioengineers study Yara for making biofuels because she's good at storing fat.",
      "Yara is an ascomycete, in the same broad fungal group as Sasha and Candi.",
    ],
    scientific: 'Yarrowia lipolytica',
    color: '#b4532f', // for her name above the dish
    kind: 'yeast',
    // Plump, egg-shaped cells that bud from their ends, with daughters that
    // line up end to end in chains instead of bunching (see yeast.js).
    chains: true,
    // All apricot; `oil` is the droplets of fat inside her cells.
    colors: { fill: '#fbd3bd', stroke: '#b4532f', highlight: '#fff4ec', dark: '#6e2f17', oil: '#fde9a8' },
    // There are no standard disk sizes for Yarrowia, so these are estimates
    // from how well each drug works on her in the lab. Fluconazole works
    // only weakly on her, so its zone is small.
    antifungals: [
      { code: 'AMB', name: 'amphotericin B', zone: 18 },
      { code: 'VOR', name: 'voriconazole', zone: 26 },
      { code: 'CAS', name: 'caspofungin', zone: 20 },
      { code: 'ITC', name: 'itraconazole', zone: 22 },
      { code: 'FLC', name: 'fluconazole', zone: 14 },
    ],
  },
  peachy: {
    facts: [
      "Peachy can live on methanol, a simple alcohol that's an unusual food for a yeast.",
      "On methanol, Peachy grows larger and more numerous peroxisomes inside her cells.",
      "Peachy starts breaking down methanol in peroxisomes that help contain toxic byproducts.",
      "Engineered Peachy strains make useful proteins, including insulin and vaccine parts.",
      "Scientists can engineer Peachy to release useful proteins, making collection easier.",
      "With enough oxygen, Peachy favors respiration over fermentation and grows densely.",
      "Peachy's biotech strains trace back to yeast collected from California black oak trees.",
      "In the 1970s, Phillips Petroleum grew Peachy on methanol for an animal-feed project.",
      "Labs often call Peachy *Pichia pastoris*, but she's now *Komagataella phaffii*.",
      "Peachy is an ascomycete, in the same broad fungal group as Sasha and Candi.",
      "Peachy is not considered a human pathogen.",
    ],
    scientific: 'Komagataella phaffii',
    color: '#be3f73', // for her name above the dish
    kind: 'yeast',
    // Pink peroxisomes inside her cells (see yeast.js).
    peroxisomes: true,
    // All rose; `perox` is her peroxisomes.
    colors: { fill: '#fcd5e3', stroke: '#be3f73', highlight: '#fff1f6', dark: '#6d1d3f', perox: '#f6a6c6' },
    // There are no standard disk sizes for Komagataella, so these are estimates.
    // She's a lab yeast that common antifungals work on well.
    antifungals: [
      { code: 'AMB', name: 'amphotericin B', zone: 17 },
      { code: 'FLC', name: 'fluconazole', zone: 22 },
      { code: 'VOR', name: 'voriconazole', zone: 28 },
      { code: 'CAS', name: 'caspofungin', zone: 21 },
      { code: 'NY', name: 'nystatin', zone: 19 },
    ],
  },
  maizey: {
    facts: [
      "Maizey causes corn smut, swelling kernels into galls that darken as spores mature.",
      "In Mexico, Maizey's young galls are eaten as huitlacoche, the \"Mexican truffle.\"",
      "Alone, Maizey grows as a cigar-shaped budding yeast that doesn't infect corn.",
      "To infect corn, two Maizey cells with compatible mating types normally fuse first.",
      "After mating, Maizey grows as threads called hyphae that enter the corn plant.",
      "Maizey's galls can grow on corn's ears, tassels, leaves and stems.",
      "Maizey's mature galls produce masses of dark resting spores called teliospores.",
      "Maizey's resting spores can survive in soil and corn debris for several years.",
      "Maizey is a basidiomycete, more closely related to mushrooms than to Sasha.",
      "Scientists study Maizey to learn how fungi trick plants and cause disease.",
      "Maizey's species name, *maydis*, means \"of maize,\" another word for corn.",
    ],
    scientific: 'Ustilago maydis',
    color: '#6b3f96', // for her name above the dish
    kind: 'yeast',
    // Long cigar-shaped cells that bud from their tips (see yeast.js).
    cigars: true,
    // All plum, a nod to huitlacoche's inky color.
    colors: { fill: '#e6d8f2', stroke: '#6b3f96', highlight: '#f7f0fd', dark: '#3b1f57' },
    // There are no standard disk sizes for Ustilago, so these are estimates.
    // Like many basidiomycete yeasts, she's thought to shrug off caspofungin,
    // so its zone is small.
    antifungals: [
      { code: 'AMB', name: 'amphotericin B', zone: 18 },
      { code: 'VOR', name: 'voriconazole', zone: 26 },
      { code: 'ITC', name: 'itraconazole', zone: 24 },
      { code: 'FLC', name: 'fluconazole', zone: 17 },
      { code: 'CAS', name: 'caspofungin', zone: 12 },
    ],
  },
  ruby: {
    facts: [
      "Ruby is the \"bleeding tooth fungus\": her young white cap oozes bright red drops.",
      "Ruby's red drops aren't blood: they're watery fluid released by \"guttation.\"",
      "Instead of gills, Ruby has tiny \"teeth\" under her cap that release spores.",
      "Ruby lives with pine and spruce trees, trading nutrients with their roots.",
      "Atromentin, a pigment linked to Ruby, has slowed blood clotting in lab tests.",
      "Ruby gets sugars from tree roots and helps her tree partner gather soil nutrients.",
      "Ruby's young caps are white and fuzzy, and they turn brown as they get older.",
      "Ruby can grow around forest litter, trapping little bits as she grows.",
      "Ruby is a basidiomycete, a mushroom-making cousin of Maizey.",
      "Ruby's species name, *peckii*, honors American mycologist Charles Horton Peck.",
      "Ruby is too acrid to eat, but people use her to dye wool.",
    ],
    scientific: 'Hydnellum peckii',
    color: '#b0283a', // for her name above the dish
    kind: 'mold',
    // Her colonies bead with red drops as they ripen (see mold.js).
    drops: true,
    colors: {
      fill: '#fdf4f2', stroke: '#a8323f', highlight: '#ffffff', dark: '#5c1a22', spores: '#c4917c', drop: '#e0283a',
    },
    // There are no standard disk sizes for Hydnellum, so these are
    // estimates. Like many basidiomycetes she's thought to shrug off
    // caspofungin, so its zone is small.
    antifungals: [
      { code: 'AMB', name: 'amphotericin B', zone: 18 },
      { code: 'VOR', name: 'voriconazole', zone: 24 },
      { code: 'ITC', name: 'itraconazole', zone: 22 },
      { code: 'POS', name: 'posaconazole', zone: 26 },
      { code: 'CAS', name: 'caspofungin', zone: 13 },
    ],
  },
  rosie: {
    facts: [
      "Rosie can cause \"rose gardener's disease\" after entering skin through a thorn prick.",
      "Rosie lives in soil, sphagnum moss, hay and on plants like rose bushes.",
      "Rosie's tiny spores form flower-like bunches at the tips of her threads.",
      "Rosie also makes dark spores that sit right along her threads.",
      "Rosie is two-faced: a mold at cooler temperatures, but a budding yeast in a warm body.",
      "Rosie's colonies start white or cream and can become wrinkled and brown-black.",
      "Rosie's dark pigment is melanin, a pigment family that also includes our skin pigments.",
      "Rosie's skin infections can form a line of bumps up an arm along lymph vessels.",
      "Itraconazole is the usual medicine for Rosie's skin infections.",
      "In Brazil, Rosie's cousin *Sporothrix brasiliensis* spreads among cats and to people.",
      "Rosie's genus name, *Sporothrix*, comes from words meaning \"spore\" and \"hair\".",
    ],
    scientific: 'Sporothrix schenckii',
    color: '#3d3632', // for her name above the dish
    kind: 'mold',
    // Her colonies darken and wrinkle as they ripen (see mold.js).
    wrinkled: true,
    // Cream and charcoal-brown: `fill`/`stroke`/`highlight`/`dark` for her
    // stalk, crown and spore, and `spores` for the dark brown-black her
    // colonies turn from the middle out.
    colors: { fill: '#f4ece6', stroke: '#3d3632', highlight: '#ffffff', dark: '#1f1a17', spores: '#3d3632' },
    // There are no standard disk sizes for Sporothrix, so these are
    // estimates. Itraconazole is her usual treatment and terbinafine works
    // well too; fluconazole works poorly on her, so its zone is small.
    antifungals: [
      { code: 'ITC', name: 'itraconazole', zone: 28 },
      { code: 'TRB', name: 'terbinafine', zone: 26 },
      { code: 'AMB', name: 'amphotericin B', zone: 20 },
      { code: 'POS', name: 'posaconazole', zone: 22 },
      { code: 'FLC', name: 'fluconazole', zone: 12 },
    ],
  },
  neve: {
    facts: [
      "Neve's sugar capsule appears as a clear halo against dark India ink.",
      "Neve's capsule helps protect her from the immune system.",
      "Neve lives in soil and old pigeon droppings, and infection starts by breathing her in.",
      "Neve can cause meningitis, especially in people with weakened immune systems.",
      "Neve makes buds attached by a narrow neck.",
      "Neve can grow at body temperature, 37 °C, which helps her cause disease.",
      "Neve makes melanin, a dark pigment that helps protect her from damage.",
      "On birdseed agar, Neve makes melanin that turns her colonies brown.",
      "Neve is a basidiomycete, a yeast cousin of Maizey and Ruby.",
      "Neve's meningitis is treated with amphotericin B and flucytosine, then fluconazole.",
      "Neve is naturally resistant to echinocandin drugs like caspofungin.",
      "Neve's species name, *neoformans*, means \"new-forming.\"",
    ],
    scientific: 'Cryptococcus neoformans',
    color: '#0e7490', // for her name above the dish
    kind: 'yeast',
    capsule: true,
    // `capsule` is her capsule's rim and `capsuleFill` its faint cyan tint,
    // so in the dish her cells stand out a little from the white disks.
    colors: {
      fill: '#b9e1e8', stroke: '#0e7490', highlight: '#ffffff', dark: '#0b3b46', capsule: '#a8d6de', capsuleFill: '#e3f5f8',
    },
    // There are no standard disk sizes for Cryptococcus, so these are
    // estimates. She's treated with amphotericin B and flucytosine, then
    // fluconazole. Echinocandins like caspofungin don't work on her at all,
    // so she gets no CAS disk, the way Fumi gets no FLC disk.
    antifungals: [
      { code: 'AMB', name: 'amphotericin B', zone: 20 },
      { code: '5FC', name: 'flucytosine', zone: 18 },
      { code: 'FLC', name: 'fluconazole', zone: 24 },
      { code: 'VOR', name: 'voriconazole', zone: 28 },
      { code: 'ITC', name: 'itraconazole', zone: 22 },
    ],
  },
  fumi: {
    facts: [
      "Fumi's species name, *fumigatus*, means \"smoky,\" for her smoky grey-green colonies.",
      "Fumi's genus is named for the aspergillum, a sprinkler used for holy water.",
      "Fumi's spores are only 2 to 3 micrometers across, so tiny they float on the air.",
      "Most people breathe in hundreds of Fumi's spores every day, and healthy lungs clear them.",
      "Fumi can grow at 50 °C, so she thrives in hot, rotting compost heaps.",
      "Fumi can cause aspergillosis, a lung infection in people with weak immune systems.",
      "Fumi's spores wear a coat of protein rodlets that hides them from the immune system.",
      "Fumi's spores get their grey-green color from a pigment called DHN-melanin.",
      "Fumi extends and branches her hyphae, often forming a circular colony on a plate.",
      "Fumi's colonies usually start white, then turn grey-green as she makes spores.",
      "Fumi makes chains of spores around a swollen stalk tip, forming a column-like head.",
      "Voriconazole is a first-line treatment for invasive aspergillosis caused by Fumi.",
      "Fumi is naturally resistant to fluconazole, a drug that works on many yeasts.",
      "Agricultural azole fungicides can select Fumi strains that resist azole medicines.",
    ],
    scientific: 'Aspergillus fumigatus',
    color: '#2f6b5e', // for her name above the dish
    kind: 'mold',
    // `fill`/`stroke`/`highlight`/`dark` are her spore's colors; `spores` is
    // the smoky green her colonies turn as they make spores.
    colors: { fill: '#dcebe5', stroke: '#3f7a6c', highlight: '#f4faf7', dark: '#1f4d43', spores: '#5b8c80' },
    // Molds have a CLSI disk test too (M51), but there are no settled zone
    // sizes for Aspergillus, so these are rough estimates. Like most molds,
    // she's naturally resistant to fluconazole, so she gets no FLC disk.
    antifungals: [
      { code: 'VOR', name: 'voriconazole', zone: 28 },
      { code: 'ITC', name: 'itraconazole', zone: 18 },
      { code: 'POS', name: 'posaconazole', zone: 30 },
      { code: 'AMB', name: 'amphotericin B', zone: 18 },
      { code: 'CAS', name: 'caspofungin', zone: 16 },
    ],
  },
  penelope: {
    facts: [
      "Alexander Fleming found Penelope's penicillin in 1928, when she spoiled one of his plates.",
      "Penelope's genus, *Penicillium*, means \"little paintbrush,\" for her spore stalks.",
      "Penelope's penicillin blocks bacterial cell-wall building.",
      "Modern penicillin-producing strains descend from Penelope on a moldy cantaloupe in Peoria.",
      "Mary Hunt, nicknamed \"Moldy Mary,\" found Penelope on a moldy cantaloupe in 1943.",
      "By D-Day in 1944, enough of Penelope's penicillin was made to treat wounded soldiers.",
      "Penelope's colonies are blue-green and velvety, with a fluffy white edge.",
      "Penelope's cousins make blue cheese like Roquefort and the white rind on Brie.",
      "Penelope's spores are so light they float on the air, so she turns up on bread and fruit.",
      "Penelope is an ascomycete, in the same big fungal group as Fumi, Sasha and Candi.",
      "Penelope's species name, *rubens*, means \"reddish.\"",
      "Fleming's mold was long called *Penicillium notatum*, but it turned out to be Penelope.",
    ],
    scientific: 'Penicillium rubens',
    color: '#3d5a8f', // for her name above the dish
    kind: 'mold',
    // All denim blue: `fill`/`stroke`/`highlight`/`dark` for her stalk,
    // and `spores` for the blue her colonies turn as they make spores.
    colors: { fill: '#dde6f0', stroke: '#3d5a80', highlight: '#f5f8fc', dark: '#26385a', spores: '#5f7fa8' },
    // There are no standard disk sizes for Penicillium, so these are
    // estimates from how well each drug works on her in the lab. Like most
    // molds, she's naturally resistant to fluconazole, so she gets no FLC disk.
    antifungals: [
      { code: 'ITC', name: 'itraconazole', zone: 24 },
      { code: 'AMB', name: 'amphotericin B', zone: 18 },
      { code: 'POS', name: 'posaconazole', zone: 26 },
      { code: 'VOR', name: 'voriconazole', zone: 20 },
      { code: 'CAS', name: 'caspofungin', zone: 16 },
    ],
  },
  miri: {
    facts: [
      "Miri is koji mold, grown on rice and soybeans to make miso and soy sauce.",
      "Miri turns rice starch into sugar for yeast to ferment into sake.",
      "Miri's enzymes unlock the savory umami taste in miso and soy sauce.",
      "In 2006, Japan's Brewing Society named Miri a national fungus.",
      "Miri is kin to *A. flavus*, but food strains do not make aflatoxin.",
      "Miri has been cultivated in East Asia for more than 1,000 years.",
      "Miri often grows radiating spore chains, making a round puff-like head.",
      "Miri's colonies can start white, then turn yellow-green to olive.",
      "In 1894, Jokichi Takamine patented Miri enzymes as Taka-diastase.",
      "Miri helps make mirin, rice vinegar, and amazake, a sweet rice drink.",
      "Miri and Fumi are cousins in the genus *Aspergillus*.",
      "Miri's species name, *oryzae*, means of rice.",
    ],
    scientific: 'Aspergillus oryzae',
    color: '#8c6d0f', // for her name above the dish
    kind: 'mold',
    // All golden honey: `fill`/`stroke`/`highlight`/`dark` for her spore
    // head and stalk, and `spores` for the olive yellow-green her colonies
    // turn as they make spores.
    colors: { fill: '#f7e6a0', stroke: '#8c6d0f', highlight: '#fffaf0', dark: '#4f3d06', spores: '#7d8a22' },
    // There are no standard disk sizes for Aspergillus, so these are
    // estimates from how well each drug works on her in the lab. Like Fumi,
    // she's naturally resistant to fluconazole, so she gets no FLC disk.
    antifungals: [
      { code: 'VOR', name: 'voriconazole', zone: 26 },
      { code: 'AMB', name: 'amphotericin B', zone: 16 },
      { code: 'POS', name: 'posaconazole', zone: 28 },
      { code: 'ITC', name: 'itraconazole', zone: 20 },
      { code: 'CAS', name: 'caspofungin', zone: 18 },
    ],
  },
};

// Each level adds an antifungal disk and doubles the colony you need to grow.
// A mold (Fumi) needs `colonies` colonies instead: 6 on level 1, and 6 more
// each level.
export const LEVELS = [
  { disks: 1, target: 4, colonies: 6 },
  { disks: 2, target: 8, colonies: 12 },
  { disks: 3, target: 16, colonies: 18 },
  { disks: 4, target: 32, colonies: 24 },
  { disks: 5, target: 64, colonies: 30 },
  { disks: 6, target: 128, colonies: 36 },
  { disks: 7, target: 256, colonies: 42 },
];

export const GAME = {
  GROUP_CAP: 8, // max cells per cluster
  CHAIN_CAP: 4, // max cells per chain, for a yeast that grows in chains (Yara)
  SNAP_REACH: 0.3, // bud attachment range, relative to dish radius
  NUTRIENTS_PER_DIVISION: 1, // nutrients per bud
  SPEED: 0.8, // dish radii per second
  ARRIVE: 0.01, // pointer tolerance, relative to dish radius
  DRAG_SPEED: 2, // drag cap in radii/sec; prevents skipping zones
  BURST_SPEED: 0.1, // split-off push; travel ≈ 0.5 × speed / settle rate
  SETTLE_RATE: 4, // slowdown rate; higher stops sooner
  SETTLE_MS: 1500, // time until offspring stay put
  SPACING: 0.5, // minimum spacing as a fraction of combined cell reach
  DIVIDE_MS: 600,

  // Disk size, center distance, and center-to-center gap in dish radii.
  DISK_RADIUS: 0.085,
  DISK_MIN_DISTANCE: 0.4,
  DISK_MAX_DISTANCE: 0.65,
  DISK_MIN_GAP: 0.4,

  // Zones block offspring and kill the player; mm maps linearly to width,
  // clamped to these limits. Widths are fractions of the dish radius.
  ZONE_MM_SMALL: 13,
  ZONE_MM_BIG: 40,
  ZONE_MIN_WIDTH: 0.02,
  ZONE_MAX_WIDTH: 0.075,

  // Zones grow from this fraction to full width over this many seconds.
  ZONE_START: 0.1,
  ZONE_SPREAD_SECONDS: 20,
  SWIM_ROOM: 0.13, // minimum gap between zones, in dish radii
  YEAST_NUTRIENTS: 8, // nutrient flecks on the agar at a time for a yeast

  // Molds (mold.js): the spore floats a little faster than a yeast swims.
  // A colony starts at COLONY_START and spreads at a steady pace, as hyphae
  // grow from its edge, to COLONY_FULL (dish radii) over COLONY_GROW_SECONDS.
  SPORE_SPEED: 1,
  MOLD_NUTRIENTS: 3, // flecks on the agar at a time (yeasts get YEAST_NUTRIENTS)
  COLONY_START: 0.025,
  COLONY_FULL: 0.15,
  COLONY_GROW_SECONDS: 5,
};
