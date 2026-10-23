# FunGals 🍄

A cute mycology game for the browser, and the sister game to [PetriPals](https://github.com/jessicasogge/petripals). Pick a fungal gal and eat nutrients to grow your colony, but steer clear of the antifungal disks and their zones of inhibition.

**[▶ Play FunGals](https://jessicasogge.github.io/fungals/)**: works on computers, phones and tablets.

## How to play

1. **Pick a gal.** Each one is a real fungus, drawn as a cartoon.
2. **Swim around the dish.** Use the arrow keys, or on a touch screen, drag your gal like a trackpad: touch anywhere on the dish and slide your finger, and she moves the same way.
3. **Eat nutrients to bud.** Every cell that eats a nutrient buds: a little daughter cell swells out of her side and grows to full size. Daughters stick together in clusters, the way budding yeast does on a plate. Yara's line up end to end in chains instead.
4. **Don't touch the antifungals.** Touching a disk, or the clear zone of inhibition around it, ends the game. The zones start small and spread outward over the first few seconds, so grab the nutrients near the disks early.

There are seven levels. Each one adds another antifungal disk and doubles the colony you need to grow, from 4 cells up to 256. Each yeast has four or five antifungals, so the later levels start over from her first drugs.

### Playing a mold: Fumi

Fumi (*Aspergillus fumigatus*) plays differently. You're one of her tiny **spores**, floating over the agar. Land on a nutrient and a spore germinates right there: a **colony** starts small and spreads out in a circle, white and fluffy with a greenish middle where it's making spores. A colony counts as soon as it starts, and you need **6 colonies** on level 1 and 6 more each level, up to 42. Like the yeasts, she has 1 antifungal disk on level 1 and one more each level (drugs repeat once she's had them all). There are only 4 nutrients on her plate at a time (the yeasts get 8), since each one is a whole colony.

Watch out for the disks: **a colony that touches an antifungal disk, or its zone of inhibition, pops**, the whole colony at once, and you lose it from your count. The colonies keep spreading and the zones keep widening for the first few seconds, so leave room. Your spore touching one is still game over. A nutrient under a colony isn't wasted: new nutrients can turn up under a colony, and a colony can spread over one, and either way it starts a new colony right there.

### Penelope, Miri, Ruby and Rosie play like Fumi

Penelope (*Penicillium rubens*), the penicillin mold, plays exactly like Fumi: you're a spore, each nutrient starts a colony, and you grow the same number of colonies each level. Her colonies turn denim blue in the middle, with a white fluffy edge. Miri (*Aspergillus oryzae*), the koji mold, plays the same way; her colonies turn olive yellow-green. Ruby (*Hydnellum peckii*), the bleeding tooth fungus, is a mushroom but plays the same way too: her colonies look like little white caps from above, browning in the middle and beading with red drops as they ripen. Rosie (*Sporothrix schenckii*) plays the same way; her colonies start cream and turn wrinkly and dark brown-black from the middle out.

### Who’s That Gal?

Tap **Who’s That Gal?** on the home page for a quiz on the gals' fun facts, like PetriPals' Who’s That Pal?. You get one fact with "this gal" in place of her name: tap the gal it's about. A wrong guess greys that gal out so you can try again, and the right one puts her name back in and shows her species. There's no score, so it's just for learning. The quiz skips facts that fit any yeast (like having a nucleus); the ones it uses are listed in `public/game/quiz-facts.js`.

## The gals

| Gal | Species | Looks |
|---|---|---|
| **Sasha** | *Saccharomyces cerevisiae* | Wheat-colored oval yeast with a bud and two bud scars |
| **Candi** | *Candida albicans* | Sky-blue oval yeast with a bud and two bud scars |
| **Olive** | *Malassezia furfur* | Olive-green bowling pin: a broad-based bud on one end, with a collarette at the neck |
| **Fumi** | *Aspergillus fumigatus* | Smoky green mold: a round head on a stalk, topped with columns of spores. In the dish, one little spore |
| **Penelope** | *Penicillium rubens* | A denim-blue paintbrush of a mold, with a wide fan of spore chains for bristles. In the dish, one round blue spore |
| **Yara** | *Yarrowia lipolytica* | An apricot yeast: one plump, egg-shaped cell with droplets of fat inside, budding at her end |
| **Rosie** | *Sporothrix schenckii* | A short spore stalk crowned with a loose fan of cream and dusty-rose teardrop spores, with dark spores along her thread. In the dish, one oval spore |
| **Ruby** | *Hydnellum peckii* | The bleeding tooth fungus: a fuzzy white mushroom cap beaded with red drops, with little spikes underneath. In the dish, one round, warty spore |
| **Neve** | *Cryptococcus neoformans* | A round, soft-aqua yeast in a thick, glossy, see-through capsule, with a small bud on a narrow neck |
| **Maizey** | *Ustilago maydis* | A plum yeast: one long, cigar-shaped cell with a small bud at her tip |
| **Peachy** | *Komagataella phaffii* | A rose-pink yeast: one plump oval cell with round peroxisomes inside and a small bud on top |
| **Miri** | *Aspergillus oryzae* | A golden puff of spore chains pointing every way, on a tall, bumpy stalk. In the dish, one round golden spore |

## The real science

- **Budding:** yeasts don't split in two like bacteria do. A small bud swells out of the mother cell and pinches off, which is why each daughter starts small in the dish and grows. Every bud leaves a ring-shaped scar on the mother, like the two on Sasha's and Candi's pictures.
- **Olive buds from one end:** *Malassezia furfur* buds again and again from the same end, on a wide base, so mother and bud make a bowling pin. Each bud leaves a collar there, the collarette, instead of scattered bud scars, and in the dish her buds always grow from the top. She's olive green for the olive oil labs pour over her plates: she can't make her own fatty acids, so she needs oil to grow.
- **Candi buds too**, but *Candida albicans* can also switch from budding yeast to hyphae, long thread-like cells. In the lab, sprouting germ tubes (the start of a hypha) in serum is a classic test for her.
- **Yara loves fat.** *Yarrowia lipolytica* ("fat-breaking") lives on fats and oils, in cheese, sausages, soil and oily seawater, and stores fat in droplets inside her cells, sometimes over a third of her weight, so companies grow her to make omega-3s and biofuels. She can bud like any yeast, but her daughters often stay attached end to end in chains (pseudohyphae), and she can grow true hyphae too. In the dish she buds from her ends, and her daughters line up in chains of up to 4 cells, after which a new daughter starts a chain of her own. Her antifungals are estimates, since there are no standard disk sizes for *Yarrowia*; fluconazole works only weakly on her, so its zone is small.
- **Peachy lives on methanol.** *Komagataella phaffii*, long known as *Pichia pastoris* (the name many labs still use), can feed on methanol, a simple alcohol most living things can't use. She breaks it down inside peroxisomes, little bags in her cells that swell on methanol until they fill most of the cell. Labs use her as a protein factory: given a new gene, she makes proteins like insulin, vaccine parts and enzymes. She plays like Sasha, budding into clusters. Her antifungals are estimates, since there are no standard disk sizes for *Komagataella*.
- **Maizey is corn smut.** *Ustilago maydis* swells corn kernels into big gray galls full of dark spores, which are eaten in Mexico as huitlacoche. On her own she's a harmless, cigar-shaped yeast that buds from her tips, and that's how she plays: her daughters cluster like the other yeasts', a little farther apart. To infect corn, two cells of different mating types have to fuse first. She's a basidiomycete, a cousin of mushrooms. Her antifungals are estimates, since there are no standard disk sizes for *Ustilago*.
- **Neve's capsule.** *Cryptococcus neoformans* wears a thick sugar coat, her capsule, that shows up as a bright halo around her in India ink and helps her hide from the immune system. She lives in soil and old pigeon droppings, people catch her by breathing her in, and she can cause meningitis, mostly in people with weakened immune systems. In the dish every cell wears its capsule, so her clusters sit a little more spread out. She's treated with amphotericin B and flucytosine, then fluconazole, and echinocandins like caspofungin don't work on her at all, so she gets no caspofungin disk. Her zones are estimates, since there are no standard disk sizes for *Cryptococcus*.
- **Ruby bleeds, but not blood.** *Hydnellum peckii*, the bleeding tooth fungus, is a mushroom whose young, fuzzy white caps push out drops of red sap. Instead of gills, the underside of her cap has little spikes (teeth) that drop her spores. She lives with pine and spruce trees, trading nutrients with their roots, so she's hard to grow in a real dish without a tree partner. In the game she plays like Fumi, and her colonies bead with red drops as they ripen. Her antifungals are estimates, since there are no standard disk sizes for *Hydnellum*.
- **Rosie and the rose thorn.** *Sporothrix schenckii* lives in soil, moss, hay and on plants like rose bushes, and causes sporotrichosis, "rose gardener's disease," when a thorn or scratch carries her into the skin. She's dimorphic: a mold in the cool soil and a budding yeast in a warm body. As a mold, her tiny spores crowd into little bunches at her thread tips, and darker spores sit right on her threads; her colonies start cream and darken to a wrinkly brown-black. Itraconazole is her usual treatment and terbinafine works well too, while fluconazole works poorly, so her disks are itraconazole, terbinafine, amphotericin B, posaconazole and fluconazole. Their zones are estimates, since there are no standard disk sizes for *Sporothrix*.
- **Fumi's colonies** grow the way mold colonies really do: each starts from a single spore (a conidium) that sprouts threads (hyphae), and the hyphae grow from their tips at the colony's edge. So a colony spreads out in a circle at a steady pace, rather than doubling like a heap of budding yeast. The middle is oldest, so that's where it makes spores first and turns green, while the rest, still growing, stays white and fluffy.
- **Fumi's picture** is her conidiophore, the stalk that makes her spores: a swollen head (the vesicle) with spores in chains that stand up from its top in a column. That shape, a bit like the aspergillum used to sprinkle holy water, gave *Aspergillus* its name. *Fumigatus* means "smoky," for her grey-green colonies.
- **Fumi's antifungals:** voriconazole is the usual first choice against her, then other azoles (itraconazole, posaconazole), amphotericin B and caspofungin, the five drugs on her disks. Like most molds, she's naturally resistant to fluconazole, so she never gets an FLC disk. There's a CLSI disk test for molds (M51), but no settled zone sizes for *Aspergillus*, so her zones are estimates.
- **Penelope is Fleming's penicillin mold.** In 1928 she spoiled one of Alexander Fleming's plates of bacteria, and the bacteria around her died. The strain that made penicillin for the world came from her too, on a moldy cantaloupe a lab worker, Mary Hunt ("Moldy Mary"), found at a market in Peoria, Illinois, in 1943. Fleming's mold was long called *Penicillium notatum*, but DNA showed it was *P. rubens*. Penicillin breaks bacteria's cell walls, which fungi don't have, so it can't hurt her.
- **Penelope's picture** is her spore stalk (a conidiophore). Its top branches into short arms with straight chains of spores, like the bristles of a little paintbrush, which is what *Penicillium* means. Fumi's stalk instead ends in a round, swollen head. Her spores are blue, so her colonies turn blue as they make them.
- **Penelope's antifungals** are estimates, since there are no standard disk sizes for *Penicillium*: itraconazole, amphotericin B, posaconazole, voriconazole and caspofungin. Like most molds, she's naturally resistant to fluconazole, so she never gets an FLC disk.
- **Miri is the koji mold.** Grown on steamed rice or soybeans, she makes the enzymes that turn starch into sugar and protein into savory umami flavors, which is how soy sauce, miso, sake, mirin and rice vinegar get made. People have grown her on purpose for over 2,000 years, and in 2006 the Brewing Society of Japan named her its "national fungus." She's a tame relative of *Aspergillus flavus*, but she doesn't make its poison, aflatoxin.
- **Miri's picture** is her spore stalk. She's Fumi's cousin, in the same genus, but where Fumi's spore chains stand up in a column, Miri's point out in every direction from her round head, making a puff. Her stalk is rough, so it's drawn bumpy.
- **Miri's antifungals** are estimates, like Fumi's: voriconazole, amphotericin B, posaconazole, itraconazole and caspofungin. Like Fumi, she's naturally resistant to fluconazole, so she never gets an FLC disk.
- **The antifungal disks** work like the Kirby-Bauer disk test for bacteria. *Candida* has a standard disk test (CLSI M44), so Candi's zones are ballpark sizes for a susceptible strain. *Saccharomyces* and *Malassezia* have no standard disk sizes, so Sasha's and Olive's are estimates from how well each drug works on them. Fluconazole only weakly holds *Saccharomyces* back, so Sasha's fluconazole zone is small. *Malassezia* is naturally resistant to echinocandins, so Olive's caspofungin disk has **no zone at all**: you can swim right up to it, but don't touch the disk itself.
- **The disk codes** are the standard ones: FLC (fluconazole), VOR (voriconazole), KCA (ketoconazole), ITC (itraconazole), POS (posaconazole), CAS (caspofungin), MCF (micafungin), AMB (amphotericin B) and NY (nystatin).
- **The zones spread** because the drug diffuses outward from the disk into the agar: fast at first, then more slowly. On a real plate this takes hours of incubation; the game speeds it up to a few seconds.

## Running it locally

The game is plain HTML, CSS and JavaScript in [`public/`](public/), with no build step. To run it with the included dev server:

```sh
npm install
npm run dev
```

Then open http://localhost:3004.

## Tests

```sh
npm test                # run the tests
npm run test:coverage   # run them and check how much of the game they cover
```

The tests use [Vitest](https://vitest.dev/). Most of the game logic runs in [jsdom](https://github.com/jsdom/jsdom), a simulated browser page. The coverage check fails if the tests leave game code untested (the thresholds are in [`vitest.config.js`](vitest.config.js)), and the deploy runs it, so untested code doesn't ship.

## Project layout

FunGals started as a copy of the PetriPals engine (steering, nutrients, disks and zones, the loading card and the win spores), with the bacteria swapped out for fungi.

| Path | What's there |
|---|---|
| `public/index.html` | Home page |
| `public/pal-picker.html` | Pick a gal |
| `public/petri-dish.html` | The game |
| `public/whos-that-gal.html` | Who’s That Gal?, a quiz: which gal is this fact about? |
| `public/game/` | Game code: the game loop (`game.js`), a colony eating and budding (`colony.js`), the mold game, where a spore starts colonies that spread (`mold.js`), the end-of-level pop-up both games share (`banner.js`), how yeast cells bud and cluster (`yeast.js`, with the cluster math in `attach.js`), steering (`keyboard.js`, `touch.js`), antifungal disks and zones (`antifungal.js`), nutrients, physics, settings and fun facts (`config.js`), the fun-fact pop-up (`facts.js`, with italics for scientific names from `italics.js`) the win spores (`spores.js`), and Who’s That Gal? (`whos-that-gal.js`, with the facts' "this gal" swap in `guess.js` and the facts it asks about in `quiz-facts.js`) |
| `public/game/gals.js` | Every gal's name and drawing, in one place. To add a gal, see the notes at the top. |
| `test/` | Tests |
| `src/index.ts` | Small Express server for local development |

## Deployment

Every push to `main` runs the tests and the coverage check and, if they pass, publishes `public/` to GitHub Pages (see [`.github/workflows/pages.yml`](.github/workflows/pages.yml)). In the repo's **Settings → Pages**, set **Source** to **GitHub Actions** once.

## Contributing

Bug reports, ideas and fixes are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for how to get started, and please follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## License

FunGals is released under the [MIT License](LICENSE). The win spores use [canvas-confetti](https://github.com/catdad/canvas-confetti), which is ISC licensed ([`public/game/vendor/confetti.LICENSE`](public/game/vendor/confetti.LICENSE)). The home page uses the [Fredoka](https://github.com/hafontia/Fredoka-One) and [Nunito](https://github.com/googlefonts/nunito) fonts, under the SIL Open Font License ([`public/fonts/`](public/fonts/)).

## Credits

Made by Jessica Sogge.
