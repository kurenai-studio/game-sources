# Changelog

Every version of Breach, newest first. Development followed the roadmap in
[docs/concept.md](docs/concept.md#roadmap-and-mvp-scope): prove the core feel on a training
range, build one mission end to end, then a campaign, then the whole game, then polish it for
release, and finally give every campaign its own sense of place. Versions before the web
release follow `0.<milestone>.<patch>`. See [Versioning](README.md#versioning).

| Milestone | Versions | Scope |
| --- | --- | --- |
| Prototype | 0.1 | The Range: vision, aim, doors, sound |
| Vertical slice | 0.2 | One mission, briefing to debrief |
| MVP | 0.3 | Saves, ranks, the Officer campaign |
| Content | 0.4 | Every campaign, enemy type, gun and twist |
| Presentation | 0.5 – 0.7 | Menus, game feel, briefing and promotion |
| Web release | 1.0 | Release and polish |
| Places | 1.1 – 1.3 | Furnished rooms; each campaign one place |
| Epilogue | 1.4 | The Captain campaign |
| Final unlock | 1.5 | The breach charge |

## v1.5.1

Documentation for the final release.

- The README, changelog and design document describe the finished game. The breach charge's
  description spells out that it works on any wall with open floor behind it, the outside
  walls of a building included, for a way in of your own.

## v1.5.0

The final unlock: the breach charge.

- Issued with promotion to Captain, one per mission (not on the rooftop overwatch). Face a wall
  with open floor behind it and press G: after a 2.5 s fuse it blows a hole one or two tiles
  wide. Anyone with a line to the blast within five tiles is stunned for a few seconds; anyone
  right next to it takes a hit, the operator included. It's the loudest thing in the game, so
  the alarm goes up and the building comes to look.
- The charge sits on the HUD beside armour and health, in the briefing's loadout, in the
  controls and on the promotion screen.
- Furniture pass: long pieces (bookcases, cabinets, benches) always back onto a wall along
  their length. Corvan Depot's staff annex is walled off from the car park.

## v1.4.0

The epilogue: the Captain campaign, Inside job. Four cases on the leak inside headquarters,
ending in the largest level in the game.

- Marsh Lane: armed men have taken a police safe house, a farmhouse out on the marsh. The
  witness is held in the back bedroom; once you're seen, a clock runs.
- Records Archive: the Calloway files are being shredded in the dark archive on Harbour Road.
- The Anchor: Hale's fixer in the back office of the police social club, on a busy night.
- Police Headquarters: the finale. Superintendent Hale's team holds the station round its
  vehicle yard: lobby, interview rooms, custody suite and cells, CID, the briefing room, the
  control room, armoury and canteen. Four ways in; Hale is burning records in his office.
- The final rank, Superintendent, and the Captain difficulty profile.
- Snooker tables for the club.
- Briefing plans: entry labels sit on a dark backing and always inside the plan.
- The campaign screen lays out six campaigns; the promotion badge scales to the taller
  insignia of the senior ranks.

## v1.3.0

Places, part three: Clean money and The top furnished. Both were built as one place each from
the start, so their layouts stay and their rooms are dressed.

- Grand Atlas: laundry and dry store on the service level, the hotel kitchen's lines and the
  security office; every room on floor 4 with a bath, bed, wardrobe, desk and armchair;
  ballroom tables, the boardroom table and a fitted kitchen on the conference floor; crates,
  pallets and bins in the yard; the penthouse lounge, bedroom, kitchen, study and terrace.
- The top: Hillcrest's kitchen, lounge, bedrooms and pool loungers; the Halcyon's salon and
  forward cabins; Ardley Lodge's library, study, drawing room and flower beds; the Gull Point
  cottage and boathouse; Westcliff House's glass room, living room, kitchen and bedroom.
- Planters span several tiles, for hedges and flower beds.

## v1.2.0

Places, part two: Supply chain as Corvan's sites across the docklands, a step up from the
estate. Glass appears at the head office, water at the docks.

- Corvan Depot: racking aisles, a sorting line, three loading docks onto the yard and a staff
  annex with the transport office.
- Corvan Head Office: offices round a glass courtyard; glass-fronted meeting rooms, the
  manager's office and his PA, kitchen, reception and an unmapped server room.
- Salter Street: a lodging house of bedsits off one narrow hall, with a dark rear outrigger.
- Cold Store: a marshalling hall between three dark racked chambers and the blast freezer,
  plant room and dock office, with a door onto the quay.
- Ferry Road: a fenced lorry yard with a gatehouse, drivers' cabin, fuel island and trailer
  park, and a cross-dock warehouse whose bays open onto it.
- Harbour Freight Office: Rook's office at the end of Pier Seven, water on both sides.
- Every entry is checked so no guard has a clear view of it as the intro ends.

## v1.1.1

Street crime tuning.

- Lighter clutter: about one item for every three tiles of floor.
- Clutter lies under vehicles and containers.
- Westquay Lockups: two-tile passages round to the corner lock-ups.

## v1.1.0

Places, part one: furnished rooms, and Street crime as one estate.

- Furniture: beds, sofas, kitchens, bathrooms, desks, shelving, workbenches, crates, pallets,
  drums, bins and more, each drawn for what it is and turned to the wall it stands against.
  Rugs and a little clutter (party litter, a bagging table, laundry, paperwork, tools) give
  rooms a life. Furniture blocks movement, not sight or bullets.
- Street crime is the Ashby estate, kept simple: houses, flats, a garage and lock-ups, brick
  and timber only.
  - 14 Harbour Lane: a mid-terrace with a rear extension, a yard and a shed, between two
    neighbours.
  - Fenwick Terrace: an end-of-terrace on a corner, open-plan at the back, a long garden.
  - Tollgate Flats: the ground floor of a dark low-rise block; two flats either side of a
    corridor, the second one unmapped.
  - Mercer Street Garage: a workshop with cars on the bays, a parts store, reception and
    office.
  - Kestrel Road: a bungalow off a central corridor with an attached garage.
  - Westquay Lockups: a court of lock-ups round a yard, a courier's lorry in the middle.
- Every entry is checked so no guard has a clear view of it as the intro ends.
- Briefing plans draw solid blocks (neighbouring houses, locked flats) quietly, so the target
  building reads first.

## v1.0.3

Release polish.

- Glass frames meet walls cleanly: a wall that meets a glass front runs on to the frame, a
  glass run turning a building corner closes into the wall, and runs are drawn as one even
  line.
- Volume steps both ways with the mouse: ‹ and › beside the value, and a click on the row
  cycles round.
- The campaign screen header spaces the rank insignia for every rank.

## v1.0.2

Release polish.

- The debrief title sizes itself to its panel.
- Glass panes join walls only along their own run.
- Guns in hand drawn part by part (stock, receiver, barrel, scope or sight), carried over the
  body with slim sleeves and gloved hands.
- The mission title card clears when the intro ends.

## v1.0.1

Repository housekeeping; no gameplay changes.

- MIT licence, and licence, homepage, repository and Node version in `package.json`.
- Level files grouped into one folder per campaign; tests split into one file per area.
- The design document matches the released game.

## v1.0.0

The web release: five campaigns, from the Range to the people at the top, played in the
browser.

- A proper page: title, description, an icon and a share image for links.
- A loading screen in the game's style while the fonts load, and a note on touch-only devices
  that the game is played with a mouse and keyboard.
- Tabbing away mid-mission pauses it.
- HUD details in the display face.
- README for players and contributors, with credits.

## v0.7.0

Presentation, part three: briefing and promotion.

- Briefing: the display face for the case title and section headings (each with a rule), gun
  choices as chips, and Deploy and Back buttons. The plan scans in under a moving line,
  command's marks fade in after it, and the chosen entry point pulses. Up and down pick an
  entry, left and right a gun, Enter deploys, Escape goes back.
- Promotion is a ceremony: the insignia stamped in with a flash, the new rank, the note line
  by line with its signature, and a card for whatever is issued with it.
- Every briefing is checked for overlapping text with every gun selected, after the entrance
  animations.

## v0.6.0

Presentation, part two: game feel.

- The operator walks: boots step in turn, the shoulders sway, the gun bobs. Reloading dips and
  tilts the gun; swapping brings the new one up into the aim. Going down is a slump, not a cut.
- Suspects fall when stopped: knocked back along the shot and twisting as they go down.
- Hit markers: an X where a shot lands on someone, red when it puts them down.
- A crosshair replaces the system cursor in play, opening up as the aim wanders.
- A small camera kick with every shot, bigger for heavier guns (screen shake setting).
- Footsteps sound like what they land on: floorboards, tiles, concrete, grass or decking.
- Levels have their own background: wind outdoors, a low room tone indoors.
- Each mission opens with a title card: the case name typed out, then where and when.

## v0.5.0

Presentation, part one: menus.

- Title screen: a live backdrop (a level's plan drifting under a sweeping, wall-occluded
  light), the logo, and career cards with rank insignia and progress.
- Campaign screen: campaign cards with star progress, and the selected campaign's story,
  promotion progress and cases with location and time.
- Every menu works from the keyboard (arrows, Enter, Escape) as well as the mouse, with hover
  and focus states and their own sounds. Screens fade between each other.
- Settings panel (title screen and pause menu): volume, blood, screen shake and fullscreen.
- Pause menu and debrief: stars stamp in one by one, then the numbers and case note.
- A low ambient bed plays under the menus.
- Fonts: Barlow Condensed and JetBrains Mono, bundled with the game (SIL Open Font License).

## v0.4.14

Content: the new terrain reaches the earlier campaigns.

- Harbour Freight Office stands on Pier Seven, Cold Store on the Westquay dock, and Westquay
  Lockups by a canal: harbour water and timber quays.
- Corvan Head Office and the Grand Atlas boardroom get glass partitions, so you see (and are
  seen) across the floor.
- Kestrel Road gets windows onto the back garden; the penthouse a glass front onto its
  terrace and a pool.

## v0.4.13

Content: Ardley Lodge tuning.

- The grounds patrol and the kitchen guard face away from the Kitchen Garden entry.
- Only real trouble (seeing you, or hearing a shot, a shout or breaking glass) sends a guard to
  a panel. He walks briskly and needs 3 s there, with an ALARM countdown on screen.
- Suppressed shots carry about half as far.

## v0.4.12

Content: the Silent twist, final design.

- Ardley Lodge has two alarm panels, marked ALARM on the plan. Alerted guards push or dig in as
  usual, and the alerted guard nearest a panel runs for it. Drop him before he sets it off and
  the mission goes on; the next alerted guard takes up the run.

## v0.4.11

Content: glass you can shoot through.

- A shot through a window shatters it, with a crash every suspect in earshot hears and shards
  left on the floor. A broken pane is an opening you can walk through. Enemy shots break glass
  too.
- Panes are drawn on their own layer as framed, joined-up lines, so corners and junctions
  with walls and doors close.

## v0.4.10

Content: the Lieutenant campaign, The top.

- Five cases following Voight's contacts: Hillcrest Villa (an L-shaped glass villa round a
  pool), The Halcyon (a yacht at its berth), Ardley Lodge (a country house round a cloistered
  courtyard), Gull Point (a round lighthouse on a rocky point) and Westcliff House (a clifftop
  villa with a glass room over the sea). Finishing it promotes you to Captain.
- New terrain: water and glass (block movement, not sight or bullets) and outdoor timber
  decking. Low walls and rails outdoors are stone and join up into one line.
- The Silent twist at Ardley Lodge, first pass: the alarm ends the case.
- The alarm needs a suspect in earshot: a suppressed shot in an empty wing goes unheard.
- A mission that is already lost stays lost, even if the operator is hit in the moments after.

## v0.4.9

Content: Sergeant campaign tuning.

- Rear Yard: six or seven suspects who run for the car faster, the extra ones starting further
  out, so the pressure builds.
- The loadout reserves room for the longest gun description on offer, measured on screen.

## v0.4.8

Content: the Sergeant campaign, Clean money. One night at the Grand Atlas Hotel, following
Meridian Partners from the service level to the penthouse.

- Five cases: Service Level, Floor 4, Conference Suite, Rear Yard and Penthouse.
- The Heavy: a contractor in a plate carrier with a rifle. One more hit to stop, always pushes
  towards a fight, fires a little faster.
- Rear Yard is the rooftop overwatch: sniper rifle issued, the camera pulled right out over the
  yard. When the alarm goes up, every suspect makes for the getaway car; one reaching it fails
  the mission.
- Promotion out of the campaign makes you Lieutenant and issues suppressors.

## v0.4.7

Content: the briefing structure and the writing style.

- Briefing: situation (short bullets), objective (one line), intel, loadout and entry point.
  The header shows the campaign and case number, the address, the time of the operation and
  the unit.
- Intel rows read Suspects, Weapons, Civilians and Intel, in short form ("4–6, light vests").
- Case files, radio calls, debrief notes and promotion notes in a terse, procedural style:
  names, times and counts, callsigns on the radio. In-game messages follow suit.
- Map labels have a dark backing so they read over walls.

## v0.4.6

Content: the specialty cases, final design. Every twist hangs off one moment, the alarm (a
suspect sees you, or a shot or shout).

- Fenwick Terrace is a house party: armed men among six to eight guests who freeze or scatter.
- Kestrel Road: one of the homeowners is held in a back bedroom. Once the alarm goes up, a
  30-second clock runs.
- Corvan Head Office: when the alarm goes up, the nearest suspect runs for the shredder. Stop
  him within eight seconds or the files, and the first star, are gone.
- Briefing: a twist is one yellow line at the top of the intel, with a yellow label on the
  plan. At most three civilians are marked. Entry labels at the edge of the map sit under their
  marker.

## v0.4.5

Content: specialty cases, second pass.

- Fenwick Terrace joins Street crime as case 2, prototyping a pursuit twist: the crew's runner
  bolts for a way out the moment he sees you.
- Overwatch moves to its place in the Sergeant campaign, where the sniper rifle is issued;
  Supply chain settles at six cases.
- The sniper scope pulls the camera further out and shows a wider strip.

## v0.4.4

Content: the gun line-up and the first specialty cases.

- Promotions issue the shotgun (Officer), the assault rifle (Senior Officer) and the sniper
  rifle (Sergeant); suppressors follow at Lieutenant.
- Sniper rifle: bolt action, five rounds, one hit stops anyone. Hold Space to look down the
  scope: the operator braces, vision reaches far down the aim and the camera pushes out.
- Suppressors fit the pistol, assault rifle and sniper rifle; a suppressed shot is heard about
  a third as far. Toggled on the briefing.
- Salter Street, a close-quarters lodging house made for the shotgun, and an overwatch
  prototype that issues the sniper rifle for the job.
- The briefing remembers your last gun and fits the loadout on one line.

## v0.4.3

Content: every gun has a job.

- From the Senior Officer campaign on, suspects wear light vests and take two hits; the
  briefing says so. Officer-campaign suspects go down to one.
- Damage per gun: one hit per pistol shot, one per shotgun pellet, two per rifle round.
- A hit that doesn't stop a suspect makes them flinch off their aim and turn to the shooter.
- The briefing describes the chosen gun.

## v0.4.2

Content: careers and cover.

- Start menu: a normal or a realism career, each with its own progress; existing saves move
  across automatically.
- A new realism career can skip the academy and start as an Officer.
- Tall objects block sight and bullets: racking, lorries, containers and vans. Low furniture
  and cars are cover you can see and shoot over.
- Intros are a cutscene: nobody can spot the operator until they end, and gate entries end
  behind the fence.

## v0.4.1

Content: realism mode.

- An optional career with one life. Going down ends it and resets progress to Recruit, with a
  "Career over" debrief showing the rank and stars it reached.
- No restarting a realism mission; quitting, or closing the game mid-mission, counts as going
  down.

## v0.4.0

Content begins: the Senior Officer campaign.

- Difficulty rises with rank: from Senior Officer on, enemies react faster, notice you sooner,
  aim tighter and fire more often.
- The Hider: waits behind cover with a shotgun, tracks you silently and only fires up close.
- Supply chain, five cases following Corvan Logistics: Corvan Depot, Corvan Head Office, Cold
  Store, Ferry Road and Harbour Freight Office.
- Warehouse racking and lorries; props with custom sizes.
- The menu lists campaigns on the left and the chosen campaign's cases on the right, so it
  scales to every rank.

## v0.3.3

MVP: lighting and solid vehicles.

- The exterior is always lit; people outside still only show when you can see them.
- Vans, cars and containers are solid for everyone, and intro walks route around them. A test
  checks every intro route stays clear of walls, doors and props.
- The tagging workflow reports a refused tag as a warning and carries on.

## v0.3.2

MVP: release tooling.

- The tagging workflow tags every version in a push on the commit that introduced it.

## v0.3.1

MVP: the Officer campaign, with a story thread from street-level dealing to the supplier
behind it.

- Tollgate Flats (a dark flat with the power cut), Mercer Street Garage (an open workshop with
  two patrols), Kestrel Road (a home taken over, on unverified intel) and Westquay Lockups (the
  open-yard finale).
- Promotion to Senior Officer needs every case and enough stars.
- Indoor concrete floors, cars and containers; each entry can have its own drop-off.

## v0.3.0

MVP: the campaign framework.

- Progress saved in the browser: rank, best stars and completed levels.
- Ranks and promotion, each with a note from the captain. Passing the Range makes you an
  Officer.
- The menu shows your rank and each campaign with its cases, stars, locks and promotion
  target.
- Loadout: choose a primary gun on the briefing; the pistol is always carried. In missions, 1
  selects the primary and 2 the pistol.

## v0.2.3

Vertical slice: release tooling.

- A workflow tags each version (`vX.Y.Z`, from `package.json`) on GitHub when it lands on
  `main`.

## v0.2.2

Vertical slice: enemy temperament.

- Pushers come for you fast and loud; holders dig in a few tiles back from the door you'd come
  through and wait, reacting faster while aimed. Set per slot or rolled on every deploy.

## v0.2.1

Vertical slice: tuning.

- Gunfire is heard through the whole building; weapons carry a suppressor flag for the later
  unlock.
- A brisker intro walk and tighter radio lines (about 5.5 s for the longest).
- Entry choice: numbered markers with names on the plan, the chosen route drawn bright, an
  entry list and a Deploy button that names the entry.
- The property boundary is drawn quieter than the building's walls.

## v0.2.0

Vertical slice: the first Officer case, played from briefing to debrief.

- Main menu, and a briefing styled as a police tablet: the floor plan with areas the plans
  don't cover, command's marks, the case file and intel. Choose one of three entries.
- The situation is rolled from the intel on every deploy: the count stays in the briefed range,
  positions vary, the layout doesn't.
- 14 Harbour Lane: a terraced house with a street, garden and three entries.
- Every level opens with a skippable intro: letterbox bars, the camera pulled back, the
  operator walking to the entry while radio lines play.
- Lookouts and Patrollers: sight, hearing, pathfinding through the house (opening doors) and
  return fire. Lookouts shout; patrollers' footsteps carry through walls.
- Civilians freeze or flee and are secured by holding E. A mission is complete when every
  suspect is down and every civilian secured.
- Armour and health, operator down, and retry from the briefing with a fresh roll.
- Debrief with stars, suspects down, civilians secured, accuracy and a case note.
- Floor materials, plaster interior walls and a police van. The weapon light is always on;
  dark rooms limit how far you see.

## v0.1.4

Prototype: HUD and settings.

- Minimal HUD: the magazine as a row of rounds and short, quiet messages. Every mission's
  objective is simply to secure the area.
- Tutorial text only on the Range, each station's card fading once read.
- Esc pauses with settings (blood, sound), restart and the controls; settings persist.
- Blood effects for people, on by default, never on the Range's cardboard props.
- Range targets turn to face the operator when first seen.

## v0.1.3

Prototype: look and feel.

- Renders at the displayed size (up to 2x), sharp on large and high-density screens.
- Soft fog edges, and vision that fades towards the edge of its range.
- Eased movement and aim; the laser drifts slowly and steadies when standing still. Recoil
  knocks the gun back visually.
- Detailed floors, walls, shadows, doors, furniture, operator and targets.
- Bullet holes that stay, sparks, cardboard chips, ejected casings and muzzle light.
- F3 shows a frame-rate readout.

## v0.1.2

Prototype: documentation.

- The design document (`docs/concept.md`), this changelog and the versioning convention.
- The build version on the title card.

## v0.1.1

Prototype: handling.

- A 60° vision cone and lighter recoil on every gun.
- Doors have a single open/close action (E or right click), and the door station asks you to
  clear three booths.

## v0.1.0

Prototype: the Range.

- Phaser 3 + TypeScript + Vite, deployed to GitHub Pages.
- Raycast vision cone with fog of war: visible, remembered and unknown.
- Laser aim with wobble that steadies when standing still.
- Doors whose leaves block line of sight, cardboard targets and sound ripples through walls.
- Five training stations (movement lane, target lane, door station, shoot or don't, a dark kill
  house) and a debrief with stars.
- Unit tests for geometry, visibility, level parsing and collision.
