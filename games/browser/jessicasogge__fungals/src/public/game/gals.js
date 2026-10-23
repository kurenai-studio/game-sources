// Every gal's drawing, in one place. The home page, the gal picker and the
// petri dish all draw the gals from here, so a change to how a gal looks
// only has to be made once.
//
// The home page shows them in its own order (HOME below), and the picker
// shuffles them.
// Each gal has:
//   id      her key, matching SPECIES in config.js and ?pal= in addresses
//   name    what she's called
//   looks   what a screen reader says after her name
//   motion  her idle animation in styles.css (bob, squish, wobble or slither)
//   frames  the part of the drawing each page shows (an SVG viewBox), so each
//           page can frame her its own way: a little room around her on the
//           home page, filling her tile on the picker, snug in the dish
//   art     the drawing itself, in a 200 x 200 space. Wrap the face in
//           <g class="face">.
//   dishArt (optional) a different drawing for the dish, framed by
//           frames.dish: a mold plays as one of her spores
//
// To add a gal: add her to the end of this list and to SPECIES in config.js,
// and give her tile a color in styles.css (.<id> next to .sasha and the
// others).

const SVG = 'http://www.w3.org/2000/svg';

// A cute face: eyes with a glint, rosy cheeks and a smile, centered on
// (x, y), in the gal's `dark` color.
const face = (x, y, dark) => `
      <g class="face">
        <circle cx="${x - 11}" cy="${y}" r="6" fill="${dark}" />
        <circle cx="${x + 11}" cy="${y}" r="6" fill="${dark}" />
        <circle cx="${x - 9}" cy="${y - 2}" r="2" fill="white" />
        <circle cx="${x + 13}" cy="${y - 2}" r="2" fill="white" />
        <ellipse cx="${x - 21}" cy="${y + 12}" rx="6" ry="3.5" fill="#f9a8d4" opacity="0.8" />
        <ellipse cx="${x + 21}" cy="${y + 12}" rx="6" ry="3.5" fill="#f9a8d4" opacity="0.8" />
        <path d="M${x - 6} ${y + 12} Q${x} ${y + 18} ${x + 6} ${y + 12}" stroke="${dark}" stroke-width="3" fill="none" stroke-linecap="round" />
      </g>`;

export const GALS = [
  // Sasha: Saccharomyces cerevisiae, a wheat-colored oval yeast cell with a
  // bud growing out of her side and two bud scars from daughters she's had
  {
    id: 'sasha',
    name: 'Sasha',
    looks: 'a wheat-colored oval Saccharomyces yeast cell with a little bud growing from her side',
    motion: 'squish',
    frames: { home: '28 20 160 160', picker: '36 28 144 144', dish: '40 32 136 136' },
    art: `
      <!-- the bud, swelling out of her upper right -->
      <circle cx="150" cy="62" r="20" fill="#f3dfbf" stroke="#8a5a2b" stroke-width="4" />
      <circle cx="144" cy="55" r="4" fill="#fbf3e4" />
      <!-- the mother cell -->
      <ellipse cx="100" cy="112" rx="52" ry="44" fill="#f3dfbf" stroke="#8a5a2b" stroke-width="4" />
      <ellipse cx="80" cy="86" rx="9" ry="5" fill="#fbf3e4" transform="rotate(-25 80 86)" />
      <!-- bud scars, one for each daughter she's had -->
      <ellipse cx="62" cy="132" rx="6" ry="4" fill="none" stroke="#b08250" stroke-width="2.5" />
      <ellipse cx="138" cy="132" rx="6" ry="4" fill="none" stroke="#b08250" stroke-width="2.5" />
      ${face(100, 112, '#5b3a1e')}
    `,
  },
  // Candi: Candida albicans, a soft sky-blue oval yeast cell with a deeper
  // blue outline, a bud growing out of her upper left and two bud scars
  {
    id: 'candi',
    name: 'Candi',
    looks: 'a sky-blue oval Candida albicans yeast cell with a little bud growing from her side',
    motion: 'bob',
    frames: { home: '12 20 160 160', picker: '20 28 144 144', dish: '24 32 136 136' },
    art: `
      <!-- the bud, swelling out of her upper left: Sasha's bud, mirrored, so
           both attach the same way -->
      <circle cx="50" cy="62" r="20" fill="#d6e8ff" stroke="#2563eb" stroke-width="4" />
      <circle cx="44" cy="55" r="4" fill="#ffffff" />
      <!-- the mother cell, the same size as Sasha's -->
      <ellipse cx="100" cy="112" rx="52" ry="44" fill="#d6e8ff" stroke="#2563eb" stroke-width="4" />
      <ellipse cx="80" cy="86" rx="9" ry="5" fill="#ffffff" transform="rotate(-25 80 86)" />
      <!-- bud scars, one for each daughter she's had, like Sasha's -->
      <ellipse cx="62" cy="132" rx="6" ry="4" fill="none" stroke="#93c5fd" stroke-width="2.5" />
      <ellipse cx="138" cy="132" rx="6" ry="4" fill="none" stroke="#93c5fd" stroke-width="2.5" />
      ${face(100, 112, '#1e3a8a')}
    `,
  },
  // Olive: Malassezia furfur, an olive-green yeast shaped like a bowling pin:
  // a broad-based bud on top of her mother cell, with a lighter collarette
  // across the neck where her buds pinch off
  {
    id: 'olive',
    name: 'Olive',
    looks: 'an olive-green Malassezia furfur yeast cell shaped like a bowling pin, budding from one end',
    motion: 'wobble',
    frames: { home: '16 22 168 168', picker: '22 28 156 156', dish: '26 32 148 148' },
    art: `
      <!-- one bowling-pin outline: both cells' outlines first, then both
           fills on top, so the outline runs smoothly round the neck -->
      <ellipse cx="100" cy="72" rx="34" ry="38" fill="#6b7a2a" stroke="#6b7a2a" stroke-width="4" />
      <ellipse cx="100" cy="134" rx="49" ry="44" fill="#6b7a2a" stroke="#6b7a2a" stroke-width="4" />
      <!-- the bud, growing on a wide base from the top of her -->
      <ellipse cx="100" cy="72" rx="32" ry="36" fill="#d9e6a6" />
      <!-- the mother cell -->
      <ellipse cx="100" cy="134" rx="47" ry="42" fill="#d9e6a6" />
      <!-- the collarette, the collar left where each bud pinches off -->
      <path d="M71 101 Q100 112 129 101" stroke="#a3b553" stroke-width="4" fill="none" stroke-linecap="round" />
      <circle cx="88" cy="56" r="5" fill="#f7faea" />
      <ellipse cx="78" cy="118" rx="8" ry="4.5" fill="#f7faea" transform="rotate(-30 78 118)" />
      ${face(100, 140, '#3a4410')}
    `,
  },
  // Fumi: Aspergillus fumigatus, a smoky green mold. Her picture is her
  // conidiophore, the stalk that makes her spores: a round head (the vesicle)
  // with chains of spores standing up from its top in columns. In the dish
  // she plays as one of those spores (dishArt), a little round, slightly
  // spiky ball, and plants colonies (see mold.js).
  {
    id: 'fumi',
    name: 'Fumi',
    looks: 'a smoky green Aspergillus fumigatus mold: a round head on a stalk, topped with columns of spores',
    motion: 'bob',
    frames: { home: '20 32 160 160', picker: '29 44 142 142', dish: '50 50 100 100' },
    art: `
      <!-- the stalk (stipe) -->
      <rect x="93" y="150" width="14" height="36" rx="6" fill="#dcebe5" stroke="#3f7a6c" stroke-width="4" />
      <!-- chains of spores on little flasks (phialides), all pointing up -->
      <ellipse cx="74" cy="97" rx="4.5" ry="7" fill="#bcd6cc" stroke="#3f7a6c" stroke-width="2.5" />
      <circle cx="74" cy="85" r="7" fill="#7fa89b" stroke="#3f7a6c" stroke-width="2.5" />
      <circle cx="74" cy="72" r="7" fill="#7fa89b" stroke="#3f7a6c" stroke-width="2.5" />
      <ellipse cx="87" cy="92" rx="4.5" ry="7" fill="#bcd6cc" stroke="#3f7a6c" stroke-width="2.5" />
      <circle cx="87" cy="80" r="7" fill="#7fa89b" stroke="#3f7a6c" stroke-width="2.5" />
      <circle cx="87" cy="67" r="7" fill="#7fa89b" stroke="#3f7a6c" stroke-width="2.5" />
      <circle cx="87" cy="54" r="7" fill="#7fa89b" stroke="#3f7a6c" stroke-width="2.5" />
      <ellipse cx="100" cy="90" rx="4.5" ry="7" fill="#bcd6cc" stroke="#3f7a6c" stroke-width="2.5" />
      <circle cx="100" cy="78" r="7" fill="#7fa89b" stroke="#3f7a6c" stroke-width="2.5" />
      <circle cx="100" cy="65" r="7" fill="#7fa89b" stroke="#3f7a6c" stroke-width="2.5" />
      <circle cx="100" cy="52" r="7" fill="#7fa89b" stroke="#3f7a6c" stroke-width="2.5" />
      <ellipse cx="113" cy="92" rx="4.5" ry="7" fill="#bcd6cc" stroke="#3f7a6c" stroke-width="2.5" />
      <circle cx="113" cy="80" r="7" fill="#7fa89b" stroke="#3f7a6c" stroke-width="2.5" />
      <circle cx="113" cy="67" r="7" fill="#7fa89b" stroke="#3f7a6c" stroke-width="2.5" />
      <circle cx="113" cy="54" r="7" fill="#7fa89b" stroke="#3f7a6c" stroke-width="2.5" />
      <ellipse cx="126" cy="97" rx="4.5" ry="7" fill="#bcd6cc" stroke="#3f7a6c" stroke-width="2.5" />
      <circle cx="126" cy="85" r="7" fill="#7fa89b" stroke="#3f7a6c" stroke-width="2.5" />
      <circle cx="126" cy="72" r="7" fill="#7fa89b" stroke="#3f7a6c" stroke-width="2.5" />
      <!-- the swollen head (vesicle) -->
      <ellipse cx="100" cy="128" rx="42" ry="34" fill="#dcebe5" stroke="#3f7a6c" stroke-width="4" />
      <ellipse cx="82" cy="112" rx="8" ry="4.5" fill="#f4faf7" transform="rotate(-25 82 112)" />
      ${face(100, 132, '#1f4d43')}
    `,
    dishArt: `
      <!-- a rough, slightly spiky spore (conidium) -->
      <g fill="#5b8c80"><circle cx="142.0" cy="100.0" r="4.5" /><circle cx="137.8" cy="118.2" r="4.5" /><circle cx="126.2" cy="132.8" r="4.5" /><circle cx="109.3" cy="140.9" r="4.5" /><circle cx="90.7" cy="140.9" r="4.5" /><circle cx="73.8" cy="132.8" r="4.5" /><circle cx="62.2" cy="118.2" r="4.5" /><circle cx="58.0" cy="100.0" r="4.5" /><circle cx="62.2" cy="81.8" r="4.5" /><circle cx="73.8" cy="67.2" r="4.5" /><circle cx="90.7" cy="59.1" r="4.5" /><circle cx="109.3" cy="59.1" r="4.5" /><circle cx="126.2" cy="67.2" r="4.5" /><circle cx="137.8" cy="81.8" r="4.5" /></g>
      <circle cx="100" cy="100" r="42" fill="#dcebe5" stroke="#3f7a6c" stroke-width="4" />
      <ellipse cx="82" cy="80" rx="9" ry="5" fill="#f4faf7" transform="rotate(-25 82 80)" />
      ${face(100, 104, '#1f4d43')}
    `,
  },
  // Penelope: Penicillium rubens, Fleming's penicillin mold, drawn as her
  // spore stalk: a denim-blue paintbrush (Penicillium means "little
  // paintbrush"), with a wide fan of spore chains for bristles. In the
  // dish she plays as one of her spores (dishArt) and plants colonies, just
  // like Fumi (see mold.js).
  {
    id: 'penelope',
    name: 'Penelope',
    looks: 'a denim-blue Penicillium rubens mold shaped like a paintbrush, with chains of spores for bristles',
    motion: 'bob',
    frames: { home: '8 12 184 184', picker: '12 16 176 176', dish: '50 50 100 100' },
    art: `
      <!-- the handle (stipe), the bristles (chains of spores on short
           branches), and the band where they meet, with her face -->
      <path d="M90 144 L93 188 Q100 195 107 188 L110 144 Z" fill="#dde6f0" stroke="#3d5a80" stroke-width="4" stroke-linejoin="round"/>
      <circle cx="55.0" cy="80.2" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="49.2" cy="73.1" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="43.4" cy="65.9" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="37.7" cy="58.8" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="31.9" cy="51.6" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="61.8" cy="75.6" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="57.3" cy="67.6" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="52.9" cy="59.5" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="48.4" cy="51.5" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="44.0" cy="43.5" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="71.0" cy="75.8" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="67.1" cy="67.5" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="63.2" cy="59.2" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="59.3" cy="50.8" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="55.4" cy="42.5" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="51.6" cy="34.2" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="78.7" cy="73.0" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="76.3" cy="64.2" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="73.9" cy="55.3" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="71.5" cy="46.4" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="69.2" cy="37.5" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="66.8" cy="28.6" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="87.3" cy="73.3" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="85.4" cy="64.3" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="83.5" cy="55.3" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="81.6" cy="46.3" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="79.7" cy="37.3" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="77.7" cy="28.3" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="95.4" cy="72.3" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="95.1" cy="63.1" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="94.8" cy="53.9" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="94.5" cy="44.7" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="94.1" cy="35.5" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="93.8" cy="26.3" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="104.6" cy="72.3" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="104.9" cy="63.1" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="105.2" cy="53.9" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="105.5" cy="44.7" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="105.9" cy="35.5" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="106.2" cy="26.3" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="112.7" cy="73.3" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="114.6" cy="64.3" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="116.5" cy="55.3" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="118.4" cy="46.3" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="120.3" cy="37.3" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="122.3" cy="28.3" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="121.3" cy="73.0" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="123.7" cy="64.2" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="126.1" cy="55.3" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="128.5" cy="46.4" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="130.8" cy="37.5" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="133.2" cy="28.6" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="129.0" cy="75.8" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="132.9" cy="67.5" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="136.8" cy="59.2" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="140.7" cy="50.8" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="144.6" cy="42.5" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="148.4" cy="34.2" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="138.2" cy="75.6" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="142.7" cy="67.6" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="147.1" cy="59.5" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="151.6" cy="51.5" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="156.0" cy="43.5" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="145.0" cy="80.2" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="150.8" cy="73.1" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="156.6" cy="65.9" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="162.3" cy="58.8" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <circle cx="168.1" cy="51.6" r="4.6" fill="#7f9cc0" stroke="#3d5a80" stroke-width="1.8"/>
      <ellipse cx="60.7" cy="87.2" rx="2.6" ry="4.8" fill="#b7c8dc" stroke="#3d5a80" stroke-width="1.8" transform="rotate(-39 60.7 87.2)"/>
      <ellipse cx="66.2" cy="83.5" rx="2.6" ry="4.8" fill="#b7c8dc" stroke="#3d5a80" stroke-width="1.8" transform="rotate(-29 66.2 83.5)"/>
      <ellipse cx="74.8" cy="84.0" rx="2.6" ry="4.8" fill="#b7c8dc" stroke="#3d5a80" stroke-width="1.8" transform="rotate(-25 74.8 84.0)"/>
      <ellipse cx="81.0" cy="81.7" rx="2.6" ry="4.8" fill="#b7c8dc" stroke="#3d5a80" stroke-width="1.8" transform="rotate(-15 81.0 81.7)"/>
      <ellipse cx="89.2" cy="82.1" rx="2.6" ry="4.8" fill="#b7c8dc" stroke="#3d5a80" stroke-width="1.8" transform="rotate(-12 89.2 82.1)"/>
      <ellipse cx="95.7" cy="81.3" rx="2.6" ry="4.8" fill="#b7c8dc" stroke="#3d5a80" stroke-width="1.8" transform="rotate(-2 95.7 81.3)"/>
      <ellipse cx="104.3" cy="81.3" rx="2.6" ry="4.8" fill="#b7c8dc" stroke="#3d5a80" stroke-width="1.8" transform="rotate(2 104.3 81.3)"/>
      <ellipse cx="110.8" cy="82.1" rx="2.6" ry="4.8" fill="#b7c8dc" stroke="#3d5a80" stroke-width="1.8" transform="rotate(12 110.8 82.1)"/>
      <ellipse cx="119.0" cy="81.7" rx="2.6" ry="4.8" fill="#b7c8dc" stroke="#3d5a80" stroke-width="1.8" transform="rotate(15 119.0 81.7)"/>
      <ellipse cx="125.2" cy="84.0" rx="2.6" ry="4.8" fill="#b7c8dc" stroke="#3d5a80" stroke-width="1.8" transform="rotate(25 125.2 84.0)"/>
      <ellipse cx="133.8" cy="83.5" rx="2.6" ry="4.8" fill="#b7c8dc" stroke="#3d5a80" stroke-width="1.8" transform="rotate(29 133.8 83.5)"/>
      <ellipse cx="139.3" cy="87.2" rx="2.6" ry="4.8" fill="#b7c8dc" stroke="#3d5a80" stroke-width="1.8" transform="rotate(39 139.3 87.2)"/>
      <rect x="71.5" y="84" width="9" height="20" rx="4.5" fill="#dde6f0" stroke="#3d5a80" stroke-width="2.6" transform="rotate(-34 76.0 104)"/>
      <rect x="81.1" y="84" width="9" height="20" rx="4.5" fill="#dde6f0" stroke="#3d5a80" stroke-width="2.6" transform="rotate(-20 85.6 104)"/>
      <rect x="90.7" y="84" width="9" height="20" rx="4.5" fill="#dde6f0" stroke="#3d5a80" stroke-width="2.6" transform="rotate(-7 95.2 104)"/>
      <rect x="100.3" y="84" width="9" height="20" rx="4.5" fill="#dde6f0" stroke="#3d5a80" stroke-width="2.6" transform="rotate(7 104.8 104)"/>
      <rect x="109.9" y="84" width="9" height="20" rx="4.5" fill="#dde6f0" stroke="#3d5a80" stroke-width="2.6" transform="rotate(20 114.4 104)"/>
      <rect x="119.5" y="84" width="9" height="20" rx="4.5" fill="#dde6f0" stroke="#3d5a80" stroke-width="2.6" transform="rotate(34 124.0 104)"/>
      <rect x="66" y="100" width="68" height="48" rx="11" fill="#dde6f0" stroke="#3d5a80" stroke-width="4"/>
      <path d="M70 109 H130" stroke="#c3d1e2" stroke-width="3" stroke-linecap="round"/>
      <rect x="93" y="144" width="14" height="6" fill="#dde6f0"/>
      <ellipse cx="80" cy="116" rx="7" ry="3.5" fill="#f5f8fc" transform="rotate(-15 80 116)"/>
      ${face(100, 123, '#26385a')}
    `,
    dishArt: `
      <!-- a smooth, round blue spore (conidium) -->
      <circle cx="100" cy="100" r="42" fill="#c9d6e6" stroke="#3d5a80" stroke-width="4" />
      <ellipse cx="82" cy="80" rx="9" ry="5" fill="#f5f8fc" transform="rotate(-25 82 80)" />
      ${face(100, 104, '#26385a')}
    `,
  },
  // Miri (Aspergillus oryzae): koji mold behind soy sauce, miso, and sake.
  // Fumi's cousin, with a round golden spore head on a tall bumpy stalk.
  // Plays like Fumi in dishArt/mold.js: spore-guided colonies.
  {
    id: 'miri',
    name: 'Miri',
    looks: 'a golden Aspergillus oryzae mold: a round puff of spore chains pointing every way, on a tall bumpy stalk',
    motion: 'bob',
    frames: { home: '4 6 192 192', picker: '8 10 184 184', dish: '50 50 100 100' },
    art: `
      <!-- the bumpy stalk (stipe) on its foot, the spore chains all around,
           and the round head (vesicle) with her face -->
      <circle cx="92" cy="134" r="2.2" fill="#f7e6a0" stroke="#8c6d0f" stroke-width="1.8"/><circle cx="108" cy="146" r="2.2" fill="#f7e6a0" stroke="#8c6d0f" stroke-width="1.8"/><circle cx="92" cy="158" r="2.2" fill="#f7e6a0" stroke="#8c6d0f" stroke-width="1.8"/><circle cx="108" cy="170" r="2.2" fill="#f7e6a0" stroke="#8c6d0f" stroke-width="1.8"/><circle cx="92" cy="180" r="2.2" fill="#f7e6a0" stroke="#8c6d0f" stroke-width="1.8"/>
      <rect x="93" y="112" width="14" height="72" rx="6" fill="#f7e6a0" stroke="#8c6d0f" stroke-width="4"/>
      <ellipse cx="100" cy="186" rx="18" ry="6" fill="#f7e6a0" stroke="#8c6d0f" stroke-width="4"/>
      <rect x="95" y="176" width="10" height="8" fill="#f7e6a0"/>
      <circle cx="144.0" cy="86.0" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="153.4" cy="86.0" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="162.8" cy="86.0" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="172.2" cy="86.0" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="141.3" cy="101.0" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="150.2" cy="104.3" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="159.0" cy="107.5" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="167.8" cy="110.7" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="133.7" cy="114.3" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="140.9" cy="120.3" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="148.1" cy="126.4" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="66.3" cy="114.3" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="59.1" cy="120.3" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="51.9" cy="126.4" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="58.7" cy="101.0" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="49.8" cy="104.3" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="41.0" cy="107.5" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="32.2" cy="110.7" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="56.0" cy="86.0" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="46.6" cy="86.0" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="37.2" cy="86.0" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="27.8" cy="86.0" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="58.7" cy="71.0" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="49.8" cy="67.7" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="41.0" cy="64.5" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="32.2" cy="61.3" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="66.3" cy="57.7" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="59.1" cy="51.7" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="51.9" cy="45.6" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="44.7" cy="39.6" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="78.0" cy="47.9" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="73.3" cy="39.8" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="68.6" cy="31.6" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="63.9" cy="23.5" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="92.4" cy="42.7" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="90.7" cy="33.4" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="89.1" cy="24.2" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="87.5" cy="14.9" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="107.6" cy="42.7" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="109.3" cy="33.4" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="110.9" cy="24.2" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="112.5" cy="14.9" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="122.0" cy="47.9" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="126.7" cy="39.8" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="131.4" cy="31.6" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="136.1" cy="23.5" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="133.7" cy="57.7" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="140.9" cy="51.7" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="148.1" cy="45.6" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="155.3" cy="39.6" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="141.3" cy="71.0" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="150.2" cy="67.7" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="159.0" cy="64.5" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <circle cx="167.8" cy="61.3" r="4.6" fill="#e2c04a" stroke="#8c6d0f" stroke-width="1.8"/>
      <ellipse cx="135.0" cy="86.0" rx="3" ry="5.5" fill="#f3dc86" stroke="#8c6d0f" stroke-width="2" transform="rotate(90 135.0 86.0)"/>
      <ellipse cx="132.9" cy="98.0" rx="3" ry="5.5" fill="#f3dc86" stroke="#8c6d0f" stroke-width="2" transform="rotate(110 132.9 98.0)"/>
      <ellipse cx="126.8" cy="108.5" rx="3" ry="5.5" fill="#f3dc86" stroke="#8c6d0f" stroke-width="2" transform="rotate(130 126.8 108.5)"/>
      <ellipse cx="73.2" cy="108.5" rx="3" ry="5.5" fill="#f3dc86" stroke="#8c6d0f" stroke-width="2" transform="rotate(230 73.2 108.5)"/>
      <ellipse cx="67.1" cy="98.0" rx="3" ry="5.5" fill="#f3dc86" stroke="#8c6d0f" stroke-width="2" transform="rotate(250 67.1 98.0)"/>
      <ellipse cx="65.0" cy="86.0" rx="3" ry="5.5" fill="#f3dc86" stroke="#8c6d0f" stroke-width="2" transform="rotate(270 65.0 86.0)"/>
      <ellipse cx="67.1" cy="74.0" rx="3" ry="5.5" fill="#f3dc86" stroke="#8c6d0f" stroke-width="2" transform="rotate(290 67.1 74.0)"/>
      <ellipse cx="73.2" cy="63.5" rx="3" ry="5.5" fill="#f3dc86" stroke="#8c6d0f" stroke-width="2" transform="rotate(310 73.2 63.5)"/>
      <ellipse cx="82.5" cy="55.7" rx="3" ry="5.5" fill="#f3dc86" stroke="#8c6d0f" stroke-width="2" transform="rotate(330 82.5 55.7)"/>
      <ellipse cx="93.9" cy="51.5" rx="3" ry="5.5" fill="#f3dc86" stroke="#8c6d0f" stroke-width="2" transform="rotate(350 93.9 51.5)"/>
      <ellipse cx="106.1" cy="51.5" rx="3" ry="5.5" fill="#f3dc86" stroke="#8c6d0f" stroke-width="2" transform="rotate(370 106.1 51.5)"/>
      <ellipse cx="117.5" cy="55.7" rx="3" ry="5.5" fill="#f3dc86" stroke="#8c6d0f" stroke-width="2" transform="rotate(390 117.5 55.7)"/>
      <ellipse cx="126.8" cy="63.5" rx="3" ry="5.5" fill="#f3dc86" stroke="#8c6d0f" stroke-width="2" transform="rotate(410 126.8 63.5)"/>
      <ellipse cx="132.9" cy="74.0" rx="3" ry="5.5" fill="#f3dc86" stroke="#8c6d0f" stroke-width="2" transform="rotate(430 132.9 74.0)"/>
      <circle cx="100" cy="86" r="30" fill="#f7e6a0" stroke="#8c6d0f" stroke-width="4"/>
      <rect x="95" y="112" width="10" height="6" fill="#f7e6a0"/>
      <ellipse cx="86" cy="70" rx="8" ry="4.5" fill="#fffaf0" transform="rotate(-25 86 70)"/>
      ${face(100, 88, '#4f3d06')}
    `,
    dishArt: `
      <!-- a round golden spore (conidium), a little rough -->
      <g fill="#d9b740"><circle cx="144.0" cy="100.0" r="3" /><circle cx="138.1" cy="122.0" r="3" /><circle cx="122.0" cy="138.1" r="3" /><circle cx="100.0" cy="144.0" r="3" /><circle cx="78.0" cy="138.1" r="3" /><circle cx="61.9" cy="122.0" r="3" /><circle cx="56.0" cy="100.0" r="3" /><circle cx="61.9" cy="78.0" r="3" /><circle cx="78.0" cy="61.9" r="3" /><circle cx="100.0" cy="56.0" r="3" /><circle cx="122.0" cy="61.9" r="3" /><circle cx="138.1" cy="78.0" r="3" /></g>
      <circle cx="100" cy="100" r="42" fill="#f2d675" stroke="#8c6d0f" stroke-width="4" />
      <ellipse cx="82" cy="80" rx="9" ry="5" fill="#fffaf0" transform="rotate(-25 82 80)" />
      ${face(100, 104, '#4f3d06')}
    `,
  },
  // Yara: Yarrowia lipolytica, a fat-loving yeast, drawn as one plump,
  // egg-shaped cell with droplets of fat inside and a smaller bud at her
  // end. In the dish her daughters line up end to end in chains (see yeast.js).
  {
    id: 'yara',
    name: 'Yara',
    looks: 'an apricot Yarrowia lipolytica yeast: one plump, egg-shaped cell with droplets of fat inside, budding at her end',
    motion: 'bob',
    frames: { home: '14 10 180 180', picker: '18 14 172 172', dish: '14 10 180 180' },
    art: `
      <!-- a smaller bud at her end, still attached -->
      <path d="M 159.4 61 A 21.6 14 0 0 1 159.4 89 A 18.4 14 0 0 1 159.4 61 Z" fill="#fbd3bd" stroke="#b4532f" stroke-width="4" transform="rotate(-28 161 75)" />
      <circle cx="166" cy="72" r="5" fill="#fde9a8" stroke="#d9a441" stroke-width="1.5" />
      <!-- her plump, egg-shaped cell -->
      <path d="M 85.4 69 A 62.6 37 0 0 1 85.4 143 A 53.4 37 0 0 1 85.4 69 Z" fill="#fbd3bd" stroke="#b4532f" stroke-width="4" transform="rotate(-14 90 106)" />
      <!-- droplets of fat she stores inside -->
      <circle cx="54" cy="121" r="7" fill="#fde9a8" stroke="#d9a441" stroke-width="1.5" />
      <circle cx="66" cy="131" r="4.5" fill="#fde9a8" stroke="#d9a441" stroke-width="1.5" />
      <circle cx="134" cy="92" r="6" fill="#fde9a8" stroke="#d9a441" stroke-width="1.5" />
      <ellipse cx="62" cy="94" rx="11" ry="5" fill="#fff4ec" transform="rotate(-14 62 94)" />
      ${face(94, 106, '#6e2f17')}
    `,
  },
  // Peachy: Komagataella phaffii (long called Pichia pastoris), a
  // methanol-eating yeast, drawn as one plump rose-pink oval with a bud on
  // her shoulder and round peroxisomes inside.
  {
    id: 'peachy',
    name: 'Peachy',
    looks: 'a rose-pink Komagataella phaffii yeast: one plump oval cell with round peroxisomes inside and a small bud on top',
    motion: 'squish',
    frames: { home: '14 14 176 176', picker: '20 18 168 168', dish: '14 14 176 176' },
    art: `
      <!-- a small bud on her shoulder -->
      <ellipse cx="152" cy="56" rx="22" ry="19" fill="#fcd5e3" stroke="#be3f73" stroke-width="4" transform="rotate(-30 152 56)" />
      <!-- her plump, oval cell -->
      <ellipse cx="96" cy="110" rx="64" ry="54" fill="#fcd5e3" stroke="#be3f73" stroke-width="4" transform="rotate(-8 96 110)" />
      <!-- peroxisomes: little bags that swell when she lives on methanol -->
      <circle cx="66" cy="134" r="10" fill="#f6a6c6" stroke="#be3f73" stroke-opacity="0.6" stroke-width="2" />
      <circle cx="84" cy="147" r="7" fill="#f6a6c6" stroke="#be3f73" stroke-opacity="0.6" stroke-width="2" />
      <circle cx="128" cy="138" r="8.5" fill="#f6a6c6" stroke="#be3f73" stroke-opacity="0.6" stroke-width="2" />
      <ellipse cx="70" cy="80" rx="13" ry="6" fill="#fff1f6" transform="rotate(-18 70 80)" />
      ${face(97, 102, '#6d1d3f')}
    `,
  },
  // Maizey: Ustilago maydis, corn smut, drawn as she grows on her own: one
  // long, cigar-shaped plum cell with a small bud at her tip.
  {
    id: 'maizey',
    name: 'Maizey',
    looks: 'a plum-colored Ustilago maydis yeast: one long, cigar-shaped cell with a small bud at her tip',
    motion: 'bob',
    frames: { home: '12 14 184 184', picker: '16 18 176 176', dish: '12 14 184 184' },
    art: `
      <g transform="rotate(-14 92 112)">
        <!-- a small bud at her tip: she buds from her ends -->
        <path d="M 158 108 C 158 101 164 98 174 98 C 184 98 190 101 190 108 C 190 115 184 118 174 118 C 164 118 158 115 158 108 Z" fill="#e6d8f2" stroke="#6b3f96" stroke-width="4" />
        <!-- her long, cigar-shaped cell, rounded at both tips -->
        <path d="M 22 112 C 22 90 52 74 92 74 C 132 74 162 90 162 112 C 162 134 132 150 92 150 C 52 150 22 134 22 112 Z" fill="#e6d8f2" stroke="#6b3f96" stroke-width="4" />
        <ellipse cx="58" cy="92" rx="16" ry="6" fill="#f7f0fd" />
      </g>
      ${face(93, 110, '#3b1f57')}
    `,
  },
  // Ruby: Hydnellum peckii, the bleeding tooth fungus: a fuzzy white
  // mushroom cap beaded with red drops, with spikes ("teeth") underneath. In
  // the dish she plays like Fumi (see mold.js), and her colonies bead with
  // red drops as they ripen.
  {
    id: 'ruby',
    name: 'Ruby',
    looks: 'a white Hydnellum peckii mushroom: a fuzzy cap beaded with bright red drops, with little spikes underneath',
    motion: 'bob',
    frames: { home: '14 22 172 172', picker: '18 30 164 164', dish: '50 50 100 100' },
    art: `
      <!-- her short, stout stalk -->
      <rect x="83" y="122" width="34" height="50" rx="12" fill="#f6dcd6" stroke="#a8323f" stroke-width="4" />
      <!-- teeth: little spikes under her cap, where her spores drop from -->
      <path d="M38 118 L43.8 132 L49.6 118 L55.4 136 L61.2 118 L67.0 132 L72.8 118 L78.6 136 L84.4 118 L90.2 132 L96.0 118 L101.8 136 L107.6 118 L113.4 132 L119.2 118 L125.0 136 L130.8 118 L136.6 132 L142.4 118 L148.2 136 L154.0 118 L159.8 132 L165.6 118 Z" fill="#f2cbc4" stroke="#a8323f" stroke-width="2.5" stroke-linejoin="round" />
      <!-- her fuzzy white cap, with a wavy edge -->
      <path d="M 30 118 C 28 76 62 50 100 50 C 138 50 172 76 170 118 C 158 124 148 116 136 123 C 124 116 112 125 100 119 C 88 125 76 116 64 123 C 52 116 42 124 30 118 Z" fill="#fdf4f2" stroke="#a8323f" stroke-width="4" />
      <ellipse cx="68" cy="70" rx="14" ry="6" fill="#ffffff" transform="rotate(-20 68 70)" />
      <!-- bright red drops she oozes from her cap -->
      <g fill="#e0283a" stroke="#8f1c28" stroke-width="1.6">
        <circle cx="127" cy="67" r="5" /><circle cx="149" cy="93" r="5" /><circle cx="55" cy="97" r="5" /><circle cx="97" cy="61" r="3.8" />
      </g>
      <g fill="#ffd6db"><circle cx="125.5" cy="65.5" r="1.4" /><circle cx="147.5" cy="91.5" r="1.4" /><circle cx="53.5" cy="95.5" r="1.4" /><circle cx="96" cy="60" r="1.1" /></g>
      ${face(100, 94, '#5c1a22')}
    `,
    dishArt: `
      <!-- a round, warty spore -->
      <g fill="#e9b4b4"><circle cx="144.0" cy="100.0" r="3" /><circle cx="138.1" cy="122.0" r="3" /><circle cx="122.0" cy="138.1" r="3" /><circle cx="100.0" cy="144.0" r="3" /><circle cx="78.0" cy="138.1" r="3" /><circle cx="61.9" cy="122.0" r="3" /><circle cx="56.0" cy="100.0" r="3" /><circle cx="61.9" cy="78.0" r="3" /><circle cx="78.0" cy="61.9" r="3" /><circle cx="100.0" cy="56.0" r="3" /><circle cx="122.0" cy="61.9" r="3" /><circle cx="138.1" cy="78.0" r="3" /></g>
      <circle cx="100" cy="100" r="42" fill="#fbe3e1" stroke="#a8323f" stroke-width="4" />
      <ellipse cx="82" cy="80" rx="9" ry="5" fill="#ffffff" transform="rotate(-25 82 80)" />
      ${face(100, 104, '#5c1a22')}
    `,
  },
  // Rosie: Sporothrix schenckii, behind "rose gardener's disease": her
  // spore stalk with a crown of teardrop spores at its tip and dark spores
  // along her thread. In the dish she plays like Fumi (see mold.js), and her
  // colonies darken and wrinkle as they ripen.
  {
    id: 'rosie',
    name: 'Rosie',
    looks: 'a Sporothrix schenckii mold: a short stalk crowned with a fan of cream and dusty-rose teardrop spores, with dark spores along her thread',
    motion: 'bob',
    frames: { home: '10 10 180 180', picker: '14 14 172 172', dish: '50 50 100 100' },
    art: `
      <!-- her thread (hypha) along the agar, and the short stalk (conidiophore) rising from it -->
      <g fill="none" stroke-linecap="round">
      <path d="M 18 156 C 56 146 78 168 100 160 C 124 151 152 166 186 150" stroke="#3d3632" stroke-width="9" />
      <path d="M 100 160 C 96 144 104 128 100 109" stroke="#3d3632" stroke-width="9" />
      <path d="M 18 156 C 56 146 78 168 100 160 C 124 151 152 166 186 150" stroke="#f4ece6" stroke-width="4" />
      <path d="M 100 160 C 96 144 104 128 100 109" stroke="#f4ece6" stroke-width="4" />
      </g>
      <!-- dark, cocoa spores that grow straight on the thread -->
      <g fill="#6b5548" stroke="#3d3632" stroke-width="2.2"><ellipse cx="40" cy="148.5" rx="8" ry="5.2" transform="rotate(-18 40 148.5)" /><ellipse cx="64" cy="154.5" rx="8" ry="5.2" transform="rotate(12 64 154.5)" /><ellipse cx="140" cy="152.5" rx="8" ry="5.2" transform="rotate(-10 140 152.5)" /><ellipse cx="164" cy="145.5" rx="8" ry="5.2" transform="rotate(20 164 145.5)" /></g>
      <!-- short attachments at her tip, where her spores sit -->
      <g stroke="#3d3632" stroke-width="2.6" stroke-linecap="round"><path d="M73.4 86.7 L68.5 87.6" /><path d="M73.7 75.9 L67.4 74.5" /><path d="M78.2 66.1 L73.7 62.9" /><path d="M86.1 58.9 L82.5 52.9" /><path d="M95.3 55.4 L94.4 50.0" /><path d="M105.2 55.5 L106.5 48.6" /><path d="M114.3 59.1 L117.2 54.4" /><path d="M122.1 66.5 L127.4 62.8" /><path d="M126.4 76.4 L131.3 75.3" /><path d="M126.6 86.7 L132.5 87.7" /></g>
      <!-- her crown: a loose fan of teardrop spores, a few in dusty rose -->
      <g stroke="#3d3632" stroke-width="2.8" stroke-linejoin="round"><path d="M 0 7.5 C 6.9 3.4 6.9 -7.5 0 -7.5 C -6.9 -7.5 -6.9 3.4 0 7.5 Z" fill="#f4ece6" transform="translate(62.6 88.6) rotate(-100)" /><path d="M 0 8.5 C 7.8 3.8 7.8 -8.5 0 -8.5 C -7.8 -8.5 -7.8 3.8 0 8.5 Z" fill="#e8c6c4" transform="translate(60.5 72.9) rotate(-77)" /><path d="M 0 9.0 C 8.3 4.0 8.3 -9.0 0 -9.0 C -8.3 -9.0 -8.3 4.0 0 9.0 Z" fill="#f4ece6" transform="translate(67.6 58.5) rotate(-54)" /><path d="M 0 9.5 C 8.7 4.3 8.7 -9.5 0 -9.5 C -8.7 -9.5 -8.7 4.3 0 9.5 Z" fill="#f4ece6" transform="translate(78.4 46.0) rotate(-31)" /><path d="M 0 9.8 C 9.0 4.4 9.0 -9.8 0 -9.8 C -9.0 -9.8 -9.0 4.4 0 9.8 Z" fill="#e8c6c4" transform="translate(92.9 41.9) rotate(-10)" /><path d="M 0 9.8 C 9.0 4.4 9.0 -9.8 0 -9.8 C -9.0 -9.8 -9.0 4.4 0 9.8 Z" fill="#f4ece6" transform="translate(108.1 40.5) rotate(11)" /><path d="M 0 9.5 C 8.7 4.3 8.7 -9.5 0 -9.5 C -8.7 -9.5 -8.7 4.3 0 9.5 Z" fill="#f4ece6" transform="translate(121.5 47.7) rotate(32)" /><path d="M 0 9.0 C 8.3 4.0 8.3 -9.0 0 -9.0 C -8.3 -9.0 -8.3 4.0 0 9.0 Z" fill="#e8c6c4" transform="translate(133.6 58.5) rotate(55)" /><path d="M 0 8.5 C 7.8 3.8 7.8 -8.5 0 -8.5 C -7.8 -8.5 -7.8 3.8 0 8.5 Z" fill="#f4ece6" transform="translate(138.1 73.9) rotate(78)" /><path d="M 0 7.5 C 6.9 3.4 6.9 -7.5 0 -7.5 C -6.9 -7.5 -6.9 3.4 0 7.5 Z" fill="#f4ece6" transform="translate(138.4 88.8) rotate(100)" /></g>
      <!-- her round tip, with her face -->
      <circle cx="100" cy="82" r="27" fill="#f8f3ee" stroke="#3d3632" stroke-width="4" />
      <ellipse cx="88" cy="69" rx="7" ry="3.6" fill="#ffffff" transform="rotate(-25 88 69)" />
      <!-- her own, slightly smaller face, to fit her round tip -->
      <g class="face"><circle cx="91" cy="84" r="5" fill="#1f1a17" /><circle cx="109" cy="84" r="5" fill="#1f1a17" /><circle cx="92.6" cy="82.4" r="1.7" fill="white" /><circle cx="110.6" cy="82.4" r="1.7" fill="white" /><ellipse cx="84" cy="93" rx="4.6" ry="2.7" fill="#f9a8d4" opacity="0.95" /><ellipse cx="116" cy="93" rx="4.6" ry="2.7" fill="#f9a8d4" opacity="0.95" /><path d="M95 93 Q100 98 105 93" stroke="#1f1a17" stroke-width="2.8" fill="none" stroke-linecap="round" /></g>
    `,
    dishArt: `
      <!-- one small, oval spore (conidium) -->
      <ellipse cx="100" cy="100" rx="38" ry="44" fill="#f4ece6" stroke="#3d3632" stroke-width="4" />
      <ellipse cx="84" cy="78" rx="8" ry="4.5" fill="#ffffff" transform="rotate(-25 84 78)" />
      ${face(100, 104, '#1f1a17')}
    `,
  },
  // Neve: Cryptococcus neoformans, a round yeast in a thick, glossy capsule
  // (like Pearl's in PetriPals), with a small bud on a narrow neck that has
  // a capsule of its own. In the dish every cell wears one (see yeast.js).
  {
    id: 'neve',
    name: 'Neve',
    looks: 'a round, soft-aqua Cryptococcus neoformans yeast in a thick, glossy, see-through capsule, with a small bud joined to her by a narrow neck',
    motion: 'bob',
    frames: { home: '14 14 176 176', picker: '18 18 168 168', dish: '14 14 176 176' },
    art: `
      <!-- her capsule: a thick, glossy, see-through sugar coat, the bright halo
           you see around her in ink. The bud has one of its own. -->
      <circle cx="94" cy="110" r="70" fill="#ffffff" fill-opacity="0.55" stroke="#c9e6eb" stroke-width="3.5" />
      <circle cx="137.9" cy="69.5" r="31" fill="#ffffff" fill-opacity="0.55" stroke="#c9e6eb" stroke-width="3" />
      <path d="M40 92 Q50 58 84 46" stroke="#ffffff" stroke-width="4.5" fill="none" stroke-linecap="round" opacity="0.95" />
      <circle cx="146" cy="150" r="3.2" fill="#ffffff" opacity="0.95" />
      <path d="M120 51.5 Q127 42 138.5 40.5" stroke="#ffffff" stroke-width="3" fill="none" stroke-linecap="round" opacity="0.95" />
      <!-- her round cell and her small bud, still joined by a narrow neck: she
           buds through a small opening, not a wide one like Olive's. Both
           outlines go down first, then both fills on top, so the two read as
           one pinched shape. -->
      <circle cx="94" cy="110" r="46" fill="none" stroke="#0e7490" stroke-width="9" />
      <circle cx="137.9" cy="69.5" r="15" fill="none" stroke="#0e7490" stroke-width="8" />
      <circle cx="94" cy="110" r="46" fill="#b9e1e8" />
      <circle cx="137.9" cy="69.5" r="15" fill="#b9e1e8" />
      <ellipse cx="74" cy="88" rx="12" ry="6" fill="#ffffff" transform="rotate(-30 74 88)" />
      ${face(94, 110, '#0b3b46')}
    `,
  },
];

// Yeasts on both ends, with the three molds spread out between them.
// Phones show only the first six.
const HOME = ['yara', 'penelope', 'sasha', 'rosie', 'candi', 'miri', 'peachy', 'neve', 'ruby', 'maizey', 'fumi', 'olive'];
export const HOME_GALS = HOME.map((id) => GALS.find((gal) => gal.id === id));

// How many gals fit on one page of the picker: four across, two down.
export const PAGE_SIZE = 8;

// `gals` split into the picker's pages, in order, PAGE_SIZE to a page (the
// last page has whoever is left over).
export function pickerPages(gals = GALS, size = PAGE_SIZE) {
  const pages = [];
  for (let i = 0; i < gals.length; i += size) pages.push(gals.slice(i, i + size));
  return pages;
}

// A copy of `gals` in a random order (a Fisher-Yates shuffle, so every order
// is equally likely). The picker uses it so no gal is always first.
export function inRandomOrder(gals, random = Math.random) {
  const order = [...gals];
  for (let i = order.length - 1; i > 0; i--) {
    const j = Math.floor(random() * (i + 1));
    [order[i], order[j]] = [order[j], order[i]];
  }
  return order;
}

export function galById(id) {
  return GALS.find((gal) => gal.id === id);
}

// Her drawing as an <svg>, framed for `page` ('home', 'picker' or 'dish').
function drawing(gal, page) {
  const svg = document.createElementNS(SVG, 'svg');
  svg.setAttribute('viewBox', gal.frames[page]);
  svg.innerHTML = page === 'dish' && gal.dishArt ? gal.dishArt : gal.art;
  // Anything drawn with SVG's own <animate> moves on the home page and in
  // the dish, but stays still on the picker, and for anyone who has asked for
  // less motion (CSS can't pause <animate>).
  const reduced = window.matchMedia?.('(prefers-reduced-motion: reduce)').matches;
  if (page === 'picker' || reduced) {
    for (const wiggle of svg.querySelectorAll('animate')) wiggle.remove();
  }
  return svg;
}

// For the home page's row of gals.
export function homeGal(gal) {
  const svg = drawing(gal, 'home');
  svg.setAttribute('class', `gal ${gal.motion}`);
  svg.setAttribute('role', 'img');
  svg.setAttribute('aria-label', `${gal.name}, ${gal.looks}`);
  return svg;
}

// Her picture on a colored tile, for the picker. The name
// next to it says who she is, so the picture is hidden from screen readers.
export function galTile(gal) {
  const tile = document.createElement('div');
  tile.className = `gal-icon ${gal.id}`;
  const svg = drawing(gal, 'picker');
  svg.setAttribute('aria-hidden', 'true');
  tile.append(svg);
  return tile;
}

// For the petri dish, hidden until the game picks her (main.js).
export function dishGal(gal) {
  const svg = drawing(gal, 'dish');
  svg.setAttribute('class', `dish-gal ${gal.motion}`);
  svg.dataset.gal = gal.id;
  svg.dataset.name = gal.name;
  svg.setAttribute('role', 'img');
  svg.setAttribute('aria-label', `${gal.name}, ${gal.looks}`);
  svg.setAttribute('hidden', '');
  return svg;
}
